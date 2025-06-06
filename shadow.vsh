#version 450 compatibility

#include "/Lib/Settings.glsl"

out vec4 texcoord;
out vec4 color;
out vec3 normal;
out vec4 lmcoord;

#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
#else
layout(location = 10) in vec4 mc_Entity;
#endif

uniform vec3 cameraPosition;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;


void main() {
	gl_Position = ftransform();

	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	texcoord = gl_MultiTexCoord0;

	normal = normalize(gl_NormalMatrix * gl_Normal);

	color = gl_Color;

	float dist = length(gl_Position.xy);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	gl_Position.xy *= 0.95 / distortFactor;

	gl_Position.z = mix(gl_Position.z, 0.5, 0.8);

	if (mc_Entity.x == 8 || mc_Entity.x == 79) gl_Position.z = -10.0;
}
