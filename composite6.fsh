#version 450


#define DIMENSION_MAIN


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"

#include "/Lib/BasicFounctions/PrecomputedAtmosphere.glsl"


uniform sampler2D shadowtex0;
#ifdef MC_GL_VENDOR_NVIDIA
	uniform sampler2D shadowtex1;
#endif
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;


/* DRAWBUFFERS:13 */
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

#ifdef LENS_FLARE
	layout(location = 1) out vec4 compositeOutput3;
	in vec2 sunCoord;
	in float sunVisibility;
#endif

#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"


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

#include "/Lib/IndividualFounctions/VolumetricClouds.glsl"
#include "/Lib/IndividualFounctions/VolumetricFog.glsl"
#include "/Lib/IndividualFounctions/UnderwaterVolumetricFog.glsl"


#include "/Lib/IndividualFounctions/WaterWaves.glsl"


void WaterRefractionLite(inout vec3 color, MaterialMask mask, vec3 normal, vec3 worldPos, vec3 viewPos, float waterDist, float opaqueDist){
	if (mask.water < 0.5 && mask.ice < 0.5 && mask.stainedGlass < 0.5) return;

	vec2 refractCoord;

	float waterDeep = opaqueDist - waterDist;

	if (mask.water > 0.5){
		vec3 wavesNormal = GetWavesNormal(worldPos + cameraPosition).xzy;
		vec4 wnv = gbufferModelView * vec4(wavesNormal.xyz, 0.0);
		vec3 wavesNormalView = normalize(wnv.xyz);

		vec4 nv = gbufferModelView * vec4(0.0, 1.0, 0.0, 0.0);
		nv.xyz = normalize(nv.xyz);

		refractCoord = nv.xy - wavesNormalView.xy;
		refractCoord *= saturate(waterDeep) * 0.5 / (waterDist + 0.0001);
		refractCoord += texcoord;
	}else{
		vec3 refractDir = refract(normalize(viewPos), normal, 0.66);
		refractDir = refractDir / saturate(dot(refractDir, -normal));
		refractDir *= saturate(waterDeep * 2.0) * 0.125;

		vec4 refractPos = vec4(viewPos + refractDir, 0.0);
		refractPos = gbufferProjection * refractPos;

		refractCoord = refractPos.xy / refractPos.w * 0.5 + 0.5;
	}

	float currentDepth = texture(gdepthtex, texcoord).x;
	float refractDepth = texture(depthtex1, refractCoord).x;
	if(refractDepth < currentDepth) refractCoord = texcoord;

	refractCoord = saturate(refractCoord) == refractCoord ? refractCoord : texcoord;

	color = CurveToLinear(texture(colortex1, refractCoord).rgb);

	#if (defined LANDSCATTERING && defined LANDSCATTERING_REFRACTION) || (defined VFOG && defined VFOG_REFRACTION)
		if (mask.stainedGlass > 0.5){
			float farDist = max(far * 1.2, 1024.0);

			float rDepth = texture(depthtex1, refractCoord).x;
			vec3 rViewPos = ViewPos_From_ScreenPos(refractCoord, rDepth);
			vec3 rWorldPos = mat3(gbufferModelViewInverse) * rViewPos;
			vec3 rWorldDir = normalize(rWorldPos);

			float rDist = rDepth < 1.0 ? length(rViewPos) : farDist;

			vec3 endPos = rDepth < 1.0 ? rWorldPos : rWorldDir * far * 1.2;

			rDist -= waterDist;

			color *= mainOutputFactor;

			#ifdef LANDSCATTERING
				#ifdef LANDSCATTERING_REFRACTION
					if (isEyeInWater == 0) LandAtmosphericScattering(color, rDist, worldPos, endPos, rWorldDir, rDepth >= 1.0);
				#endif
			#endif

			#ifdef VFOG
				#ifdef VFOG_REFRACTION
					float cloudShadow = GetSmoothCloudShadow();
					//if (isEyeInWater == 1) color += UnderwaterVolumetricFog(worldPos, endPos, rWorldDir, cloudShadow);
					if (isEyeInWater == 0) VolumetricFog(color, worldPos, endPos, rWorldDir, GetGlobalCloudProperties(), cloudShadow);
				#endif
			#endif

			color /= mainOutputFactor;
		}
	#endif
}



