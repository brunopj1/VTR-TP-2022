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

float getHeight(vec2 pos) {
	return texture(texHeightmap, pos).r * T_Height;
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
	float deltaX = 1 / float(heightmap_width);
	float deltaZ = 1 / float(heightmap_height);

	vec2 L = texCoord - vec2(deltaX, 0);
	vec2 R = texCoord + vec2(deltaX, 0);
	vec2 D = texCoord - vec2(0, deltaZ);
	vec2 U = texCoord + vec2(0, deltaZ);

	vec3 dirX = vec3(R.x - L.x, getHeight(R) - getHeight(L),     0    );
	vec3 dirZ = vec3(    0    , getHeight(D) - getHeight(U), D.y - U.y);

	DataOut.normal = normalize(m_normal * normalize(cross(dirZ, dirX)));
}

