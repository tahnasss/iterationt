

#define CLOUD_CLEAR_ALTITUDE 		1200.0 	// [0.0 100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1500.0 1600.0 1700.0 1800.0 1900.0 2000.0 2250.0 2500.0 2750.0 3000.0 4000.0 5000.0]
#define CLOUD_CLEAR_THICKNESS 		2500.0 	// [0.0 100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1500.0 1600.0 1700.0 1800.0 1900.0 2000.0 2250.0 2500.0 2750.0 3000.0 4000.0 5000.0]
#define CLOUD_CLEAR_COVERY 			0.0 	// [-0.5 -0.4 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0]
#define CLOUD_CLEAR_DENSITY 		1.0 	// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0 5.0]
#define CLOUD_CLEAR_SUNLIGHTING		1.0		// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0 5.0]
#define CLOUD_CLEAR_SKYLIGHTING		1.0		// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0 5.0]
#define CLOUD_CLEAR_NOISE_SCALE 	0.0002 	// [0.0001 0.00012 0.00014 0.00016 0.00018 0.0002 0.00022 0.00024 0.00026 0.00028 0.0003 0.00035 0.0004 0.0005]
#define CLOUD_CLEAR_FBM_OCTSCALE	2.8 	// [2.0 2.1 2.2 2.3 2.4 2.5 2.55 2.6 2.65 2.7 2.75 2.8 2.85 2.9 2.95 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0]
#define CLOUD_CLEAR_UPPER_LIMIT 	0.5 	// [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CLOUD_CLEAR_LOWER_LIMIT 	0.15 	// [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define CLOUD_RAIN_ALTITUDE 		600.0 	// [0.0 100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1500.0 1600.0 1700.0 1800.0 1900.0 2000.0 2250.0 2500.0 2750.0 3000.0 4000.0 5000.0]
#define CLOUD_RAIN_THICKNESS 		2500.0 	// [0.0 100.0 200.0 300.0 400.0 500.0 600.0 700.0 800.0 900.0 1000.0 1100.0 1200.0 1300.0 1400.0 1500.0 1600.0 1700.0 1800.0 1900.0 2000.0 2250.0 2500.0 2750.0 3000.0 4000.0 5000.0]
#define CLOUD_RAIN_COVERY 			2.0 	// [-0.5 -0.4 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0]
#define CLOUD_RAIN_DENSITY 			1.0 	// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0 5.0]
#define CLOUD_RAIN_SUNLIGHTING		0.6 	// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0 5.0]
#define CLOUD_RAIN_SKYLIGHTING		0.8		// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0 5.0]
#define CLOUD_RAIN_NOISE_SCALE 		0.0003 	// [0.0001 0.00012 0.00014 0.00016 0.00018 0.0002 0.00022 0.00024 0.00026 0.00028 0.0003 0.00035 0.0004 0.0005]
#define CLOUD_RAIN_FBM_OCTSCALE		2.4 	// [2.0 2.1 2.2 2.3 2.4 2.5 2.55 2.6 2.65 2.7 2.75 2.8 2.85 2.9 2.95 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0]
#define CLOUD_RAIN_UPPER_LIMIT 		0.6 	// [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CLOUD_RAIN_LOWER_LIMIT 		0.4 	// [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]


#define CLOUD_ACCURACY 				17.0 	// [11.0 17.0 25.0 37.0 55.0 83.0 125.0]
#define CLOUD_FBM_OCTAVES			4 		// [4 5 6 7 8 9]
#define ADAPTIVE_OCTAVES

#define CLOUD_LIGHTING_OFFSET
#define CLOUD_FADING

#define CLOUD_SPEED 				1.0 	// [0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0 4.0 5.0 7.5 10.0 15.0 20.0 30.0 40.0 50.0 75.0 100.0]


#define ADAPTIVE_OCTAVES_LEVEL 		3
#define ADAPTIVE_OCTAVES_DISTANCE 	60.0
#define CLOUD_SUNLIGHT_QUALITY 		3
#define CLOUD_SKYLIGHT_QUALITY 		2
#define CLOUD_CLEAR_SUNLIGHT_LENGTH 300.0
#define CLOUD_CLEAR_SKYLIGHT_LENGTH 700.0
#define CLOUD_RAIN_SUNLIGHT_LENGTH 	150.0
#define CLOUD_RAIN_SKYLIGHT_LENGTH 	100.0
#define FTC_OFFSET 					0 		// [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255 260 265 270 275 280 285 290 295 300 305 310 315 320 325 330 335 340 345 350 355]




