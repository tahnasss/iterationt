#version 450


#define DIMENSION_MAIN


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const int 		noiseTextureResolution  = 64;

const float		sunPathRotation	= -30;		// [-90 -89 -88 -87 -86 -85 -84 -83 -82 -81 -80 -79 -78 -77 -76 -75 -74 -73 -72 -71 -70 -69 -68 -67 -66 -65 -64 -63 -62 -61 -60 -59 -58 -57 -56 -55 -54 -53 -52 -51 -50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 ]


/* DRAWBUFFERS:137 */
layout(location = 0) out vec4 compositeOutput1;
layout(location = 1) out vec4 compositeOutput3;
layout(location = 2) out vec4 compositeOutput7;


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



void WaterFog(inout vec3 color, in vec3 viewDir, in float opaqueDist, in float waterDist, in MaterialMask mask, in float occludedWater, in float waterSkylight, in float totalInternalReflection){
	float inAir = step(float(isEyeInWater), 0.0);

	float eyeWaterDepth = saturate(float(eyeBrightnessSmooth.y) / 120.0 - 0.8);

	float distDiff = opaqueDist - waterDist;
	waterDist = mix(mix(waterDist, opaqueDist, mask.stainedGlass),
	                mix(distDiff, min(distDiff * 0.3, 6.0), occludedWater),
				    inAir);

	waterDist = max(waterDist, totalInternalReflection * 50.0 * eyeWaterDepth);

	float fogDensity = mix(0.03, 0.7, mask.ice);

	vec3 shadowVectorRefracted = refract(-shadowVector, gbufferModelView[1].xyz, 1.0 / WATER_REFRACT_IOR);

	vec3 waterFogColor = mix(vec3(0.05, 0.6, 1.0), vec3(0.3, 0.9, 1.5), mask.ice);
	waterFogColor = mix(waterFogColor, vec3(0.5), wetness * 0.6);

	waterFogColor *= dot(vec3(0.33333), colorSkylight) * 0.02;

	if (isEyeInWater == 0){
		waterFogColor *= 2.6 - wetness * 2.2;
		waterFogColor *= waterSkylight;
		fogDensity = 0.2;

		float scatter = 1.0 / (pow(saturate(dot(shadowVectorRefracted, viewDir) * 0.5 + 0.5) * 20.0, 2.0) + 0.1);
		waterFogColor = mix(waterFogColor, colorShadowlight * 5.0 * waterFogColor, vec3(scatter * (1.0 - wetness)));
	}else{
		waterFogColor *= 1.0 - wetness * 0.6;
		float scatter = 1.0 / (pow(saturate(dot(shadowVectorRefracted, viewDir) * 0.5 + 0.5) * 10.0, 1.0) + 0.1);
		vec3 waterSunlightScatter = colorShadowlight * scatter * waterFogColor * 2.0;

		waterFogColor *= dot(viewDir, gbufferModelView[1].xyz) * 0.4 + 0.6;
		waterFogColor += waterSunlightScatter * (eyeWaterDepth * (1.0 - wetness * 0.6));
	}

	float visibility = exp(-waterDist * fogDensity * WATERFOG_DENSITY);

	visibility = clamp(visibility, 0.35 * mask.ice, 1.0);
	visibility = mix(visibility, 0.7, mask.hand);

	vec3 attenuationColor = mix(vec3(0.1, 0.6, 1.0), vec3(0.2, 0.5, 0.7), inAir);
	color *= pow(attenuationColor * 0.99, vec3(waterDist * (0.21 * inAir + 0.04) * WATERFOG_DENSITY));

	color = mix(waterFogColor, color, visibility);
}





vec3 CalculateStars(vec3 worldDir){
	const float scale = 384.0;
	const float coverage = 0.007;
	const float maxLuminance = 1.0 * NIGHT_BRIGHTNESS;
	const float minTemperature = 4000.0;
	const float maxTemperature = 8000.0;

	//float visibility = curve(saturate(worldDir.y));

	float cosine = dot(worldSunVector,  vec3(0, 0, 1));
	vec3 axis = cross(worldSunVector,  vec3(0, 0, 1));
	float cosecantSquared = 1.0 / dot(axis, axis);
	worldDir = cosine * worldDir + cross(axis, worldDir) + (cosecantSquared - cosecantSquared * cosine) * dot(axis, worldDir) * axis;

	vec3  p = worldDir * scale;
	ivec3 i = ivec3(floor(p));
	vec3  f = p - i;
	float r = dot(f - 0.5, f - 0.5);

	vec3 i3 = fract(i * vec3(443.897, 441.423, 437.195));
	i3 += dot(i3, i3.yzx + 19.19);
	vec2 hash = fract((i3.xx + i3.yz) * i3.zy);
	hash.y = 2.0 * hash.y - 4.0 * hash.y * hash.y + 3.0 * hash.y * hash.y * hash.y;

	float c = remap(1.0 - coverage, 1.0, hash.x);
	return (maxLuminance * remap(0.25, 0.0, r) * c * c) * Blackbody(mix(minTemperature, maxTemperature, hash.y));
}