#include "/Lib/IndividualFounctions/Reflections/SSR.glsl"


void CalculateSpecularReflections(inout vec3 color, in vec3 viewDir, in vec3 normal, in vec3 albedo, in Material material){
	vec3 reflection = CurveToLinear(texture(colortex3, texcoord).rgb);

	//reflection = vec3(0.0);

	if (texture(colortex7, texcoord).a > 0.75){
		color = reflection;
		return;
	}

	reflection *= mix(vec3(1.0), albedo, vec3(material.metalness));


	#if TEXTURE_PBR_FORMAT == 0

		vec3 l = normalize(reflect(viewDir, normal) + normal * material.roughness);
		vec3 h = normalize(l - viewDir);

		float NdotL = saturate(dot(normal, l));
		float NdotV = saturate(dot(normal, -viewDir));
		float LdotH = 1.0 - saturate(dot(l, h));

		float LdotH2 = LdotH * LdotH;
	    float F = material.f0 + (1.0 - material.f0) * LdotH2 * LdotH2 * LdotH;

	    float k = material.roughness * 0.5;
		float vis = 1.0 / ((NdotL * (1.0 - k) + k) * ((NdotV + 0.8) * (1.0 - k) + k));

	    float specular = NdotL * F * vis;

		#ifdef ROUGHNESS_CLAMP
			specular = mix(specular, 0.0, saturate(material.roughness * 4.0 - 1.5));
		#endif

		specular = mix(specular, 1.0, material.metalness);

		vec3 temp = color;

		float diff = (length(color) - length(reflection)) / (length(color) + length(reflection));
		diff = sign(diff) * sqrt(abs(diff));
		specular += 0.75 * diff * (1.0 - specular) * specular;

		color = mix(color, reflection, saturate(specular));

		color += temp * material.metalness;

	#elif TEXTURE_PBR_FORMAT == 1

		#ifdef ROUGHNESS_CLAMP
			reflection *= 1.0 - saturate(material.roughness * 4.0 - 1.5);
		#endif

		color += reflection;

	#endif
}





void TransparentAbsorption(inout vec3 color, vec4 stainedGlassAlbedo, float waterDist)
{
	vec3 stainedGlassColor = normalize(stainedGlassAlbedo.rgb + 0.0001) * pow(length(stainedGlassAlbedo.rgb), 0.5);

	stainedGlassAlbedo.a = pow(stainedGlassAlbedo.a, 0.2);

	#ifdef UNDERWATER_FOG
		if (isEyeInWater == 1) stainedGlassAlbedo.a = mix(0.0, stainedGlassAlbedo.a, saturate(exp(-waterDist * 0.05 * WATERFOG_DENSITY)));
	#endif

	color *= GammaToLinear(mix(vec3(1.0), stainedGlassColor, stainedGlassAlbedo.a));
}


float SpecularGGX(vec3 n, vec3 v, vec3 l, float roughness, float f0){
	vec3 h = normalize(v + l);
	float NdotL = saturate(dot(n, l));
	float NdotV = saturate(dot(n, v));
	float NdotH = saturate(dot(n, h));
	float LdotH = 1.0 - saturate(dot(l, h));

	float roughness2 = roughness * roughness;
	float denom = NdotH * NdotH * (roughness2 - 1.0) + 1.0;
	float D = roughness2 / (PI * denom * denom);

	float LdotH2 = LdotH * LdotH;
	float F = f0 + (1.0 - f0) * LdotH2 * LdotH2 * LdotH;

	float k = roughness * 0.5;
	float vis = 1.0 / ((NdotL * (1.0 - k) + k) * (NdotV * (1.0 - k) + k));

	return NdotL * D * F * vis;
}

