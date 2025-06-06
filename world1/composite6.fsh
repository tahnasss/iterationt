#version 450 compatibility


#define DIMENSION_END


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


layout(location = 0) out vec4 compositeOutput1;


in vec2 texcoord;

in vec3 worldShadowVector;
in vec3 shadowVector;
in vec3 worldSunVector;

in vec3 colorTorchlight;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"

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

#include "/Lib/IndividualFounctions/EndSky.glsl"


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

    vec3 rViewPos = ViewPos_From_ScreenPos(refractCoord, texture(depthtex1, refractCoord).x);
    vec3 rWorldDir = normalize(mat3(gbufferModelViewInverse)* rViewPos);

    color += EndFog(max(length(rViewPos) - waterDist, 0.0), rWorldDir) / mainOutputFactor;
}



#include "/Lib/IndividualFounctions/Reflections/SSR.glsl"



void 	CalculateSpecularReflections(inout vec3 color, in vec3 viewDir, in vec3 normal, in vec3 albedo, in Material material, in float skylight, in bool isWater)
{

	bool totalInternalReflection = texture(colortex1, texcoord).a > 0.5;

	vec3 reflection = CurveToLinear(texture(colortex3, texcoord).rgb);

	reflection *= mix(vec3(1.0), albedo, vec3(material.metalness));


	#if TEXTURE_PBR_FORMAT == 0

		vec3 Y = normalize(reflect(viewDir, normal) + normal * material.roughness);
		vec3 b = normalize(-viewDir + Y);

		float g = saturate(dot(normal, Y));

		float F = saturate(dot(normal, -viewDir));

		float D = saturate(dot(Y, b)); //D
	    float P = material.metalness * 0.96 + 0.04; //P
	    float L = pow(1.0 - D, 5.0); //L
	    float u = P + (1.0 - P) * L; //u

	    float I = material.roughness / 2.0; //I
	    float invI = 1 - I; //invI
	    float k = 1.0 / ((g * invI + I) * ((F + 0.8) * invI + I)); //k

	    float T = g * u * k; //T

		#ifdef ROUGHNESS_CLAMP
			T = mix(T, 0.0, saturate(material.roughness * 4.0 - 1.5));
		#endif

		T = mix(T, 1.0, material.metalness);

		//if(isWater && isEyeInWater == 0) T=mix(0.1, T, 0.7);

		vec3 temp = color;

		float diff = (length(color) - length(reflection)) / (length(color) + length(reflection));
		diff = sign(diff) * sqrt(abs(diff));
		T += 0.75 * diff * (1.0 - T) * T;

		color = mix(color, reflection, saturate(T));

		color += temp * material.metalness;

	#elif TEXTURE_PBR_FORMAT == 1

		#ifdef ROUGHNESS_CLAMP
			reflection *= 1.0 - saturate(material.roughness * 4.0 - 1.5);
		#endif

		color += reflection;

	#endif
}



void TransparentAbsorption(inout vec3 color, in vec4 stainedGlassAlbedo, in float depthL, in float depthW, in MaterialMask mask)
{
    if(mask.stainedGlass > 0.5){
        vec3 stainedGlassColor = normalize(stainedGlassAlbedo.rgb + 0.0001) * pow(length(stainedGlassAlbedo.rgb), 0.5);
        color *= GammaToLinear(mix(vec3(1.0), stainedGlassColor, vec3(pow(stainedGlassAlbedo.a, 0.2))));
    }else if(mask.water > 0.5 || mask.ice > 0.5 || isEyeInWater == 1) {
        float opaqueDist 	= LinearDepth_From_ScreenDepth(depthL);
        float waterDist 	= LinearDepth_From_ScreenDepth(depthW);
        float waterDeep = isEyeInWater > 0.5 ? waterDist * 0.5 : opaqueDist - waterDist;
        color *= GammaToLinear(mix(vec3(1.0), vec3(0.1, 0.4, 1.0), min(waterDeep * 0.25, 0.5)));
    }
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

	color += colorTorchlight * albedo * (specularHighlight * heldLightFalloff * TORCHLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS * 0.05);
}


void VanillaFog(inout vec3 color, in float dist)
{
	if (blindness > 0.0) color = mix(color, vec3(0.0), smoothstep(1.5, mix(far, 4.5, blindness), dist) * blindness);

	if(isEyeInWater == 3) color = mix(color, vec3(0.05), smoothstep(0.0, 2.0, dist));

	if (isEyeInWater == 2) color = mix(color, vec3(15.1355, 3.8774, 0.1199) * TORCHLIGHT_BRIGHTNESS, smoothstep(0.0, 1.0, dist));
}

void SelectionBox(inout vec3 color, in vec3 albedo, in bool isSelection){
	if (isSelection){
		float exposure = CurveToLinear(texelFetch(colortex2, ivec2(0, screenSize.y - 1.0), 0).a);
		color = albedo * exposure * 30.0;
	}
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	float globalCloudShadow	= 1.0;

	FixParticleMask(materialMaskSoild, materialMask);
	bool isSmooth = false;
	ApplyMaterial(gbuffer.material, materialMask, isSmooth);

    vec3 viewPos 		= ViewPos_From_ScreenPos(texcoord, gbuffer.depthW);
	vec3 worldPos		= mat3(gbufferModelViewInverse) * viewPos;
	vec3 viewDir 		= normalize(viewPos.xyz);
	vec3 worldDir 		= normalize(worldPos.xyz);

	float farDist = max(far * 1.2, 1024.0);
	float opaqueDist 	= gbuffer.depthL < 1.0 ? length(ViewPos_From_ScreenPos(texcoord, gbuffer.depthL)) : farDist;
	float waterDist 	= gbuffer.depthW < 1.0 ? length(viewPos) : farDist;


	vec3 color = CurveToLinear(texture(colortex1, texcoord).rgb);

	WaterRefractionLite(color, materialMask, gbuffer.normalW, worldPos, viewPos, waterDist, opaqueDist);

	TransparentAbsorption(color, gbuffer.albedoW, gbuffer.depthL, gbuffer.depthW, materialMask);


	if (gbuffer.material.doCSR){
		CalculateSpecularReflections(color, viewDir, gbuffer.normalW, gbuffer.albedo, gbuffer.material, gbuffer.lightmapW.g, materialMask.water > 0.5);
	}

	color *= mainOutputFactor;

	#ifdef SPECULAR_HELDLIGHT
	if (heldBlockLightValue + heldBlockLightValue2 > 0.0 && materialMask.sky < 0.5){
		TorchSpecularHighlight(color, worldPos, viewDir, waterDist, gbuffer.albedo, gbuffer.normalW, gbuffer.material);
	}
	#endif

    color += EndFog(waterDist, worldDir);
	//color += EndFog2(waterDist, worldDir);

	VanillaFog(color, waterDist);

	SelectionBox(color, gbuffer.albedo, materialMaskSoild.selection > 0.5 && isEyeInWater < 2.5);


	color /= mainOutputFactor;
	color = LinearToCurve(color);

	compositeOutput1 = vec4(color.rgb, 0.0);
}

/* DRAWBUFFERS:1 */
