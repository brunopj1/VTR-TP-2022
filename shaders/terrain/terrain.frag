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

vec3 getTriPlanarBlend(vec3 normal){
	// in wNorm is the world-space normal of the fragment
	vec3 blending = abs( normal );
	blending = normalize(max(blending, 0.00001)); // Force weights to sum to 1.0
	float b = (blending.x + blending.y + blending.z);
	blending /= vec3(b, b, b);
	return blending;
}

vec4 getTriPlanarColor(sampler2D tex, vec3 coord, vec3 blend) {
	vec3 x_axis = vec3(texture(tex, coord.yz));
	vec3 y_axis = vec3(texture(tex, coord.xz));
	vec3 z_axis = vec3(texture(tex, coord.xy));
	return vec4(x_axis * blend.x + y_axis * blend.y + z_axis * blend.z, 0);
}

// Get texture

vec4 getTexture(sampler2D tex_grass, sampler2D tex_dirt, vec3 coord, vec3 blend, float f) {
	vec4 color_grass = getTriPlanarColor(tex_grass, coord, blend);
	vec4 color_dirt = getTriPlanarColor(tex_dirt, coord, blend);
	return mix(color_grass, color_dirt, f);
}

// Main

void main() {
	// Tex coord
	vec3 coord = DataIn.position.xyz * 0.001 * Texture_Freq;
	vec3 blend = getTriPlanarBlend(DataIn.normal_world);

	// Normalize the data
	vec3 normal = normalize(DataIn.normal);
	vec3 light_dir = normalize(vec3(m_view * -l_dir));
	vec3 eye = normalize(vec3(- m_view * DataIn.position));

	// Calculate the slope
	float slope = clamp(1 - 2 * pow(DataIn.normal_world.y, 2) + 0.5, 0, 1);

	// Normal Mapping
	if (use_normal_mapping > 0) {
		mat3 tbn = mat3(DataIn.tangent, DataIn.bitangent, DataIn.normal);
		vec4 normal_tex = getTexture(tex_grass_normal, tex_dirt_normal, coord, blend, slope);
		normal = normalize(vec3(normal_tex * 2.0 - 1.0));
		normal = tbn * normal;
	}

	// Light Intensity
	float intensity = max(dot(normal, light_dir), 0.0);

	// Ambient Occlusion
	if (use_ao_mapping > 0) {
		vec4 ao = getTexture(tex_grass_ao, tex_dirt_ao, coord, blend, slope);
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
			vec4 roughness = vec4(1) - getTexture(tex_grass_roughness, tex_dirt_roughness, coord, blend, slope);
			specular *= roughness.r;
		}
	}

	// Albedo / Diffuse
	vec4 albedo = getTexture(tex_grass_albedo, tex_dirt_albedo, coord, blend, slope);

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