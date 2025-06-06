


#define RAYTRACE_QUALITY 16 //[8 16 32 64 128 256 512]

#define RAYTRACE_REFINEMENT //Improves ray trace quality by refining the rays with minimal performance overhead.
#define RAYTRACE_REFINEMENT_STEPS 6 //[2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32]





bool rayTrace(vec3 rayOrigin, vec3 rayDir, float NoV, float jitter, bool isHand, inout vec3 rayPosition) {
    const int steps = RAYTRACE_QUALITY + 3;
    const float maxLength = 1.0 / RAYTRACE_QUALITY;
    const float minLength = maxLength * 0.01;
    const float zThicknessThreshold = 0.2;

    float maxDist = LinearDepth_From_ScreenDepth(1.0);

	float rayLength = ((rayOrigin.z + rayDir.z * maxDist) > -near) ?
      	 			  (-near - rayOrigin.z) / rayDir.z : maxDist;

	vec3 direction = normalize(ScreenPos_From_ViewPos_Raw(rayDir * rayLength + rayOrigin) - rayPosition);
    float stepWeight = 1.0 / abs(direction.z);

	float stepLength = mix(minLength, maxLength, NoV);
    vec3 increment = direction * vec3(max(pixelSize, stepLength), stepLength);

	rayPosition = rayPosition + increment * (jitter * 0.5 + 0.5);

	float depth = texture(depthtex1, rayPosition.xy).x;

    bool isRayExit = false;

	for(int i = 0; i <= steps; i++){
		if (saturate(rayPosition.xy) != rayPosition.xy) return false;

        if (depth < rayPosition.z) {

            #ifdef RAYTRACE_REFINEMENT

                if (rayPosition.z >= 1.0){
                    isRayExit = true;
                    break;
                }

                vec3 newDir = direction * stepLength;

                for (int j = 0; j < RAYTRACE_REFINEMENT_STEPS; j++) {
                    newDir *= 0.5;

                    if (rayPosition.z > depth) {
                        rayPosition -= newDir;
                    } else {
                        rayPosition += newDir;
                    }

                    if(isHand) {
                        depth = texture(depthtex2, rayPosition.xy).x;
                    }else{
                        depth = texture(depthtex1, rayPosition.xy).x;
                    }

                }

                if (rayPosition.z < depth) {
                    continue;
                }

            #endif

            float linearZ = LinearDepth_From_ScreenDepth(rayPosition.z);
            float linearD = LinearDepth_From_ScreenDepth(depth);

            float dist = abs(linearD - linearZ) / linearZ;

            if (dist < zThicknessThreshold
             && linearZ > 0.0
             && linearZ < maxDist)
            return true;
        }

        stepLength = clamp(abs(depth - rayPosition.z) * stepWeight, minLength, maxLength);
		rayPosition += direction * stepLength;
		depth = texture(depthtex1, rayPosition.xy).x;
	}

	return depth >= 1.0 && isRayExit;
}






float SignExtract(float x) {
	return uintBitsToFloat((floatBitsToUint(x) & 0x80000000u) | floatBitsToUint(1.0));
}

mat3 GetRotationMatrix(vec3 from, vec3 to) {
	float cosine = dot(from, to);

	float tmp = SignExtract(cosine);
	      tmp = 1.0 / (tmp + cosine);

	vec3 axis = cross(to, from);
	vec3 tmpv = axis * tmp;

	return mat3(
		axis.x * tmpv.x + cosine, axis.x * tmpv.y - axis.z, axis.x * tmpv.z + axis.y,
		axis.y * tmpv.x + axis.z, axis.y * tmpv.y + cosine, axis.y * tmpv.z - axis.x,
		axis.z * tmpv.x - axis.y, axis.z * tmpv.y + axis.x, axis.z * tmpv.z + cosine
	);
}


#include "/Lib/IndividualFounctions/Reflections/Complex.glsl"

