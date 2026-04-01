#version 450

uniform vec4 color;

layout(location = 0) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = color;
}