struct CloudProperties{
	float altitude;
	float thickness;
	float coverage;
	float density;
	float sunlighting;
	float skylighting;
	float scale;
	float octScale;
	float lowerLimit;
	float upperLimit;
};


CloudProperties GetGlobalCloudProperties(){
	float lerpFactor = wetness;

	CloudProperties cp;
	cp.altitude 	= mix(CLOUD_CLEAR_ALTITUDE, 	CLOUD_RAIN_ALTITUDE, 		lerpFactor);
	cp.thickness 	= mix(CLOUD_CLEAR_THICKNESS, 	CLOUD_RAIN_THICKNESS, 		lerpFactor);
	cp.coverage 	= mix(CLOUD_CLEAR_COVERY, 		CLOUD_RAIN_COVERY, 			lerpFactor);
	cp.density 		= mix(CLOUD_CLEAR_DENSITY, 		CLOUD_RAIN_DENSITY, 		lerpFactor);
	cp.sunlighting 	= mix(CLOUD_CLEAR_SUNLIGHTING, 	CLOUD_RAIN_SUNLIGHTING, 	lerpFactor);
	cp.skylighting 	= mix(CLOUD_CLEAR_SKYLIGHTING, 	CLOUD_RAIN_SKYLIGHTING, 	lerpFactor);
	cp.scale 		= mix(CLOUD_CLEAR_NOISE_SCALE, 	CLOUD_RAIN_NOISE_SCALE, 	lerpFactor);
	cp.octScale 	= mix(CLOUD_CLEAR_FBM_OCTSCALE, CLOUD_RAIN_FBM_OCTSCALE, 	lerpFactor);
	cp.lowerLimit 	= mix(CLOUD_CLEAR_LOWER_LIMIT, 	CLOUD_RAIN_LOWER_LIMIT, 	lerpFactor);
	cp.upperLimit 	= mix(CLOUD_CLEAR_UPPER_LIMIT, 	CLOUD_RAIN_UPPER_LIMIT, 	lerpFactor);

	return cp;
}



float Calculate3DNoise(vec3 position){
    vec3 p = floor(position);
    vec3 b = curve(fract(position));

    vec2 uv = 17.0 * p.z + p.xy + b.xy;
    vec2 rg = texture(noisetex, (uv + 0.5) / 64.0).zw;

    return mix(rg.x, rg.y, b.z);
}



float CalculateCloudFBM(vec3 position, vec3 windDirection, int octaves, CloudProperties cp){
    const float octAlpha = 0.45;
    float octScale = cp.octScale;
    float octShift = (octAlpha / octScale) / octaves;

    float accum = 0.0;
    float alpha = 0.5;
    vec3  shift = windDirection;

	position += windDirection;

    for (int i = 0; i < octaves; i++) {
		accum += alpha * Calculate3DNoise(position);
        position = (position + shift) * octScale;
        alpha *= octAlpha;
    }

    return accum + octShift;
}


float GetCloudDensity(CloudProperties cp, vec3 worldPos, vec3 windDirection, int octaves){
    vec3  cloudPos  = worldPos * cp.scale;

    float clouds = CalculateCloudFBM(cloudPos, windDirection, octaves, cp);

	float normalizedHeight  = saturate((worldPos.y - cp.altitude) / cp.thickness);
	float heightAttenuation = saturate(normalizedHeight / cp.lowerLimit) * saturate((1.0 - normalizedHeight) / (1.0 - cp.upperLimit));

	clouds  = clouds * heightAttenuation * (1.9 + cp.coverage) - (0.9 * heightAttenuation + normalizedHeight * 0.5 + 0.1);
	clouds  = saturate(clouds * 5.0 * cp.density);

	return clouds;
}

float CalculateMultipleScatteringCloudPhases(float VoL){
	float cloudForwardG = 0.7 - 0.3 * wetness;
	float cloudBackwardG = -0.2;
	float cloudMixG = 0.5;

	float phases = 0.0;
	float cn = 1.0;

    for (int i = 0; i < 4; i++, cn *= 0.5){
        phases += mix(MiePhaseFunction(cloudBackwardG * cn, VoL), MiePhaseFunction(cloudForwardG * cn, VoL), cloudMixG) * cn;
    }

	return phases;
}




