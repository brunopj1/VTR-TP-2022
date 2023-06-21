#version 330

uniform	mat4 m_pvm;
uniform vec4 cam_pos;
uniform float Terrain_Length;
uniform int Terrain_Chunks;

in vec4 position;

out Data {
	vec4 pos;
	vec2 texCoord;
} DataOut;

void main () {
	// Calculate the camera offset
	float chunk_size = Terrain_Length / Terrain_Chunks;
	vec2 cam_offset = floor(cam_pos.xz / chunk_size) * chunk_size;
	// Offset the position / texcoord
	vec2 pos = position.xz * Terrain_Length + cam_offset;
	DataOut.pos = vec4(pos.x, 0, pos.y, 1);
	DataOut.texCoord = DataOut.pos.xz * 0.001;
	gl_Position = m_pvm * DataOut.pos;
}
