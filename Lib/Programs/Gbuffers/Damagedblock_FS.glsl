//Damagedblock_FS


#include "/Lib/Settings.glsl"


uniform sampler2D texture;


in vec4 color;
in vec2 texcoord;


void main(){
    vec4 albedo = texture2D(texture, texcoord);
    albedo *= color;

    #ifdef WHITE_DEBUG_WORLD
        albedo.rgb = vec3(1.0);
    #endif

    if(albedo.a < 0.1) discard;

	gl_FragData[0] = vec4(albedo.rgb, 1.0);
}

/* DRAWBUFFERS:0 */
