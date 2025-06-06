vec3 ViewPos_From_ScreenPos(vec2 coord, float depth){
	#ifdef TAA
		coord -= taaJitter * 0.5;
	#endif
	vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
	vec3 viewPos = vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * ndcPos.xy, 0.0) + gbufferProjectionInverse[3].xyz;
	return viewPos / (gbufferProjectionInverse[2].w * ndcPos.z + gbufferProjectionInverse[3].w);
}

vec3 ViewPos_From_ScreenPos_Raw(vec2 coord, float depth){
	vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
	vec3 viewPos = vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * ndcPos.xy, 0.0) + gbufferProjectionInverse[3].xyz;
	return viewPos / (gbufferProjectionInverse[2].w * ndcPos.z + gbufferProjectionInverse[3].w);
}

vec3 ScreenPos_From_ViewPos_Raw(vec3 viewPos){
	vec3 screenPos = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * viewPos + gbufferProjection[3].xyz;
	return screenPos * (0.5 / -viewPos.z) + 0.5;
}

float LinearDepth_From_ScreenDepth(float depth){
    depth = depth * 2.0 - 1.0;
    return 1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}

float ScreenDepth_From_LinearDepth(float depth){
	depth = (1.0 / depth - gbufferProjectionInverse[3][3]) / gbufferProjectionInverse[2][3];
    return depth * 0.5 + 0.5;
}
