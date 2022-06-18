#version 330

uniform	mat4 m_pvm;
uniform vec4 cam_pos;
uniform float cam_far;

in vec4 position;
in vec2 texCoord0;

out vec2 texCoord;

void main () {
    texCoord = texCoord0;
    vec3 pos = position.xyz * cam_far + cam_pos.xyz;
    gl_Position = m_pvm * vec4(pos, 1);
}
