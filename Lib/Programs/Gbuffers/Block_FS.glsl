//Block_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform float wetness;
uniform float frameTimeCounter;

uniform sampler2D texture;
uniform sampler2D specular;
uniform sampler2D normals;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;


in vec4 color;
in vec2 texcoord;
in vec4 viewPos;
in vec3 worldPos;
in vec2 blockLight;
flat in float materialIDs;

in vec4 portalCoord;


float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}


#include "/Lib/IndividualFounctions/Ripple.glsl"


const vec3[] COLORS = vec3[](
    vec3(0.022087, 0.098399, 0.110818),
    vec3(0.011892, 0.095924, 0.089485),
    vec3(0.027636, 0.101689, 0.100326),
    vec3(0.046564, 0.109883, 0.114838),
    vec3(0.064901, 0.117696, 0.097189),
    vec3(0.063761, 0.086895, 0.123646),
    vec3(0.084817, 0.111994, 0.166380),
    vec3(0.097489, 0.154120, 0.091064),
    vec3(0.106152, 0.131144, 0.195191),
    vec3(0.097721, 0.110188, 0.187229),
    vec3(0.133516, 0.138278, 0.148582),
    vec3(0.070006, 0.243332, 0.235792),
    vec3(0.196766, 0.142899, 0.214696),
    vec3(0.047281, 0.315338, 0.321970),
    vec3(0.204675, 0.390010, 0.302066),
    vec3(0.080955, 0.314821, 0.661491)
);

const mat4 SCALE_TRANSLATE = mat4(
    0.5, 0.0, 0.0, 0.25,
    0.0, 0.5, 0.0, 0.25,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0
);

mat2 mat2_rotate_z(float radian) {
	return mat2(
		cos(radian), -sin(radian),
		sin(radian), cos(radian)
	);
}

mat4 end_portal_layer(float layer) {
    mat4 translate = mat4(
        1.0, 0.0, 0.0, 17.0 / layer,
        0.0, 1.0, 0.0, (2.0 + layer / 1.5) * (frameTimeCounter * 0.0005),
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    mat2 rotate = mat2_rotate_z(radians((layer * layer * 4321.0 + layer * 9.0) * 2.0));

    mat2 scale = mat2((4.5 - layer / 4.0) * 2.0);

    return mat4(scale * rotate) * translate * SCALE_TRANSLATE;
}

void main(){
//albedo
	vec4 albedo = texture2D(texture, texcoord);
	albedo *= color;

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif

//TBN
	vec3 dp1 = dFdxCoarse(viewPos.xyz);
	vec3 dp2 = dFdyCoarse(viewPos.xyz);
	vec3 N = normalize(cross(dp1, dp2));
	vec2 duv1 = dFdx(texcoord);
	vec2 duv2 = dFdy(texcoord);
	vec3 dp2perp = cross(dp2, N);
	vec3 dp1perp = cross(N, dp1);
	vec3 T = normalize(dp2perp * duv1.x + dp1perp * duv2.x);
	vec3 B = normalize(dp2perp * duv1.y + dp1perp * duv2.y);
	float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
	mat3 tbn = mat3(T * invmax, B * invmax, N);

//wet effect
	vec3 mcPos = worldPos + cameraPosition;
	float NdotU = dot(tbn[2], gbufferModelView[1].xyz);

	#ifdef DIMENSION_MAIN
		float wet = max(wetness, SURFACE_WETNESS);
		GetModulatedRainSpecular(wet, mcPos);

		#ifdef RAIN_SPLASH_EFFECT
			vec2 rainNormal = GetRainNormal(mcPos, wet);
		#endif

		wet *= saturate(NdotU * 0.5 + 0.5);
		wet *= saturate(blockLight.y * 10.0 - 9.0);
	#else
		float wet = SURFACE_WETNESS;
		GetModulatedRainSpecular(wet, mcPos);

		wet *= saturate(NdotU * 0.5 + 0.5);
	#endif

	float wetFact = saturate(wet * 1.5);

//normal
	#ifdef MC_NORMAL_MAP
		vec3 normalTex = DecodeNormalTex(texture2D(normals, texcoord).rgb);
		normalTex = mix(normalTex, vec3(0.0, 0.0, 1.0), wetFact);
	#else
		vec3 normalTex = vec3(0.0, 0.0, 1.0);
	#endif

	#ifdef DIMENSION_MAIN
		#ifdef RAIN_SPLASH_EFFECT
			rainNormal *= wet * NdotU * 0.7;
			normalTex = normalize(normalTex + vec3(rainNormal, 0.0));
		#endif
	#endif

	vec3 viewNormal = tbn * normalize(normalTex);

	#ifdef TERRAIN_NORMAL_CLAMP
		vec3 viewDir = -normalize(viewPos.xyz);
		viewNormal = normalize(viewNormal + tbn[2] * inversesqrt(saturate(dot(viewNormal, viewDir)) + 0.001));
	#endif

	vec2 normalEnc = EncodeNormal(viewNormal);

//specular
	#ifdef MC_SPECULAR_MAP
		vec4 specTex = texture2D(specular, texcoord);
		#if TEXTURE_PBR_FORMAT == 1
			specTex.b = specTex.a;
		#endif
	#else
		vec4 specTex = vec4(0.0);
	#endif

	if (materialIDs == 33.0){
		vec3 portalColor = texture2DProj(texture, portalCoord).rgb * COLORS[0];
		for (int i = 0; i < 16; i++){
			portalColor += texture2DProj(texture, portalCoord * end_portal_layer(float(i + 1))).rgb * COLORS[i];
		}
		albedo.rgb = portalColor;
		specTex.rgb = vec3(1.0, 0.0, 254.0 / 255.0);
	}

	specTex.a = wetFact;


	if(albedo.a <= 0.0) discard;

	gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normalEnc, blockLight);
    gl_FragData[2] = vec4(Pack2x8(specTex.rg), Pack2x8(specTex.ba), (materialIDs + 0.1) / 255.0, 1.0);
}
/* DRAWBUFFERS:036 */
