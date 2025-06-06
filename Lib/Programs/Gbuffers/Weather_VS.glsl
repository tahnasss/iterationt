//Weather_VS


uniform vec2 taaJitter;


out vec2 texcoord;


void main(){
    gl_Position = ftransform();

    //#ifdef TAA
    //    gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
    //#endif

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
