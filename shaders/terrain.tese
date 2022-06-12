#version 410

layout(triangles, fractional_even_spacing, ccw) in;

uniform	mat4 m_pvm;
uniform	mat4 m_view;
uniform	mat3 m_normal;

uniform float Terrain_Length;
uniform float Terrain_Height;
uniform float Heightmap_Freq;

in Data {
	vec4 pos;
	vec2 texCoord;
} DataIn[];

out Data {
	vec4 position;
	vec3 normal;
	vec3 normal_world;
	vec3 tangent;
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

float getNoise_Mountains(vec2 pos) {
	float v = 0.5000 * voronoiNoise(pos);
	pos *= 2;
	v += 0.2500 * voronoiNoise(pos);
	pos *= 2;
	v += 0.1250 * voronoiNoise(pos);
	pos *= 2;
	v += 0.1250 * gradientNoise(pos);
	pos *= 2;
	v += 0.0625 * gradientNoise(pos);

	return v;
}

float getNoise_Plains(vec2 pos) {
	return gradientNoise(pos * 4);
}

float getHeight(vec2 pos) {
	float noise = getNoise_Mountains(pos);
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
	DataOut.position = pos;
	gl_Position = m_pvm * pos;

	// Normal
	float offsetPos = 5;
	float offsetTex = offsetPos / Terrain_Length;
	
	vec3 L = vec3(pos.x - offsetPos, getHeight((texCoord - vec2(offsetTex, 0)) * Heightmap_Freq),             pos.z);
	vec3 R = vec3(pos.x + offsetPos, getHeight((texCoord + vec2(offsetTex, 0)) * Heightmap_Freq),             pos.z);
	vec3 D = vec3(            pos.x, getHeight((texCoord - vec2(0, offsetTex)) * Heightmap_Freq), pos.z + offsetPos);
	vec3 U = vec3(            pos.x, getHeight((texCoord + vec2(0, offsetTex)) * Heightmap_Freq), pos.z - offsetPos);

	vec3 dirX = R - L;
	vec3 dirZ = D - U;

	DataOut.normal_world = normalize(cross(dirZ, dirX));
	DataOut.normal = normalize(m_normal * DataOut.normal_world);

	// Tangent
	vec3 tangent = normalize(cross(vec3(1.0, 0.0, 0.0), DataOut.normal_world));
	DataOut.tangent = normalize(m_normal * tangent);
}

