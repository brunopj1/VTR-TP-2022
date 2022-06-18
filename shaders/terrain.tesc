#version 410

layout(vertices = 3) out;

uniform	mat4 m_pvm;

uniform vec2 viewport_size;
uniform vec4 cam_up;

uniform float Pixels_Per_Tri;
uniform float Terrain_Height;

in Data {
	vec4 pos;
	vec2 texCoord;
} DataIn[];

out Data {
	vec4 pos;
	vec2 texCoord;
} DataOut[];

// Frustum Culling

void loadFrustum(out vec4[6] frustum_planes) {
	for (int i = 0; i < 3; ++i) {
		for (int j = 0; j < 2; ++j) {
			frustum_planes[i*2+j].x = m_pvm[0][3] + (j == 0 ? m_pvm[0][i] : -m_pvm[0][i]);
			frustum_planes[i*2+j].y = m_pvm[1][3] + (j == 0 ? m_pvm[1][i] : -m_pvm[1][i]);
			frustum_planes[i*2+j].z = m_pvm[2][3] + (j == 0 ? m_pvm[2][i] : -m_pvm[2][i]);
			frustum_planes[i*2+j].w = m_pvm[3][3] + (j == 0 ? m_pvm[3][i] : -m_pvm[3][i]);
			frustum_planes[i*2+j]*= length(frustum_planes[i*2+j].xyz);
		}
	}
}

vec3 negativeVertex(vec3 bmin, vec3 bmax, vec3 n) {
	bvec3 b = greaterThan(n, vec3(0));
	return mix(bmin, bmax, b);
}

bool isVisibleAABB(vec3 bmin, vec3 bmax) {
	float a = 1.0f;
	vec4[6] frustum_planes;
	loadFrustum(frustum_planes);

	for (int i = 0; i < 6 && a >= 0.0f; ++i) {
		vec3 n = negativeVertex(bmin, bmax, frustum_planes[i].xyz);
		a = dot(vec4(n, 1.0f), frustum_planes[i]);
	}

	return (a >= 0.0);
}

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
	return max(pix / Pixels_Per_Tri, 1);
}

void main() {

	DataOut[gl_InvocationID].pos = DataIn[gl_InvocationID].pos;
	DataOut[gl_InvocationID].texCoord = DataIn[gl_InvocationID].texCoord;

	if (gl_InvocationID == 0) {

		// Vertices dos triangulos:
		// 2   0--2   
		// | \  \ |
		// 0--1   1

		ivec3 idx_outer_tess;
		ivec2 aresta1, aresta2, aresta3;
		vec3 bmin, bmax;

		// Triangulo Esquerdo
		if (DataIn[1].pos.x > DataIn[2].pos.x) { 
			idx_outer_tess = ivec3(0, 1, 2);
			aresta1 = ivec2(2, 1);
			aresta2 = ivec2(0, 2);
			aresta3 = ivec2(0, 1);

			bmin = vec3(DataIn[2].pos.x, 0, DataIn[2].pos.z);
			bmax = vec3(DataIn[1].pos.x, Terrain_Height, DataIn[1].pos.z);
		}	
		// Triangulo Direito
		else { 
			idx_outer_tess = ivec3(2, 0, 1);
			aresta1 = ivec2(0, 1);
			aresta2 = ivec2(1, 2);
			aresta3 = ivec2(0, 2);

			bmin = vec3(DataIn[0].pos.x, 0, DataIn[0].pos.z);
			bmax = vec3(DataIn[1].pos.x, Terrain_Height, DataIn[1].pos.z);
		}

		if (isVisibleAABB(bmin, bmax)) {
			// Calcular a tesselacao interna e da diagonal do chunk
			float tes = calculateTes(DataIn[aresta1.x].pos, DataIn[aresta1.y].pos);
			gl_TessLevelInner[0] = tes;
			gl_TessLevelOuter[idx_outer_tess.x] = tes;

			// Calcular a tesselacao externa (dir x)
			tes = calculateTes(DataIn[aresta2.x].pos, DataIn[aresta2.y].pos);
			gl_TessLevelOuter[idx_outer_tess.y] = tes;

			// Calcular a tesselacao externa (dir z)
			tes = calculateTes(DataIn[aresta3.x].pos, DataIn[aresta3.y].pos);
			gl_TessLevelOuter[idx_outer_tess.z] = tes;
		}
		else {
			gl_TessLevelInner[0] = 0;
			gl_TessLevelOuter[0] = 0;
			gl_TessLevelOuter[1] = 0;
			gl_TessLevelOuter[2] = 0;
		}

	}
}