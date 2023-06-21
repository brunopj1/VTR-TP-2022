#version 410

layout(triangles, fractional_even_spacing, ccw) in;

uniform	mat4 m_pvm;
uniform	mat4 m_view;
uniform	mat3 m_normal;

uniform float Terrain_Length;
uniform float Terrain_Height;
uniform float Heightmap_Freq;
uniform float Noise_Exp;

uniform float Noise_1_Freq;
uniform float Noise_1_Weight;
uniform float Noise_2_Freq;
uniform float Noise_2_Weight;
uniform float Noise_3_Freq;
uniform float Noise_3_Weight;
uniform float Noise_4_Freq;
uniform float Noise_4_Weight;
uniform float Noise_5_Freq;
uniform float Noise_5_Weight;

float total_weight = Noise_1_Weight + Noise_2_Weight + Noise_3_Weight + Noise_4_Weight + Noise_5_Weight;

in Data {
	vec4 pos;
	vec2 texCoord;
} DataIn[];

out Data {
	vec3 normal;
	vec3 tangent;
	vec3 bitangent;
	vec2 texCoord;
} DataOut;

// Gradient Noise

vec2 grad(ivec2 z) { // replace this anything that returns a random vector
    // 2D to 1D  (feel free to replace by some other)
    int n = z.x + z.y * 11111;

    // Hugo Elias hash (feel free to replace by another one)
    n = (n << 13) ^ n;
    n = (n * (n * n * 15731 + 789221) + 1376312589) >> 16;

    // Perlin style vectors
    n &= 7;
    vec2 gr = vec2(n&1, n>>1) * 2.0 - 1.0;

    return (n >= 6) ? vec2(0.0, gr.x) : 
           (n >= 4) ? vec2(gr.x, 0.0) :
                      gr;                          
}

float gradientNoise(vec2 p) {
    ivec2 i = ivec2(floor(p));
     vec2 f =       fract(p);
	
	vec2 u = f*f*(3.0-2.0*f); // feel free to replace by a quintic smoothstep instead

    return mix( mix( dot( grad( i+ivec2(0,0) ), f-vec2(0.0,0.0) ), 
                     dot( grad( i+ivec2(1,0) ), f-vec2(1.0,0.0) ), u.x),
                mix( dot( grad( i+ivec2(0,1) ), f-vec2(0.0,1.0) ), 
                     dot( grad( i+ivec2(1,1) ), f-vec2(1.0,1.0) ), u.x), u.y)
			* 0.5 + 0.5;
}

// Voronoi Noise 

const mat2 myt = mat2(.12121212, .13131313, -.13131313, .12121212);
const vec2 mys = vec2(1e4, 1e6);

vec2 rhash(vec2 uv) {
	uv *= myt;
	uv *= mys;
	return fract(fract(uv / mys) * uv);
}

float voronoiNoise(vec2 point) {
	vec2 p = floor(point);
	vec2 f = fract(point);
	float res = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 b = vec2(i, j);
			vec2 r = vec2(b) - f + rhash(p + b);
			res += 1. / pow(dot(r, r), 8.);
		}
	}
	return pow(1.0 / res, 0.0625);
}

// Noise

float getNoise(vec2 pos) {
	float v = 0;
	v += Noise_1_Weight * voronoiNoise(pos * Noise_1_Freq);
	v += Noise_2_Weight * voronoiNoise(pos * Noise_2_Freq);
	v += Noise_3_Weight * voronoiNoise(pos * Noise_3_Freq);
	v += Noise_4_Weight * gradientNoise(pos * Noise_4_Freq);
	v += Noise_5_Weight * gradientNoise(pos * Noise_5_Freq);
	// Dividir pela soma dos pesos
	// Aplicar um expoente para reduzir a elevação fora dos picos
	return pow(v / (total_weight), Noise_Exp);
}

float getHeight(vec2 pos) {
	float noise = getNoise(pos);
	return noise * Terrain_Height;
}

// Main

void main() {
	// TexCoord
	vec2 texCoord = 
		DataIn[0].texCoord * gl_TessCoord.x +
		DataIn[1].texCoord * gl_TessCoord.y +
		DataIn[2].texCoord * gl_TessCoord.z;

	DataOut.texCoord = texCoord;

	// Noise
	float noise = getHeight(texCoord * Heightmap_Freq);

	// Position
	vec4 pos = 
		DataIn[0].pos * gl_TessCoord.x +
		DataIn[1].pos * gl_TessCoord.y +
		DataIn[2].pos * gl_TessCoord.z;

	pos.y += noise;
	gl_Position = pos;

	// Normal
	vec2 posL = pos.xz - vec2(1, 0); vec3 L = vec3(posL.x, getHeight(posL * 0.001 * Heightmap_Freq), posL.y);
	vec2 posR = pos.xz + vec2(1, 0); vec3 R = vec3(posR.x, getHeight(posR * 0.001 * Heightmap_Freq), posR.y);
	vec2 posD = pos.xz + vec2(0, 1); vec3 D = vec3(posD.x, getHeight(posD * 0.001 * Heightmap_Freq), posD.y);
	vec2 posU = pos.xz - vec2(0, 1); vec3 U = vec3(posU.x, getHeight(posU * 0.001 * Heightmap_Freq), posU.y);

	vec3 dirX = R - L;
	vec3 dirZ = D - U;

	DataOut.normal = normalize(cross(dirZ, dirX));

	// Tangent + Bitangent
	DataOut.tangent = normalize(dirX);
	DataOut.bitangent = cross(DataOut.normal, DataOut.tangent);
}
