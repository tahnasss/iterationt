#version 450


#define DIMENSION_MAIN


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const int 		RGBA8       = 0;
const int 		RG16        = 0;
const int 		RGB16       = 0;
const int 		RGBA16      = 0;

const int 		RGB16F      = 0;
const int 		RGBA16F     = 0;

const int 		colortex0Format         = RGBA8;
const int 		colortex1Format         = RGBA16;
const int 		colortex2Format         = RGBA16;
const int 		colortex3Format 		= RGBA16;
const int 		colortex4Format 		= RGBA16;
const int 		colortex5Format 		= RGBA16;
const int 		colortex6Format 		= RGBA16;
const int 		colortex7Format 		= RGBA16;
const int 		colortex8Format 		= RG16;

const bool		colortex2Clear          = false;
const bool		colortex7Clear          = false;



const float 	shadowIntervalSize 		= 4.0f;

const int 		noiseTextureResolution  = 64;

const int 		shadowMapResolution 	= 2048;		// [1024 2048 4096 8192 16384 32768]
const float 	shadowDistance 			= 192.0;	// [64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0]

const float     shadowDistanceRenderMul = 1.0f;		// [-1.0f 1.0f]



const bool 		shadowHardwareFiltering1   = true;

const bool 		shadowtex0Mipmap           = true;
const bool 		shadowtex0Nearest          = false;

const bool 		shadowtex1Mipmap           = true;
const bool 		shadowtex1Nearest          = false;

const bool 		shadowcolor0Mipmap         = false;
const bool 		shadowcolor0Nearest        = false;

const bool 		shadowcolor1Mipmap         = false;
const bool 		shadowcolor1Nearest        = false;


const float     wetnessHalflife 			= 200.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float     drynessHalflife 			= 50.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float 	eyeBrightnessHalflife 		= 10.0f;
const float 	centerDepthHalflife 		= 1.0;		//[0.5 0.7 1.0 1.5 2.0 3.0 5.0 7.0 10.0]

const float		sunPathRotation				= -30;		// [-90 -89 -88 -87 -86 -85 -84 -83 -82 -81 -80 -79 -78 -77 -76 -75 -74 -73 -72 -71 -70 -69 -68 -67 -66 -65 -64 -63 -62 -61 -60 -59 -58 -57 -56 -55 -54 -53 -52 -51 -50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90]

const float 	ambientOcclusionLevel 		= 0.0f;
const int       superSamplingLevel 			= 0;



uniform sampler2D shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;


/* DRAWBUFFERS:1 */
layout(location = 0) out vec4 compositeOutput1;


in vec2 texcoord;

in vec3 worldShadowVector;
in vec3 shadowVector;
in vec3 worldSunVector;
in vec3 worldMoonVector;

in vec3 colorShadowlight;
in vec3 colorSunlight;
in vec3 colorMoonlight;

in vec3 colorSkylight;
in vec3 colorSunSkylight;
in vec3 colorMoonSkylight;

in vec3 colorTorchlight;

in float timeNoon;
in float timeMidnight;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"


float BlueNoise(const float ir){
	return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy)%64, 0).x + ir * (frameCounter % 64));
}


#include "/Lib/BasicFounctions/PrecomputedAtmosphere.glsl"
#include "/Lib/IndividualFounctions/VolumetricClouds.glsl"
#include "/Lib/IndividualFounctions/PlanarClouds.glsl"
//#include "/Lib/Aurora.glsl"

#include "/Lib/BasicFounctions/Sunlight_Shadow.glsl"
#include "/Lib/BasicFounctions/Blocklight.glsl"
#define PROGRAM_GI_1
#include "/Lib/IndividualFounctions/GlobalIllumination.glsl"
#include "/Lib/IndividualFounctions/GlobalIllumination_AO.glsl"