#ifdef CLOUD_LOCAL_LIGHTING
vec4 SampleVolumetricClouds(CloudProperties cp, vec3 worldPos, vec3 worldDir, vec3 sunVector, vec3 moonVector, vec3 colorSun, vec3 colorMoon, vec3 colorSky, vec3 windDirection){
	float eyeLength = length(worldPos - cameraPosition);
	int octaves = CLOUD_FBM_OCTAVES;
	#ifdef ADAPTIVE_OCTAVES
		octaves += max(ADAPTIVE_OCTAVES_LEVEL - int(floor(sqrt(eyeLength) / ADAPTIVE_OCTAVES_DISTANCE)), 0);
	#endif

	float density = GetCloudDensity(cp, worldPos, windDirection, octaves);
	float softDensity = density;
	density = smoothstep(0.0, 0.6, density);

	if (density < 0.0001) return vec4(0.0);


	float VdotS = dot(worldDir, sunVector);
	float sunlightLength = mix(CLOUD_CLEAR_SUNLIGHT_LENGTH, CLOUD_RAIN_SUNLIGHT_LENGTH, wetness);
	float skylightLength = mix(CLOUD_CLEAR_SKYLIGHT_LENGTH, CLOUD_RAIN_SKYLIGHT_LENGTH, wetness);

	float sunlightExtinction = 0.0;
	#ifdef CLOUD_LIGHTING_OFFSET
		float sa = smoothstep(0.2, 0.05, worldDir.y);
		float checkOffset = smoothstep(sa * 0.6, -0.6, VdotS) * (60.0 - 40.0 * wetness) * (1.0 + 3.0 * sa);
	#endif
	for (int i = 1; i <= CLOUD_SUNLIGHT_QUALITY; i++){
		float fi = float(i) / 2;
		fi = pow(fi, 1.5) * sunlightLength;
		#ifdef CLOUD_LIGHTING_OFFSET
			fi += checkOffset;
		#endif
		vec3 checkPos = sunVector * fi + worldPos;
		float densityCheck = GetCloudDensity(cp, checkPos, windDirection, octaves);
		sunlightExtinction += densityCheck;

	}
	float sunlightEnergy = 1.0 / (sunlightExtinction * 10.0 + 1.0);

	float powderFactor = exp2(-softDensity * 12.0 / cp.sunlighting);
	float powderFactorSun = powderFactor * saturate(sunlightEnergy * sunlightEnergy * 14.0);
	sunlightEnergy *= MiePhaseFunction(powderFactorSun * 0.3, VdotS * 0.5 + 0.5);

	vec3 sunlightColor = colorSun * (sunlightEnergy * cp.sunlighting * 90.0);

	vec3 cloudColor = sunlightColor * CalculateMultipleScatteringCloudPhases(VdotS);


	float VdotM = dot(worldDir, moonVector);

	float moonlightExtinction = 0.0;
	for (int i = 1; i <= CLOUD_SUNLIGHT_QUALITY; i++)
	{
		float fi = float(i) / 2;
		fi = pow(fi, 1.5);
		vec3 checkPos = moonVector * fi * sunlightLength + worldPos /*make clouds look denser towards sun * (1.5 - sunAngle)*/;
		float densityCheck = GetCloudDensity(cp, checkPos, windDirection, octaves);
		moonlightExtinction += densityCheck;

	}
	float moonlightEnergy = 1.0 / (moonlightExtinction * 10.0 + 1.0);

	float powderFactorMoon = powderFactor * saturate(moonlightEnergy * moonlightEnergy * 14.0);
	moonlightEnergy *= MiePhaseFunction(powderFactorMoon * 0.3, VdotM * 0.5 + 0.5);

	vec3 moonlightColor = colorMoon * (moonlightEnergy * cp.sunlighting * 90.0);

	cloudColor += moonlightColor * CalculateMultipleScatteringCloudPhases(VdotM);


	float skylightExtinction = 0.0;
	for (int i = 1; i < CLOUD_SKYLIGHT_QUALITY; i++)
	{
		float fi = float(i) / 2;
		vec3 checkPos =  worldPos + vec3(0.0, fi * skylightLength, 0.0);
		float densityCheck = GetCloudDensity(cp, checkPos, windDirection, octaves);
		skylightExtinction += densityCheck;
	}
	float skylightEnergy = 0.15 / (skylightExtinction * 1.0 + 1.0);
	vec3 skylightColor = colorSky * skylightEnergy * cp.skylighting;

	cloudColor += skylightColor;


	return vec4(cloudColor * density, density);
}

#else

