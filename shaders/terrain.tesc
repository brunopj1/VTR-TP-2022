#version 410

layout(vertices = 3) out;

uniform float tes_olevel;
uniform float tes_ilevel;

in vec3 posV[];

out vec3 posTV[];

void main() {

	posTV[gl_InvocationID] = posV[gl_InvocationID];
	
	if (gl_InvocationID == 0) {
		gl_TessLevelOuter[0] = tes_olevel;
		gl_TessLevelOuter[1] = tes_olevel;
		gl_TessLevelOuter[2] = tes_olevel;
		gl_TessLevelInner[0] = tes_ilevel;
	}
}