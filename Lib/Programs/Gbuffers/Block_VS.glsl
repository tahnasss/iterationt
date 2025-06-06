//Block_VS


#include "/Lib/Settings.glsl"


uniform mat4 gbufferModelViewInverse;
uniform vec2 taaJitter;
uniform int blockEntityId;


#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
#else
layout(location = 10) in vec4 mc_Entity;
#endif


out vec4 color;
out vec2 texcoord;
out vec4 viewPos;
out vec3 worldPos;
out vec2 blockLight;
flat out float materialIDs;

out vec4 portalCoord;


void main() {
	viewPos = gl_ModelViewMatrix * gl_Vertex;
	worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz + gbufferModelViewInverse[3].xyz;
	gl_Position = gl_ProjectionMatrix * viewPos;

	#ifdef TAA
		gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
	#endif

	color = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	blockLight.x = clamp((lmcoord.x * 34.14 / 32.0) - 1.07 / 32.0, 0.0, 1.0);
    blockLight.y = clamp((lmcoord.y * 34.14 / 32.0) - 1.07 / 32.0, 0.0, 1.0);

    materialIDs = blockEntityId == 119 ? 33.0 : 1.0;

	portalCoord = gl_Position * 0.5;
	portalCoord.xy = vec2(portalCoord.x + portalCoord.w, portalCoord.y + portalCoord.w);
    portalCoord.zw = gl_Position.zw;
}
