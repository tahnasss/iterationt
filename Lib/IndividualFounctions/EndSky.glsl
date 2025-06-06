vec3 CalculateStars(vec3 worldDir){
	float angleY = frameTimeCounter * 0.002;
	mat3 eyeRoataionMatrixY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));

	worldDir = eyeRoataionMatrixY * worldDir;

	const float scale = 384.0;
	const float coverage = 0.007;
	const float maxLuminance = 0.04;
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

vec2 RaySphereIntersectionIO(vec3 p, vec3 dir, float r)
{
	float b = dot(p, dir);
	float c = -r * r + dot(p, p);

	float d = b * b -c;
	if (d < 0.0)
	{
		return vec2(-1e10, 1e10);
	}

	d = sqrt(d);

	return vec2(-b + d, -b - d);
}

vec3 RayPlaneIntersection(vec3 ori, vec3 dir, vec3 normal)
{
	float rayPlaneAngle = dot(dir, normal);

	float planeRayDist = 1e8;
	vec3 intersectionPos = dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot(-ori, normal) / rayPlaneAngle;
		intersectionPos = ori + dir * planeRayDist;
	}

	return intersectionPos;
}


vec3 H(vec3 albedo, float a){
    vec3 R = sqrt(vec3(1.0) - albedo);
    vec3 r = (1.0 - R) / (1.0 + R);
    vec3 H = r + (0.5 - r * a) * log((1.0 + a) / a);
    H *= albedo * a;

    return 1.0 / (1.0 - H);
}

vec3 ppss(vec3 albedo, vec3 normal, vec3 eyeDir, vec3 lightDir, float s){
    float NdotL = dot(normal, lightDir);
    float NdotV = dot(normal, eyeDir);
    albedo *= curve(saturate(NdotL));

    vec3 color = albedo * H(albedo, NdotL) * H(albedo, NdotV) / (4.0 * PI * (NdotL + NdotV));

    return saturate(color);
}

float Disc(float a, float s, float h){
    float disc = curve(saturate((a - (1.0 - s)) * h));
	return disc * disc;
}

