#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


layout(location = 0) out vec4 compositeOutput7;


in vec2 texcoord;


#include "/Lib/Uniform/GbufferTransforms.glsl"


#define max3(x, y, z)    max(x, max(y, z))
#define min9(a, b, c, d, e, f, g, h, i) min(a, min(b, min(c, min(d, min(e, min(f, min(g, min(h, i))))))))
#define max9(a, b, c, d, e, f, g, h, i) max(a, max(b, max(c, max(d, max(e, max(f, max(g, max(h, i))))))))


vec3 SampleColor(vec2 coord){
    return CurveToLinear(texture(colortex1, coord).rgb);
}

float SampleDepth(vec2 coord){
    return texture(gdepthtex, coord).x;
}

vec4 SamplePrevious(vec2 coord){
    vec4 previous = texture(colortex7, coord);
    previous.rgb = CurveToLinear(previous.rgb);
    return previous;
}

float SampleDepthReference(vec2 coord, float materialID){
    if (materialID == 6.0 || materialID == 8.0){
        return texture(gdepthtex, coord).x;
    }else{
        return texture(depthtex1, coord).x;
    }
}

vec2 CalculateCameraVelocity(vec2 coord, float depth){
    vec3 projection = vec3(coord, depth) * 2.0 - 1.0;
    projection = (vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * projection.xy, 0.0) + gbufferProjectionInverse[3].xyz) / (gbufferProjectionInverse[2].w * projection.z + gbufferProjectionInverse[3].w);
    projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;

    if (depth < 1.0) projection += cameraPosition - previousCameraPosition;

    projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
    projection = (vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;
    return (coord - projection.xy);
}

vec3 clipAABB(vec3 boxMin, vec3 boxMax, vec3 q){
    vec3 p_clip = 0.5 * (boxMax + boxMin);
    vec3 e_clip = 0.5 * (boxMax - boxMin);

    vec3 v_clip = q - p_clip;
    vec3 v_unit = v_clip.xyz / e_clip;
    vec3 a_unit = abs(v_unit);
    float ma_unit = max3(a_unit.x, a_unit.y, a_unit.z);

    if (ma_unit > 1.0){
        return v_clip / ma_unit + p_clip;
    }else{
        return q;
    }
}


vec4 TemporalReprojection(vec2 coord, vec2 velocity){
    vec2 ccoord = coord + taaJitter * 0.5;

    vec3 currentCol = SampleColor(ccoord);
    vec3 col1 = SampleColor(ccoord + vec2( pixelSize.x, 0.0         ));
    vec3 col2 = SampleColor(ccoord + vec2(-pixelSize.x, 0.0         ));
    vec3 col3 = SampleColor(ccoord + vec2( pixelSize.x,  pixelSize.y));
    vec3 col4 = SampleColor(ccoord + vec2(-pixelSize.x,  pixelSize.y));
    vec3 col5 = SampleColor(ccoord + vec2( pixelSize.x, -pixelSize.y));
    vec3 col6 = SampleColor(ccoord + vec2(-pixelSize.x, -pixelSize.y));
    vec3 col7 = SampleColor(ccoord + vec2( 0.0        ,  pixelSize.y));
    vec3 col8 = SampleColor(ccoord + vec2( 0.0        , -pixelSize.y));

    vec3 colMin = min9(currentCol, col1, col2, col3, col4, col5, col6, col7, col8);
    vec3 colMax = max9(currentCol, col1, col2, col3, col4, col5, col6, col7, col8);
    vec3 colAVG = (currentCol + col1 + col2 + col3 + col4 + col5 + col6 + col7 + col8) * (1.0 / 9.0);

    float currentDepth = SampleDepth(ccoord);
    float depth1 = SampleDepth(ccoord + vec2( pixelSize.x, 0.0         ));
    float depth2 = SampleDepth(ccoord + vec2(-pixelSize.x, 0.0         ));
    float depth3 = SampleDepth(ccoord + vec2( pixelSize.x,  pixelSize.y));
    float depth4 = SampleDepth(ccoord + vec2(-pixelSize.x,  pixelSize.y));
    float depth5 = SampleDepth(ccoord + vec2( pixelSize.x, -pixelSize.y));
    float depth6 = SampleDepth(ccoord + vec2(-pixelSize.x, -pixelSize.y));
    float depth7 = SampleDepth(ccoord + vec2( 0.0        ,  pixelSize.y));
    float depth8 = SampleDepth(ccoord + vec2( 0.0        , -pixelSize.y));

    float depthMin = min9(currentDepth, depth1, depth2, depth3, depth4, depth5, depth6, depth7, depth8);
    float depthMax = max9(currentDepth, depth1, depth2, depth3, depth4, depth5, depth6, depth7, depth8);
    //vec3 depthAVG = (currentDepth + depth1 + depth2 + depth3 + depth4 + depth5 + depth6 + depth7 + depth8) * (1.0 / 9.0);


    coord -= velocity;
    vec4 previousSample = SamplePrevious(coord);


    #ifdef TAA_SHARPEN
        vec3 sharpen = vec3(1.0) - exp(clamp(colAVG, colMin, colMax) - currentCol);
        currentCol += saturate(sharpen) * TAA_SHARPNESS;
    #endif

    previousSample.rgb = clipAABB(colMin, colMax, previousSample.rgb);

    float depthThreshold = 2e-5;
    previousSample.a = clamp(previousSample.a, depthMin - depthThreshold, depthMax + depthThreshold);


    float blendWeight = TAA_AGGRESSION;

    vec2 pixelVelocity = abs(fract(velocity * screenSize) - 0.5) * 2.0;
    blendWeight *= sqrt(pixelVelocity.x * pixelVelocity.y) * 0.25 + 0.75;

    blendWeight = saturate(coord) != coord ? 0.0 : blendWeight;


    vec4 taa = mix(vec4(currentCol, currentDepth), previousSample, blendWeight);

    taa.rgb = LinearToCurve(taa.rgb);
    return taa;
}


void main(){
    float materialID = floor(texture(colortex5, texcoord).b * 255.0);
    float depth = SampleDepthReference(texcoord, materialID);
    vec2 velocity = depth < 0.7 || materialID == 33.0 ? vec2(0.0) : CalculateCameraVelocity(texcoord, depth);

    #ifdef TAA
        vec4 taa = TemporalReprojection(texcoord, velocity);
    #else
        vec4 taa = vec4(texture(colortex1, texcoord).rgb, SampleDepth(texcoord));
    #endif

    compositeOutput7 = taa;
}

/* DRAWBUFFERS:7 */
