#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const bool colortex1MipmapEnabled  = true;


/* DRAWBUFFERS:12 */
layout(location = 0) out vec4 compositeOutput1;
layout(location = 1) out vec4 compositeOutput2;


in vec2 texcoord;

#ifdef DIMENSION_NETHER
	uniform float BiomeNetherWastesSmooth;
	uniform float BiomeSoulSandValleySmooth;
	uniform float BiomeCrimsonForestSmooth;
	uniform float BiomeWarpedForestSmooth;
	uniform float BiomeBasaltDeltasSmooth;

    vec3 NetherLighting(){
    	vec3 netherLighting =	 BiomeNetherWastesSmooth * vec3(0.99, 0.34, 0.1) * 4.5e-4;
    	netherLighting +=		 BiomeSoulSandValleySmooth * vec3(0.6, 0.77, 1.0) * 1.75e-4;
    	netherLighting +=		 BiomeCrimsonForestSmooth * vec3(0.99, 0.38, 0.05) * 5e-4;
    	netherLighting +=		 BiomeWarpedForestSmooth * vec3(0.79, 0.82, 1.0) * 2.5e-4;
    	netherLighting +=		 BiomeBasaltDeltasSmooth * vec3(1.0, 0.78, 0.62) * 1e-3;

    	return netherLighting;
    }
#endif


#include "/Lib/Uniform/GbufferTransforms.glsl"

float SampleDepthReference(vec2 coord, float materialID){
    if (materialID == 6.0 || materialID == 8.0){
        return texture(gdepthtex, coord).x;
    }else{
        return texture(depthtex1, coord).x;
    }
}

vec2 CalculateCameraVelocity(vec2 coord, float depth){
    vec3 projection = vec3(coord, depth) * 2.0 - 1.0;
    projection = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);
    projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;

    if (depth < 1.0) projection += cameraPosition - previousCameraPosition;

    projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
    projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;
    return (coord - projection.xy);
}