vec4 SampleVolumetricClouds(CloudProperties cp, vec3 worldPos, vec3 worldDir, vec3 windDirection, float VdotL, float phases){
	float eyeLength = length(worldPos - cameraPosition);
	int octaves = CLOUD_FBM_OCTAVES;
	#ifdef ADAPTIVE_OCTAVES
		octaves += max(ADAPTIVE_OCTAVES_LEVEL - int(floor(sqrt(eyeLength) / ADAPTIVE_OCTAVES_DISTANCE)), 0);
	#endif

	float density = GetCloudDensity(cp, worldPos, windDirection, octaves);
	float softDensity = density;
	density = smoothstep(0.0, 0.6, density);

	if (density < 0.0001) return vec4(0.0);

	float sunlightLength = mix(CLOUD_CLEAR_SUNLIGHT_LENGTH, CLOUD_RAIN_SUNLIGHT_LENGTH, wetness);
	float skylightLength = mix(CLOUD_CLEAR_SKYLIGHT_LENGTH, CLOUD_RAIN_SKYLIGHT_LENGTH, wetness);

	float sunlightExtinction = 0.0;
	#ifdef CLOUD_LIGHTING_OFFSET
		float sa = smoothstep(0.2, 0.05, worldDir.y);
		float checkOffset = smoothstep(sa * 0.6, -0.6, VdotL) * (60.0 - 40.0 * wetness) * (1.0 + 3.0 * sa);
	#endif
	for (int i = 1; i <= CLOUD_SUNLIGHT_QUALITY; i++)
	{
		float fi = float(i) / 2;
		fi = pow(fi, 1.5) * sunlightLength;
		#ifdef CLOUD_LIGHTING_OFFSET
			fi += checkOffset;
		#endif
		vec3 checkPos = worldShadowVector * fi + worldPos;
		float densityCheck = GetCloudDensity(cp, checkPos, windDirection, octaves);
		sunlightExtinction += densityCheck;
	}
	float sunlightEnergy = 1.0 / (sunlightExtinction * 10.0 + 1.0);

	float powderFactor = exp2(-softDensity * 12.0 / cp.sunlighting);
	powderFactor *= saturate(sunlightEnergy * sunlightEnergy * 14.0);
	sunlightEnergy *= MiePhaseFunction(powderFactor * 0.3, VdotL * 0.5 + 0.5);

	vec3 sunlightColor = colorShadowlight * (sunlightEnergy * cp.sunlighting * 90.0);

	vec3 cloudColor = sunlightColor * phases;


	float skylightExtinction = 0.0;
	for (int i = 1; i < CLOUD_SKYLIGHT_QUALITY; i++)
	{
		float fi = float(i) / 2;
		fi = pow(fi, 1.5);
		vec3 checkPos =  worldPos + vec3(0.0, fi * skylightLength, 0.0);
		float densityCheck = GetCloudDensity(cp, checkPos, windDirection, octaves);
		skylightExtinction += densityCheck;
	}
	float skylightEnergy = 0.15 / (skylightExtinction * 1.0 + 1.0);

	vec3 skylightColor = colorSkylight * skylightEnergy * cp.skylighting;

	cloudColor += skylightColor;


	return vec4(cloudColor * density, density);
}

#endif