vec3 FresnelNonpolarized(float VdotH, ComplexVec3 n1, ComplexVec3 n2) {
	ComplexVec3 eta = ComplexDiv(n1, n2);

	float       cosThetaI = VdotH;
	float       sinThetaI = 1.0 - cosThetaI * cosThetaI;
	ComplexVec3 sinThetaT = ComplexMul(eta, sinThetaI);
	ComplexVec3 cosThetaT = ComplexSqrt(ComplexSub(1.0, ComplexMul(sinThetaT, sinThetaT)));

	ComplexVec3 RsNum = ComplexSub(ComplexMul(eta, cosThetaI), cosThetaT);
	ComplexVec3 RsDiv = ComplexAdd(ComplexMul(eta, cosThetaI), cosThetaT);
	//vec3 sqrtRs = ComplexAbs(RsNum) / ComplexAbs(RsDiv);
	//vec3 Rs = sqrtRs * sqrtRs;
	vec3 Rs = (RsNum.r * RsNum.r + RsNum.i * RsNum.i) / (RsDiv.r * RsDiv.r + RsDiv.i * RsDiv.i);

	ComplexVec3 RpNum = ComplexSub(ComplexMul(eta, cosThetaT), cosThetaI);
	ComplexVec3 RpDiv = ComplexAdd(ComplexMul(eta, cosThetaT), cosThetaI);
	//vec3 sqrtRp = ComplexAbs(RpNum) / ComplexAbs(RpDiv);
	//vec3 Rp = sqrtRp * sqrtRp;
	vec3 Rp = (RpNum.r * RpNum.r + RpNum.i * RpNum.i) / (RpDiv.r * RpDiv.r + RpDiv.i * RpDiv.i);

	return saturate((Rs + Rp) * 0.5);
}



vec2 ProjectSky(vec3 dir, float tileSize) {
	float tileSizeDivide = 0.5 * tileSize - 1.5;

	vec2 coord;
	if (abs(dir.x) > abs(dir.y) && abs(dir.x) > abs(dir.z)) {
		dir /= abs(dir.x);
		coord.x = dir.y * tileSizeDivide + tileSize * 0.5;
		coord.y = dir.z * tileSizeDivide + tileSize * (dir.x < 0.0 ? 0.5 : 1.5);
	} else if (abs(dir.y) > abs(dir.x) && abs(dir.y) > abs(dir.z)) {
		dir /= abs(dir.y);
		coord.x = dir.x * tileSizeDivide + tileSize * 1.5;
		coord.y = dir.z * tileSizeDivide + tileSize * (dir.y < 0.0 ? 0.5 : 1.5);
	} else {
		dir /= abs(dir.z);
		coord.x = dir.x * tileSizeDivide + tileSize * 2.5;
		coord.y = dir.y * tileSizeDivide + tileSize * (dir.z < 0.0 ? 0.5 : 1.5);
	}

	return coord * pixelSize;
}


#define SPECULAR_TAIL_CLAMP 0.3

vec3 sampleGGXVNDF(vec3 Ve, float alpha, vec2 Xi) {
    Xi.y = mix(Xi.y, 0.0, SPECULAR_TAIL_CLAMP);

    // Section 3.2: transforming the view direction to the hemisphere configuration
    vec3 Vh = normalize(vec3(alpha * Ve.x, alpha * Ve.y, Ve.z));

    // Section 4.1: orthonormal basis (with special case if cross product is zero)
    float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
    vec3 T1 = lensq > 0.0 ? vec3(-Vh.y, Vh.x, 0.0) * inversesqrt(lensq) : vec3(1.0, 0.0, 0.0);
    vec3 T2 = cross(Vh, T1);

    // Section 4.2: parameterization of the projected area
    float r = sqrt(Xi.y);
    float phi = radians(360.0) * Xi.x;

    float s = 0.5 * (1.0 + Vh.z);

    float t1 = r * cos(phi);
    float t2 = r * sin(phi);
        t2 = (1.0 - s) * sqrt(1.0 - t1 * t1) + s * t2;

    // Section 4.3: reprojection onto hemisphere
    vec3 Nh = t1 * T1 + t2 * T2 + sqrt(max(1.0 - t1 * t1 - t2 * t2, 0.0)) * Vh;

    // Section 3.4: transforming the normal back to the ellipsoid configuration
    vec3 Ne = normalize(vec3(alpha * Nh.x, alpha * Nh.y, max(Nh.z, 0.0)));

    return Ne;
}
