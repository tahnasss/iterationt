


//Shadow-------------------------
	#define SHADOW_MAP_BIAS			0.9	// [0.0 0.1 0.7 0.75 0.8 0.85 0.9 0.92 0.94 0.96]

	#define VARIABLE_PENUMBRA_SHADOWS
	#define COLORED_SHADOWS

	#define SHADOW_BASIC_BLUR 		0.5 // [0.0 0.25 0.5 0.75 1.0]
	#define VPS_QUALITY 			17  // [11 17 25 37 55 83 125]
	#define VPS_SPREAD 				0.1 // [0.02 0.03 0.05 0.07 0.1 0.15 0.2 0.3 0.5 0.7 1.0 1.5 2.0 3.0 5.0 7.0 10.0]

	#define SCREEN_SPACE_SHADOWS

	#define CAUSTICS

	#define SUNLIGHT_LEAK_FIX

//GI------------------------------
	#define GI_RSM

	#define GI_QUALITY				16.0  // [8.0 12.0 16.0 24.0 32.0 48.0 64.0 96.0 128.0]
	#define GI_RADIUS				100.0 // [10.0 15.0 20.0 30.0 50.0 70.0 100.0 150.0 200.0 300.0 500.0]
	#define GI_BRIGHTNESS			1.0 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.6 1.8 2.0 2.5 3.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 100.0]
	#define GI_RENDER_RESOLUTION	0.5	// [0.25 0.5]

	#define GI_SKYLIGHT_FALLOFF

//Light Misc-----------------------
	#define NOLIGHT_BRIGHTNESS				0.000005 // [0.000005 0.000007 0.00001 0.000015 0.00002 0.00003 0.00005 0.00007 0.0001 0.00015 0.0002 0.0003 0.0005 0.0007 0.001]
	#define NETHER_BRIGHTNESS 				1.0 // [0.1 0.15 0.2 0.3 0.5 0.7 1.0 1.5 2.3.5 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 100.0]
	#define COLD_MOONLIGHT

	#define TORCHLIGHT_BRIGHTNESS			0.02 // [0.0 0.001 0.0015 0.002 0.003 0.005 0.007 0.01 0.015 0.02 0.3 0.5 0.07 0.1 0.15 0.2 0.3 0.5 0.7 1.0 1.5 2.3.5 5.0 7.0 10.0]

	#define LIGHTMAP_CURVE 					2.2

	#define TORCHLIGHT_COLOR_TEMPERATURE 	3000 // [2000 2500 3000 3500 4000 4500 5000 5500 6000 6500 7000 7500 8000 8500 9000 9500 10000 12000 15000]


	#define HELDLIGHT_BRIGHTNESS 			1.0 // [0.0 0.1 0.15 0.2 0.3 0.5 0.7 1.0 1.5 2.3.5 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 100.0]
	#define HELDLIGHT_FALLOFF 				2.0 // [1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0]
	#define NORMAL_HELDLIGHT
	#define SPECULAR_HELDLIGHT
  //#define FLASHLIGHT_HELDLIGHT
  	#define FLASHLIGHT_HELDLIGHT_FALLOFF 	1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0]


	#define SUNLIGHT_INTENSITY				1.0	// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
	#define SKYLIGHT_INTENSITY 				1.0	// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

