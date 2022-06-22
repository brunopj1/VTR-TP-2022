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

// Texture Tiling Fix

vec4 hash4( vec2 p ) { 
	return fract(sin(
		vec4(
			1.0+dot(p,vec2(37.0,17.0)), 
			2.0+dot(p,vec2(11.0,47.0)),
			3.0+dot(p,vec2(41.0,29.0)),
			4.0+dot(p,vec2(23.0,31.0))
		)) * 103.0);
}

void getTextureNoTileCoords(vec2 coord, out vec2[4] uv, out vec2[4] ddx, out vec2[4] ddy, out vec2 blend) {
	vec2 iuv = floor( coord );
    vec2 fuv = fract( coord );
   
    // generate per-tile transform
    vec4 ofa = hash4( iuv + vec2(0.0,0.0) );
    vec4 ofb = hash4( iuv + vec2(1.0,0.0) );
    vec4 ofc = hash4( iuv + vec2(0.0,1.0) );
    vec4 ofd = hash4( iuv + vec2(1.0,1.0) );

    vec2 _ddx = dFdx( coord );
    vec2 _ddy = dFdy( coord );

    // transform per-tile uvs
    ofa.zw = sign(ofa.zw-0.5);
    ofb.zw = sign(ofb.zw-0.5);
    ofc.zw = sign(ofc.zw-0.5);
    ofd.zw = sign(ofd.zw-0.5);
    
    // uv's, and derivarives (for correct mipmapping)
    uv[0] = coord * ofa.zw + ofa.xy; ddx[0] = _ddx * ofa.zw; ddy[0] = _ddy * ofa.zw;
    uv[1] = coord * ofb.zw + ofb.xy; ddx[1] = _ddx * ofb.zw; ddy[1] = _ddy * ofb.zw;
    uv[2] = coord * ofc.zw + ofc.xy; ddx[2] = _ddx * ofc.zw; ddy[2] = _ddy * ofc.zw;
    uv[3] = coord * ofd.zw + ofd.xy; ddx[3] = _ddx * ofd.zw; ddy[3] = _ddy * ofd.zw;
        
    // fetch and blend
    blend = smoothstep(0.25,0.75,fuv);
}

vec4 textureNoTile(sampler2D tex, vec2[4] uv, vec2[4] ddx, vec2[4] ddy, vec2 blend) {
    return mix( mix( textureGrad( tex, uv[0], ddx[0], ddy[0] ), 
                     textureGrad( tex, uv[1], ddx[1], ddy[1] ), blend.x ), 
                mix( textureGrad( tex, uv[2], ddx[2], ddy[2] ),
                     textureGrad( tex, uv[3], ddx[3], ddy[3] ), blend.x), blend.y );
}

// Get texture

vec4 getTexture(sampler2D tex_grass, sampler2D tex_dirt,          // Textures to use
                vec2[4] uv, vec2[4] ddx, vec2[4] ddy, vec2 blend, // Texture no tiling
				float f) {                                        // Texture blending
	vec4 color_grass = textureNoTile(tex_grass, uv, ddx, ddy, blend); // texture(tex_grass, coord);
	vec4 color_dirt = textureNoTile(tex_dirt, uv, ddx, ddy, blend);// texture(tex_dirt, coord);
	return mix(color_grass, color_dirt, f);
}

// Main

void main() {
	// Tex coord
	vec2[4] uv, ddx, ddy; vec2 blend;
	vec2 coord = DataIn.texCoord * Texture_Freq;
	getTextureNoTileCoords(coord, uv, ddx, ddy, blend);

	// Normalize the data
	vec3 normal = normalize(DataIn.normal);
	vec3 light_dir = normalize(vec3(m_view * -l_dir));
	vec3 eye = normalize(vec3(- m_view * DataIn.position));

	// Calculate the slope
	float slope = clamp(1 - 2 * pow(DataIn.normal_world.y, 2) + 0.5, 0, 1);

	// Normal Mapping
	if (use_normal_mapping > 0) {
		mat3 tbn = mat3(DataIn.tangent, DataIn.bitangent, DataIn.normal);
		vec4 normal_tex = getTexture(tex_grass_normal, tex_dirt_normal, uv, ddx, ddy, blend, slope);
		normal = normalize(vec3(normal_tex * 2.0 - 1.0));
		normal = tbn * normal;
	}

	// Light Intensity
	float intensity = max(dot(normal, light_dir), 0.0);

	// Ambient Occlusion
	if (use_ao_mapping > 0) {
		vec4 ao = getTexture(tex_grass_ao, tex_dirt_ao, uv, ddx, ddy, blend, slope);
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
			vec4 roughness = vec4(1) - getTexture(tex_grass_roughness, tex_dirt_roughness, uv, ddx, ddy, blend, slope);
			specular *= roughness.r;
		}
	}

	// Albedo / Diffuse
	vec4 albedo = getTexture(tex_grass_albedo, tex_dirt_albedo, uv, ddx, ddy, blend, slope);

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