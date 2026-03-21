#version 450

uniform vec4 color;
uniform vec4 rect;
uniform float radius;
uniform float borderWidth;
uniform vec4 borderColor;

uniform vec2 center;
uniform vec2 scale;

#define softness 0.5

layout(location = 0) in vec2 fragPos;
layout(location = 1) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

float sdf(vec2 p, vec2 c, vec2 r) {
    vec2 q = (p - c) / r;
    return (length(q) - 1.0) * min(r.x, r.y);
}

void main() {
    vec2 s = max(abs(scale), vec2(1e-5));
    float maxRadius = min(rect.z / (2.0 * s.x), rect.w / (2.0 * s.y));
    float baseRadius = clamp(radius, 0.0, maxRadius);
    vec2 radii = baseRadius * s;
    float dist = sdf(fragPos, center, radii);

    float fill = 1.0 - smoothstep(-softness, softness, dist);
    float border = clamp(fill - (1.0 - smoothstep(-softness, softness, dist + borderWidth)), 0.0, 1.0);

    float fillAlpha = color.a * (fill - border);
    float borderAlpha = borderColor.a * border;

    vec4 fillColor = vec4(color.rgb * fillAlpha, fillAlpha);
    vec4 strokeColor = vec4(borderColor.rgb * borderAlpha, borderAlpha);

    fragColor = strokeColor + fillColor * (1.0 - strokeColor.a);
}