vec3 UnprojectSky(vec2 coord, float tileSize){
	coord *= screenSize;
	float tileSizeDivide = 1.0 / (0.5 * tileSize - 1.5);

	vec3 direction = vec3(0.0);

	if (coord.x < tileSize) {
		direction.x =  coord.y < tileSize ? -1 : 1;
		direction.y = (coord.x - tileSize * 0.5) * tileSizeDivide;
		direction.z = (coord.y - tileSize * (coord.y < tileSize ? 0.5 : 1.5)) * tileSizeDivide;
	} else if (coord.x < 2.0 * tileSize) {
		direction.x = (coord.x - tileSize * 1.5) * tileSizeDivide;
		direction.y =  coord.y < tileSize ? -1 : 1;
		direction.z = (coord.y - tileSize * (coord.y < tileSize ? 0.5 : 1.5)) * tileSizeDivide;
	} else {
		direction.x = (coord.x - tileSize * 2.5) * tileSizeDivide;
		direction.y = (coord.y - tileSize * (coord.y < tileSize ? 0.5 : 1.5)) * tileSizeDivide;
		direction.z =  coord.y < tileSize ? -1 : 1;
	}

	return normalize(direction);
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
	float waterDist = mix(length(ViewPos_From_ScreenPos(texcoord, gbuffer.depthW)), farDist, step(1.0, gbuffer.depthW));

	float cloudShadow 				= 1.0;

	#ifdef ATMO_HORIZON
		float minAltitude = 800.0;
	#else
		float minAltitude = 100.0;
	#endif
	vec3 camera = vec3(0.0, max(cameraPosition.y, minAltitude) * 0.001 + atmosphereModel.bottom_radius, 0.0);

	float noise_0  = bayer64(gl_FragCoord.xy);

	float noise_1 = noise_0;
	#ifdef TAA
		noise_1 = fract(frameCounter * (1.0 / 7.0) + noise_1);
    #endif

	vec3 finalComposite = CurveToLinear(texture(colortex1, texcoord).rgb) * mainOutputFactor;


//////////////////// Sky ///////////////////////////////////////////////////////////////////////////
//////////////////// Sky ///////////////////////////////////////////////////////////////////////////

	worldDir = (isEyeInWater == 1 && materialMask.water > 0.5) ? refract(worldDir, mat3(gbufferModelViewInverse) * gbuffer.normalW, WATER_REFRACT_IOR) : worldDir;

	if (materialMaskSoild.sky > 0.5){
		finalComposite = vec3(0.0);

		vec3 transmittance = vec3(1.0);
		float cloudVisibility = 1.0;

		#ifdef ATMO_HORIZON
			bool horizon = true;
		#else
			bool horizon = false;
		#endif
		bool ray_r_mu_intersects_ground;
		vec3 atmosphere = GetSkyRadiance(atmosphereModel, colortex11, colortex9, colortex10, camera, worldDir, worldSunVector, worldMoonVector, horizon, transmittance, ray_r_mu_intersects_ground);

		finalComposite += atmosphere;

		#ifdef PLANAR_CLOUDS
			PlanarClouds(finalComposite, worldDir, camera, noise_1, ray_r_mu_intersects_ground);
		#endif

		#ifdef VOLUMETRIC_CLOUDS
			VolumetricClouds(finalComposite, worldDir, camera, cloudProperties, noise_1, ray_r_mu_intersects_ground, cloudVisibility);
		#endif


		vec3 sunDisc;
		vec3 moonDisc;
		vec3 celestial = vec3(0.0);

		#ifdef STARS
			celestial += CalculateStars(worldDir);
		#endif

		#if (defined MOON_TEXTURE && MC_VERSION >= 11605)
			if(isEyeInWater == 1){
				moonDisc = vec3(RenderMoonDisc(worldDir, worldMoonVector));
				float luminance = Luminance(moonDisc);
				moonDisc = mix(moonDisc, luminance * vec3(0.7771, 1.0038, 1.6190), vec3(0.5));
			}else{
				moonDisc = gbuffer.albedo * SKY_TEXTURE_BRIGHTNESS * 0.2;
			}
		#else
			moonDisc = vec3(RenderMoonDisc(worldDir, worldMoonVector));
		#endif

		sunDisc = RenderSunDisc(worldDir, worldSunVector);
		sunDisc += moonDisc * NIGHT_BRIGHTNESS;
		#ifdef CAVE_MODE
			sunDisc *= 1.0 - eyeBrightnessZeroSmooth;
		#endif

		celestial += sunDisc * (RAIN_SHADOW * 200.0);

		celestial *= transmittance * cloudVisibility;

		finalComposite += sunDisc * (200.0 - RAIN_SHADOW * 200.0) + celestial;

		#ifdef CAVE_MODE
			finalComposite = mix(finalComposite, vec3(max(NOLIGHT_BRIGHTNESS, 0.00007) * 0.05), saturate(eyeBrightnessZeroSmooth));
		#endif
	}

//////////////////// Transparent ///////////////////////////////////////////////////////////////////
//////////////////// Transparent ///////////////////////////////////////////////////////////////////

	float totalInternalReflection = 0.0;
	if (length(worldDir) < 0.5)
	{
		//viewDir = reflect(viewDir, gbuffer.normalW);
		finalComposite = vec3(0.0);
		totalInternalReflection = 1.0;
	}

	#ifdef UNDERWATER_FOG
		if(gbuffer.waterMask > 0.5 || isEyeInWater == 1 || materialMask.ice > 0.5){
			float occludedWater = gbuffer.waterMask * materialMask.stainedGlass;
			WaterFog(finalComposite, viewDir, opaqueDist, waterDist, materialMask, occludedWater, gbuffer.lightmapW.g, totalInternalReflection);
			//finalComposite += colorSkylight * (occludedWater * 0.06);
		}
	#endif

//////////////////// Main Ouptut ///////////////////////////////////////////////////////////////////
//////////////////// Main Ouptut ///////////////////////////////////////////////////////////////////

	finalComposite /= mainOutputFactor;
	finalComposite = LinearToCurve(finalComposite);
	//finalComposite += rand(texcoord + sin(frameTimeCounter)) * (1.0 / 65535.0);

	compositeOutput1 = vec4(finalComposite.rgb, 0.0);

//////////////////// Sky Image /////////////////////////////////////////////////////////////////////
//////////////////// Sky Image /////////////////////////////////////////////////////////////////////

	vec3 skyImage = vec3(0.0);
	float cloudVisibility = 1.0;
	vec3 transmittance = vec3(1.0);
	float tileSize = min(SKY_IMAGE_RESOLUTION, min(floor(screenSize.x * 0.5) / 1.5, floor(screenSize.y * 0.5)));
	vec2 cmp = tileSize * vec2(3.0, 2.0);

	if (gl_FragCoord.x < cmp.x && gl_FragCoord.y < cmp.y)
	{
		vec3 viewVector = UnprojectSky(texcoord, tileSize);

		#ifdef ATMO_REFLECTION_HORIZON
			bool horizon = true;
		#else
			bool horizon = false;
		#endif
		bool ray_r_mu_intersects_ground;
		vec3 atmosphere = GetSkyRadiance(atmosphereModel, colortex11, colortex9, colortex10, camera, viewVector, worldSunVector, worldMoonVector, horizon, transmittance, ray_r_mu_intersects_ground);

		skyImage += atmosphere;


		#ifdef PLANAR_CLOUDS
			PlanarClouds(skyImage, viewVector, camera, noise_0, ray_r_mu_intersects_ground);
		#endif

		#ifdef VOLUMETRIC_CLOUDS
			VolumetricClouds(skyImage, viewVector, camera, cloudProperties, noise_0, ray_r_mu_intersects_ground, cloudVisibility);
		#endif

		#ifdef CAVE_MODE
			skyImage = mix(skyImage, vec3(max(NOLIGHT_BRIGHTNESS, 0.00005) * 0.07), eyeBrightnessZeroSmooth);
		#endif

		skyImage /= mainOutputFactor;
		skyImage = LinearToCurve(skyImage);
	}

	compositeOutput3 = vec4(skyImage, 0.0);

	cloudVisibility = saturate(cloudVisibility) * 0.5 + totalInternalReflection;
	compositeOutput7 = vec4(transmittance, cloudVisibility);
}
