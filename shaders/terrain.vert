#version 330

uniform	mat4 m_pvm;

in vec4 position;	// local space

out Data {
	vec3 pos;
} DataOut;

void main () {
	DataOut.pos = vec3(position);
	gl_Position = m_pvm * position;
}