vec3 MotionBlur(){
	float materialID = floor(texture(colortex5, texcoord).b * 255.0);
    float depth = SampleDepthReference(texcoord, materialID);
    vec2 velocity = depth < 0.7 || materialID == 33.0 ? vec2(0.0) : CalculateCameraVelocity(texcoord, depth);

	if (length(velocity) < 1e-7) return CurveToLinear(texture(colortex7, texcoord).rgb);

	velocity *= MOTION_BLUR_SUTTER_ANGLE / 720.0;

	float maxVelocity = 0.1;
	velocity = clamp(velocity, vec2(-maxVelocity), vec2(maxVelocity));


	float steps = MOTION_BLUR_QUALITY;
	float samples = 0.0;
	vec3 color = vec3(0.0);

	float dither = 0.0;
	#ifdef MOTION_BLUR_DITHER
		dither = InterleavedGradientNoise(gl_FragCoord.xy);
	#endif

	for (float i = -steps; i <= steps; i++){
		vec2 coord = texcoord.st + velocity * (i + dither) / (steps + 1.0);

		if (saturate(coord) == coord){
			color += CurveToLinear(texture(colortex7, coord).rgb);
			samples++;
		}
	}

	color.rgb /= samples;

	return color;
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

float title(inout vec3 color){
    float exposure = CurveToLinear(texelFetch(colortex2, ivec2(0, screenSize.y - 1.0), 0).a);
    float titleCounter = texelFetch(colortex2, ivec2(2, screenSize.y - 1.0), 0).a * 20.0;
    titleCounter = smoothstep(7.0, 4.0, titleCounter);
    if (titleCounter <= 0.0) return 0.0;

    vec4 title = vec4(0.0);

    vec3 viewDir = normalize(ViewPos_From_ScreenPos_Raw(texcoord, 1.0));
    vec3 camera = vec3(0.0, 0.0, 4.0);

    float angleRx = acos(dot(gbufferModelView[1].xyz, vec3(0.0, 0.0, -1.0))) - 0.5 * PI;

    angleRx = -0.5 * angleRx + 0.1;
    mat3 Rx = mat3(1, 0, 0,
                   0, cos(angleRx), sin(angleRx),
                   0, -sin(angleRx), cos(angleRx));

    float angleRy = eyeRySmooth * 7.0;
    mat3 Ry = mat3(cos(angleRy), 0, -sin(angleRy),
                   0, 1, 0,
                   sin(angleRy), 0, cos(angleRy));
    Rx = Ry * Rx;

    vec3 op = camera;
    op = Rx * op;
    vec3 pp = Rx * viewDir;

    op = mat3(gbufferModelViewInverse) * op + gbufferModelViewInverse[3].xyz * 0.1;
    pp = mat3(gbufferModelViewInverse) * pp + gbufferModelViewInverse[3].xyz * 0.1;

    //op = Ry * op;
    op = op * Ry;


    vec3 intersectionPlane = mat3(gbufferModelView) * RayPlaneIntersection(op, pp, -gbufferModelViewInverse[2].xyz);


    if(clamp(intersectionPlane.xy, vec2(-1.9, -1.0), vec2(2.1, 1.0)) == intersectionPlane.xy){
        vec2 titleCoord = intersectionPlane.xy * vec2(0.25, -0.25) + vec2(0.48, 0.28);
        ivec2 tcoord = ivec2(titleCoord * 50.0) + ivec2(0, 64);
        title = texelFetch(colortex12, tcoord, 0);
		//title.a = 1.0;
		//title.rgb = step(0.5, title.rgb);

        #ifdef DIMENSION_NETHER
            title.rgb *= NetherLighting() * 0.07;
        #else
            title.rgb *= vec3(exposure * 15.0 / mainOutputFactor);
        #endif
    }

    title.a *= titleCounter;

    color = mix(color, title.rgb, title.a);

    return title.a;
}

float GetExposureTiles(){
	int avglod = int(log2(min(viewWidth, viewHeight)));
	float avg = Luminance(CurveToLinear(textureLod(colortex1, vec2(0.65, 0.65), avglod).rgb));
	#ifdef LUMINANCE_WEIGHT
		#if LUMINANCE_WEIGHT_MODE == 0
			float lumaOffset = remap(2e-4, 8e-6, avg * mainOutputFactor);
		#endif
	#endif

	int lod = 6;

    float tileScale = exp2(float(lod));
	vec2 tileCount = floor(screenSize / tileScale);
	vec2 tileCenter = tileCount * 0.5;

    float exposure = 0.0;
    float weights = 0.0;

	for (int x = 0; x < tileCount.x; x++){
	for (int y = 0; y < tileCount.y; y++){
        float tileExposure = Luminance(CurveToLinear(texelFetch(colortex1, ivec2(x, y), lod).rgb));

		vec2 tileDistance = (tileCenter - vec2(x, y) + 0.5) * pixelSize * tileScale * 2.0;
        float centerDistance = length(tileDistance);

        #if AE_MODE == 0
            #ifdef DIMENSION_END
				float tileWeight = 1.0;
			#else
				float tileWeight = remap(0.6, 0.4, centerDistance);
			#endif
        #elif AE_MODE == 1
			float tileWeight = remap(0.7, 0.0, centerDistance);
			tileWeight *= tileWeight;
        #elif AE_MODE == 2
            float tileWeight = remap(0.6, 0.4, centerDistance);
		#elif AE_MODE == 3
			float tileWeight = 1.0;
        #endif

		#ifdef AE_CLAMP
			tileExposure = max(1e-12 * mainOutputFactor, tileExposure);
		#endif

        #if (defined CAVE_MODE && defined DIMENSION_MAIN) || defined DIMENSION_NETHER
            float lumaWeight = avg / tileExposure;
            tileWeight *= pow(lumaWeight, 0.7);
        #else
            #ifdef LUMINANCE_WEIGHT
                #if LUMINANCE_WEIGHT_MODE == 0
					float lumaWeight = avg / tileExposure;
					lumaWeight = pow(lumaWeight, lumaOffset);
                #elif LUMINANCE_WEIGHT_MODE == 1
					float lumaWeight = avg / tileExposure;
					lumaWeight = pow(lumaWeight, LUMINANCE_WEIGHT_STRENGTH);
				#elif LUMINANCE_WEIGHT_MODE == 2
                    float lumaWeight = tileExposure / avg;
					lumaWeight = pow(lumaWeight, LUMINANCE_WEIGHT_STRENGTH);
                #endif
				tileWeight *= lumaWeight;
            #endif
        #endif

        exposure += tileExposure * tileWeight;
        weights += tileWeight;
    }
	}
    exposure /= weights;
    exposure *= mainOutputFactor;

	return  LinearToCurve(exposure);
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	#ifdef MOTION_BLUR
		vec3 color = MotionBlur();
	#else
		vec3 color = CurveToLinear(texture(colortex7, texcoord).rgb);
	#endif

	#ifdef DIMENSION_MAIN
		#ifdef LENS_FLARE
			color += CurveToLinear(texture(colortex3, texcoord).rgb) * 1.0;
		#endif
	#endif

    float bloomGuide = 0.0;
    #ifdef TITLE
        bloomGuide = title(color);
    #endif

    color = LinearToCurve(color);

    compositeOutput1 = vec4(color, bloomGuide);


    vec4 data2 = texture(colortex2, texcoord);

    if (distance(gl_FragCoord.xy, vec2(0.0, screenSize.y - 1.0)) < 1.0){
        float avgExposure = GetExposureTiles();
        #ifdef SMOOTH_EXPOSURE
            float prevAvgExposure = data2.a;
            float exposureTime = saturate((step(avgExposure, prevAvgExposure) * 2.0 + 1.0) * frameTime / EXPOSURE_TIME);
            avgExposure = mix(prevAvgExposure, avgExposure, exposureTime);
        #endif
        data2.a = avgExposure;
    }

    if (distance(gl_FragCoord.xy, vec2(2.0, screenSize.y - 1.0)) < 1.0){
        float preAlpha = data2.a;
        float newAlpha = preAlpha + min(frameTime, 0.5) * 0.05;
        data2.a = saturate(newAlpha);
    }

    if (distance(gl_FragCoord.xy, vec2(6.0, screenSize.y - 1.0)) < 1.0){
        data2.a = 1.0 - wetness * RAIN_SHADOW;
    }

    compositeOutput2 = data2;
}
