#version 450


#define DIMENSION_END
#define ENABLE_RAND


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


layout(location = 0) out vec4 compositeOutput3;


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

#include "/Lib/IndividualFounctions/Reflections/SSR.glsl"


vec3 ComputeFakeSkyReflection(vec3 reflectWorldDir, bool isSmooth)
{
	vec3 sky = vec3(0.0);

	BlackHole_AccretionDisc_Reflection(sky, reflectWorldDir, worldShadowVector);

	PlanetEnd2(sky, vec3(0.0), reflectWorldDir, worldShadowVector);

	return sky / mainOutputFactor;
}


vec4 CalculateSpecularReflections(in vec3 viewPos, in vec3 viewDir, in vec3 normal, in float gbufferdepth, in vec3 albedo, in Material material, in float skylight, in bool isHand, in bool isSmooth)
{
	bool totalInternalReflection = texture(colortex7, texcoord).a > 0.5;

	mat3 rot = GetRotationMatrix(vec3(0, 0, 1), normal);
	vec3 tangentView = viewDir * rot;
	float NdotU = saturate((dot(normal, gbufferModelView[1].xyz) + 0.7) * 2.0) * 0.75 + 0.25;
	float NdotV = max(1e-12, dot(-viewDir, normal));
	float noise = BlueNoise(0.447213595);


	vec3 screenPos = vec3(texcoord, gbufferdepth);

	vec3 reflection;
	float hitDepth;
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

		hitDepth = 1.0;
	}

	reflection = CurveToLinear(texture(colortex1, screenPos.xy).rgb);

	vec3 rayDirectionWorld = mat3(gbufferModelViewInverse) * rayDirection;
	vec3 skyReflection = vec3(0.0);
	if(!totalInternalReflection && isEyeInWater == 0){
		skylight = clamp(fma(skylight, 8.0f, -1.5f), 0.0f, 1.0f);
		skyReflection = ComputeFakeSkyReflection(rayDirectionWorld, isSmooth);
		skyReflection *= NdotU;
	}
	if(totalInternalReflection) skyReflection = CurveToLinear(texture(colortex1, texcoord).rgb);

	reflection = hit ? reflection : skyReflection;

	float dist = length(viewPos);
	float rDist = max(max(far * 1.2, 1024.0) - dist, 0.0);
	if(hit){
		vec3 hitPos = ViewPos_From_ScreenPos(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
		rDist = distance(hitPos, viewPos);

		if(!isSmooth) hitDepth = saturate(max(rDist * 2.0, 3.0 * material.roughness));
	}
	reflection += EndFog(rDist, rayDirectionWorld) / mainOutputFactor;


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
	vec3 viewDir 		= normalize(viewPos.xyz);

	compositeOutput3 = vec4(0.0);
	if (gbuffer.material.doCSR) compositeOutput3 = CalculateSpecularReflections(viewPos, viewDir, gbuffer.normalW, gbuffer.depthW, gbuffer.albedo, gbuffer.material, gbuffer.lightmapW.g, materialMask.hand > 0.5, isSmooth);
}

/* DRAWBUFFERS:3 */
