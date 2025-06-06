//Line_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform int renderStage;


in vec4 color;


void main(){
    vec4 albedo = color;

    float materialIDs = 1.0;
    if (renderStage == MC_RENDER_STAGE_OUTLINE) albedo.rgb = vec3(SELECTION_BOX_COLOR);

    materialIDs = 200.0;

    if(albedo.a < 0.1) discard;

	gl_FragData[0] = vec4(albedo.rgb, 1.0);
	gl_FragData[1] = vec4(EncodeNormal(vec3(0.0, 0.0, 1.0)), 0.0, 0.0);
	gl_FragData[2] = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, 1.0);
}

/* DRAWBUFFERS:036 */
