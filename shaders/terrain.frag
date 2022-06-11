#version 330

uniform mat4 m_view;
uniform vec4 l_dir;

uniform sampler2D texLevel0;
uniform sampler2D texLevel1;
uniform sampler2D texLevel2;

uniform float Texture_Freq;

in Data {
	vec4 eye;
	vec4 position;
	vec3 normal;
	vec3 normal_world;
	vec2 texCoord;
	float heightNormalized;
} DataIn;

out vec4 colorOut;

// Funções para determinar o diffuse do pixel

vec4 computeLight(vec4 diffuse) {
	// Diffuse
	vec3 l = normalize(vec3(m_view * -l_dir));
	vec3 n = normalize(DataIn.normal);
	float intensity = max(0, dot(n, l));

	// Specular
	const float shininess = 512;
	vec4 spec = vec4(0);
	if (intensity > 0.0) {
		vec3 e = normalize(vec3(DataIn.eye));
		vec3 h = normalize(l + e);	
		float spec_intensity = max(dot(h,n), 0.0);
		spec = vec4(pow(spec_intensity, shininess));
	}
	
	// return the color
	return max(intensity *  diffuse + spec, diffuse * 0.25);
	//return max(intensity, 0.25);
}

vec4 getTriPlanarBlend() {
	vec3 blending = abs(DataIn.normal_world);
	blending = normalize(max(blending, 0.00001)); // Force weights to sum to 1.0
	float b = (blending.x + blending.y + blending.z);
	blending /= vec3(b, b, b);

	float factor = Texture_Freq * 0.001;
	vec3 xaxis = vec3(texture(texLevel1, DataIn.position.yz * factor));
	vec3 yaxis = vec3(texture(texLevel1, DataIn.position.xz * factor));
	vec3 zaxis = vec3(texture(texLevel1, DataIn.position.xy * factor));

	vec4 diffuse = vec4(xaxis * blending.x + yaxis * blending.y + zaxis * blending.z, 0);
	//diffuse = texture(texLevel0, DataIn.position.xz * factor);
	return diffuse;
}

vec4 getTextureByHight() {
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
	return diffuse;
}

// Main

void main() {
	// Texture
	//vec4 diffuse = getTriPlanarBlend();
	vec4 diffuse = getTextureByHight();

	// Color
	// Light
	colorOut = computeLight(diffuse);
}