//Sky&Fog--------------------------
  //#define ATMO_HORIZON
	#define ATMO_REFLECTION_HORIZON

  //#define INDOOR_FOG

	#define VOLUMETRIC_CLOUDS
	#define CLOUD_SHADOW

  //#define CLOUD_LOCAL_LIGHTING

	#define LANDSCATTERING
	#define LANDSCATTERING_DISTANCE		0.005 // [0.001 0.002 0.003 0.005 0.007 0.01 0.15 0.2 0.3 0.5 0.7 1.0]
	#define LANDSCATTERING_STRENGTH     1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.5 1.7 2.0 2.5 3.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0 100.0]
  //#define LANDSCATTERING_SHADOW
    #define LANDSCATTERING_SHADOW_QUALITY 8 // [4 6 8 10 12 14 16 18 20 22 24 28 32 48 64 128]

	#define UNDERWATER_FOG
	#define WATERFOG_DENSITY 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
	#define UNDERWATER_VFOG_DENSITY 1.0 // [0.0 0.01 0.015 0.02 0.03 0.05 0.07 0.1 0.15 0.2 0.3 0.5 0.7 1.0 1.5 2.3.5 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 100.0]

	#define NETHER_BLOOM_BOOST 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

	#define NETHERFOG_DENSITY 1.0 // [0.0 0.1 0.15 0.2 0.3 0.5 0.7 1.0 1.5 2.3.5 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 100.0]

	#define SKY_TEXTURE_BRIGHTNESS	1.0

	#define STARS

	#define MOON_TEXTURE

	#define NIGHT_BRIGHTNESS 		0.00015 // [0.0 0.0001 0.00015 0.0002 0.0003 0.0005 0.0007 0.001 0.0015 0.002 0.003 0.005 0.007 0.01 1.0]

//Texture--------------------------
	#define TEXTURE_RESOLUTION		 0	// [0 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192]

	#define ANISOTROPIC_FILTERING_QUALITY 0 // [0 2 4 8 16 32]

	#define MOD_BLOCK_SUPPORT

  //#define PARALLAX
    #define PARALLAX_QUALITY 		 60 // [10 20 30 40 60 80 100 150 200 300 500]
	#define PARALLAX_MAX_REFINEMENTS 8 	// [0 2 4 6 8 12 16]

	#define PARALLAX_SHADOW
	#define PARALLAX_SHADOW_QUALITY  60 // [10 15 20 30 40 60 80 100 150 200 300 500]

  //#define SMOOTH_PARALLAX
  //#define PARALLAX_BASED_NORMAL
 	#define PARALLAX_DEPTH			1.0	// [0.1 0.15 0.2 0.3 0.5 0.75 1.0 1.25 1.5 1.75 2.0 3.0 5.0 7.5 10.0]

	#define FORCE_WET_EFFECT
	#define RAIN_SPLASH_EFFECT
  //#define RAIN_SPLASH_BILATERAL

//PBR------------------------------
	#define TEXTURE_PBR_FORMAT 		0 	//[0 1]

	#define ROUGHNESS_CLAMP

  //#define TERRAIN_NORMAL_CLAMP
	#define HAND_NORMAL_CLAMP
	#define ENTITY_NORMAL_CLAMP

	#define SKY_IMAGE_RESOLUTION 60.0 // [30.0 40.0 60.0 100.0 150.0 200.0 300.0 500.0]

	//#define LANDSCATTERING_REFLECTION
    //#define VFOG_REFLECTION

	//#define LANDSCATTERING_REFRACTION
	//#define VFOG_REFRACTION

  //#define TEXTURE_EMISSIVENESS
	#define EMISSIVENESS_BRIGHTNESS 0.5 // [0.0 0.1 0.2 0.3 0.5 0.7 1.0 1.5 2.0 3.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 100.0]
	#define EMISSIVENESS_GAMMA 		2.2 // [1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0]

//Texture Misc---------------------
	#define WATER_REFRACT_IOR		1.2
	#define WATER_PARALLAX
	#define WAVE_SCALE 				0.06 // [0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.15 0.2 0.3 0.5 0.7 1.0]
	#define WAVE_HEIGHT 			1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 3.0 5.0 7.0 10.0]

	#define RAIN_SHADOW 			1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

	#define SURFACE_WETNESS 		0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

 	#define CORRECT_PARTICLE_NORMAL

	#define RAIN_VISIBILITY			1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 5.0]

	#define SELECTION_BOX_COLOR		1.0	// [0.0 1.0]

	#define ENTITY_STATUS_COLOR
	#define EYES_LIGHTING

  //#define GENERAL_GRASS_FIX
	#define WAVING_PLANTS
  //#define PLANT_TOUCH_EFFECT
	#define ANIMATION_SPEED 1.0