float GetSmoothCloudShadow(){
	float globalCloudShadow = 1.0;
	#ifdef VOLUMETRIC_CLOUDS
		#ifdef CLOUD_SHADOW
			globalCloudShadow = texelFetch(colortex2, ivec2(6, screenSize.y - 1.0), 0).a;
		#endif
	#endif
	return globalCloudShadow;
}

vec3 SkyLighting(vec3 worldNormal, float lightmap, CloudProperties cp){
	float SdotN = dot(worldNormal, normalize(worldSunVector + vec3(0.0, 1.0, 0.0))) * 0.4 + 0.6;
	float MdotN = dot(worldNormal, normalize(worldMoonVector + vec3(0.0, 1.0, 0.0))) * 0.4 + 0.6;
	vec3 skylight = colorSunSkylight * SdotN;
	skylight += colorMoonSkylight * MdotN;

	vec3 skySunLight = (worldNormal.y * 0.35 + 0.65) * colorShadowlight * 0.03;

	skylight += skySunLight;

	#ifdef VOLUMETRIC_CLOUDS
		skylight += skySunLight * (cp.sunlighting * (1.0 - wetness) * saturate(cp.coverage * 2.0 + 0.4) );
	#endif

	skylight = mix(skylight, skySunLight, vec3(wetness * 0.92));

	return skylight * max(isEyeInWater == 1 ? 0.003 : 0.0, lightmap * 0.35 * SKYLIGHT_INTENSITY);
}


////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main(){
	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);
	CloudProperties cloudProperties = GetGlobalCloudProperties();

	FixParticleMask(materialMaskSoild, materialMask, gbuffer.depthL, gbuffer.depthW);

	if (materialMask.water > 0.5)
	{
		gbuffer.material.roughness = 1.0;
		gbuffer.material.metalness = 0.0;
	}

	vec3 viewPos 					= ViewPos_From_ScreenPos(texcoord, gbuffer.depthL);
	vec3 worldPos					= mat3(gbufferModelViewInverse) * viewPos;

	vec3 viewDir 					= normalize(viewPos);
	vec3 worldDir 					= normalize(worldPos);
	vec3 rawWorldNormal 			= mat3(gbufferModelViewInverse) * gbuffer.normalL;
	vec3 worldNormal 				= rawWorldNormal;

	float farDist = max(far * 1.2, 1024.0);
	float opaqueDist = mix(length(viewPos), farDist, step(1.0, gbuffer.depthL));

	float cloudShadow 				= 1.0;
	float globalCloudShadow			= GetSmoothCloudShadow();

	vec3 finalComposite = vec3(0.0);

