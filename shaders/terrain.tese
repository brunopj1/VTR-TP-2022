#version 410

layout(triangles, equal_spacing, ccw) in;

uniform	mat4 m_pvm;

in vec3 posTV[];

void main() {
	vec3 pos = 
		posTV[0] * gl_TessCoord.x +
		posTV[1] * gl_TessCoord.y +
		posTV[2] * gl_TessCoord.z;

	gl_Position = m_pvm * vec4(pos, 1.0);
}

