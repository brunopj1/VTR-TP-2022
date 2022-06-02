#version 330

uniform	mat4 m_pvm;

uniform float T_Length;
uniform int T_Chunks;

in vec4 position;	// local space
in vec2 texCoord0;

out vec3 posV;

void main () {
	posV = vec3(position);
	gl_Position = m_pvm * position;
}
