#version 330

uniform sampler2D tex_skybox;

in vec2 texCoord;

out vec4 colorOut;

void main() {
    colorOut = texture(tex_skybox, texCoord);
    //colorOut = vec4(texCoord, 0, 1);
}