//////////////////// Soild /////////////////////////////////////////////////////////////////////////
//////////////////// Soild /////////////////////////////////////////////////////////////////////////

	if (materialMaskSoild.sky < 0.5){

		#ifdef VOLUMETRIC_CLOUDS
			#ifdef CLOUD_SHADOW
				//cloudShadow = CloudShadow(worldPos.xyz, worldShadowVector, cloudProperties);
				cloudShadow = globalCloudShadow;
			#endif
		#endif

		vec3 sunlightMult = colorShadowlight * SUNLIGHT_INTENSITY * clamp(cloudShadow, 0.01, 1.0);

		#ifdef CAVE_MODE
			sunlightMult *= mix(1.0, 0.1, eyeBrightnessZeroSmooth);
		#endif

		vec3 waterTint = vec3(1.0);

		#ifdef UNDERWATER_FOG
			if (isEyeInWater == 1) waterTint = vec3(0.55, 0.75, 1.0) / max(3.0, opaqueDist * 0.1 * WATERFOG_DENSITY);
		#endif

		vec4 gi = vec4(0.0);
		#ifdef GI_RSM
			gi = GI_SpatialFilter(opaqueDist, gbuffer.normalL, viewDir, sunlightMult * waterTint, gbuffer.lightmapL.g);
		#else
			gi.a = GI_SpatialFilter(opaqueDist, gbuffer.normalL, viewDir);
		#endif
		gi = mix(gi, vec4(0.0), materialMask.particle);

		float aoStrength = 1.0 - materialMaskSoild.grass * 0.5;
		float ao = 1.0 - gi.a * aoStrength;


		worldNormal = mix(worldNormal, vec3(0.0, 1.0, 0.0), materialMaskSoild.grass);


		#ifdef CAVE_MODE
			finalComposite += vec3(max(NOLIGHT_BRIGHTNESS, 0.00005));
		#else
			finalComposite += vec3(NOLIGHT_BRIGHTNESS);
		#endif
		finalComposite += SkyLighting(worldNormal, gbuffer.lightmapL.g, cloudProperties) * waterTint;
		finalComposite += BlockLighting(gbuffer.lightmapL.r, materialMaskSoild);
		finalComposite += gi.rgb;

		finalComposite *= ao;


		finalComposite += HeldLighting(worldPos, viewDir, gbuffer.normalL, ao, materialMask.hand > 0.5);

		float sunlight = Fd_Burley(worldNormal, -worldDir, worldShadowVector, gbuffer.material.roughness);

		float sunlightTrans = materialMaskSoild.leaves * 0.2 + materialMask.particle * 0.5 + materialMaskSoild.grass * 0.15;
		sunlight = sunlight * (1.0 - sunlightTrans) + sunlightTrans;



		#ifdef VARIABLE_PENUMBRA_SHADOWS
			vec3 shadow = VariablePenumbraShadow(worldPos, materialMaskSoild, worldNormal);
		#else
			vec3 shadow = ClassicSoftShadow(worldPos, materialMaskSoild, worldNormal);
		#endif

		#ifdef SCREEN_SPACE_SHADOWS
			shadow *= ScreenSpaceShadow(viewPos.xyz, gbuffer.normalL, materialMaskSoild);
		#endif

		#ifdef CAUSTICS
			if (materialMask.water > 0.5 || isEyeInWater == 1) shadow *= mix(CalculateWaterCaustics(worldPos, materialMask), 1.0, 0.3 * (1.0 - isEyeInWater));
		#endif

		shadow *= waterTint;

		#ifdef SUNLIGHT_LEAK_FIX
			float occludedWater = gbuffer.waterMask * materialMask.stainedGlass;
			float lightMask = saturate(gbuffer.lightmapL.g * mix(1e4, 1.0, occludedWater));
			shadow *= isEyeInWater == 1 ? 1.0 : lightMask;
		#endif
			shadow *= gbuffer.parallaxShadow;
		finalComposite += sunlight * shadow * sunlightMult;

		finalComposite *= gbuffer.albedo;


		finalComposite += TextureLighting(gbuffer.albedo, gbuffer.lightmapL.r, gbuffer.material.emissiveness, materialMaskSoild);
		finalComposite += vec3(1.0) * materialMaskSoild.lightning;

		vec3 specularHighlight = vec3(0.0);

		if (materialMask.water < 0.5 && materialMask.ice < 0.5){
			specularHighlight = mix(vec3(1.0), gbuffer.albedo, vec3(gbuffer.material.metalness)) * shadow * sunlightMult *
							   (SpecularGGX(worldNormal, -worldDir, worldShadowVector, clamp(gbuffer.material.roughness, 0.0015, 0.8), gbuffer.material.f0) *
							    mix(1.0, 0.5, materialMaskSoild.grass) * 0.1);
		}

		float metalnessMask = float(gbuffer.material.doCSR) * gbuffer.material.metalness;
		float skylightmap = min(smoothstep(0.3, 0.8, gbuffer.lightmapL.g), float(isEyeInWater == 0));
		metalnessMask *= 0.25 * skylightmap + 0.75;
		finalComposite *= 1.0 - metalnessMask;

		finalComposite += specularHighlight;
	}

	finalComposite /= mainOutputFactor;
	finalComposite = LinearToCurve(finalComposite);

	compositeOutput1 = vec4(finalComposite.rgb, 0.0);
}