//DOF------------------------------
  //#define DOF
	#define DOF_SAMPLES 32 				// [16 32 64 128 256 512 1024]
	#define CAMERA_FOCUS_MODE 0 		// [0 1]
	#define CAMERA_FOCAL_POINT 10.0 	// [0.2 0.3 0.4 0.6 0.8 1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0 5.0 6.0 8.0 10.0 12.5 15.0 17.5 20.0 15.0 30.0 40.0 50.0 60.0 80.0 100.0 150.0 200.0 250.0 300.0 400.0 500.0 600.0 800.0 1000.0]
	#define CAMERA_AUTO_FOCAL_OFFSET 0 	//[-16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4.5 -4 -3.5 -3 -2.5 -2 -1.5 -1 -0.5 0 0.5 1 1.5 2 2.5 3 3.5 4 4.5 5 6 7 8 9 10 11 12 13 14 15 16]

	#define CAMERA_APERTURE 2.8 // [0.95 1.2 1.4 1.8 2.8 4 5.6 8.0 11.0 16.0 22.0]


//Bloom----------------------------
	#define BLOOM_EFFECTS

	#define BLOOM_AMOUNT			1.5	// [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 3.0 4.0 5.0 7.0 10.0]

	#define LENS_FLARE

  	#define GLARE_BRIGHTNESS 		1.0 // [0.1 0.2 0.3 0.5 0.7 1.0 1.5 2.0 3.0 5.0 7.0 10.0 15.0 20.0]
  	#define FLARE_BRIGHTNESS 		1.0 // [0.1 0.2 0.3 0.5 0.7 1.0 1.5 2.0 3.0 5.0 7.0 10.0 15.0 20.0]
	#define FLARE_GHOSTING
  //#define FLARE_SHADOWBASED

//TAA------------------------------
	#define TAA

	#define TAA_AGGRESSION 			0.97
	#define TAA_SHARPEN
	#define TAA_SHARPNESS 			0.5     //[0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

//Motion Blur----------------------
	#define MOTION_BLUR
	#define MOTION_BLUR_DITHER
	#define MOTION_BLUR_QUALITY 3 // [2 3 5 10 20 30 50 100]
	#define MOTION_BLUR_SUTTER_ANGLE 90.0 // [45.0 90.0 135.0 180.0 270.0 360.0]

//Exposure-------------------------
  //#define MANUAL_EXPOSURE
	#define EV_VALUE 	14 		// [0 1.0/3.0 2.0/3.0 1 1+1.0/3.0 1+2.0/3.0 2 2+1.0/3.0 2+2.0/3.0 3 3+1.0/3.0 3+2.0/3.0 4 4+1.0/3.0 4+2.0/3.0 5 5+1.0/3.0 5+2.0/3.0 6 6+1.0/3.0 6+2.0/3.0 7 7+1.0/3.0 7+2.0/3.0 8 8+1.0/3.0 8+2.0/3.0 9 9+1.0/3.0 9+2.0/3.0 10 10+1.0/3.0 10+2.0/3.0 11 11+1.0/3.0 11+2.0/3.0 12 12+1.0/3.0 12+2.0/3.0 13 13+1.0/3.0 13+2.0/3.0 14 14+1.0/3.0 14+2.0/3.0 15 15+1.0/3.0 15+2.0/3.0 16 16+1.0/3.0 16+2.0/3.0 17 17+1.0/3.0 17+2.0/3.0 18 18+1.0/3.0 18+2.0/3.0 19 19+1.0/3.0 19+2.0/3.0 20]
	#define AE_OFFSET	0 		// [-5 -4-2.0/3.0 -4-1.0/3.0 -4 -3-2.0/3.0 -3-1.0/3.0 -3 -2-2.0/3.0 -2-1.0/3.0 -2 -1-2.0/3.0 -1-1.0/3.0 -1 -2.0/3.0 -1.0/3.0 0 1/3 2/3 1 1+1.0/3.0 1+2.0/3.0 2 2+1.0/3.0 2+2.0/3.0 3 3+1.0/3.0 3+2.0/3.0 4 4+1.0/3.0 4+2.0/3.0 5]
	#define AE_MODE		0 		// [0 1 2 3]
	#define AE_CURVE	0.7 	// [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
	#define AE_CLAMP
	#define LUMINANCE_WEIGHT
	#define LUMINANCE_WEIGHT_MODE 		0 	// [0 1 2]
	#define LUMINANCE_WEIGHT_STRENGTH 	0.7 // [0.5 0.7 1.0 1.5 2.0]

	#define SMOOTH_EXPOSURE
	#define EXPOSURE_TIME 	1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0]

