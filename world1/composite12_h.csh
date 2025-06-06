#version 450


layout(local_size_x = 2, local_size_y = 2) in;
const vec2 workGroupsRender = vec2(1.953125e-3f, 1.953125e-3f);


uniform sampler2D colortex3;
uniform vec2 screenSize;
uniform vec2 pixelSize;


layout(rgba16) uniform image2D colorimg3;


#include "/Lib/IndividualFounctions/DualBlur.glsl"


void main(){
    ivec2 outputTexelCoord;
    vec4 outcolor = vec4(DualBlurDownSample(8.0, colortex3, outputTexelCoord), 1.0);

    imageStore(colorimg3, outputTexelCoord, outcolor);
}
