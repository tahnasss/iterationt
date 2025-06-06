#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"

vec2 TexelOffset(float l){
    vec2 offset = vec2(0.0);

    float r = step(2.0, l);
    offset.x += r * (ceil(screenSize.x * 0.5) + 5.0);
    offset.y -= r * (floor(0.75 * screenSize.y) + 10.0);

    offset.y += ceil((1.0 - exp2(-l)) * screenSize.y) + l * 5.0;

    return offset;
}

vec3 DualBlurDownSample(const float level, sampler2D tex, out ivec2 outputTexelCoord){
    const vec3 sampleOffset[5] = vec3[5](
        vec3(0.0, 0.0, 0.5),
        vec3(-1.0, -1.0, 0.125),
        vec3(-1.0, 1.0, 0.125),
        vec3(1.0, -1.0, 0.125),
        vec3(1.0, 1.0, 0.125));

    vec2 currTexelCoord = vec2(gl_GlobalInvocationID.xy) * 2.0 + 1.0;
    vec2 prevSize = ceil(screenSize * exp2(-level - 1.0)) * 2.0 - 0.5;

    vec2 prevTexelOffset = TexelOffset(level - 1.0);

    vec3 blurDown = vec3(0.0);

    for (int i = 0; i < 5; i++){
        vec2 sampleTexelCoord = clamp(currTexelCoord + sampleOffset[i].xy, vec2(0.5), vec2(prevSize));
        sampleTexelCoord += prevTexelOffset;

        vec2 sampleCoord = sampleTexelCoord * pixelSize;
        blurDown += CurveToLinear(texture(tex, sampleCoord).rgb) * sampleOffset[i].z;
    }

    outputTexelCoord = ivec2(TexelOffset(level)) + ivec2(gl_GlobalInvocationID.xy);

    return LinearToCurve(blurDown);
}

//*
vec3 DualBlurUpSample(const float level, sampler2D tex, out ivec2 outputTexelCoord){
    const vec3 sampleOffset[8] = vec3[8](
        vec3(-0.5, -0.5, 1.0 / 6.0),
        vec3(-0.5, 0.5, 1.0 / 6.0),
        vec3(0.5, -0.5, 1.0 / 6.0),
        vec3(0.5, 0.5, 1.0 / 6.0),
        vec3(-1.0, 0.0, 1.0 / 12.0),
        vec3(0.0, -1.0, 1.0 / 12.0),
        vec3(0.0, 1.0, 1.0 / 12.0),
        vec3(1.0, 0.0, 1.0 / 12.0));

    vec2 currTexelCoord = vec2(gl_GlobalInvocationID.xy) * 0.5 + 0.25;
    vec2 prevSize = ceil(screenSize * exp2(-level - 3.0)) * 2.0 - 0.5;

    vec2 prevTexelOffset = TexelOffset(level + 1.0);

    vec3 blurUp = vec3(0.0);

    for (int i = 0; i < 8; i++){
        vec2 sampleTexelCoord = clamp(currTexelCoord + sampleOffset[i].xy, vec2(0.5), vec2(prevSize));
        sampleTexelCoord += prevTexelOffset;

        vec2 sampleCoord = sampleTexelCoord * pixelSize;
        blurUp += CurveToLinear(texture(tex, sampleCoord).rgb) * sampleOffset[i].z;
    }

    outputTexelCoord = ivec2(TexelOffset(level)) + ivec2(gl_GlobalInvocationID.xy);

    return LinearToCurve(blurUp);
}
//*/
