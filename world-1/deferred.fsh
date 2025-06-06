#version 450 compatibility

//gbuffers_skybasic.fsh

layout(location = 0) out vec4 deferredOutput4;
layout(location = 1) out vec4 deferredOutput5;

uniform sampler2D colortex3;
uniform sampler2D colortex6;

in vec2 texcoord;

void main() {
    vec4 data3 = texture2D(colortex3, texcoord);
    vec4 data6 = texture2D(colortex6, texcoord);

    deferredOutput4 = data3;
    deferredOutput5 = vec4(0.0, 0.0, data6.z, 0.0);
}

/* DRAWBUFFERS:45 */
