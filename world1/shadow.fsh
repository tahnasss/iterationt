#version 450 compatibility

#include "/Lib/Settings.glsl"

uniform sampler2D tex;

in vec4 texcoord;
in vec4 color;
in vec3 normal;
in vec4 lmcoord;

void main() {

	vec4 tex = texture(tex, texcoord.st, 0) * color;

	#ifdef WHITE_DEBUG_WORLD
		tex.rgb = vec3(1.0);
	#endif


	vec3 shadowNormal = normal.xyz;

	if (normal.z < 0.0)
	{
		tex.rgb = vec3(0.0);
	}

	gl_FragData[0] = vec4(tex.rgb, tex.a);
	gl_FragData[1] = vec4(shadowNormal.xyz * 0.5 + 0.5, 0.0);
}
