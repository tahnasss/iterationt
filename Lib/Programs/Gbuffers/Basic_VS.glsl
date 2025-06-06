//Basic_VS


#include "/Lib/Settings.glsl"


uniform vec2 taaJitter;


out vec4 color;
out vec2 texcoord;
out vec3 normal;
out vec2 blockLight;


void main(){
    gl_Position = ftransform();

    #ifdef TAA
        gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
    #endif

    color = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    normal = gl_NormalMatrix * gl_Normal;

    vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    blockLight.x = clamp(lmcoord.x * 1.066875 - 0.0334375, 0.0, 1.0);
    blockLight.y = clamp(lmcoord.y * 1.066875 - 0.0334375, 0.0, 1.0);
}
