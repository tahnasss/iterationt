//Basic_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform int renderStage;

uniform sampler2D texture;


in vec4 color;
in vec2 texcoord;
in vec3 normal;
in vec2 blockLight;


float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}

void main(){
    vec4 albedo = color;

	vec2 mcLightmap = blockLight;

	float materialIDs = 1.0;
    if (renderStage == MC_RENDER_STAGE_OUTLINE || renderStage == MC_RENDER_STAGE_DEBUG)
    {
        if (renderStage == MC_RENDER_STAGE_OUTLINE) albedo.rgb = vec3(SELECTION_BOX_COLOR);
        materialIDs = 200.0;
		mcLightmap = vec2(0.0);
    }

	if(albedo.a < 0.1) discard;

	gl_FragData[0] = vec4(albedo.rgb, 1.0);
	gl_FragData[1] = vec4(EncodeNormal(normal), mcLightmap);
	gl_FragData[2] = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, 1.0);
}

/* DRAWBUFFERS:036 */
