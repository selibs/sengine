#version 450

uniform vec4 color;
uniform vec2 start;
uniform vec2 end;
uniform sampler2D gradient;

layout(location = 0) in vec2 fragPos;
layout(location = 1) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

const float PI = 3.14159265358979323846;
const float TAU = 6.28318530717958647692;

void main() {
    vec2 dir = end - start;
    float baseAngle = atan(dir.y, dir.x);
    vec2 delta = fragPos - start;
    float angle = atan(delta.y, delta.x);
    float t = fract((angle - baseAngle) / TAU);
    fragColor = texture(gradient, vec2(0.5, t)) * color;
}
