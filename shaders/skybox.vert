#version 330

uniform	mat4 m_pvm;
uniform vec4 cam_pos;

in vec4 position;
in vec2 texCoord0;

out vec2 texCoord;

void main () {
    texCoord = texCoord0;
    vec4 pos = position + vec4(cam_pos.xyz, 0);
    gl_Position = m_pvm * pos;
}
