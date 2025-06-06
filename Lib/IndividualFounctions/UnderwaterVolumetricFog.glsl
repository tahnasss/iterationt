#define UNDERWATER_VFOG


vec3 GetWavesNormalFromTex(vec3 position) {

	vec2 coord = position.xz;
	vec3 lightVector = refract(worldShadowVector, vec3(0.0, 1.0, 0.0), 1.0 / WATER_REFRACT_IOR);
	coord.x += position.y * lightVector.x / lightVector.y;
	coord.y += position.y * lightVector.z / lightVector.y;

	coord *= 0.02;
	coord = mod(coord, vec2(1.0));

	vec3 normal;
	normal.xyz = DecodeNormal(texture(colortex8, coord).xy);

	return normal;
}

float CalculateWaterCaustics(vec3 worldPos){

	worldPos.xyz += cameraPosition;
	vec3 lookupCenter = worldPos;
	lookupCenter.y += 1.0;

	vec3 wavesNormal = GetWavesNormalFromTex(lookupCenter).xzy;
	vec3 refractVector = refract(vec3(0.0, 1.0, 0.0), wavesNormal.xyz, 1.0);
	vec3 collisionPoint = lookupCenter - refractVector / refractVector.y;
	//collisionPoint -= worldPos;

	float dist = distance(collisionPoint, worldPos);

	return dist * 2.8 + 0.2;
}


vec3 UnderwaterVolumetricFog(vec3 startPos, vec3 endPos, vec3 worldDir, float globalCloudShadow){
	float range = 50.0;

	float startDist = length(startPos);
	if(startDist > range) return vec3(0.0);

	endPos = length(endPos) > range ? worldDir * range : endPos;

	float rayDist = distance(startPos, endPos);
	vec3 rayDir = (endPos - startPos) / rayDist;

	float steps = 16.0;
	float stepLength = range / steps;

	float noise = BlueNoise(1.61803398);

	vec3 result = vec3(0.0);

	for (int i = 0; i < steps; i++){
		float rayLength = (float(i) + noise) * stepLength;
		vec3 rayPos = startPos + rayDir * rayLength;

		if(startDist + rayLength > range || rayLength > rayDist) break;

		vec3 shadowProjPos = ShadowPos_From_WorldPos_Distorted(rayPos + gbufferModelViewInverse[3].xyz);
		#ifdef MC_GL_VENDOR_NVIDIA
			vec3 shadow = vec3(step(shadowProjPos.z + 1e-06, textureLod(shadowtex1, shadowProjPos.xy, 0).x));
		#else
			vec3 shadow = vec3(step(shadowProjPos.z + 1e-06, textureLod(shadowtex0, shadowProjPos.xy, 0).x));
		#endif

		rayLength += startDist;

		float caustics = CalculateWaterCaustics(rayPos);
		shadow *= caustics * caustics * caustics;
		shadow /= max(3.0, rayLength * 0.1);
		#ifdef UNDERWATER_FOG
			shadow *= pow(vec3(0.1, 0.6, 1.0) * 0.99, vec3(rayLength * 0.04 * WATERFOG_DENSITY));
		#endif

		result += shadow;
	}
	result /= steps;

	vec3 lightVector = refract(worldShadowVector, vec3(0.0, -1.0, 0.0), 1.0 / 1.2);
	float LdotV = dot(lightVector,worldDir);
	float phace = MiePhaseFunction(0.7, LdotV);

	result *= colorShadowlight * (5.0 * phace * SUNLIGHT_INTENSITY * UNDERWATER_VFOG_DENSITY);

	#ifdef UNDERWATER_FOG
		result *= vec3(0.2, 0.65, 1.0);
	#endif

	#ifdef VOLUMETRIC_CLOUDS
		#ifdef CLOUD_SHADOW
			result *= clamp(globalCloudShadow, 0.01, 1.0);
		#endif
	#endif

	return result;
}
