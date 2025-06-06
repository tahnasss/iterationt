#version 450


layout(local_size_x = 2, local_size_y = 2) in;
const vec2 workGroupsRender = vec2(0.5f, 0.5f);


const float level = 0.0;


uniform sampler2D colortex1;
uniform vec2 screenSize;
uniform vec2 pixelSize;


layout(rgba16) uniform image2D colorimg3;


const vec3 sampleOffset[5] = vec3[5](
    vec3(0.0, 0.0, 0.5),
    vec3(-1.0, -1.0, 0.125),
    vec3(-1.0, 1.0, 0.125),
    vec3(1.0, -1.0, 0.125),
    vec3(1.0, 1.0, 0.125));


void main(){
    vec2 currTexelCoord = vec2(gl_GlobalInvocationID.xy) * 2.0 + 1.0;
    vec2 prevSize = screenSize - 0.5;

    vec3 blurDown = vec3(0.0);

    for (int i = 0; i < 5; i++){
        vec2 inputCoord = clamp(currTexelCoord + sampleOffset[i].xy, vec2(0.5), vec2(prevSize)) * pixelSize;

        blurDown += texture(colortex1, inputCoord).rgb * sampleOffset[i].z;
    }

    ivec2 outputTexelCoord = ivec2(gl_GlobalInvocationID.xy);
    imageStore(colorimg3, outputTexelCoord, vec4(blurDown, 1.0));
}
