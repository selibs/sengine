#version 450

uniform vec4 color;
uniform sampler2D source;

layout(location = 1) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = texture(source, fragUV) * color;
}
