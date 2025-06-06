

float CurveBlockLightSky(float blockLight){
	blockLight = 1.0 - pow(1.0 - blockLight * 0.9, 0.7);

	blockLight = saturate(blockLight * blockLight * blockLight * 1.95);

	return blockLight;
}

float CurveBlockLightTorch(float blockLight){
	float dist = (1.0 - blockLight) * 15.0 + 1.0;
	dist = dist * dist;

	blockLight *= curve(saturate(blockLight * 4.0 - 0.17));
	blockLight /= dist;

	return blockLight;
}

struct Material {
	float rawSmoothness;
	float rawMetalness;
	float roughness;
	float metalness;
	float f0;
	vec3 n;
	vec3 k;
	float emissiveness;
	bool albedoTintsMetalReflections;
	bool doCSR;
};

struct GbufferData {
	vec3 albedo;
	vec4 albedoW;
	vec3 normalL;
	vec3 normalW;
	float depthL;
	float depthW;
	vec2 lightmapL;
	vec2 lightmapW;
	float materialIDL;
	float materialIDW;
	float waterMask;
	float rainAlpha;
	float parallaxShadow;
	Material material;
};

struct Ray {
	vec3 dir;
	vec3 origin;
};

struct Plane {
	vec3 normal;
	vec3 origin;
};

struct Intersection {
	vec3 pos;
	float distance;
	float angle;
};

float F0ToIor(float f0) {
	f0 = sqrt(f0) * 0.99999; // *0.99999 to prevent divide by 0 errors
	return (1.0 + f0) / (1.0 - f0);
}
vec3 F0ToIor(vec3 f0) {
	f0 = sqrt(f0) * 0.99999; // *0.99999 to prevent divide by 0 errors
	return (1.0 + f0) / (1.0 - f0);
}

const Material airMaterial 		= Material(0.0, 0.0, 0.0, 0.0, 0.0,    vec3(1.000275), vec3(0.0), 0.0, false, false);
const Material material_water 	= Material(1.0, 0.0, 0.0, 0.0, 0.1427, vec3(1.200000), vec3(0.0), 0.0, false, true);
const Material material_glass 	= Material(1.0, 0.0, 0.0, 0.0, 0.1863, vec3(1.458000), vec3(0.0), 0.0, false, true);
const Material material_ice 	= Material(1.0, 0.0, 0.0, 0.0, 0.1338, vec3(1.309000), vec3(0.0), 0.0, false, true);

