//Weather_FS


uniform sampler2D texture;


in vec2 texcoord;


void main() {
	vec4 tex = texture2D(texture, texcoord);

	if(tex.a < 0.1) discard;

	gl_FragData[0] = vec4(0.0, 0.0, 0.0, tex.a);
}

/* DRAWBUFFERS:0 */
