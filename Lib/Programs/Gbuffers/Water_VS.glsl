//Water_VS


#include "/Lib/Settings.glsl"


uniform mat4 gbufferModelViewInverse;
uniform vec2 taaJitter;


#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
layout(location = 13) in vec4 at_tangent;
#else
layout(location = 10) in vec4 mc_Entity;
layout(location = 12) in vec4 at_tangent;
#endif


out vec4 color;
out vec2 texcoord;
out mat3 tbn;
out vec4 viewPos;
out vec3 worldPos;
out float dist;
out vec2 blockLight;

out float iswater;
out float isice;
out float isStainedGlass;
flat out float materialIDs;


void main() {
	viewPos = gl_ModelViewMatrix * gl_Vertex;
	dist = length(viewPos.xyz);
	worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz + gbufferModelViewInverse[3].xyz;
	gl_Position = gl_ProjectionMatrix * viewPos;

	#ifdef TAA
        gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
    #endif

	color = gl_Color;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	vec3 N = normalize(gl_NormalMatrix * gl_Normal);
    vec3 T = normalize(gl_NormalMatrix * at_tangent.xyz);
    vec3 B = cross(T, N) * sign(at_tangent.w);
    tbn = mat3(T, B, N);

	vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	blockLight.x = clamp(lmcoord.x * 1.066875 - 0.0334375, 0.0, 1.0);
    blockLight.y = clamp(lmcoord.y * 1.066875 - 0.0334375, 0.0, 1.0);


	iswater = 0.0f;
	isice = 0.0f;
	isStainedGlass = 1.0f;
	materialIDs = 7.0;

	if(mc_Entity.x == 0)
	{
		isStainedGlass = 0.0f;
		materialIDs = 1.0;
		gl_Position.z -= 1e-4;
	}

	if(mc_Entity.x == 8)
	{
		iswater = 1.0;
		isStainedGlass = 0.0f;
		materialIDs = 6.0;
	}

	if (mc_Entity.x == 79)
	{
		isice = 1.0f;
		isStainedGlass = 0.0f;
		materialIDs = 8.0;
	}
}