Material MaterialFromTex(inout vec3 baseTex, vec4 specTex)
{
	//materialID = floor(materialID * 255.0);
	Material material;
	float wet = specTex.a;

	#if TEXTURE_PBR_FORMAT == 0
		material.rawSmoothness = mix(specTex.r, 1.0, wet);
		material.rawMetalness = specTex.g;

		material.roughness = 1.0 - material.rawSmoothness;
		material.roughness *= material.roughness;

		material.metalness = material.rawMetalness;

		material.f0 = material.rawMetalness * 0.96 + 0.04;

		material.emissiveness = specTex.b;


	#elif TEXTURE_PBR_FORMAT == 1
		bool isMetal = specTex.g > (229.5 / 255.0);

		material.rawSmoothness = mix(specTex.r, 1.0, wet);
		material.rawMetalness = float(isMetal);

		material.roughness = 1.0 - material.rawSmoothness;
		material.roughness *= material.roughness;

		material.metalness = material.rawMetalness;

		if (isMetal){
			material.f0 = 0.91;
			int index = int(specTex.g * 255.0 + 0.5) - 230;
			material.albedoTintsMetalReflections = index < 8;
			if (material.albedoTintsMetalReflections) {
				vec3[8] metalN = vec3[8](
					vec3(2.91140, 2.94970, 2.58450), // Iron
					vec3(0.18299, 0.42108, 1.37340), // Gold
					vec3(1.34560, 0.96521, 0.61722), // Aluminium
					vec3(3.10710, 3.18120, 2.32300), // Chrome
					vec3(0.27105, 0.67693, 1.31640), // Copper
					vec3(1.91000, 1.83000, 1.44000), // Lead
					vec3(2.37570, 2.08470, 1.84530), // Platinum
					vec3(0.15943, 0.14512, 0.13547)  // Silver
				);
				vec3[8] metalK = vec3[8](
					vec3(3.0893, 2.9318, 2.7670), // Iron
					vec3(3.4242, 2.3459, 1.7704), // Gold
					vec3(7.4746, 6.3995, 5.3031), // Aluminium
					vec3(3.3314, 3.3291, 3.1350), // Chrome
					vec3(3.6092, 2.6248, 2.2921), // Copper
					vec3(3.5100, 3.4000, 3.1800), // Lead
					vec3(4.2655, 3.7153, 3.1365), // Platinum
					vec3(3.9291, 3.1900, 2.3808)  // Silver
				);

				material.n = metalN[index];
				material.k = metalK[index];
			} else {
				material.n = F0ToIor(baseTex.rgb) * airMaterial.n;
				material.k = vec3(0.0);
			}
		} else {
			material.f0 = specTex.g * 0.96 + 0.04;
			material.n = F0ToIor(mix(vec3(0.04) * material.rawSmoothness, baseTex, material.rawMetalness)) * airMaterial.n;
			material.k = vec3(0.0);

			material.albedoTintsMetalReflections = false;
		}

		material.emissiveness = specTex.b == 1.0 ? 0.0 : specTex.b;

	#endif


	#ifdef ROUGHNESS_CLAMP
		material.doCSR = max(0.625 - material.roughness, 0.0) + material.rawMetalness > 0.0001;
	#else
		material.doCSR = max(1.0 - material.roughness, 0.0) + material.rawMetalness > 0.0001;
	#endif

	material.emissiveness = pow(material.emissiveness, EMISSIVENESS_GAMMA);

	baseTex *= 1.0 - saturate(wet * 2.5 - 1.5) * 0.3;

	return material;
}



GbufferData GetGbufferData()
{
	GbufferData data;

	vec4 gbuffer0 = texture(colortex0, texcoord.st);
	vec4 gbuffer3 = texture(colortex3, texcoord.st);
	vec4 gbuffer4 = texture(colortex4, texcoord.st);
	vec4 gbuffer5 = texture(colortex5, texcoord.st);
	vec4 gbuffer6 = texture(colortex6, texcoord.st);

	data.albedo 		= GammaToLinear(gbuffer0.rgb);
	data.albedoW 		= vec4(Unpack2x8(gbuffer5.r), Unpack2x8(gbuffer5.g));
	data.albedoW.rgb 	= GammaToLinear(data.albedoW.rgb);
	data.normalL 		= DecodeNormal(gbuffer3.rg);
	data.normalW 		= DecodeNormal(gbuffer4.rg);
	data.depthL 		= texture(depthtex1, texcoord.st).x;
	data.depthW 		= texture(gdepthtex, texcoord.st).x;
	data.lightmapL 		= gbuffer3.ba;
	data.lightmapW 		= gbuffer4.ba;
	//data.lightmapL 		= vec2(CurveBlockLightTorch(data.lightmapL.r), CurveBlockLightSky(data.lightmapL.g));
	//data.lightmapW 		= vec2(CurveBlockLightTorch(data.lightmapW.r), CurveBlockLightSky(data.lightmapW.g));
	data.lightmapL 		= vec2(data.lightmapL.r, CurveBlockLightSky(data.lightmapL.g));
	data.lightmapW 		= vec2(data.lightmapW.r, CurveBlockLightSky(data.lightmapW.g));
	data.materialIDL 	= gbuffer6.b;
	data.materialIDW 	= gbuffer5.b;
	data.waterMask 		= gbuffer5.a;
	data.rainAlpha 		= 1.0 - gbuffer0.a;
	//data.rainAlpha 		= data.rainAlpha > 0.999 ? 0.0 : data.rainAlpha;
	data.parallaxShadow = gbuffer6.a;


	vec4 specTex		= vec4(Unpack2x8(gbuffer6.r), Unpack2x8(gbuffer6.g));
	data.material       = MaterialFromTex(data.albedo, specTex);

	return data;
}