void TorchSpecularHighlight(inout vec3 color, in vec3 worldPos, in vec3 viewDir, in float dist, in vec3 albedo, in vec3 normal, in Material material){

	float specularHighlight = SpecularGGX(normal, -viewDir, -viewDir, max(material.roughness, 0.002), material.f0);

	#ifdef FLASHLIGHT_HELDLIGHT
		float heldLightFalloff = 1.0 / pow(max(dist, 0.5), FLASHLIGHT_HELDLIGHT_FALLOFF);

		vec3 torchPos = worldPos.xyz + gbufferModelViewInverse[1].xyz * 0.1;
		vec3 torchPosL = torchPos + gbufferModelViewInverse[0].xyz * 0.23;
		vec3 torchPosR = torchPos - gbufferModelViewInverse[0].xyz * 0.23;
		vec3 torchDirL = normalize((gbufferModelView * vec4(torchPosL, 0.0)).xyz);
		vec3 torchDirR = normalize((gbufferModelView * vec4(torchPosR, 0.0)).xyz);
		float spotRadiusL = dot(torchDirL, vec3(0.0, 0.0, -1.0));
		float spotRadiusR = dot(torchDirR, vec3(0.0, 0.0, -1.0));
		spotRadiusL = saturate(spotRadiusL * 2.0 - 1.8);
		spotRadiusR = saturate(spotRadiusR * 2.0 - 1.8);

		heldLightFalloff *= (heldBlockLightValue2 * spotRadiusL + heldBlockLightValue * spotRadiusR);
	#else
		float heldLightFalloff = 1.0 / pow(max(dist, 0.5), HELDLIGHT_FALLOFF);

		heldLightFalloff *= (heldBlockLightValue + heldBlockLightValue2);
	#endif

	color += colorTorchlight * albedo * (specularHighlight * heldLightFalloff * TORCHLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS * 0.005);
}


void Rain(inout vec3 color, in vec3 worldDir, in float rainMask, in float cloudShadow){
	if(isEyeInWater == 0.0 && wetness > 0.0){
		vec3 rainSunlight = colorShadowlight * (10.0 - RAIN_SHADOW * 9.0);
		vec3 rainColor = (colorSkylight + rainSunlight * 0.1) * 0.01;
		vec3 snowColor = (colorSkylight + rainSunlight * 0.3) * 0.1;


		color = mix(color, mix(rainColor, snowColor, eyeSnowySmooth), saturate(rainMask * (0.3 * eyeSnowySmooth + 0.2) * wetness * RAIN_VISIBILITY));
	}
}

void VanillaFog(inout vec3 color, in float dist)
{
	if (blindness > 0.0) color = mix(color, vec3(0.0), smoothstep(1.5, mix(far, 4.5, blindness), dist) * blindness);

	if(isEyeInWater == 3){
		vec3 skylight = colorSkylight;
		skylight += colorShadowlight * 0.05;
		skylight = mix(skylight, colorShadowlight * 0.02, vec3(wetness * 0.92));
		skylight *= eyeBrightnessSmoothCurved;

		color = mix(color, skylight, smoothstep(0.0, 2.0, dist));
	}

	if (isEyeInWater == 2) color = mix(color, vec3(15.1355, 3.8774, 0.1199) * TORCHLIGHT_BRIGHTNESS, smoothstep(0.0, 1.0, dist));
}

void SelectionBox(inout vec3 color, in vec3 albedo, in bool isSelection){
	if (isSelection){
		float exposure = CurveToLinear(texelFetch(colortex2, ivec2(0, screenSize.y - 1.0), 0).a);
		color = albedo * exposure * 12.0;
	}
}

void LowlightColorFade(inout vec3 color){
	const float threshold = LOWLIGHT_COLORFADE_THRESHOLD;
	float luminance = Luminance(color);
	color = mix(color, luminance * vec3(0.7777, 1.0004, 1.6190), saturate((threshold - luminance) * LOWLIGHT_COLORFADE_STRENGTH / threshold));
}