//Post-----------------------------
	#define TONEMAP_OPERATOR 	Default // Each tonemap operator defines a different way to present the raw internal HDR color information to a color range that fits nicely with the limited range of monitors/displays. Each operator gives a different feel to the overall final image. [Default SEUSTonemap LottesTonemap UchimuraTonemap HableTonemap ACESTonemap ACESTonemap2 None]
	#define TONEMAP_CURVE 		1.0 // Controls the intensity of highlights. Lower values give a more filmic look, higher values give a more vibrant/natural look. Default: 2.0 [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 3.0 5.0]


  //#define ADVANCED_COLOR
	#define GAMMA 				1.0 // Gamma adjust. Lower values make shadows darker. Higher values make shadows brighter. Default: 1.0 [0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5]
	#define LUMA_GAMMA 			1.0 // Gamma adjust of luminance only. Preserves colors while adjusting contrast. Lower values make shadows darker. Higher values make shadows brighter. Default: 1.0 [0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5]
	#define SATURATION 			1.0 // Saturation adjust. Higher values give a more colorful image. Default: 1.0 [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
	#define WHITE_CLIP 			0.0 // Higher values will introduce clipping to white on the highlights of the image. [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
	#define WHITE_BALANCE 		6500 // [4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000 5100 5200 5300 5400 5500 5600 5700 5800 5900 6000 6100 6200 6300 6400 6500 6600 6700 6800 6900 7000 7100 7200 7300 7400 7500 7600 7700 7800 7900 8000 8100 8200 8300 8400 8500 8600 8700 8800 8900 9000 9100 9200 9300 9400 9500 9600 9700 9800 9900 10000 10100 10200 10300 10400 10500 10600 10700 10800 10900 11000 11100 11200 11300 11400 11500 11600 11700 11800 11900 12000]
	#define TINT_BALANCE 		0.0 // [-1.0 -0.95 -0.9 -0.85 -0.8 -0.75 -0.7 -0.65 -0.6 -0.55 -0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

	#define POST_SHARPENING 	1 //[0 1 2 3]

	#define SEREEN_RATIO 		0.0 // [0.0 1.333333 1.435052 1.5 1.6 1.777778 2.0 2.333333 2.39]

  //#define LOWLIGHT_COLORFADE
	#define LOWLIGHT_COLORFADE_THRESHOLD 0.0001 // [0.00001 0.000015 0.00002 0.00003 0.00005 0.00007 0.0001 0.00015 0.0002 0.0003 0.0005 0.0007 0.001]
	#define LOWLIGHT_COLORFADE_STRENGTH  0.7 	// [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
  //#define LUT



//Other----------------------------
  //#define CAVE_MODE
  //#define WHITE_DEBUG_WORLD
  #define TITLE
  //#define TEAPOT
  //#define DEBUG_COUNTER
