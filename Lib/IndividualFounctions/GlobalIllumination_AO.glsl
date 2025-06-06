#if (!defined GI_RSM || defined DIMENSION_NETHER)

////////////////////PROGRAM_GI_0////////////////////////////////////////////////////////////////////
////////////////////PROGRAM_GI_0////////////////////////////////////////////////////////////////////
#ifdef PROGRAM_GI_0

float SSAO(vec3 origin, vec3 normal){
	const int numRays = 16;

	const float phi = 1.618033988;
	const float gAngle = phi * 3.14159265 * 1.0003;

	float aoAccum = 0.0;

	float radius = 0.30 * -origin.z;
		  radius = radius * 0.5 + 0.4;
	float zThickness = 0.30 * -origin.z;
		  zThickness = zThickness * 0.5 + 0.5;

	float aoMul = 1.0;

	for (int i = 0; i < numRays; i++)
	{
		float fi = float(i) + RandNextF();
		float fiN = fi / float(numRays);
		float lon = gAngle * fi * 6.0;
		float lat = asin(fiN * 2.0 - 1.0);

		vec3 kernel;
		kernel.x = cos(lat) * cos(lon);
		kernel.z = cos(lat) * sin(lon);
		kernel.y = sin(lat);

		kernel.xyz = normalize(kernel.xyz + normal.xyz);

		float sampleLength = radius * mod(fiN, 0.02f) * 50.0;

		vec3 samplePos = fma(vec3(sampleLength), kernel, origin);

		vec3 samplePosProj = ScreenPos_From_ViewPos_Raw(samplePos);

		float actualZ = -LinearDepth_From_ScreenDepth(texture(depthtex1, samplePosProj.xy).x);

		float depthDiff = actualZ - samplePos.z;
		
		if (depthDiff > 0.0 && depthDiff < zThickness)
		{
			float aow = 1.35 * saturate(dot(normalize(samplePos - origin), normal));
			aoAccum += aow;
		}
	}

	aoAccum /= numRays;

	float ao = 1.0 - aoAccum;
	ao = pow(ao, 1.7);

	return 1.0 - ao;
}


vec2 CalculateCameraVelocity(vec2 coord, float depth){
    vec3 projection = vec3(coord, depth) * 2.0 - 1.0;
    projection = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);
    projection = mat3(gbufferPreviousModelView) * (mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz + cameraPosition - previousCameraPosition) + gbufferPreviousModelView[3].xyz;
    projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;
    return (coord - projection.xy);
}

vec4 GI_TemporalFilter(){
	vec4 prev = texture(colortex2, texcoord);
	vec2 coord = texcoord;
	vec2 tcoord = texcoord / GI_RENDER_RESOLUTION;


	if(saturate(tcoord) == tcoord){
		coord = tcoord;

		float currDepth = texture(depthtex1, coord).x;

		if(currDepth < 1.0){
			float blendWeightAo = 0.75;

			vec3 currNormal = DecodeNormal(texture(colortex3, coord).xy);
			vec3 currViewPos = ViewPos_From_ScreenPos_Raw(coord, currDepth);

			float currAo = SSAO(currViewPos, currNormal);

			vec2 velocity = CalculateCameraVelocity(coord, currDepth);

			vec2 pcoord = coord - velocity;
			vec2 prevCoord = clamp(pcoord, vec2(0.0), vec2(1.0) - pixelSize);
			if(prevCoord != pcoord) return vec4(vec3(0.0), currAo);

			prevCoord *= GI_RENDER_RESOLUTION;

			float prevAo = texture(colortex2, prevCoord).a;

			prevCoord.x += GI_RENDER_RESOLUTION;

			vec4 prevData = texture(colortex2, prevCoord);
			vec3 prevNormal = prevData.xyz * 2.0 - 1.0;
			float prevDist = prevData.a * 500.0;

			float normalWeight = float(dot(currNormal, prevNormal) > 0.5);

			float currDist = length(currViewPos);
			currDist = min(currDist, 500.0);

			float cameraVelocity = distance(cameraPosition, previousCameraPosition);
			float depthWeight = max(abs(currDist - prevDist) - cameraVelocity, 0.0);
			depthWeight = exp(-depthWeight / (currDist + 1.0) * 10.0);
			depthWeight = saturate(depthWeight * 2.0);

			return vec4(vec3(0.0), mix(currAo, prevAo, blendWeightAo * normalWeight * depthWeight));
		}
	}

	tcoord.x -= 1.0;

	if(saturate(tcoord) == tcoord){
		coord = tcoord;

		float depth = texture(depthtex1, coord).x;

        if (depth < 1.0){

    		vec3 normal = DecodeNormal(texture(colortex3, coord).xy);
            float dist = length(ViewPos_From_ScreenPos_Raw(coord, depth));

		    return vec4(normal * 0.5 + 0.5, dist * 0.002);
        }else{
            return vec4(vec3(0.5), 0.0);
        }
	}
	return prev;
}