#ifdef LENS_FLARE

	//https://www.shadertoy.com/view/MdGSWy

	#define ORB_FLARE_COUNT	6.0
	#define DISTORTION_BARREL 1.0

	vec2 GetDistOffset(vec2 uv, vec2 pxoffset){
	    vec2 tocenter = uv.xy;
	    vec3 prep = normalize(vec3(tocenter.y, -tocenter.x, 0.0));

	    float angle = length(tocenter.xy) * 2.221 * DISTORTION_BARREL;
	    vec3 oldoffset = vec3(pxoffset, 0.0);

	    vec3 rotated = oldoffset * cos(angle) + cross(prep, oldoffset) * sin(angle) + prep * dot(prep, oldoffset) * (1.0 - cos(angle));

	    return rotated.xy;
	}

	vec3 flare(vec2 uv, vec2 pos, float dist, float chromaOffset, float size){
	    pos = GetDistOffset(uv, pos);

	    float r = max(0.01 - pow(length(uv + (dist - chromaOffset) * pos), 2.4) *( 1.0 / (size * 2.0)), 0.0) * 0.85;
		float g = max(0.01 - pow(length(uv +  dist                 * pos), 2.4) * (1.0 / (size * 2.0)), 0.0) * 1.0;
		float b = max(0.01 - pow(length(uv + (dist + chromaOffset) * pos), 2.4) * (1.0 / (size * 2.0)), 0.0) * 1.5;

	    return vec3(r, g, b);
	}


	vec3 orb(vec2 uv, vec2 pos, float dist, float size){
	    vec3 c = vec3(0.0);

	    for (float i = 0.0; i < ORB_FLARE_COUNT; i++){
	        float j = i + 1;
	        float offset = j / (j + 0.1);
	        float colOffset = j / ORB_FLARE_COUNT * 0.5;

			float ss = size / (j + 1.0);

	        c += flare(uv, pos, dist + offset, ss * 2.0, ss) * vec3(1.0 - colOffset, 1.0, 0.5 + colOffset) * j;
	    }

	    c += flare(uv, pos, dist + 0.8, 0.05, 3.0 * size) * 0.5;

	    return c;
	}

	vec3 ring(vec2 uv, vec2 pos, float dist, float chromaOffset, float blur){
	    vec2 uvd = uv * length(uv);

	    float r = max(1.0 / (1.0 + 250.0 * pow(length(uvd + (dist - chromaOffset) * pos), blur)), 0.0) * 0.8;
		float g = max(1.0 / (1.0 + 250.0 * pow(length(uvd +  dist                 * pos), blur)), 0.0) * 1.0;
		float b = max(1.0 / (1.0 + 250.0 * pow(length(uvd + (dist + chromaOffset) * pos), blur)), 0.0) * 1.5;

	    return vec3(r, g, b);
	}

	vec3 LensFlare(){
		if (sunVisibility <= 0.0 || isEyeInWater > 0) return vec3(0.0);

		vec2 coord = texcoord - 0.5;
		vec2 sunPos = sunCoord - 0.5;
		coord.x *= aspectRatio;
		sunPos.x *= aspectRatio;

		vec2 v = coord - sunPos;

		float dist = length(v);
		float fovFactor = max(gbufferProjection[1][1], 2.0);
		float gDist = dist * 13.0 / fovFactor;
		float phase = atan2(v) + 0.131;


		float gl = 2.0 - saturate(gDist) + sin(phase * 12.0) * saturate(gDist * 2.5 - 0.2);
		gl = gl * gl;
		gDist = gDist * gDist;
		gl *= 3e-4 / (gDist * gDist);

		float size = 0.5 * fovFactor;
		vec3 fl = vec3(0.0);
		#ifdef FLARE_GHOSTING
			fl += orb(coord, sunPos, 0.0, size * 0.02) * 0.15;
			fl += ring(coord, sunPos,  1.0, 0.02, 1.4) * 0.02;
		#endif
		fl += ring(coord, sunPos, -1.0, 0.02, 1.4) * 0.01;

		fl += flare(coord, sunPos, -2.00, 0.05, size * 0.05) * 0.5;
		fl += flare(coord, sunPos, -0.90, 0.02, size * 0.03) * 0.25;
		fl += flare(coord, sunPos, -0.70, 0.01, size * 0.06) * 0.5;
		fl += flare(coord, sunPos, -0.55, 0.02, size * 0.02) * 0.25;
		fl += flare(coord, sunPos, -0.35, 0.02, size * 0.04) * 1.0;
		fl += flare(coord, sunPos, -0.25, 0.01, size * 0.15) * vec3(0.3, 0.4, 0.38);
		fl += flare(coord, sunPos, -0.25, 0.02, size * 0.08) * 0.3;
		fl += flare(coord, sunPos,  0.05, 0.01, size * 0.03) * 0.1;
		fl += flare(coord, sunPos,  0.30, 0.02, size * 0.20) * vec3(0.3, 0.25, 0.15);
		fl += flare(coord, sunPos,  1.20, 0.03, size * 0.10) * 0.5;

		vec3 lf = colorSunlight * (vec3(gl * GLARE_BRIGHTNESS) + fl * FLARE_BRIGHTNESS);

		return LinearToCurve(lf * (sunVisibility / mainOutputFactor));
	}

