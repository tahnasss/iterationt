float GetMaterialMask(const in int ID, in float matID){
	matID = (matID > 254.0f) ? 0.0f : matID;
	return (matID == ID) ? 1.0f : 0.0f;
}

struct MaterialMask{
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

	float torch;
	float lava;
	float glowstone;
	float fire;
	float redstoneTorch;
	float redstone;
	float soulFire;
	float amethyst;

	float eyes;
	float particle;
	float particlelit;

	float selection;
	float debug;
};

MaterialMask CalculateMasks(float materialID){
	MaterialMask mask;

	materialID *= 255.0;

	materialID = floor(materialID);

	mask.sky				= GetMaterialMask(0, materialID);
	mask.land				= GetMaterialMask(1, materialID);
	mask.grass				= GetMaterialMask(2, materialID);
	mask.leaves				= GetMaterialMask(3, materialID);
	mask.hand				= GetMaterialMask(4, materialID);
	mask.entityPlayer		= GetMaterialMask(5, materialID);
	mask.water				= GetMaterialMask(6, materialID);
	mask.stainedGlass		= GetMaterialMask(7, materialID);
	mask.ice				= GetMaterialMask(8, materialID);

	mask.entitys			= GetMaterialMask(10, materialID);
	mask.entitysLitHigh		= GetMaterialMask(11, materialID);
	mask.entitysLitMedium	= GetMaterialMask(12, materialID);
	mask.entitysLitLow		= GetMaterialMask(13, materialID);



	mask.torch				= GetMaterialMask(25, materialID);
	mask.lava 				= GetMaterialMask(26, materialID);
	mask.glowstone 			= GetMaterialMask(27, materialID);
	mask.fire 				= GetMaterialMask(28, materialID);
	mask.redstoneTorch 		= GetMaterialMask(29, materialID);
	mask.redstone	 		= GetMaterialMask(30, materialID);
	mask.soulFire	 		= GetMaterialMask(31, materialID);
	mask.amethyst	 		= GetMaterialMask(32, materialID);

	mask.eyes				= GetMaterialMask(38, materialID);
	mask.particle			= GetMaterialMask(39, materialID);
	mask.particlelit		= GetMaterialMask(40, materialID);

	mask.selection			= GetMaterialMask(200, materialID);
	mask.debug				= GetMaterialMask(201, materialID);

	return mask;
}
