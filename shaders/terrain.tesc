#version 410

layout(vertices = 3) out;

uniform float T_Length;
uniform int T_Chunks;
uniform float T_Height;

uniform float tessellation;

in Data {
	vec3 pos;
} DataIn[];

out Data {
	vec3 pos;
	flat float tes;
} DataOut[];

// Constantes
float T_Length_2 = T_Length * 0.5;
float C_Length = T_Length / T_Chunks;
float C_Length_2 = C_Length * 0.5;
float T_Hypotenuse = sqrt(2 * T_Length_2 * T_Length_2);

float calculateNormDist(vec2 pos) {
	float dist = length(pos);
	float norm_dist = dist / T_Hypotenuse;
	return norm_dist;
} 

// TODO calcular a tesselacao com base no tamanho dos triangulos
// TODO reduzir a tesselacao de triangulos fora do view frustum
float calculateTes(float norm_dist) {
	float tes = (1 - norm_dist) * tessellation;
	return max(tes, 1);
}

void main() {

	DataOut[gl_InvocationID].pos = DataIn[gl_InvocationID].pos;
	
	if (gl_InvocationID == 0) {

		// Determinar um vertice comum dos triangulos
		vec2 pos;
		int idx0, idx1, idxSame;
		vec2 offset0, offset1;

		// Vertices dos triangulos:
		// 2   0--2   
		// | \  \ |
		// 0--1   1

		// Triangulo Esquerdo
		if (DataIn[1].pos.x > DataIn[2].pos.x) { 
			pos = DataIn[2].pos.xz;
			idxSame = 0;
			idx0 = 1;
			offset0 = vec2(- C_Length, 0);
			idx1 = 2;
			offset1 = vec2(0, C_Length);
		}	
		// Triangulo Direito
		else { 
			pos = DataIn[0].pos.xz;
			idxSame = 2;
			idx0 = 0;
			offset0 = vec2(C_Length, 0);
			idx1 = 1;
			offset1 = vec2(0, - C_Length);
		}

		// Calcular a tesselacao interna e da diagonal do chunk
		pos += vec2(C_Length_2, C_Length_2);
		float norm_dist = calculateNormDist(pos);
		float tes = calculateTes(norm_dist);
		gl_TessLevelInner[0] = tes;
		gl_TessLevelOuter[idxSame] = tes;

		// Calcular a tesselacao externa 0
		vec2 _pos = pos + offset0;
		float _norm_dist = calculateNormDist(_pos);
		float _tes = calculateTes(_norm_dist);
		gl_TessLevelOuter[idx0] = min(tes, _tes);

		// Calcular a tesselacao externa 1
		_pos = pos + offset1;
		_norm_dist = calculateNormDist(_pos);
		_tes = calculateTes(_norm_dist);
		gl_TessLevelOuter[idx1] = min(tes, _tes);

		// Guardar o nivel de tesselacao do triangulo
		DataOut[gl_InvocationID].tes = norm_dist;
	}
}