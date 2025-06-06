//Armor_Glint_FS


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

    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
