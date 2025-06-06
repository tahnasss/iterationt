//Water_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform float frameTimeCounter;
uniform float wetness;
uniform int isEyeInWater;


uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;


in vec4 color;
in vec2 texcoord;
in mat3 tbn;
in vec4 viewPos;
in vec3 worldPos;
in float dist;
in vec2 blockLight;

in float iswater;
in float isice;
in float isStainedGlass;
flat in float materialIDs;


#include "/Lib/IndividualFounctions/WaterWaves.glsl"


vec3 GetWaterParallaxCoord(vec3 position, vec3 viewVector){
	vec3 stepSize = vec3(vec2(0.6 * WAVE_HEIGHT), 0.6);
	float waveHeight = GetWaves(position);
	vec3 pCoord = vec3(0.0, 0.0, 1.0);
	vec3 steps = viewVector * stepSize;

	float sampleHeight = waveHeight;

	for (int i = 0; sampleHeight < pCoord.z && i < 120; ++i)
	{
		pCoord.xy += steps.xy * saturate((pCoord.z - sampleHeight) * (-viewVector.z + 0.05) / (stepSize.z * 0.2));
		pCoord.z += steps.z;
		sampleHeight = GetWaves(position + vec3(pCoord.x, 0.0, pCoord.y));
	}

	return position.xyz + vec3(pCoord.x, 0.0, pCoord.y);
}



float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}



#include "/Lib/IndividualFounctions/Ripple.glsl"


void main() {
//albedo
	vec4 tex = texture2D(texture, texcoord);
	tex *= color;


//normal
	vec3 mcPos = worldPos + cameraPosition;
	float wet = wetness;
	GetModulatedRainSpecular(wet, mcPos);

	#ifdef DIMENSION_MAIN
		#ifdef RAIN_SPLASH_EFFECT
			vec2 rainNormal = GetRainNormal(mcPos, wet);
		#endif
	#endif

	float NdotU = dot(tbn[2], gbufferModelView[1].xyz);


	if (isEyeInWater == 0)	wet *= saturate(NdotU * 0.5 + 0.5);
	wet *= saturate(blockLight.y * 10.0 - 9.0);
	wet *= wetness;

	float wetFact = saturate(wet * 1.5);

	vec3 waterNormal = vec3(0.0);

    if (iswater > 0.5){
		#ifdef WATER_PARALLAX
			mcPos = GetWaterParallaxCoord(mcPos, normalize(viewPos.xyz * tbn));
		#endif
        waterNormal = GetWavesNormal(mcPos);
		//waterNormal = DecodeNormalTex(texture2D(normals, texcoord).rgb);
    }else{
		#ifdef MC_NORMAL_MAP
			waterNormal = DecodeNormalTex(texture2D(normals, texcoord).rgb);
			waterNormal = mix(waterNormal, vec3(0.0, 0.0, 1.0), wetFact);
		#else
			waterNormal = vec3(0.0, 0.0, 1.0);
		#endif
	}

	#ifdef DIMENSION_MAIN
		#ifdef RAIN_SPLASH_EFFECT
			rainNormal *= wet * NdotU;
			waterNormal = normalize(waterNormal + vec3(rainNormal, 0.0));
		#endif
	#endif

	waterNormal = tbn * waterNormal;

	vec2 normalEnc = EncodeNormal(waterNormal);



	gl_FragData[0] = vec4(normalEnc, blockLight);

	gl_FragData[1] = vec4(Pack2x8(tex.rg), Pack2x8(tex.ba), (materialIDs + 0.1) / 255.0, iswater);

	tex.a = materialIDs == 1.0 ? tex.a : 0.0;

	gl_FragData[2] = tex;
}

/* DRAWBUFFERS:450 */
