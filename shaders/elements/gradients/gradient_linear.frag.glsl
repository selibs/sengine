#version 450

uniform vec4 color;
uniform vec2 start;
uniform vec2 end;
uniform sampler2D gradient;

layout(location = 0) in vec2 fragPos;
layout(location = 1) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

void main() {
    vec2 dir = end - start;
    float dirLenSq = max(dot(dir, dir), 0.000001);
    float t = clamp(dot(fragPos - start, dir) / dirLenSq, 0.0, 1.0);
    fragColor = texture(gradient, vec2(t, 0.5)) * color;
}
