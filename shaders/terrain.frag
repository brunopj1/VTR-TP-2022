#version 330

uniform mat4 m_view;
uniform vec4 l_dir;

uniform sampler2D texHeightmap;
uniform sampler2D texGrass;

uniform float T_Texture_Freq;

in Data {
	vec3 normal;
	vec2 texCoord;
} DataIn;

out vec4 colorOut;

void main() {
	vec3 ld = normalize(vec3(m_view * -l_dir));
	float intensity = max(0, dot(normalize(DataIn.normal), ld));

	/* Terrain Color
	vec4 diffuse = vec4(0.156, 0.514, 0.239, 0);
	vec4 ambient = vec4(0.062, 0.306, 0.149, 0);
	colorOut = mix(ambient, diffuse, intensity);
	//*/

	//* Grass Texture
	vec4 diffuse = texture(texGrass, DataIn.texCoord * T_Texture_Freq);
	colorOut = max(intensity, 0.25) * diffuse;
	//*/
}
