#version 330

uniform	mat4 m_pvm;
uniform vec4 cam_pos;
uniform float Terrain_Length;

in vec4 position;
in vec2 texCoord0;

out Data {
	vec4 pos;
	vec2 texCoord;
} DataOut;

void main () {
	// Calculate the camera offset
	vec4 cam_offset = vec4(cam_pos.x, 0, cam_pos.z, 0);
	DataOut.pos = position + cam_offset;
	// Calculate the camera offset for the texCoord
	vec2 cam_offset_tex = vec2(cam_pos.x, -cam_pos.z) / Terrain_Length;
	DataOut.texCoord = texCoord0 + cam_offset_tex;
	// Position
	gl_Position = m_pvm * DataOut.pos;
}
