//Skybasic_FS


uniform int renderStage;


void main(){
    if (gl_PrimitiveID != 0 || renderStage != MC_RENDER_STAGE_SKY) discard;
    gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
}
/* DRAWBUFFERS:0 */