void PlanetEnd2(inout vec3 color, in vec3 eye, in vec3 rayDir, in vec3 lightDir){
	float Rground = 20e6;
	eye.y += Rground;
	eye.y += 15e6;

	float VdotL = dot(worldShadowVector, rayDir);
    float timeFactor = frameTimeCounter * 10.0;


    float angleX = -1.8;
    float angleY = 3.0;

    mat3 eyeRoataionMatrixX = mat3(1, 0, 0, 0, cos(angleX), -sin(angleX), 0, sin(angleX), cos(angleX));
    mat3 eyeRoataionMatrixY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
    mat3 eyeRoataionMatrix = eyeRoataionMatrixX * eyeRoataionMatrixY;

    float ringAngle = 0.008;

    mat3 ringRoataionMatrix = mat3(1.0, 0.0, 0.0,
                                   0.0, cos(ringAngle), sin(ringAngle),
                                   0.0, -sin(ringAngle), cos(ringAngle));
    mat3 ringRoataionMatrixInverse = transpose(ringRoataionMatrix);



    rayDir = eyeRoataionMatrix * rayDir;
    lightDir = eyeRoataionMatrix * lightDir;

	vec3 rayDirRing = ringRoataionMatrix * rayDir;
	vec3 lightDirRing = ringRoataionMatrix * lightDir;

	vec3 ringOrigin = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);
	vec2 ringRadius = vec2(1.6, 2.6);



    vec3 surface = vec3(0.0);
	float LdotR = dot(rayDir, -lightDir);

	vec2 RgroundIntersection = RaySphereIntersectionIO(eye, rayDir, Rground);
    if(RgroundIntersection.x > 0.0){
        color *= 0.0;
        vec3 surfacePos = rayDir * RgroundIntersection.y;
        vec3 surfaceNormal = normalize(surfacePos - vec3(0.0, -eye.y, 0.0));
		vec3 surfaceAlbedo = vec3(1.0, 0.87, 0.55);


        surface = ppss(surfaceAlbedo, surfaceNormal, -rayDir, lightDir, 1.0);
        surface *= 70.0;

		vec3 origin = ringOrigin + surfacePos / Rground;
		vec3 rayPos = RayPlaneIntersection(origin, lightDirRing, vec3(0.0, 0.0, 1.0));
		float rayRadius = length(rayPos);

		if (rayRadius > ringRadius.x && rayRadius < ringRadius.y && dot(rayPos - origin, lightDirRing) > 0.0){
			const float octAlpha = 0.5;
			float octScale = 4.0;
			float octShift = (octAlpha / octScale) / 5;

			float accum = 0.0;
			float alpha = 0.5;
			float shift = 0.0;

			float position = rayRadius * 0.5 + 0.69;

			position += shift;

			for (int i = 0; i < 5; i++){
				accum += alpha * texture(noisetex, vec2(position, 0.0)).z;
				position = (position + shift) * octScale;
				alpha *= octAlpha;
			}

			surface *= exp(-pow(saturate(accum + octShift - 0.1) * 1.5, 3.0) * smoothstep(ringRadius.x, ringRadius.x * 1.1, rayRadius));
		}


        float UdotN = saturate(dot(ringRoataionMatrixInverse[2], surfaceNormal));
        float DdotN = saturate(dot(-ringRoataionMatrixInverse[2], surfaceNormal));
        float OLdotN = saturate(dot(ringRoataionMatrixInverse * normalize(vec3(-lightDir.xy, 0.0)), surfaceNormal));

        float ringLighting = Disc(UdotN, 1.2, 1.5) * (1.0 - Disc(UdotN, 3.4, 0.3));
        ringLighting += Disc(DdotN, 1.2, 1.5) * (1.0 - Disc(DdotN, 3.4, 0.3));
        ringLighting *= 1.0 - Disc(OLdotN, 0.7, 1.3);

        surface += surfaceAlbedo * (0.01 + ringLighting * 0.7);
    }

	color += surface * 0.007;


    vec3 ring = vec3(0.0);

    if (rayDirRing.z * ringAngle < 0.0){

        vec3 origin = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);

        vec3 ringPos = RayPlaneIntersection(origin, rayDirRing, vec3(0.0, 0.0, 1.0));
        float rayRadius = length(ringPos);
        vec2 ringRadius = vec2(1.6, 2.6);


        if(rayRadius > ringRadius.x && rayRadius < ringRadius.y)
        {
            const float octAlpha = 0.5;
            float octScale = 4.0;
            float octShift = (octAlpha / octScale) / 5;

            float accum = 0.0;
            float alpha = 0.5;
            float shift = 0.0;

            float position = rayRadius * 0.5 + 0.69;

            position += shift;

            for (int i = 0; i < 5; i++) {
                accum += alpha * texture(noisetex, vec2(position, 0.0)).z;
                position = (position + shift) * octScale;
                alpha *= octAlpha;
            }

            ring += pow(saturate(accum + octShift - 0.1) * 1.5, 3.0);
            ring *= smoothstep(ringRadius.x, ringRadius.x * 1.1, rayRadius);
            //ring *= smoothstep(ringRadius.y, ringRadius.y * 0.95, rayRadius);

            if(ringPos.y < 0.0 && RgroundIntersection.x > 0.0){
                ring *= 0.0;
            }else{
				color *= exp(-ring * 3.0);
			}

            float d = length(cross(lightDirRing, ringPos));
            if(d < 1.0 && dot(lightDirRing, ringPos) < 0.0) ring *= 0.025;
        }
    }
    ring *= vec3(1.0, 0.85, 0.60) * (1.0 + MiePhaseFunction(0.8, VdotL) * 10.0);

	color +=  ring * 0.01;
}



//www.shadertoy.com/view/lstSRS

mat3 RotateMatrix(float x, float y, float z){
    mat3 matx = mat3(1.0, 0.0, 0.0,
                     0.0, cos(x), sin(x),
                     0.0, -sin(x), cos(x));

    mat3 maty = mat3(cos(y), 0.0, -sin(y),
                     0.0, 1.0, 0.0,
                     sin(y), 0.0, cos(y));

    mat3 matz = mat3(cos(z), sin(z), 0.0,
                     -sin(z), cos(z), 0.0,
                     0.0, 0.0, 1.0);

    return maty * matx * matz;
}

void WarpSpace(inout vec3 eyevec, inout vec3 raypos){
    vec3 origin = vec3(0.0, 0.0, 0.0);

    float singularityDist = distance(raypos, origin);
    float warpFactor = 1.0 / (singularityDist * singularityDist + 0.000001);

    vec3 singularityVector = normalize(origin - raypos);

    float warpAmount = 0.06;

    eyevec = normalize(eyevec + singularityVector * warpFactor * warpAmount);
}


