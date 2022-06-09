#version 410

layout(vertices = 3) out;

uniform	mat4 m_pvm;
uniform vec2 viewport_size;
uniform vec4 cam_up;

uniform float pixels_per_tri;

in Data {
	vec4 pos;
	vec2 texCoord;
} DataIn[];

out Data {
	vec4 pos;
	vec2 texCoord;
} DataOut[];

// TODO reduzir a tesselacao de triangulos fora do view frustum
float calculateTes(vec4 pos0, vec4 pos1) {
	// Calcular o centro e raio da esfera
	float radius = length(vec3(pos0 - pos1)) * 0.5;
	vec4 center = (pos0 + pos1) * 0.5;
	// Calcular o ponto de cima
	vec4 up = m_pvm * (center + cam_up * radius);
	vec3 up_ndc = up.xyz / up.w;
	vec2 up_screen = (up_ndc.xy * .5 + .5) * viewport_size;
	// Calcular o ponto de baixo
	vec4 down = m_pvm * (center - cam_up * radius);
	vec3 down_ndc = down.xyz / down.w;
	vec2 down_screen = (down_ndc.xy * .5 + .5) * viewport_size;
	// Calcular o numero de pixeis da esfera
	float pix = abs(up_screen.y - down_screen.y);
	// Calcular o numero de triangulos
	return max(pix / pixels_per_tri, 1);
}

void main() {

	DataOut[gl_InvocationID].pos = DataIn[gl_InvocationID].pos;
	DataOut[gl_InvocationID].texCoord = DataIn[gl_InvocationID].texCoord;

	if (gl_InvocationID == 0) {

		// Vertices dos triangulos:
		// 2   0--2   
		// | \  \ |
		// 0--1   1

		// Triangulo Esquerdo
		if (DataIn[1].pos.x > DataIn[2].pos.x) { 

			// Calcular a tesselacao interna e da diagonal do chunk
			float tes = calculateTes(DataIn[2].pos, DataIn[1].pos);
			gl_TessLevelInner[0] = tes;
			gl_TessLevelOuter[0] = tes;

			// Calcular a tesselacao externa (dir x)
			tes = calculateTes(DataIn[0].pos, DataIn[2].pos);
			gl_TessLevelOuter[1] = tes;

			// Calcular a tesselacao externa (dir z)
			tes = calculateTes(DataIn[0].pos, DataIn[1].pos);
			gl_TessLevelOuter[2] = tes;
		}	
		// Triangulo Direito
		else { 

			// Calcular a tesselacao interna e da diagonal do chunk
			float tes = calculateTes(DataIn[0].pos, DataIn[1].pos);
			gl_TessLevelInner[0] = tes;
			gl_TessLevelOuter[2] = tes;

			// Calcular a tesselacao (dir x)
			tes = calculateTes(DataIn[1].pos, DataIn[2].pos);
			gl_TessLevelOuter[0] = tes;

			// Calcular a tesselacao (dir z)
			tes = calculateTes(DataIn[0].pos, DataIn[2].pos);
			gl_TessLevelOuter[1] = tes;
		}
	}
}