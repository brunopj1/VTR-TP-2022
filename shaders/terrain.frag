#version 330

in Data {
	flat float tes;
} DataIn;

out vec4 colorOut;

void main() {
	colorOut = vec4(DataIn.tes, DataIn.tes, DataIn.tes, 0);
}
