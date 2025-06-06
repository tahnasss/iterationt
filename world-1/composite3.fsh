#version 450


#define DIMENSION_NETHER
#define ENABLE_RAND


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


layout(location = 0) out vec4 compositeOutput3;


in vec2 texcoord;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"


#include "/Lib/BasicFounctions/NetherColor.glsl"


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

vec3 NetherFog(float dist)
{
	dist = min(dist, far * 1.2);

	float fogDensity = NetherFogColor().w;
	float fogFactor = pow(1.0 - exp(-dist * fogDensity), 2.0);

	vec3 fogColor = NetherFogColor().xyz * 0.0125;

	return fogFactor * fogColor;
}

#include "/Lib/IndividualFounctions/Reflections/SSR.glsl"


vec4 CalculateSpecularReflections(in vec3 viewPos, in vec3 viewDir, in vec3 normal, in float gbufferdepth, in vec3 albedo, in Material material, in bool isHand, in bool isSmooth)
{
	mat3 rot = GetRotationMatrix(vec3(0, 0, 1), normal);
	vec3 tangentView = viewDir * rot;
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

	reflection = hit ? reflection : vec3(0.0);

	float rDist = 96.0;
	if(hit){
		vec3 hitPos = ViewPos_From_ScreenPos(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
		rDist = distance(hitPos, viewPos);

		if(!isSmooth) hitDepth = saturate(max(rDist * 2.0, 3.0 * material.roughness));
	}
	reflection += NetherFog(rDist) / mainOutputFactor;


	#if TEXTURE_PBR_FORMAT == 1
		reflection *= FresnelNonpolarized(MdotV, ComplexVec3(airMaterial.n, airMaterial.k), ComplexVec3(material.n, material.k));
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
	if (gbuffer.material.doCSR) compositeOutput3 = CalculateSpecularReflections(viewPos, viewDir, gbuffer.normalW, gbuffer.depthW, gbuffer.albedo, gbuffer.material, materialMask.hand > 0.5, isSmooth);
}

/* DRAWBUFFERS:3 */
