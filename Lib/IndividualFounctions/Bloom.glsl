#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


in vec2 texcoord;


#ifdef DIMENSION_NETHER
	uniform float BiomeNetherWastesSmooth;
	uniform float BiomeSoulSandValleySmooth;
	uniform float BiomeCrimsonForestSmooth;
	uniform float BiomeWarpedForestSmooth;
	uniform float BiomeBasaltDeltasSmooth;
#endif


/* DRAWBUFFERS:1 */
layout(location = 0) out vec4 compositeOutput1;


#include "/Lib/Uniform/GbufferTransforms.glsl"


vec2 TexelOffset(float l){
    vec2 offset = vec2(0.0);

    float r = step(2.0, l);
    offset.x += r * (ceil(screenSize.x * 0.5) + 5.0);
    offset.y -= r * (floor(0.75 * screenSize.y) + 10.0);

    offset.y += ceil((1.0 - exp2(-l)) * screenSize.y) + l * 5.0;

    return offset;
}

vec3 DualBlurUpSample(const float level, sampler2D tex){
    const vec3 sampleOffset[8] = vec3[8](
        vec3(-0.5, -0.5, 1.0 / 6.0),
        vec3(-0.5, 0.5, 1.0 / 6.0),
        vec3(0.5, -0.5, 1.0 / 6.0),
        vec3(0.5, 0.5, 1.0 / 6.0),
        vec3(-1.0, 0.0, 1.0 / 12.0),
        vec3(0.0, -1.0, 1.0 / 12.0),
        vec3(0.0, 1.0, 1.0 / 12.0),
        vec3(1.0, 0.0, 1.0 / 12.0));

    vec2 currTexelCoord = gl_FragCoord.xy * exp2(-level - 1.0);
    vec2 sampleSize = ceil(screenSize * exp2(-level - 2.0)) * 2.0 - 0.5;

    vec2 texelOffset = TexelOffset(level);

    vec3 blurUp = vec3(0.0);

    for (int i = 0; i < 8; i++){
        vec2 sampleTexelCoord = clamp(currTexelCoord + sampleOffset[i].xy, vec2(0.5), vec2(sampleSize));
        sampleTexelCoord += texelOffset;

        vec2 sampleCoord = sampleTexelCoord * pixelSize;
        blurUp += CurveToLinear(texture(tex, sampleCoord).rgb) * sampleOffset[i].z;
    }

    return blurUp;
}


void AddFogScatter(inout vec3 color, in float bloomGuide){
	#ifdef DIMENSION_MAIN
		float rainAlpha = 0.4 - 0.4 * texture(colortex0, texcoord).a;
		rainAlpha *= RAIN_VISIBILITY;
	#endif

	#ifdef DIMENSION_NETHER
		float linearDepth = length(ViewPos_From_ScreenPos(texcoord, texture(colortex7, texcoord).a));
		linearDepth = min(linearDepth, far);
	#else
		float linearDepth = length(ViewPos_From_ScreenPos(texcoord, texture(gdepthtex, texcoord).x));
	#endif

	vec3 bloomData = vec3(0.0);

	float weights = 0.0;

	bloomData += DualBlurUpSample(0.0, colortex3) * 0.90909091;
	bloomData += DualBlurUpSample(1.0, colortex4) * 0.82644628;
	bloomData += DualBlurUpSample(2.0, colortex4) * 0.75131480;
	bloomData += DualBlurUpSample(3.0, colortex4) * 0.68301346;
	bloomData += DualBlurUpSample(4.0, colortex4) * 0.62092132;
	bloomData += DualBlurUpSample(5.0, colortex4) * 0.56447393;
	bloomData += DualBlurUpSample(6.0, colortex4) * 0.51315812;
	bloomData += DualBlurUpSample(7.0, colortex4) * 0.46650738;

	bloomData *= 0.18744402;

	float bloomAmount = BLOOM_AMOUNT * 0.1;


	#ifdef DIMENSION_NETHER

		float biomeOffset =	 BiomeNetherWastesSmooth * 2.0;
		biomeOffset +=		 BiomeCrimsonForestSmooth * 1.5;
		biomeOffset +=		 BiomeWarpedForestSmooth * 0.5;
		biomeOffset +=		 BiomeBasaltDeltasSmooth * 1.0;

		biomeOffset = biomeOffset * NETHER_BLOOM_BOOST + 1.0;

		float fogDensity = 0.004 * biomeOffset * NETHER_BLOOM_BOOST * NETHERFOG_DENSITY;

		if (isEyeInWater > 1) fogDensity = 0.5;

		float visibility = 1.0 / exp(linearDepth * fogDensity);
		float fogFactor = 1.1 - visibility;
		fogFactor *= bloomGuide;

		bloomAmount = max(bloomAmount * biomeOffset, fogFactor);

	#else

		float fogDensity = 0.0f;

		#ifdef UNDERWATER_FOG
			if (isEyeInWater == 1) fogDensity = 0.05 * WATERFOG_DENSITY;
		#endif
		if (isEyeInWater > 1) fogDensity = 0.5;

		float visibility = 1.0 / exp(linearDepth * fogDensity);
		float fogFactor = 1.1 - visibility;
		fogFactor *= bloomGuide;


		#ifdef DIMENSION_MAIN
			#ifndef INDOOR_FOG
				float rainBloomAmount = wetness * (0.2 * eyeBrightnessSmoothCurved + 0.15);
			#else
				float rainBloomAmount = wetness * 0.35;
			#endif
			rainBloomAmount = saturate(rainBloomAmount + rainAlpha * 0.8);

			bloomAmount = max(bloomAmount, rainBloomAmount);
		#endif

		bloomAmount = max(bloomAmount, fogFactor);

	#endif

	color = mix(color, bloomData, saturate(bloomAmount));
}



void main(){
	vec4 data1 = texture(colortex1, texcoord);
	vec3 color = CurveToLinear(data1.rgb);

	#ifdef BLOOM_EFFECTS
		AddFogScatter(color, 1.0 - data1.a);
	#endif

	color = LinearToCurve(color);

	compositeOutput1 = vec4(color, 0.0);
}
