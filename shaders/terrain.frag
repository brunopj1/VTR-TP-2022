#version 330

uniform mat4 m_view;
uniform vec4 cam_pos;

uniform float Terrain_Height;
uniform float Texture_Freq;

uniform vec4 l_dir;
uniform vec4 l_color;
uniform vec4 l_ambient;

uniform sampler2D tex_grass_albedo;
uniform sampler2D tex_grass_ao;
uniform sampler2D tex_grass_height;
uniform sampler2D tex_grass_normal;
uniform sampler2D tex_grass_roughness;

uniform int use_specular_light;
uniform int use_ao_mapping;
uniform int use_height_mapping;
uniform int use_normal_mapping;
uniform int use_roughness_mapping;

in Data {
	vec4 position;
	vec3 normal;
	vec3 normal_world;
	vec2 texCoord;
} DataIn;

out vec4 colorOut;

// Funções para determinar o diffuse do pixel

/*
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
*/

// TODO update this
vec4 getTriPlanarBlend() {
	vec3 blending = abs(DataIn.normal_world);
	blending = normalize(max(blending, 0.00001)); // Force weights to sum to 1.0
	float b = (blending.x + blending.y + blending.z);
	blending /= vec3(b, b, b);

	float factor = Texture_Freq * 0.001;
	vec3 xaxis = vec3(texture(tex_grass_albedo, DataIn.position.yz * factor));
	vec3 yaxis = vec3(texture(tex_grass_albedo, DataIn.position.xz * factor));
	vec3 zaxis = vec3(texture(tex_grass_albedo, DataIn.position.xy * factor));

	vec4 diffuse = vec4(xaxis * blending.x + yaxis * blending.y + zaxis * blending.z, 0);
	//diffuse = texture(texLevel0, DataIn.position.xz * factor);
	return diffuse;
}

// TODO update this
vec4 getTextureByHight() {
	float h = DataIn.position.y;
	vec2 coord = DataIn.texCoord * Texture_Freq;
	vec4 diffuse;

	if (h < 0.5 * Terrain_Height) {
		diffuse = texture(tex_grass_albedo, coord);
	}
	else if (h < 0.7 * Terrain_Height) {
		diffuse = texture(tex_grass_albedo, coord);
	}
	else {
		diffuse = texture(tex_grass_albedo, coord);
	}
	return diffuse;
}

// Main

void main() {
	// Texture Coord
	vec2 coord = DataIn.texCoord * Texture_Freq;

	// Light Intensity
	vec3 n = normalize(DataIn.normal);
	vec3 l = normalize(vec3(m_view * -l_dir));
	float intensity = max(dot(n, l), 0.0);

	// Specular
	vec4 specular = vec4(0.0);
	if (use_specular_light > 0 && intensity > 0.0) {
		vec3 e = normalize(vec3(-(m_view * DataIn.position)));
		vec3 h = normalize(l + e);	
		float specIntensity = pow(max(dot(h, n), 0.0), 128);
		specular = l_color * specIntensity;
		// Roughness
		if (use_roughness_mapping > 0) {
			vec4 roughness = vec4(1) - texture(tex_grass_roughness, coord);
			specular *= roughness;
		}
	}

	// Albedo / Diffuse
	vec4 diffuse = texture(tex_grass_albedo, coord) * l_color;

	// Ambient Occlusion
	if (use_ao_mapping > 0) {
		vec4 ao = texture(tex_grass_ao, coord);
		diffuse *= ao;
	}

	// Brightness Boost
	diffuse = clamp(diffuse * vec4(1.2), 0, 1);

	// Color
	colorOut = max(intensity * diffuse + specular, diffuse * 0.25);
}