void VolumetricClouds(inout vec3 color, in vec3 worldDir, in vec3 camera, in CloudProperties cloudProperties, in float noise, in bool ray_r_mu_intersects_ground, out float cloudTransmittance){
	//noise = BlueNoise(1.41421356);
	vec3 cloudAccum = vec3(0.0, 0.0, 0.0);
	cloudTransmittance = 1.0;

	float cloudUpperAltitude = cloudProperties.altitude + cloudProperties.thickness * (cameraPosition.y > cloudProperties.altitude ? 1.0 : 0.6 + 0.2 * wetness);

	if ((cameraPosition.y < cloudProperties.altitude && ray_r_mu_intersects_ground) || (cameraPosition.y > cloudUpperAltitude &&  worldDir.y > 0.0)) return;

	CloudProperties cp = cloudProperties;
	float planetRadius = atmosphereModel.bottom_radius * 1e3;

	vec3 rayStartPos = vec3(0.0, planetRadius + cameraPosition.y, 0.0);
	vec2 iBottom = RaySphereIntersection(rayStartPos, worldDir, planetRadius + cloudProperties.altitude);
	vec2 iTop = RaySphereIntersection(rayStartPos, worldDir, planetRadius + cloudUpperAltitude);

	vec2 iMarching = cameraPosition.y > cloudUpperAltitude ? vec2(iTop.x, iBottom.x) : vec2(iBottom.y, iTop.y);
	vec3 marchingStart = iMarching.x * worldDir;
	vec3 marchingEnd = iMarching.y * worldDir;

	float inCloud = (1.0 - saturate((cameraPosition.y - cloudUpperAltitude) * 0.005)) *
					(1.0 - saturate((cloudProperties.altitude - cameraPosition.y) * 0.005));

	float iInner = iBottom.y >= 0.0 && cameraPosition.y > cloudProperties.altitude ? iBottom.x : iTop.y;
	iInner = min(iInner, cloudProperties.altitude * 10.0);

	marchingStart = marchingStart * (1.0 - inCloud) + cameraPosition;
	marchingEnd = mix(marchingEnd, iInner * worldDir, inCloud) + cameraPosition;

	float marchingSteps = CLOUD_ACCURACY;
	float marchingStepSize = 1.0 / marchingSteps;

	vec3 marchingIncrement = (marchingEnd - marchingStart) * marchingStepSize;
	vec3 marchingPos = marchingStart + marchingIncrement * noise;

	float wind = 0.002 * (frameTimeCounter * CLOUD_SPEED + 10.0 * FTC_OFFSET);
	//wind = 0.002 * mod(frameTimeCounter * 60.0, 3600.0);

	vec3  windDirection = vec3(1.0, wetness * 0.1 -0.05, 0.4) * wind;

	#ifndef CLOUD_LOCAL_LIGHTING
		float VdotL = dot(worldDir, worldShadowVector);
		float phases = CalculateMultipleScatteringCloudPhases(VdotL);
	#endif

	vec3 rayHitPos;
	float sumTransmit;

	for (int i = 0; i < marchingSteps; i++, marchingPos += marchingIncrement){
		vec3 cloudPos = marchingPos;
		cloudPos.y = length(cloudPos + vec3(0.0, planetRadius, 0.0)) - planetRadius;

		vec3 atmoPoint = marchingPos - cameraPosition;
		atmoPoint = camera + atmoPoint * 0.001;

		#ifdef CLOUD_LOCAL_LIGHTING
			vec3 colorMoon;
			vec3 colorSky;
			vec3 colorSkyMoon;
			vec3 colorSun = GetSunAndSkyIrradiance(atmosphereModel, colortex11, colortex10, atmoPoint, worldSunVector, worldMoonVector, colorMoon, colorSky, colorSkyMoon);
			#ifdef COLD_MOONLIGHT
				DoNightEye(colorMoon);
			#endif
			colorSky += colorSkyMoon;

			vec4 cloudSample = SampleVolumetricClouds(cp, cloudPos, worldDir, worldSunVector, worldMoonVector, colorSun, colorMoon, colorSky, windDirection);
		#else
			vec4 cloudSample = SampleVolumetricClouds(cp, cloudPos, worldDir, windDirection, VdotL, phases);
		#endif

		cloudAccum += cloudSample.rgb * cloudTransmittance;

		rayHitPos += marchingPos * cloudTransmittance;
		sumTransmit += cloudTransmittance;

		cloudTransmittance *= 1.0 - cloudSample.a;
		if (cloudTransmittance < 0.0001) break;
	}

	#ifdef CLOUD_FADING
		rayHitPos /= sumTransmit;
		rayHitPos -= cameraPosition;

		float fading = exp(-max(length(rayHitPos) + (4e3 * wetness - 6e3), 0.0) * 1.5e-5);
		float cloudTransmittanceFaded = mix(1.0, cloudTransmittance, fading);
		cloudAccum *= fading;

		if(cloudTransmittance > 0.9999) return;

		vec3 atmoPoint = camera + rayHitPos * 0.001;
		vec3 transmittance;
		vec3 aerialPerspective = GetSkyRadianceToPoint(atmosphereModel, colortex11, colortex9, camera, atmoPoint, worldSunVector, worldMoonVector, transmittance);

		color *= cloudTransmittanceFaded;

		color += aerialPerspective * (1.0 - cloudTransmittanceFaded);
		color += cloudAccum * transmittance;
	#else
		if(cloudTransmittance > 0.9999) return;

		rayHitPos /= sumTransmit;
		rayHitPos -= cameraPosition;

		vec3 atmoPoint = camera + rayHitPos * 0.001;
		vec3 transmittance;
		vec3 aerialPerspective = GetSkyRadianceToPoint(atmosphereModel, colortex11, colortex9, camera, atmoPoint, worldSunVector, worldMoonVector, transmittance);

		color *= cloudTransmittance;

		color += aerialPerspective * (1.0 - cloudTransmittance);
		color += cloudAccum * transmittance;
	#endif
}
