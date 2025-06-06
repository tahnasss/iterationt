//Entities_VS


#include "/Lib/Settings.glsl"


uniform int entityId;
uniform vec2 taaJitter;


out vec4 color;
out vec2 texcoord;
out vec4 viewPos;
out vec2 blockLight;
flat out float materialIDs;


void main() {
	viewPos = gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * viewPos;

	#ifdef TAA
        gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
    #endif

	color = gl_Color;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	blockLight.x = clamp(lmcoord.x * 1.066875 - 0.0334375, 0.0, 1.0);
    blockLight.y = clamp(lmcoord.y * 1.066875 - 0.0334375, 0.0, 1.0);

	materialIDs = 10.0;

	if(entityId == 14
	|| entityId == 22
	|| entityId == 26)
	materialIDs = 11.0;

	if(entityId == 17)
	materialIDs = 12.0;

	if(entityId == 2
	|| entityId == 15
	|| entityId == 24
	|| entityId == 200)
	materialIDs = 13.0;

	if(entityId == 7000)
	materialIDs = 14.0;
}
