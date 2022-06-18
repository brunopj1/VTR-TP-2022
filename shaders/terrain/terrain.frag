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
uniform sampler2D tex_grass_normal;
uniform sampler2D tex_grass_roughness;

uniform sampler2D tex_dirt_albedo;
uniform sampler2D tex_dirt_ao;
uniform sampler2D tex_dirt_normal;
uniform sampler2D tex_dirt_roughness;

uniform int use_specular_light;
uniform int use_ao_mapping;
uniform int use_normal_mapping;
uniform int use_roughness_mapping;

in Data {
	vec4 position;
	vec3 normal_world;
	vec3 normal;
	vec3 tangent;
	vec3 bitangent;
	vec2 texCoord;
} DataIn;

out vec4 colorOut;

// Get texture

#define TEX_ALBEDO    0
#define TEX_AO        1
#define TEX_NORMAL    2
#define TEX_ROUGHNESS 3

vec4 getTexture(int type, vec2 coord, float f) {
	vec4 color1, color2;
	switch (type) {
		case TEX_ALBEDO:
			color1 = texture(tex_grass_albedo, coord);
			color2 = texture(tex_dirt_albedo, coord);
			break;
		case TEX_AO:
			color1 = texture(tex_grass_ao, coord);
			color2 = texture(tex_dirt_ao, coord);
			break;
		case TEX_NORMAL:
			color1 = texture(tex_grass_normal, coord);
			color2 = texture(tex_dirt_normal, coord);
			break;
		case TEX_ROUGHNESS:
			color1 = texture(tex_grass_roughness, coord);
			color2 = texture(tex_dirt_roughness, coord);
			break;
	}
	return mix(color1, color2, f);
}

// Main

void main() {
	// Normalize the data
	vec2 coord = DataIn.texCoord * Texture_Freq;
	vec3 normal = normalize(DataIn.normal);
	vec3 light_dir = normalize(vec3(m_view * -l_dir));
	vec3 eye = normalize(vec3(- m_view * DataIn.position));

	// Calculate the slope
	float slope = 1 - DataIn.normal_world.y + 0.4;

	// Normal Mapping
	if (use_normal_mapping > 0) {
		mat3 tbn = mat3(DataIn.tangent, DataIn.bitangent, DataIn.normal);
		vec4 normal_tex = getTexture(TEX_NORMAL, coord, slope);
		normal = normalize(vec3(normal_tex * 2.0 - 1.0));
		normal = tbn * normal;
	}

	// Light Intensity
	float intensity = max(dot(normal, light_dir), 0.0);

	// Ambient Occlusion
	if (use_ao_mapping > 0) {
		vec4 ao = getTexture(TEX_AO, coord, slope);
		intensity *= ao.r;
	}

	// Specular
	vec4 specular = vec4(0.0);
	if (use_specular_light > 0 && intensity > 0.0) {
		vec3 half_vec = normalize(light_dir + eye);	
		float specIntensity = pow(max(dot(half_vec, normal), 0.0), 128);
		specular = l_color * specIntensity;
		// Roughness
		if (use_roughness_mapping > 0) {
			vec4 roughness = vec4(1) - getTexture(TEX_ROUGHNESS, coord, slope);
			specular *= roughness.r;
		}
	}

	// Albedo / Diffuse
	vec4 albedo = getTexture(TEX_ALBEDO, coord, slope);

	// Diffuse + Ambient
	vec4 diffuse = albedo * max(l_color * intensity, l_ambient);

	// Brightness Boost
	diffuse = clamp(diffuse * 2, 0, 1);

	// Specular Attenuation
	specular = specular * 0.4;

	// Color
	colorOut = clamp(diffuse + specular, 0, 1);
	//colorOut = max(intensity * diffuse + specular, diffuse * 0.4);
}