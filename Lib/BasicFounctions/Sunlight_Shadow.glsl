

float F_Schlick(float VoH, float f0, float f90){
    VoH = 1.0 - VoH;
    float VoH2 = VoH * VoH;
    return f0 + (f90 - f0) * VoH2 * VoH2 * VoH;
}

float Fd_Burley(vec3 n, vec3 v, vec3 l, float roughness){
	vec3 h = normalize(v + l);
	float LdotH = saturate(dot(l, h));
	float NdotL = saturate(dot(n, l));
	float NdotV = saturate(dot(n, v));

    float f90 = 0.5 + 2.0 * roughness * LdotH * LdotH;

    float lightScatter = F_Schlick(NdotL, 1.0, f90);
    float viewScatter = F_Schlick(NdotV, 1.0, f90);

    return NdotL * lightScatter * viewScatter * 0.5;
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

vec3 VariablePenumbraShadow(vec3 worldPos, MaterialMask mask, vec3 worldNormal){
	worldPos += gbufferModelViewInverse[3].xyz;
    worldPos -= gbufferModelViewInverse[2].xyz * 0.5 * mask.hand;

	worldNormal = mix(worldNormal, vec3(0, 1, 0), saturate(mask.grass + mask.leaves));

	float dist;
	float distortFactor;
	vec3 shadowProjPos = ShadowPos_From_WorldPos_Distorted_Biased(worldPos, worldNormal, dist, distortFactor);

    #ifdef TAA
		float noise = BlueNoise(0.447213595);
	#else
		float noise = rand(texcoord.st).x;
	#endif

	vec3 result = vec3(0.0);

	float spread = VPS_SPREAD / distortFactor;


	float avgDiff = 0.0;
    float spreadLod = log2(shadowMapResolution / 512.0);
	for (int i = -1; i <= 1; i++){
		for (int j = -1; j <= 1; j++){
			vec2 lookupCoord = shadowProjPos.xy + vec2(i, j) * spread * 0.0039;
			float depthDiff = clamp(shadowProjPos.z - textureLod(shadowtex0, lookupCoord, spreadLod).x, 0.0, 0.025);
			avgDiff += depthDiff * depthDiff;
		}
	}
	avgDiff /= 9.0;
	avgDiff = sqrt(avgDiff);


	float sampleSpread = avgDiff * 0.1 * spread + SHADOW_BASIC_BLUR / shadowMapResolution;

    shadowProjPos.z -= dist * 0.0012 + noise * 0.00005;

    const float steps = VPS_QUALITY;
    const float rSteps = 1.0 / steps;

	for (float i = 0.0; i < steps; i++){
        float rot = (i + noise) * 10.166407;
        float radius = sqrt((i + noise) * rSteps);
        vec2 offset = vec2(cos(rot), sin(rot)) * sampleSpread * radius * 2.0;

        vec3 sampleCoord = vec3(shadowProjPos.xy + offset, shadowProjPos.z);

		#ifdef COLORED_SHADOWS
			float translucentShadow = step(sampleCoord.z, textureLod(shadowtex0, sampleCoord.xy, 0.0).x);
			result += vec3(translucentShadow);

			float soildShadow = textureLod(shadowtex1, sampleCoord, 0.0).x;
			vec3 shadowColorSample = GammaToLinear(texture(shadowcolor0, sampleCoord.xy).rgb);
			result += shadowColorSample * (soildShadow - translucentShadow);
		#else
			float soildShadow = textureLod(shadowtex1, sampleCoord, 0.0).x;
			result += vec3(soildShadow);
		#endif
	}

	return result * rSteps;
}

vec3 ClassicSoftShadow(vec3 worldPos, MaterialMask mask, vec3 worldNormal){
    worldPos += gbufferModelViewInverse[3].xyz;
    worldPos -= gbufferModelViewInverse[2].xyz * 0.5 * mask.hand;

	worldNormal = mix(worldNormal, vec3(0, 1, 0), saturate(mask.grass + mask.leaves));

	float dist;
	float distortFactor;
	vec3 shadowProjPos = ShadowPos_From_WorldPos_Distorted_Biased(worldPos, worldNormal, dist, distortFactor);

	vec3 result = vec3(0.0);

	#ifdef TAA
		float noise = BlueNoise(0.447213595);
	#else
		float noise = rand(texcoord.st).x;
	#endif


	int count = 0;
	float spread = SHADOW_BASIC_BLUR / shadowMapResolution;

    shadowProjPos.z -= dist * 0.0012 + noise * 0.00005;


    const float steps = 4.0;
    const float rSteps = 1.0 / steps;

	for (float i = 0.0; i < steps; i++){
        float rot = (i + noise) * 10.166407;
        float radius = sqrt((i + noise) * rSteps);
        vec2 offset = vec2(cos(rot), sin(rot)) * spread * radius * 2.0;

        vec3 sampleCoord = vec3(shadowProjPos.xy + offset, shadowProjPos.z);

		#ifdef COLORED_SHADOWS
			float translucentShadow = step(sampleCoord.z, textureLod(shadowtex0, sampleCoord.xy, 0.0).x);
			result += vec3(translucentShadow);

			float soildShadow = textureLod(shadowtex1, sampleCoord, 0.0).x;
			vec3 shadowColorSample = GammaToLinear(texture(shadowcolor0, sampleCoord.xy).rgb);
			result += shadowColorSample * (soildShadow - translucentShadow);
		#else
			float soildShadow = textureLod(shadowtex1, sampleCoord, 0.0).x;
			result += vec3(soildShadow);
		#endif
	}

    return result * rSteps;
}

float ScreenSpaceShadow(vec3 origin, vec3 geoNormal, MaterialMask mask){
	if (mask.hand > 0.5) return 1.0;


    #ifdef TAA
        float noise = BlueNoise(1.41421356);
    #else
        float noise = rand(texcoord.st).x;
    #endif


	float fov = mask.grass > 0.5 ? 80.0 : atan(1.0 / gbufferProjection[1][1]) * 360.0 / PI;

	vec3 rayPos = origin;
	vec3 rayDir = shadowVector * (-origin.z * 0.000035 * fov);

	float NdotL = saturate(dot(shadowVector, geoNormal));

	rayPos += geoNormal * 0.0003 * max(abs(origin.z), 0.1) / (NdotL + 0.01) * (1.0 - mask.grass);

	if (mask.grass < 0.5 && mask.leaves < 0.5){
		rayPos += geoNormal * 0.00001 * -origin.z * fov * 0.15;
		rayPos += rayDir * 13000.0 * min(pixelSize.x, pixelSize.y) * 0.15;
	}

	float zThickness = 0.025 * -origin.z;
	float shadow = 1.0;
	float absorption = 0.0;
	absorption += 0.7 * mask.grass;
	absorption += 0.85 * mask.leaves;
	absorption = pow(absorption, sqrt(length(origin)) * 0.5);

	float ds = 1.0;
	for (int i = 0; i < 12; i++){
		rayPos += rayDir * ds;

		ds += 0.3;

		vec3 thisRayPos = rayPos + rayDir * noise * ds;

		vec2 rayProjPos = ScreenPos_From_ViewPos_Raw(thisRayPos).xy;

		if(abs(rayProjPos.x) > 1.0 || abs(rayProjPos.y) > 1.0) break;

		#ifdef TAA
			rayProjPos.xy += taaJitter * 0.5;
		#endif

		vec3 samplePos = ViewPos_From_ScreenPos_Raw(rayProjPos.xy, texture(depthtex1, rayProjPos.xy).x); // half res rendering fix

		float depthDiff = samplePos.z - thisRayPos.z;

		if (depthDiff > 0.0 && depthDiff < zThickness) shadow *= absorption;

		if(shadow < 0.01) break;
	}

	return shadow;
}

vec3 GetWavesNormalFromTex(vec3 position){
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

vec2 NoiseRotated(float noise){
	return  (0.495 * sqrt(noise)) * vec2(cos(noise * 2.0 * PI), sin(noise * 2.0 * PI));
}

float CalculateWaterCaustics(vec3 worldPos, MaterialMask mask){
	if (isEyeInWater == 1 && mask.water > 0.5) return 1.0;

	worldPos.xyz += cameraPosition;
    const float threshold = 7.0;

	vec2 dither = NoiseRotated(BlueNoise(1.41421356));

	vec3 lookupCenter = worldPos + vec3(0.0, 1.0, 0.0);

	vec3 lightVector = refract(worldShadowVector, vec3(0.0, -1.0, 0.0), 1.0 / 1.2);
	vec3 depthBias = vec3(worldPos.y * lightVector.x, 0.0, worldPos.y * lightVector.z) / lightVector.y;


	float caustics = 0.0;

	for (float i = -1.0; i <= 1.0; i++){
		for (float j = -1.0; j <= 1.0; j++){
			vec2 offset = (dither + vec2(i, j)) * 0.1;

			vec3 lookupPoint = lookupCenter;
            lookupPoint.xz += offset;

			vec3 wavesNormal = GetWavesNormalFromTex(lookupPoint).xzy;

			vec3 refractVector = refract(vec3(0.0, 1.0, 0.0), wavesNormal.xyz, 1.0);
			vec3 collisionPoint = lookupPoint - refractVector / refractVector.y;
            collisionPoint -= worldPos;

			float dist = dot(collisionPoint, collisionPoint) * 7.1;

			caustics += 1.0 - saturate(dist * threshold);
		}
	}
    caustics *= threshold * 0.025;

	return caustics * 0.9 + 0.2;
}
