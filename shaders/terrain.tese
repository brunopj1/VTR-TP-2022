#version 410

layout(triangles, fractional_even_spacing, ccw) in;

uniform	mat4 m_pvm;
uniform mat3 m_normal;

uniform vec2 viewport_size;

uniform float Terrain_Height;
uniform float Noise_Freq;

in Data {
	vec4 pos;
	vec2 texCoord;
} DataIn[];

out Data {
	float noise;
	vec3 normal;
	vec2 texCoord;
} DataOut;

// Noise Aux Functions

float rand(float n) { return fract(sin(n) * 43758.5453123); }

float rand(vec2 n) { return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453); }

float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float PI = 3.14159265358979323846;

// Noise Functions
	
float genericNoise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
	vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float simplexNoise(vec2 v){
	const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
	vec2 i  = floor(v + dot(v, C.yy) );
	vec2 x0 = v -   i + dot(i, C.xx);
	vec2 i1;
	i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod(i, 289.0);
	vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 )) + i.x + vec3(0.0, i1.x, 1.0 ));
	vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
	m = m*m ;
	m = m*m ;
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
	vec3 g;
	g.x  = a0.x  * x0.x  + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}

float perlinNoiseAux(vec2 p, float freq ){
	float unit = viewport_size.x / freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float perlinNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*perlinNoiseAux(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

float getNoise(vec2 pos) {
	return simplexNoise(pos * Noise_Freq);
}

// Main

void main() {
	// TexCoord
	vec2 texCoord = 
		DataIn[0].texCoord * gl_TessCoord.x +
		DataIn[1].texCoord * gl_TessCoord.y +
		DataIn[2].texCoord * gl_TessCoord.z;
		
	DataOut.texCoord = texCoord;

	// Noise
	DataOut.noise = getNoise(texCoord);

	// Position
	vec4 pos = 
		DataIn[0].pos * gl_TessCoord.x +
		DataIn[1].pos * gl_TessCoord.y +
		DataIn[2].pos * gl_TessCoord.z;

	gl_Position = m_pvm * (pos + vec4(0, DataOut.noise * Terrain_Height, 0, 0));

	// Normal
	DataOut.normal = vec3(0, 1, 0);
}