struct MaterialMask
{
	float sky;
	float land;
	float grass;
	float leaves;
	float hand;
	float entityPlayer;
	float water;
	float stainedGlass;
	float ice;

	float entitys;
	float entitysLitHigh;
	float entitysLitMedium;
	float entitysLitLow;
	float lightning;

	float torch;
	float lava;
	float glowstone;
	float fire;
	float redstoneTorch;
	float redstone;
	float soulFire;
	float amethyst;
	float endPortal;

	float eyes;
	float particle;
	float particlelit;

	float selection;
	float debug;
};

MaterialMask CalculateMasks(float materialID)
{
	MaterialMask mask;

	materialID = floor(materialID * 255.0);

	mask.sky				= float(materialID == 0.0);
	mask.land				= float(materialID == 1.0);
	mask.grass				= float(materialID == 2.0);
	mask.leaves				= float(materialID == 3.0);
	mask.hand				= float(materialID == 4.0);
	mask.entityPlayer		= float(materialID == 5.0);
	mask.water				= float(materialID == 6.0);
	mask.stainedGlass		= float(materialID == 7.0);
	mask.ice				= float(materialID == 8.0);

	mask.entitys			= float(materialID == 10.0);
	mask.entitysLitHigh		= float(materialID == 11.0);
	mask.entitysLitMedium	= float(materialID == 12.0);
	mask.entitysLitLow		= float(materialID == 13.0);
	mask.lightning			= float(materialID == 14.0);

	mask.torch				= float(materialID == 25.0);
	mask.lava 				= float(materialID == 26.0);
	mask.glowstone 			= float(materialID == 27.0);
	mask.fire 				= float(materialID == 28.0);
	mask.redstoneTorch 		= float(materialID == 29.0);
	mask.redstone	 		= float(materialID == 30.0);
	mask.soulFire	 		= float(materialID == 31.0);
	mask.amethyst	 		= float(materialID == 32.0);
	mask.endPortal	 		= float(materialID == 33.0);

	mask.eyes				= float(materialID == 38.0);
	mask.particle			= float(materialID == 39.0);
	mask.particlelit		= float(materialID == 40.0);

	mask.selection			= float(materialID == 200.0);
	mask.debug				= float(materialID == 201.0);

	return mask;
}

void FixParticleMask(inout MaterialMask materialMaskSoild, inout MaterialMask materialMask, inout float depthL, in float depthW){
	#if MC_VERSION >= 11500
	if(materialMaskSoild.particle > 0.5 || materialMaskSoild.particlelit > 0.5){
		materialMask.particle = 1.0;
		materialMask.water = 0.0;
		materialMask.stainedGlass = 0.0;
		materialMask.ice = 0.0;
		materialMask.sky = 0.0;
		depthL = depthW;
	}
	#endif
}

void FixParticleMask(inout MaterialMask materialMaskSoild, inout MaterialMask materialMask){
	#if MC_VERSION >= 11500
	if(materialMaskSoild.particle > 0.5 || materialMaskSoild.particlelit > 0.5){
		materialMask.particle = 1.0;
		materialMask.water = 0.0;
		materialMask.stainedGlass = 0.0;
		materialMask.ice = 0.0;
		materialMask.sky = 0.0;
	}
	#endif
}

void ApplyMaterial(inout Material material, in MaterialMask materialMask, inout bool isSmooth){
	if (materialMask.water > 0.5){
		material = material_water;
		isSmooth = true;
	}
	if (materialMask.stainedGlass > 0.5){
		material = material_glass;
		isSmooth = true;
	}
	if (materialMask.ice > 0.5){
		material = material_ice;
		isSmooth = true;
	}
}
