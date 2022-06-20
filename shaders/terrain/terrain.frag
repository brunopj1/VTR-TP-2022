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

// Triplanar Blending


// Get texture

vec4 getTexture(sampler2D tex_grass, sampler2D tex_dirt, vec2 coord, float f) {
	vec4 color_grass = texture(tex_grass, coord);
	vec4 color_dirt = texture(tex_dirt, coord);
	return mix(color_grass, color_dirt, f);
}

// Main

void main() {
	// Tex coord
	vec2 coord = DataIn.texCoord * Texture_Freq;

	// Normalize the data
	vec3 normal = normalize(DataIn.normal);
	vec3 light_dir = normalize(vec3(m_view * -l_dir));
	vec3 eye = normalize(vec3(- m_view * DataIn.position));

	// Calculate the slope
	float slope = clamp(1 - 2 * pow(DataIn.normal_world.y, 2) + 0.5, 0, 1);

	// Normal Mapping
	if (use_normal_mapping > 0) {
		mat3 tbn = mat3(DataIn.tangent, DataIn.bitangent, DataIn.normal);
		vec4 normal_tex = getTexture(tex_grass_normal, tex_dirt_normal, coord, slope);
		normal = normalize(vec3(normal_tex * 2.0 - 1.0));
		normal = tbn * normal;
	}

	// Light Intensity
	float intensity = max(dot(normal, light_dir), 0.0);

	// Ambient Occlusion
	if (use_ao_mapping > 0) {
		vec4 ao = getTexture(tex_grass_ao, tex_dirt_ao, coord, slope);
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
			vec4 roughness = vec4(1) - getTexture(tex_grass_roughness, tex_dirt_roughness, coord, slope);
			specular *= roughness.r;
		}
	}

	// Albedo / Diffuse
	vec4 albedo = getTexture(tex_grass_albedo, tex_dirt_albedo, coord, slope);

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