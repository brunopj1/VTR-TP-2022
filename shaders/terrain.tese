#version 410

layout(triangles, fractional_even_spacing, ccw) in;

uniform	mat4 m_pvm;

uniform float T_Length;
uniform int T_Chunks;
uniform float T_Height;
uniform float T_Freq;

in Data {
	vec3 pos;
	flat float tes;
} DataIn[];

out Data {
	flat float tes;
} DataOut;

float rand(float n) { 
	return fract(sin(n) * 43758.5453123);
}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
	vec2 b = floor(n);
	vec2 f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

void main() {

	DataOut.tes = DataIn[0].tes;

	vec3 pos = 
		DataIn[0].pos * gl_TessCoord.x +
		DataIn[1].pos * gl_TessCoord.y +
		DataIn[2].pos * gl_TessCoord.z;

	pos.y = noise(pos.xz * T_Freq * 0.01) * 0.5 * T_Height;

	gl_Position = m_pvm * vec4(pos, 1.0);
}

