#version 450


#define DIMENSION_NETHER


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const int 		RGBA8       = 0;
const int 		RG16        = 0;
const int 		RGB16       = 0;
const int 		RGBA16      = 0;

const int 		RGB16F      = 0;
const int 		RGBA16F     = 0;

const int 		colortex0Format         = RGBA8;
const int 		colortex1Format         = RGBA16;
const int 		colortex2Format         = RGBA16;
const int 		colortex3Format 		= RGBA16;
const int 		colortex4Format 		= RGBA16;
const int 		colortex5Format 		= RGBA16;
const int 		colortex6Format 		= RGBA16;
const int 		colortex7Format 		= RGBA16;
const int 		colortex8Format 		= RG16;

const bool		colortex2Clear          = false;
const bool		colortex7Clear          = false;


const float     wetnessHalflife 			= 200.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float     drynessHalflife 			= 50.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float 	eyeBrightnessHalflife 		= 10.0f;
const float 	centerDepthHalflife 		= 1.0;		//[0.5 0.7 1.0 1.5 2.0 3.0 5.0 7.0 10.0]

const float		sunPathRotation				= -30;		// [-90 -89 -88 -87 -86 -85 -84 -83 -82 -81 -80 -79 -78 -77 -76 -75 -74 -73 -72 -71 -70 -69 -68 -67 -66 -65 -64 -63 -62 -61 -60 -59 -58 -57 -56 -55 -54 -53 -52 -51 -50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 ]

const float 	ambientOcclusionLevel 		= 0.0f;
const int       superSamplingLevel 			= 0;


/* DRAWBUFFERS:17 */
layout(location = 0) out vec4 compositeOutput1;
layout(location = 1) out vec4 compositeOutput7;


in vec2 texcoord;

in vec3 colorTorchlight;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"


#include "/Lib/BasicFounctions/NetherColor.glsl"
#include "/Lib/BasicFounctions/Blocklight.glsl"
#define PROGRAM_GI_1
#include "/Lib/IndividualFounctions/GlobalIllumination_AO.glsl"


////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main(){

	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);

	FixParticleMask(materialMaskSoild, materialMask, gbuffer.depthL, gbuffer.depthW);


	vec3 viewPos 					= ViewPos_From_ScreenPos(texcoord, gbuffer.depthL);
	vec3 worldPos					= mat3(gbufferModelViewInverse) * viewPos;

	vec3 viewDir 					= normalize(viewPos);
	vec3 worldDir 					= normalize(worldPos);
	vec3 worldNormal 				= mat3(gbufferModelViewInverse) * gbuffer.normalL;


	vec3 finalComposite = vec3(0.0);

	if (materialMaskSoild.sky < 0.5){
		float ao = 1.0 - mix(GI_SpatialFilter(length(viewPos), gbuffer.normalL, viewDir), 0.0, materialMask.particle);

		finalComposite += NetherLighting();
 		finalComposite += BlockLighting(gbuffer.lightmapL.r, materialMaskSoild);

		finalComposite *= ao;

		finalComposite += HeldLighting(worldPos, viewDir, gbuffer.normalL, ao, materialMask.hand > 0.5);

		finalComposite *= gbuffer.albedo;

		finalComposite += TextureLighting(gbuffer.albedo, gbuffer.lightmapL.r, gbuffer.material.emissiveness, materialMaskSoild);

	}else{
		finalComposite = vec3(0.0);
	}

	finalComposite /= mainOutputFactor;
	finalComposite = LinearToCurve(finalComposite);

	compositeOutput1 = vec4(finalComposite.rgb, 1.0f);
}
