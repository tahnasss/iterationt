#version 450


#define DIMENSION_MAIN
#define ENABLE_RAND


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D shadowtex0;
#ifdef MC_GL_VENDOR_NVIDIA
	uniform sampler2D shadowtex1;
#endif
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;


/* DRAWBUFFERS:3 */
layout(location = 0) out vec4 compositeOutput3;


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

#include "/Lib/BasicFounctions/PrecomputedAtmosphere.glsl"


float BlueNoise(const float ir){
	return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy)%64, 0).x + ir * (frameCounter % 64));
}


float Get3DNoise(in vec3 pos)
{
	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f = smoothstep(vec3(0.0), vec3(1.0), f);

	vec2 uv =  (p.xy + p.z * vec2(-17.0f, -17.0f)) + f.xy;

	vec2 coord =  (uv + 0.5f) / 64.0;
	vec2 noiseSample = texture(noisetex, coord).xy;
	float xy1 = noiseSample.x;
	float xy2 = noiseSample.y;
	return mix(xy1, xy2, f.z);
}

float GetSmoothCloudShadow(){
	float globalCloudShadow = 1.0;
	#ifdef VOLUMETRIC_CLOUDS
		#ifdef CLOUD_SHADOW
			globalCloudShadow = texelFetch(colortex2, ivec2(6, screenSize.y - 1.0), 0).a;
		#endif
	#endif
	return globalCloudShadow;
}


#include "/Lib/IndividualFounctions/Reflections/SSR.glsl"
#include "/Lib/IndividualFounctions/VolumetricClouds.glsl"
#include "/Lib/IndividualFounctions/VolumetricFog.glsl"
#include "/Lib/IndividualFounctions/UnderwaterVolumetricFog.glsl"


vec3 ComputeFakeSkyReflection(vec3 reflectWorldDir, bool isSmooth)
{
	float tileSize = min(SKY_IMAGE_RESOLUTION, min(floor(screenSize.x * 0.5) / 1.5, floor(screenSize.y * 0.5)));
	vec2 skyImageCoord = ProjectSky(reflectWorldDir, tileSize);
	vec4 sky = texture(colortex3, skyImageCoord);
	sky.rgb = CurveToLinear(sky.rgb);
	vec4 transmittance = texture(colortex7, skyImageCoord);

	if (isSmooth) {
		vec3 sunDisc = RenderSunDisc(reflectWorldDir, worldSunVector);
		#if (defined MOON_TEXTURE && MC_VERSION >= 11605)
			vec3 moonDisc = vec3(RenderMoonDiscReflection(reflectWorldDir, worldMoonVector)) * 0.1;
		#else
			vec3 moonDisc = vec3(RenderMoonDisc(reflectWorldDir, worldMoonVector));
		#endif
		float luminance = Luminance(moonDisc);
		moonDisc = mix(moonDisc, luminance * vec3(0.7771, 1.0038, 1.6190), vec3(0.5));

		sunDisc += moonDisc * NIGHT_BRIGHTNESS;

		#ifdef VOLUMETRIC_CLOUDS
			#ifdef CLOUD_SHADOW
				sunDisc *= mix(1.0, transmittance.a * 2.0, RAIN_SHADOW);
			#endif
		#endif

		sky.rgb += sunDisc * 200.0 * transmittance.rgb / mainOutputFactor;
	}

	return sky.rgb;
}


