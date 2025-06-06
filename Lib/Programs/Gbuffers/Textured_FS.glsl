//Textured_FS


#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D texture;


in vec4 color;
in vec2 texcoord;
in vec2 blockLight;
in float materialIDs;


float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}


void main(){
//albedo
    vec4 albedo = texture2D(texture, texcoord);
    albedo *= color;

	#ifdef WHITE_DEBUG_WORLD
        albedo.rgb = vec3(1.0);
    #endif


//normal
	vec2 normalEnc = EncodeNormal(vec3(0.0, 0.0, 1.0));


	if(albedo.a < 0.1) discard;

	gl_FragData[0] = vec4(albedo.rgb, 1.0);
    gl_FragData[1] = vec4(normalEnc, blockLight);
    gl_FragData[2] = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, 1.0);
}
/* DRAWBUFFERS:036 */
