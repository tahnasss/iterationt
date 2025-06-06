#include "/Lib/Uniform/ShadowModelViewEnd.glsl"


vec3 ShadowPos_From_WorldPos_Distorted_Biased(vec3 worldPos, vec3 worldNormal, out float dist, out float distortFactor){
	vec3 sn = normalize((shadowModelViewEnd * vec4(worldNormal.xyz, 0.0)).xyz) * vec3(1, 1, -1);

	vec4 sp = (shadowModelViewEnd * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	vec3 shadowPos = sp.xyz / sp.w;

    dist = length(shadowPos.xy);
	distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	shadowPos.xyz += sn * 0.002 * distortFactor;
	shadowPos.xy *= 0.95f / distortFactor;

	shadowPos.z = mix(shadowPos.z, 0.5, 0.8);

	return shadowPos * 0.5f + 0.5f;
}

vec3 ShadowPos_From_WorldPos_Distorted(vec3 worldPos){
	vec4 sp = (shadowModelViewEnd * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	vec3 shadowPos = sp.xyz / sp.w;

    float dist = length(shadowPos.xy);
	float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	shadowPos.xy *= 0.95f / distortFactor;

	shadowPos.z = mix(shadowPos.z, 0.5, 0.8);

	return shadowPos * 0.5f + 0.5f;
}

vec3 ShadowPos_From_WorldPos(vec3 worldPos){
	vec4 sp = (shadowModelViewEnd * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	vec3 shadowPos = sp.xyz / sp.w;

	shadowPos.z = mix(shadowPos.z, 0.5, 0.8);

	return shadowPos * 0.5f + 0.5f;
}

vec3 ShadowPos_From_WorldPos_Raw(vec3 worldPos){
	vec4 sp = (shadowModelViewEnd * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	vec3 shadowPos = sp.xyz / sp.w;

	return shadowPos * 0.5f + 0.5f;
}

vec2 DistortShadowPos(vec2 shadowPos){
	shadowPos = shadowPos * 2.0 - 1.0;

    float dist = length(shadowPos.xy);
	float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	shadowPos *= 0.95f / distortFactor;

	return shadowPos * 0.5 + 0.5;
}
