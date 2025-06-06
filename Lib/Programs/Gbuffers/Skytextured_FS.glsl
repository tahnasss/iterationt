//Skytextured_FS


#include "/Lib/Settings.glsl"


uniform sampler2D texture;
uniform int isEyeInWater;
uniform int renderStage;


in vec4 color;
in vec4 texcoord;


void main() {
	vec4 albedo = vec4(0.0);

	#ifdef MOON_TEXTURE
		if (renderStage == MC_RENDER_STAGE_MOON)
	    {
			albedo = texture2D(texture, texcoord.st);
			albedo *= color;
			if(isEyeInWater == 1) albedo.a = 0.0;
		}
	#endif

	if(albedo.a < 0.1) discard;

	gl_FragData[0] = vec4(albedo.rgb, 1.0);
}
/* DRAWBUFFERS:0 */
