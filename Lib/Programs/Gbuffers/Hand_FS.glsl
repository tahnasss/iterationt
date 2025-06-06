//Hand_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform mat4 gbufferModelView;
uniform float wetness;

uniform sampler2D texture;
uniform sampler2D specular;
uniform sampler2D normals;


in vec4 color;
in vec2 texcoord;
in vec4 viewPos;
in vec2 blockLight;
flat in float materialIDs;


float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
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
	float NdotU = dot(tbn[2], gbufferModelView[1].xyz);

	#ifdef DIMENSION_MAIN
		float wet = max(wetness, SURFACE_WETNESS) * 0.5;
		wet *= saturate(NdotU * 0.5 + 0.5);
		wet *= saturate(blockLight.y * 10.0 - 9.0);
	#else
		float wet = SURFACE_WETNESS * 0.5;
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

	vec3 viewNormal = tbn * normalize(normalTex);

	#ifdef HAND_NORMAL_CLAMP
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

	specTex.a = wetFact;



	if(albedo.a <= 0.0) discard;

	gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normalEnc, blockLight);
    gl_FragData[2] = vec4(Pack2x8(specTex.rg), Pack2x8(specTex.ba), (materialIDs + 0.1) / 255.0, 1.0);
}
/* DRAWBUFFERS:036 */