float Calculate3DNoise(vec3 position){
    vec3 p = floor(position);
    vec3 b = curve(fract(position));

    vec2 uv = 17.0 * p.z + p.xy + b.xy;
    vec2 rg = texture(noisetex, (uv + 0.5) / 64.0).zy;

    return mix(rg.x, rg.y, b.z);
}

float CalculateCloudFBM(vec3 position, vec3 shift){
	const int octaves = 4;
    const float octAlpha = 0.87;
    const float octScale = 2.5;
    const float octShift = (octAlpha / octScale) / octaves;

    float accum = 0.0;
    float alpha = 0.5;

    for (int i = 0; i < octaves; i++) {
		accum += alpha * Calculate3DNoise(position);
        position = (position + shift) * octScale;
        alpha *= octAlpha;
    }

    return accum + octShift;
}

float CalculateCloudFBM_LQ(vec3 position, vec3 shift){
	const int octaves = 3;
    const float octAlpha = 0.9;
    const float octScale = 2.0;
    const float octShift = (octAlpha / octScale) / octaves;

    float accum = 0.0;
    float alpha = 0.5;

    for (int i = 0; i < octaves; i++) {
		accum += alpha * Calculate3DNoise(position);
        position = (position + shift) * octScale;
        alpha *= octAlpha;
    }

    return accum + octShift;
}

float pcurve(float x, float a, float b){
    float k = pow(a + b, a + b) / (pow(a, a) * pow(b, b));
    return k * pow(x, a) * pow(1.0 - x, b);
}

void BlackHole_AccretionDisc_Stars(inout vec3 color, in vec3 rayDir, in vec3 lightDir){
	const float steps = 50.0;
	const float rSteps = 1.0 / steps;
	const float stepLength = 0.2;

	const float discRadius = 2.25;
	const float discWidth = 3.5;
	const float discInner = discRadius - discWidth * 0.5;
	const float discOuter = discRadius + discWidth * 0.5;

	#ifdef TAA
		float noise = BlueNoise(1.61803398);
	#else
		float noise = InterleavedGradientNoise(gl_FragCoord.xy);
	#endif

	vec3 eye = -lightDir * 8.0;
	vec3 rayPos = eye + rayDir * 3.0;

	mat3 rotation = RotateMatrix(0.1, 0.0, -0.35);


	vec3 result = vec3(0.0);
	float transmittance = 1.0;

	rayPos += rayDir * stepLength * noise;

	for(int i = 0; i < steps; i++){
		if(transmittance < 0.0001) break;

		WarpSpace(rayDir, rayPos);
		rayPos += rayDir * stepLength;

		{
			vec3 discPos = rotation * rayPos;

			float r = length(discPos);
			float p = atan2(-discPos.zx);
			float h = discPos.y;

			float radialGradient = 1.0 - saturate((r - discInner) / discWidth * 0.5);
			float dist = abs(h);

			float discThickness = 0.1;
			discThickness *= radialGradient;

			float fr = abs(r - discInner) + 0.4;
			fr = fr * fr;
			float fade = fr * fr * 0.04;
   			float bloomFactor = 1.0 / (h * h * 40.0 + fade + 0.00002);
			bloomFactor *= saturate(2.0 - abs(dist) / discThickness);
			bloomFactor = bloomFactor * bloomFactor;


			float dr = pcurve(radialGradient, 4.0, 0.9);
			float density = dr;

			density *= saturate(1.0 - abs(dist) / discThickness);
			density = saturate(density * 0.7);
			density = saturate(density + bloomFactor * 0.1);

			if (density > 0.0001){
				vec3 discCoord = vec3(r, p * (1.0 - radialGradient * 0.5), h * 0.1) * 3.5;

				float fbm = CalculateCloudFBM(discCoord, frameTimeCounter * vec3(0.1, 0.07, 0.0));
				float fbm2 = fbm * fbm;
				density *= fbm2 * fbm2 * fbm;
				density *= dr;

				float gr = 1.0 - radialGradient;
				gr = gr * gr;
				float glowStrength = 1.0 / (gr * gr * 400.0 + 0.002);
				vec3 glow = Blackbody(2700.0 + glowStrength * 50.0) * glowStrength;

				float stepTransmittance = exp(-density * 5.0);
				float integral = 1.0 - stepTransmittance;
				transmittance *= stepTransmittance;

				result += integral * transmittance * glow;
			}

			vec2 t = vec2(1.0, 0.01);
			float torusDist = length(length(discPos + vec3(0.0, -0.05, 0.0)) - t);
			float bloomDisc = 1.0 / (pow(torusDist, 3.5) + 0.001);
			vec3 col = Blackbody(12000.0);
			bloomDisc *= step(0.5, r);

			result += col * bloomDisc * 0.1 * transmittance;
		}
	}
	result *= rSteps;

	#ifdef STARS
		color += CalculateStars(rayDir);
	#endif

	color *= transmittance;

	color += result;
}