#endif


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	GbufferData gbuffer 			= GetGbufferData();
	CloudProperties cloudProperties = GetGlobalCloudProperties();
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	float globalCloudShadow	= GetSmoothCloudShadow();

	FixParticleMask(materialMaskSoild, materialMask);
	bool isSmooth = false;
	ApplyMaterial(gbuffer.material, materialMask, isSmooth);

	vec3 viewPos 		= ViewPos_From_ScreenPos(texcoord, gbuffer.depthW);
	vec3 worldPos		= mat3(gbufferModelViewInverse) * viewPos;
	vec3 viewDir 		= normalize(viewPos.xyz);
	vec3 worldDir 		= normalize(worldPos.xyz);

	float farDist = max(far * 1.2, 1024.0);
	float opaqueDist = mix(length(ViewPos_From_ScreenPos(texcoord, gbuffer.depthL)), farDist, step(1.0, gbuffer.depthL));
	float waterDist = mix(length(viewPos), farDist, step(1.0, gbuffer.depthW));


	vec3 color = CurveToLinear(texture(colortex1, texcoord).rgb);

	WaterRefractionLite(color, materialMask, gbuffer.normalW, worldPos, viewPos, waterDist, opaqueDist);

	if (materialMask.stainedGlass > 0.5){
		TransparentAbsorption(color, gbuffer.albedoW, waterDist);
	}

	if (gbuffer.material.doCSR){
		CalculateSpecularReflections(color, viewDir, gbuffer.normalW, gbuffer.albedo, gbuffer.material);
	}


	color *= mainOutputFactor;

	#ifdef SPECULAR_HELDLIGHT
	if (heldBlockLightValue + heldBlockLightValue2 > 0.0 && materialMask.sky < 0.5){
		TorchSpecularHighlight(color, worldPos, viewDir, waterDist, gbuffer.albedo, gbuffer.normalW, gbuffer.material);
	}
	#endif


	vec3 rayWorldPos = materialMask.sky > 0.5 ? worldDir * far * 1.2 : worldPos;

	#ifdef LANDSCATTERING
		LandAtmosphericScattering(color, waterDist, vec3(0.0), rayWorldPos, worldDir, materialMask.sky > 0.5);
	#endif

	#ifdef VFOG
		#ifdef UNDERWATER_VFOG
			if (isEyeInWater == 1) color += UnderwaterVolumetricFog(vec3(0.0), worldPos, worldDir, globalCloudShadow);
		#endif
		if (isEyeInWater == 0) VolumetricFog(color, vec3(0.0), rayWorldPos, worldDir, cloudProperties, globalCloudShadow);
	#endif

	Rain(color, worldDir, gbuffer.rainAlpha, globalCloudShadow);

	VanillaFog(color, waterDist);

	SelectionBox(color, gbuffer.albedo, materialMaskSoild.selection > 0.5 && isEyeInWater < 2.5);

	#ifdef LOWLIGHT_COLORFADE
		LowlightColorFade(color);
	#endif

	//color += vec3(sunVisibility * 0.01);


	color /= mainOutputFactor;
	color = LinearToCurve(color);

	compositeOutput1 = vec4(color.rgb, 0.0);

	#ifdef LENS_FLARE
		compositeOutput3 = vec4(LensFlare(), 0.0);
	#endif
}
