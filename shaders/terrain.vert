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
	// Offset the position / texcoord
	DataOut.pos = vec4(vec3(position * Terrain_Length + cam_offset), 1);
	DataOut.pos.w = 1;
	DataOut.texCoord = DataOut.pos.xz / 1000.0;
	gl_Position = m_pvm * DataOut.pos;
}
