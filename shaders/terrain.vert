#version 330

uniform	mat4 m_pvm;

in vec4 position;
in vec2 texCoord0;

out Data {
	vec4 pos;
	vec2 texCoord;
} DataOut;

void main () {
	DataOut.pos = position;
	DataOut.texCoord = texCoord0;
	gl_Position = m_pvm * position;
}
