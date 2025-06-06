#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"


const bool	colortex1MipmapEnabled  = true;


layout(location = 0) out vec4 compositeOutput1;

in vec2 texcoord;


#include "/Lib/Uniform/GbufferTransforms.glsl"


vec2 NoiseRotated(float noise){
	return  (0.6 * sqrt(noise)) * vec2(cos(noise * 2.0 * PI), sin(noise * 2.0 * PI));
}


vec2 CalculateDistOffset(const vec2 prep, const float angle, const vec2 offset) {
    return offset * angle + prep * dot(prep, offset) * (1.0 - angle);
}


vec3 DepthOfField(){
    if (floor(texture(colortex5, texcoord).b * 255.0) == 4) return texture(colortex1, texcoord).rgb;

    const float filmDiagonal    = 0.04327;
    const float filmHeight      = 0.024;
    const float focalLength     = 0.5 * filmHeight * gbufferProjection[1][1];
    const float aperture        = CAMERA_APERTURE;
    //const float apertureRadius  = 0.5 * focalLength / aperture;

    float depth = LinearDepth_From_ScreenDepth(texture(depthtex0, texcoord).x);
    float centerDepth = LinearDepth_From_ScreenDepth(centerDepthSmooth);
    #if CAMERA_FOCUS_MODE == 0
        float focus = centerDepth + CAMERA_AUTO_FOCAL_OFFSET;
    #else
        float focus = CAMERA_FOCAL_POINT;
    #endif

    float pcoc = focalLength * focalLength * (depth - focus) / (depth * (focus - focalLength) * aperture * filmHeight);

    float noise = InterleavedGradientNoise(gl_FragCoord.xy);
    //noise = fract(noise + 1.61803398 * (frameCounter % 64));


    const int ringCounts = 3;
    float ringSteps = abs(pcoc) * screenSize.x / ringCounts;


    int lod = int(min(floor(log2(ringSteps)), 3.0));

    vec3 dof = vec3(0.0);
    float weights = 0.0;

    vec2 randomOffset = NoiseRotated(noise) * ringSteps;

    for(int i = 0; i < ringCounts; i++){
        int ringSampleCounts = max(i * 8, 1);

        for(int j = 0; j < ringSampleCounts; j++){

            float rot = (float(j * 2 + i % 2)) * PI / float(ringSampleCounts);

            vec2 sampleCoordOffset = vec2(cos(rot), sin(rot));
            sampleCoordOffset *= i * ringSteps;
            sampleCoordOffset += randomOffset;
            sampleCoordOffset *= pixelSize;

            dof += CurveToLinear(textureLod(colortex1, texcoord.st + sampleCoordOffset, lod).rgb);
            weights += 1.0;
        }
    }
    dof /= weights;

    return LinearToCurve(dof);
}


void main(){
    #ifdef DOF
    #endif
    vec3 color = DepthOfField();

    compositeOutput1 = vec4(color, 1.0);
}

/* DRAWBUFFERS:1 */
