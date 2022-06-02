#version 330

uniform mat4 m_view;
uniform vec4 l_dir;

uniform sampler2D texHeightmap;

in Data {
	vec3 normal;
	vec2 texCoord;
} DataIn;

out vec4 colorOut;

void main() {
	vec3 ld = normalize(vec3(m_view * -l_dir));
	float intensity = max(0, dot(normalize(DataIn.normal), ld));

	vec4 diffuse = vec4(0.156, 0.514, 0.239, 0);
	vec4 ambient = vec4(0.062, 0.306, 0.149, 0);
	colorOut = mix(ambient, diffuse, intensity);

	//colorOut = vec4(intensity, intensity, intensity, 0);
	//colorOut = vec4(DataIn.texCoord * intensity, intensity, 0);
	//colorOut = vec4(DataIn.normal, 0);
	//colorOut = texture(texHeightmap, DataIn.texCoord).rrrr;
}
