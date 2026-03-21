#version 450

uniform vec4 color;
uniform vec2 start;
uniform vec2 end;
uniform sampler2D gradient;

layout(location = 0) in vec2 fragPos;
layout(location = 1) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

void main() {
    float t = distance(start, fragPos) / distance(start, end);
    fragColor = texture(gradient, vec2(0.5, t)) * color;
}
