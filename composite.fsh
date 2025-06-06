#version 450


#define DIMENSION_MAIN
#define ENABLE_RAND


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#ifdef MC_GL_VENDOR_NVIDIA
	uniform sampler2D shadowtex1;
#else
	uniform sampler2D shadowtex0;
#endif
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;


/* DRAWBUFFERS:28 */
layout(location = 0) out vec4 compositeOutput2;
layout(location = 1) out vec4 compositeOutput8;


in vec2 texcoord;


#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"


#include "/Lib/IndividualFounctions/WaterWaves.glsl"



#define PROGRAM_GI_0
#include "/Lib/IndividualFounctions/GlobalIllumination.glsl"
#include "/Lib/IndividualFounctions/GlobalIllumination_AO.glsl"


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	compositeOutput2 = GI_TemporalFilter();

    vec3 screenCaustics = GetWavesNormal(vec3(texcoord.s * 50.0, 1.0, texcoord.t * 50.0)).xyz;
    vec2 causticsNormal = EncodeNormal(screenCaustics);

    //float data7 = texture(colortex7, texcoord).a;
    compositeOutput8 = vec4(causticsNormal.xy, 0.0, 0.0);
}
