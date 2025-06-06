//Damagedblock_VS


#include "/Lib/Settings.glsl"


uniform vec2 taaJitter;


out vec4 color;
out vec2 texcoord;


void main(){
    gl_Position = ftransform();

    #ifdef TAA
        gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
    #endif

    color = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
