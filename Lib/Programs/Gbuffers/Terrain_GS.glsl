//Terrain_GS


#include "/Lib/Settings.glsl"


layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;


uniform ivec2 atlasSize;


in vec4 v_color[];
in vec2 v_texcoord[];
in vec4 v_viewPos[];
in vec3 v_worldPos[];
in mat3 v_tbn[];
in vec2 v_blockLight[];
flat in float v_materialIDs[];
in float v_noWetItem[];


out vec4 color;
out vec2 texcoord;
out vec3 viewPos;
out vec3 worldPos;
out mat3 tbn;
out vec2 blockLight;
flat out float materialIDs;
out float noWetItem;
flat out float textureResolution;

void main(){
    #if TEXTURE_RESOLUTION == 0
        vec2 coordSize = max(max(abs(v_texcoord[0].st - v_texcoord[1].st) / distance(v_viewPos[0], v_viewPos[1]),
                                 abs(v_texcoord[1].st - v_texcoord[2].st) / distance(v_viewPos[1], v_viewPos[2])),
                                 abs(v_texcoord[2].st - v_texcoord[0].st) / distance(v_viewPos[2], v_viewPos[0]));

        textureResolution = floor(max(atlasSize.x * coordSize.x, atlasSize.y * coordSize.y) + 0.5);
    #else
        textureResolution = TEXTURE_RESOLUTION;
    #endif

    for (int i = 0; i < 3; i++) {
        gl_Position = gl_in[i].gl_Position;

        color = v_color[i];
        texcoord = v_texcoord[i];
        viewPos = v_viewPos[i].xyz;
        worldPos = v_worldPos[i];
        tbn = v_tbn[i];
        blockLight = v_blockLight[i];
        materialIDs = v_materialIDs[i];
        noWetItem  = v_noWetItem[i];

        EmitVertex();
    }
    EndPrimitive();
}