vec4 CalculateSpecularReflections(in vec3 viewPos, in vec3 worldPos, in vec3 viewDir, in vec3 normal, in float gbufferdepth, in vec3 albedo, in Material material, in float skylight, in bool isHand, in bool isSmooth)
{
	bool totalInternalReflection = texture(colortex7, texcoord).a > 0.75;

	mat3 rot = GetRotationMatrix(vec3(0, 0, 1), normal);
	vec3 tangentView = viewDir * rot;
	float NdotU = saturate((dot(normal, gbufferModelView[1].xyz) + 0.7) * 2.0) * 0.75 + 0.25;
	float NdotV = max(1e-12, dot(-viewDir, normal));
	float noise = BlueNoise(0.447213595);


	vec3 screenPos = vec3(texcoord, gbufferdepth);

	vec3 reflection;
	float hitDepth = 1.0;
	vec3 rayDirection;
	float MdotV;

	bool hit;

	if(isSmooth){
		rayDirection = reflect(viewDir, normal);
		MdotV = dot(normal, -viewDir);
		float NdotL = abs(dot(normal, rayDirection));

		hit = rayTrace(viewPos, rayDirection, NdotV, noise, isHand, screenPos) && NdotL > 0.0;

		hitDepth = 0.0;
	}else{
		vec3 facetNormal = rot * sampleGGXVNDF(-tangentView, material.roughness, RandNext2F());
		MdotV = dot(facetNormal, -viewDir);
		rayDirection = viewDir + 2.0 * MdotV * facetNormal;
		float NdotL = abs(dot(normal, rayDirection));

		hit = rayTrace(viewPos, rayDirection, NdotV, noise, isHand, screenPos) && NdotL > 0.0;
	}

	reflection = CurveToLinear(texture(colortex1, screenPos.xy).rgb);

	vec3 rayDirectionWorld = mat3(gbufferModelViewInverse) * rayDirection;
	vec3 skyReflection = vec3(0.0);

	skylight = smoothstep(0.3, 0.8, skylight);

	if(!totalInternalReflection && isEyeInWater == 0 && skylight > 0.0){
		skyReflection = ComputeFakeSkyReflection(rayDirectionWorld, isSmooth);
		skyReflection *= skylight * NdotU;
	}
	if(totalInternalReflection) skyReflection = CurveToLinear(texture(colortex1, texcoord).rgb);

	reflection = hit ? reflection : skyReflection;

	#if (defined LANDSCATTERING && defined LANDSCATTERING_REFLECTION) || (defined VFOG && defined VFOG_REFLECTION)
		float dist = length(viewPos);
		float rDist = max(max(far * 1.2, 1024.0) - dist, 0.0);
		bool notSky = false;


		vec3 endPos = rayDirectionWorld * max(far * 1.2 - dist, 0.0) + worldPos;

		if(hit){
			notSky = floor(texture(colortex6, screenPos.xy).b * 255.0) > 0.5;

			if(notSky){
				vec3 hitPos = ViewPos_From_ScreenPos(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
				rDist = distance(hitPos, viewPos);

				endPos = mat3(gbufferModelViewInverse) * hitPos;
			}

			if(!isSmooth) hitDepth = saturate(max(rDist * 2.0, 3.0 * material.roughness));
		}

		if (isEyeInWater == 1) skylight = 1.0;

		if (skylight > 0.0){
			reflection *= mainOutputFactor;

			vec3 volumetricReflection = reflection;

			#ifdef LANDSCATTERING
				#ifdef LANDSCATTERING_REFLECTION
					LandAtmosphericScattering(volumetricReflection, rDist, worldPos, endPos, rayDirectionWorld, !notSky);
				#endif
			#endif

			#ifdef VFOG
				#ifdef VFOG_REFLECTION
					float cloudShadow = GetSmoothCloudShadow();
					#ifdef UNDERWATER_VFOG
						if (isEyeInWater == 1) volumetricReflection += UnderwaterVolumetricFog(worldPos, endPos, rayDirectionWorld, cloudShadow);
					#endif
					if (isEyeInWater == 0) VolumetricFog(volumetricReflection, worldPos, endPos, rayDirectionWorld, GetGlobalCloudProperties(), cloudShadow);
				#endif
			#endif

			reflection = mix(reflection, volumetricReflection, skylight);

			reflection /= mainOutputFactor;
		}
	#else
		if(hit && !isSmooth){
			vec3 hitPos = ViewPos_From_ScreenPos(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
			float rDist = distance(hitPos, viewPos);

			hitDepth = saturate(max(rDist * 2.0, 3.0 * material.roughness));
		}
	#endif

	#if TEXTURE_PBR_FORMAT == 1
	if(!totalInternalReflection) {
		reflection *= FresnelNonpolarized(MdotV, ComplexVec3(airMaterial.n, airMaterial.k), ComplexVec3(material.n, material.k));
	}
	#endif

	return vec4(LinearToCurve(reflection.rgb), hitDepth);
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	FixParticleMask(materialMaskSoild, materialMask);
	bool isSmooth = false;
	ApplyMaterial(gbuffer.material, materialMask, isSmooth);

	vec3 viewPos 		= ViewPos_From_ScreenPos(texcoord, gbuffer.depthW);
	vec3 worldPos		= mat3(gbufferModelViewInverse) * viewPos;
	vec3 viewDir 		= normalize(viewPos.xyz);

	compositeOutput3 = vec4(0.0);
	if (gbuffer.material.doCSR) compositeOutput3 = CalculateSpecularReflections(viewPos, worldPos, viewDir, gbuffer.normalW, gbuffer.depthW, gbuffer.albedo, gbuffer.material, gbuffer.lightmapW.g, materialMask.hand > 0.5, isSmooth);
}
