#version 420
 
layout(triangles) in;
layout (line_strip, max_vertices=6) out;

uniform mat4 m_pvm;
uniform	mat3 m_normal;

uniform sampler2D tex_grass_normal;
uniform float Texture_Freq;

in Data {
	vec3 normal;
	vec3 tangent;
	vec3 bitangent;
	vec2 texCoord;
} DataIn[3];

out Data {
	vec4 color;
} DataOut;

 void main()
{
	float scale = 3;

	// Normal
	gl_Position = m_pvm * gl_in[0].gl_Position;
	DataOut.color = vec4(1, 0, 0, 1);
    EmitVertex();
	gl_Position = m_pvm * (gl_in[0].gl_Position + vec4(scale * DataIn[0].normal, 0));
	DataOut.color = vec4(1, 0, 0, 1);
    EmitVertex();
	EndPrimitive();

	// Tangent
	gl_Position = m_pvm * gl_in[0].gl_Position;
	DataOut.color = vec4(0, 1, 0, 1);
    EmitVertex();
	gl_Position = m_pvm * (gl_in[0].gl_Position + vec4(scale * DataIn[0].tangent, 0));
	DataOut.color = vec4(0, 1, 0, 1);
    EmitVertex();
	EndPrimitive();

	// Bitangent
	gl_Position = m_pvm * gl_in[0].gl_Position;
	DataOut.color = vec4(0, 0, 1, 1);
    EmitVertex();
	gl_Position = m_pvm * (gl_in[0].gl_Position + vec4(scale * DataIn[0].bitangent, 0));
	DataOut.color = vec4(0, 0, 1, 1);
    EmitVertex();
	EndPrimitive();
}

