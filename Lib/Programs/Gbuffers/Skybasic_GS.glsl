//Skybasic_GS


layout(triangles) in;
layout(triangle_strip, max_vertices = 4) out;


void main(){
    if (gl_PrimitiveIDIn == 0){
        gl_Position = vec4(-1.0, -1.0, 0.0, 1.0);
        EmitVertex();
        gl_Position = vec4(1.0, -1.0, 0.0, 1.0);
        EmitVertex();
        gl_Position = vec4(-1.0, 1.0, 0.0, 1.0);
        EmitVertex();
        gl_Position = vec4(1.0, 1.0, 0.0, 1.0);
        EmitVertex();
        EndPrimitive();
    }
}
