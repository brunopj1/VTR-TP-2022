#version 330

uniform mat4 m_view;
uniform vec4 l_dir;

uniform sampler2D texHeightmap;
uniform sampler2D texLevel0;
uniform sampler2D texLevel1;
uniform sampler2D texLevel2;

uniform float Terrain_Height;
uniform float Noise_Freq;

in Data {
	float noise;
	vec3 normal;
	vec2 texCoord;
} DataIn;

out vec4 colorOut;

// Main

void main() {
	//vec3 ld = normalize(vec3(m_view * -l_dir));
	//float intensity = max(0, dot(normalize(DataIn.normal), ld));
	colorOut = vec4(vec3(DataIn.noise), 1);
}
