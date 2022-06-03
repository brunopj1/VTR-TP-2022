#version 330

uniform mat4 m_view;
uniform vec4 l_dir;

uniform sampler2D texHeightmap;
uniform sampler2D texLevel0;
uniform sampler2D texLevel1;
uniform sampler2D texLevel2;

uniform float Terrain_Height;
uniform float Texture_Freq;
uniform float Texture_Blending_Freq;
uniform float Texture_Blending_Intensity;

in Data {
	float heightNorm;
	vec3 normal;
	vec2 texCoord;
} DataIn;

out vec4 colorOut;

// Random functions

float rand(float n) {
	return fract(sin(n) * 43758.5453123);
}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

// Noise functions

float noise(float p){
	float fl = floor(p);
	float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}
	
float noise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
	vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

// Main

void main() {
	vec3 ld = normalize(vec3(m_view * -l_dir));
	float intensity = max(0, dot(normalize(DataIn.normal), ld));

	/* Terrain Color
	vec4 diffuse = vec4(0.156, 0.514, 0.239, 0);
	vec4 ambient = vec4(0.062, 0.306, 0.149, 0);
	colorOut = mix(ambient, diffuse, intensity);
	//*/

	//* Textures
	float delta_h = (noise(DataIn.texCoord * Texture_Blending_Freq) - 0.5) * Texture_Blending_Intensity;
	float h = DataIn.heightNorm + delta_h;
	vec2 coord = DataIn.texCoord * Texture_Freq;
	vec4 diffuse;
	if (h < Terrain_Height * 0.1) {
		diffuse = texture(texLevel0, coord);
	}
	else if (h < Terrain_Height * 0.7) {
		diffuse = texture(texLevel1, coord);
	}
	else {
		diffuse = texture(texLevel2, coord);
	}
	colorOut = max(intensity, 0.25) * diffuse;
	//*/
}
