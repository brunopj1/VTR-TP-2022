#version 330

uniform	mat4 m_pvm;
uniform vec4 cam_pos;
uniform float Terrain_Length;

in vec4 position;

out Data {
	vec4 pos;
	vec2 texCoord;
} DataOut;

void main () {
	// Calculate the camera offset
	vec4 cam_offset = vec4(cam_pos.x, 0, cam_pos.z, 0);
	DataOut.pos = position * Terrain_Length + cam_offset;
	DataOut.pos.w = 1;
	// Calculate the camera offset for the texCoord
	DataOut.texCoord = DataOut.pos.xz / 1000.0;
	// Position
	gl_Position = m_pvm * DataOut.pos;
}
