#version 410

layout(triangles, fractional_even_spacing, ccw) in;

uniform	mat4 m_pvm;
uniform mat3 m_normal;

uniform sampler2D texHeightmap;
uniform int heightmap_width;
uniform int heightmap_height;

uniform float T_Height;
uniform float T_Freq;

in Data {
	vec4 pos;
	vec2 texCoord;
} DataIn[];

out Data {
	vec3 normal;
	vec2 texCoord;
} DataOut;

vec2 texCoordToPixel = vec2(heightmap_width, heightmap_height);
vec2 pixelToTexCoord = 1.0 / vec2(heightmap_width, heightmap_height);

float getHeight(vec2 pos) {
	vec2 pixel = pos * texCoordToPixel;
	ivec2 pixel_i = ivec2(pixel);
	vec2 fraction = pixel - pixel_i;

	float h_00 = texture(texHeightmap, (pixel_i              ) * pixelToTexCoord).r;
	float h_01 = texture(texHeightmap, (pixel_i + ivec2(0, 1)) * pixelToTexCoord).r;
	float h_10 = texture(texHeightmap, (pixel_i + ivec2(1, 0)) * pixelToTexCoord).r;
	float h_11 = texture(texHeightmap, (pixel_i + ivec2(1, 1)) * pixelToTexCoord).r;

	return mix(mix(h_00, h_01, fraction.y), mix(h_10, h_11, fraction.y), fraction.x) * T_Height;
	//return texture(texHeightmap, pos).r * T_Height;
	// (noise(pos.xz * T_Freq * 0.01) * 0.5 + 0.5) * T_Height
}

void main() {

	// TexCoord
	vec2 texCoord = 
		DataIn[0].texCoord * gl_TessCoord.x +
		DataIn[1].texCoord * gl_TessCoord.y +
		DataIn[2].texCoord * gl_TessCoord.z;
		
	DataOut.texCoord = texCoord;

	// Position
	vec4 pos = 
		DataIn[0].pos * gl_TessCoord.x +
		DataIn[1].pos * gl_TessCoord.y +
		DataIn[2].pos * gl_TessCoord.z;

	pos.y = getHeight(texCoord);
	gl_Position = m_pvm * pos;

	// Normal
	vec2 L = texCoord - vec2(pixelToTexCoord.x, 0);
	vec2 R = texCoord + vec2(pixelToTexCoord.x, 0);
	vec2 D = texCoord - vec2(0, pixelToTexCoord.y);
	vec2 U = texCoord + vec2(0, pixelToTexCoord.y);

	vec3 dirX = vec3(R.x - L.x, getHeight(R) - getHeight(L),     0    );
	vec3 dirZ = vec3(    0    , getHeight(D) - getHeight(U), D.y - U.y);

	DataOut.normal = normalize(m_normal * normalize(cross(dirZ, dirX)));
}