#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////





////////////////////PROGRAM_GI_1////////////////////////////////////////////////////////////////////
////////////////////PROGRAM_GI_1////////////////////////////////////////////////////////////////////
#ifdef PROGRAM_GI_1

float GI_SpatialFilter(float dist, vec3 normal, vec3 viewDir){
	const vec2 offset[49] = vec2[49](
	vec2(-3.0, -3.0), vec2(-2.0, -3.0), vec2(-1.0, -3.0), vec2(0.0, -3.0), vec2(1.0, -3.0), vec2(2.0, -3.0), vec2(3.0, -3.0),
	vec2(-3.0, -2.0), vec2(-2.0, -2.0), vec2(-1.0, -2.0), vec2(0.0, -2.0), vec2(1.0, -2.0), vec2(2.0, -2.0), vec2(3.0, -2.0),
	vec2(-3.0, -1.0), vec2(-2.0, -1.0), vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0), vec2(2.0, -1.0), vec2(3.0, -1.0),
	vec2(-3.0,  0.0), vec2(-2.0,  0.0), vec2(-1.0,  0.0), vec2(0.0,  0.0), vec2(1.0,  0.0), vec2(2.0,  0.0), vec2(3.0,  0.0),
	vec2(-3.0,  1.0), vec2(-2.0,  1.0), vec2(-1.0,  1.0), vec2(0.0,  1.0), vec2(1.0,  1.0), vec2(2.0,  1.0), vec2(3.0,  1.0),
	vec2(-3.0,  2.0), vec2(-2.0,  2.0), vec2(-1.0,  2.0), vec2(0.0,  2.0), vec2(1.0,  2.0), vec2(2.0,  2.0), vec2(3.0,  2.0),
	vec2(-3.0,  3.0), vec2(-2.0,  3.0), vec2(-1.0,  3.0), vec2(0.0,  3.0), vec2(1.0,  3.0), vec2(2.0,  3.0), vec2(3.0,  3.0));

    vec2 coord = texcoord.st * GI_RENDER_RESOLUTION;

	float weights = 0.0;
	float gi = 0.0;

	float clampedDist = min(dist, 500.0);

	float b = saturate(clampedDist * 0.03) * 0.03 + 0.025;
	float depthThreshold = 1.1 + saturate(1.0 - abs(dot(normal, viewDir)) / b) * 10.0;

	for (int i = 0; i < 49; i++){
		vec2 sampleCoord = clamp(coord + pixelSize * offset[i] * 2.0, vec2(0.0), vec2(GI_RENDER_RESOLUTION) - pixelSize);

		float weight = length(offset[i]);
	  	weight = exp2(-weight * weight * 0.1);

		vec4 sampleData = texture(colortex2, sampleCoord + vec2(GI_RENDER_RESOLUTION, 0.0));

		vec3 sampleNormal = sampleData.xyz * 2.0 - 1.0;
		float normalWeight = abs(dot(normal, sampleNormal));
		normalWeight = exp2(normalWeight * 64.0 - 64.0);

		float depthWeight = saturate(-abs(sampleData.w * 500.0 - clampedDist) + depthThreshold);

		weight *= normalWeight * depthWeight;
		gi += texture(colortex2, sampleCoord).a * weight;
		weights += weight;
	}
	gi /= weights + 1e-20;

	return gi;
}

#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////

#endif
