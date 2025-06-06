#version 450 compatibility


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


out vec2 texcoord;

out vec3 colorTorchlight;


void main()
{
	gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);
	texcoord = gl_Vertex.xy;


	colorTorchlight = Blackbody(TORCHLIGHT_COLOR_TEMPERATURE);
}