void BlackHole_AccretionDisc_Reflection(inout vec3 color, in vec3 rayDir, in vec3 lightDir){
	const float steps = 30.0;
	const float rSteps = 1.0 / steps;
	const float stepLength = 0.2;

	const float discRadius = 2.25;
	const float discWidth = 3.5;
	const float discInner = discRadius - discWidth * 0.5;
	const float discOuter = discRadius + discWidth * 0.5;


	float noise = BlueNoise(1.61803398);

	vec3 eye = -lightDir * 8.0;
	vec3 rayPos = eye + rayDir * 4.0;

	mat3 rotation = RotateMatrix(0.1, 0.0, -0.35);


	vec3 result = vec3(0.0);
	float transmittance = 1.0;

	rayPos += rayDir * stepLength * noise;

	for(int i = 0; i < steps; i++){
		if(transmittance < 0.0001) break;

		WarpSpace(rayDir, rayPos);
		rayPos += rayDir * stepLength;

		{
			vec3 discPos = rotation * rayPos;

			float r = length(discPos);
			float p = atan2(-discPos.zx);
			float h = discPos.y;

			float radialGradient = 1.0 - saturate((r - discInner) / discWidth * 0.5);
			float dist = abs(h);

			float discThickness = 0.1;
			discThickness *= radialGradient;

			float fr = abs(r - discInner) + 0.4;
			fr = fr * fr;
			float fade = fr * fr * 0.04;
   			float bloomFactor = 1.0 / (h * h * 40.0 + fade + 0.00002);
			bloomFactor *= saturate(2.0 - abs(dist) / discThickness);
			bloomFactor = bloomFactor * bloomFactor;


			float dr = pcurve(radialGradient, 4.0, 0.9);
			float density = dr;

			density *= saturate(1.0 - abs(dist) / discThickness);
			density = saturate(density * 0.7);
			density = saturate(density + bloomFactor * 0.1);

			if (density > 0.0001){
				vec3 discCoord = vec3(r, p * (1.0 - radialGradient * 0.5), h * 0.1) * 3.5;

				float fbm = CalculateCloudFBM(discCoord, frameTimeCounter * vec3(0.1, 0.07, 0.0));
				float fbm2 = fbm * fbm;
				density *= fbm2 * fbm2 * fbm;
				density *= dr;

				float gr = 1.0 - radialGradient;
				gr = gr * gr;
				float glowStrength = 1.0 / (gr * gr * 400.0 + 0.002);
				vec3 glow = Blackbody(2700.0 + glowStrength * 50.0) * glowStrength;

				float stepTransmittance = exp(-density * 5.0);
				float integral = 1.0 - stepTransmittance;
				transmittance *= stepTransmittance;

				result += integral * transmittance * glow;
			}

			vec2 t = vec2(1.0, 0.01);
			float torusDist = length(length(discPos + vec3(0.0, -0.05, 0.0)) - t);
			float bloomDisc = 1.0 / (pow(torusDist, 3.5) + 0.001);
			vec3 col = Blackbody(12000.0);
			bloomDisc *= step(0.5, r);

			result += col * bloomDisc * 0.1 * transmittance;
		}
	}
	result *= rSteps;

	color *= transmittance;

	color += result;
}

vec3 EndFog(float dist, vec3 worldDir){
	float VdotL = dot(worldShadowVector, worldDir);

    float angleX = -0.2372;
	float angleY = 3.0;

    mat3 eyeRoataionMatrixX = mat3(1, 0, 0, 0, cos(angleX), -sin(angleX), 0, sin(angleX), cos(angleX));
    mat3 eyeRoataionMatrixY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
    mat3 eyeRoataionMatrix = eyeRoataionMatrixX * eyeRoataionMatrixY;

    worldDir = eyeRoataionMatrix * worldDir;

    dist = min(dist, 512.0);
    float h = abs(dot(worldDir, vec3(0.0, 1.0, 0.0))) * dist * 0.03;
    float density = (1.0 - exp(-h)) / h * dist;

	density *= MiePhaseFunction(0.3, VdotL) * 10.0 + 0.25;

    return vec3(density * 1e-5 * SUNLIGHT_INTENSITY);
}
