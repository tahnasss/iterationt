#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


layout(location = 0) out vec4 compositeOutput3;

in vec2 texcoord;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"


vec4 ReflectionFilter(sampler2D v, GbufferData gbuffer, float size, vec2 noise){
    vec4 reflectionData = texture(v, texcoord);
    if (!gbuffer.material.doCSR || reflectionData.w < 0.0001) return reflectionData;

    vec3 viewPos = ViewPos_From_ScreenPos(texcoord, gbuffer.depthW);
    vec3 viewDir = normalize(viewPos);
    float linearDepth = -viewPos.z;
    float NdotV = saturate(dot(-viewDir, gbuffer.normalW));

    float roughness2 = max(gbuffer.material.roughness, 1e-4);

    float T = size * 0.9;
    T *= min(roughness2 * 20.0, 1.1);
    T *= reflectionData.w * 0.8 + 0.2;

    vec4 accum = vec4(0.0);
    float weights = 0.0;

    float J = reflectionData.w * 0.475 + 0.025;

    const float cos17508 = cos(1.5708);
    const float sin15708 = sin(1.5708);
    vec2 D = normalize(cross(gbuffer.normalW, viewDir).xy);
    vec2 L = D * mat2(cos17508, -sin15708, sin15708, cos17508);
    D *= mix(0.1075, 0.5, NdotV);
    L *= mix(0.7, 0.5, NdotV);

    vec3 nVrN = reflect(-viewDir, gbuffer.normalW);

    vec2 ScreenTexel4 = 4.0 * pixelSize;
    vec2 ScreenTexel4Inverse = 1.0 - ScreenTexel4;

    vec2 Temp = T * 1.5 * pixelSize;
    L *= Temp;
    D *= Temp;
    roughness2 = 100.0 / roughness2;

    for (int i=-1; i<=1; i++){
        vec2 Temp2 = D * (i + noise.x) + texcoord;

        for (int j=-1; j<=1; j++){
            vec2 sampleCoord = Temp2 + L * (j + noise.y);
            sampleCoord = clamp(sampleCoord, ScreenTexel4, ScreenTexel4Inverse);

            vec4 sampleData = texture(v, sampleCoord);

            if (sampleData.w < 0.0001) continue;

            float sampleLinerDepth = LinearDepth_From_ScreenDepth(texture(gdepthtex, sampleCoord).x);
            vec3 nVrSN = reflect(-viewDir, DecodeNormal(texture(colortex4, sampleCoord).xy));

            float normalWeight = pow(saturate(dot(nVrN, nVrSN)), roughness2);
            float depthWeight = exp(-(abs(sampleLinerDepth - linearDepth) * 1.1));
            float sampleWeight = normalWeight * depthWeight;

            accum += vec4(pow(length(sampleData.xyz), J) * normalize(sampleData.xyz + 1e-10), sampleData.w) * sampleWeight;
            weights += sampleWeight;
        }
    }
    if (weights < 0.0001) return reflectionData;

    accum /= weights + 0.0001;
    accum.xyz = pow(length(accum.xyz), 1.0 / J) * normalize(accum.xyz + 1e-06);

    return accum;
}

float BlueNoise(const float ir){
	return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) % 64, 0).x + ir * (frameCounter % 64));
}

vec2 NoiseRotated(float noise){
	return  (0.495 * sqrt(noise)) * vec2(cos(noise * 2.0 * PI), sin(noise * 2.0 * PI));
}


void main(){
	GbufferData gbuffer = GetGbufferData();

    #ifdef PROGRAM_REFLECTIONFILTER_0
        vec4 reflection = ReflectionFilter(colortex3, gbuffer, 30.0, vec2(0.0));
    #else
        vec2 noise = NoiseRotated(BlueNoise(1.41421356));
        vec4 reflection = ReflectionFilter(colortex3, gbuffer, 15.0, noise);
    #endif

	compositeOutput3 = reflection;
}

/* DRAWBUFFERS:3 */
