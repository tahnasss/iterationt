

vec3 BlockLighting(float lightmap, MaterialMask mask){
	float lightSourceMask = step(mask.glowstone
							   + mask.torch
							   + mask.entitysLitHigh
							   + mask.entitysLitMedium
							   + mask.entitysLitLow
							   + mask.particlelit
							   + mask.soulFire
							   + mask.amethyst
							   + step(1.0, lightmap), 0.0);

	#ifdef TEXTURE_EMISSIVENESS
	 	lightSourceMask = 0.8 * lightSourceMask + 0.2;
	#else
		lightSourceMask = 0.9 * lightSourceMask + 0.1;
	#endif

	#ifdef DIMENSION_MAIN
		return CurveBlockLightTorch(lightmap) * colorTorchlight * lightSourceMask * TORCHLIGHT_BRIGHTNESS;
	#else
		return CurveBlockLightTorch(lightmap) * colorTorchlight * lightSourceMask * TORCHLIGHT_BRIGHTNESS * 10.0;
	#endif
}

vec3 TextureLighting(vec3 albedo, float lightmap, float emissiveness, MaterialMask mask){

	#ifdef TEXTURE_EMISSIVENESS
		#ifdef DIMENSION_MAIN
			return albedo * emissiveness * EMISSIVENESS_BRIGHTNESS * TORCHLIGHT_BRIGHTNESS;
		#else
			return albedo * emissiveness * EMISSIVENESS_BRIGHTNESS * TORCHLIGHT_BRIGHTNESS * 10.0;
		#endif
	#else
		float albedoLuminance = length(albedo);
		vec3 albedo2 = albedo * albedoLuminance;

		float blockLightingMask = step(1.0, lightmap * mask.land - mask.entitys) * 0.2;
			  blockLightingMask += 	mask.glowstone 		* 0.8;
			  blockLightingMask += 	mask.torch 			* 1.5;
			  blockLightingMask += 	mask.fire 			* 0.25;
			  blockLightingMask += 	mask.lava 			* 0.5;
			  blockLightingMask += 	mask.redstoneTorch 	* 0.1;

		vec3 blockLighting = blockLightingMask * colorTorchlight * albedo2;

		blockLightingMask = 	mask.soulFire 			* 0.05;
		blockLightingMask += 	mask.amethyst 			* 0.015;
		blockLightingMask += 	mask.endPortal 			* 200.0;
		blockLightingMask += 	mask.entitysLitHigh 	* 1.0;
		blockLightingMask += 	mask.entitysLitMedium 	* 0.5;
		blockLightingMask += 	mask.entitysLitLow 		* 0.25;
		blockLightingMask += 	mask.particlelit 		* 0.5;
		blockLightingMask += 	mask.eyes 				* 0.05;
		blockLightingMask += 	mask.redstone 			* 0.1 * emissiveness;

		blockLighting += blockLightingMask * albedo2;

		//blockLighting += mask.endPortal * albedo * 30.0;


		#ifdef DIMENSION_MAIN
			return blockLighting * TORCHLIGHT_BRIGHTNESS;
		#else
			return blockLighting * TORCHLIGHT_BRIGHTNESS * 10.0;
		#endif
	#endif
}

vec3 HeldLighting(vec3 worldPos, vec3 viewDir, vec3 normal, float ao, bool isHand){
	if(heldBlockLightValue + heldBlockLightValue2 > 0.0){
		#ifdef FLASHLIGHT_HELDLIGHT
			float heldLightFalloff = 1.0 / pow(max(length(worldPos.xyz), 0.2), FLASHLIGHT_HELDLIGHT_FALLOFF);

			#ifdef NORMAL_HELDLIGHT
				heldLightFalloff *= (saturate(dot(-viewDir, normal)) * 0.8 + 0.2) * (ao * 0.5 + 0.5);
			#else
				heldLightFalloff *= ao;
			#endif

			vec3 torchPos = worldPos.xyz + gbufferModelViewInverse[1].xyz * 0.1;
			vec3 torchPosL = torchPos + gbufferModelViewInverse[0].xyz * 0.23;
			vec3 torchPosR = torchPos - gbufferModelViewInverse[0].xyz * 0.23;
			vec3 torchDirL = normalize((gbufferModelView * vec4(torchPosL, 0.0)).xyz);
			vec3 torchDirR = normalize((gbufferModelView * vec4(torchPosR, 0.0)).xyz);
			float spotRadiusL = dot(torchDirL, vec3(0.0, 0.0, -1.0));
			float spotRadiusR = dot(torchDirR, vec3(0.0, 0.0, -1.0));
			spotRadiusL = saturate(spotRadiusL * 2.0 - 1.8);
			spotRadiusR = saturate(spotRadiusR * 2.0 - 1.8);

			heldLightFalloff = isHand ? 0.1 * max(heldBlockLightValue, heldBlockLightValue2) : heldLightFalloff * (heldBlockLightValue2 * spotRadiusL + heldBlockLightValue * spotRadiusR);
		#else
			float heldLightFalloff = 1.0 / pow(max(length(worldPos.xyz), 1.0), HELDLIGHT_FALLOFF);

			#ifdef NORMAL_HELDLIGHT
				heldLightFalloff *= (saturate(dot(-viewDir, normal)) * 0.8 + 0.2) * (ao * 0.5 + 0.5);
			#else
				heldLightFalloff *= ao;
			#endif

			heldLightFalloff = isHand ? 0.02 * max(heldBlockLightValue, heldBlockLightValue2) : heldLightFalloff * (heldBlockLightValue + heldBlockLightValue2) * 0.04;
		#endif

		#ifdef DIMENSION_MAIN
			return heldLightFalloff * colorTorchlight * TORCHLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS;
		#else
			return heldLightFalloff * colorTorchlight * TORCHLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS * 10.0;
		#endif
	}
	return vec3(0.0);
}
