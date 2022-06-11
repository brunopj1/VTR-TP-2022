#version 330

uniform mat4 m_view;
uniform vec4 l_dir;

uniform sampler2D texLevel0;
uniform sampler2D texLevel1;
uniform sampler2D texLevel2;

uniform float Texture_Freq;

in Data {
	float heightNormalized;
	vec3 normal;
	vec2 texCoord;
} DataIn;

out vec4 colorOut;

void main() {
	// Light
	vec3 ld = normalize(vec3(m_view * -l_dir));
	float intensity = max(0, dot(normalize(DataIn.normal), ld));

	// Texture
	float h = DataIn.heightNormalized;
	vec2 coord = DataIn.texCoord * Texture_Freq;
	vec4 diffuse;
	if (h < 0.5) {
		diffuse = texture(texLevel0, coord);
	}
	else if (h < 0.7) {
		diffuse = texture(texLevel1, coord);
	}
	else {
		diffuse = texture(texLevel2, coord);
	}

	// Color
	colorOut = max(intensity, 0.25) * diffuse;
	//colorOut = vec4(intensity);
}
