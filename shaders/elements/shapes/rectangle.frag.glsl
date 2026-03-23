#version 450

uniform vec4 color;
uniform vec4 rect;
uniform float radius;
uniform float borderWidth;
uniform vec4 borderColor;

#define softness 0.5

layout(location = 0) in vec2 fragPos;
layout(location = 0) out vec4 fragColor;

float sdf(vec2 center, vec2 size) {
    vec2 q = abs(center) - size + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void main() {
    vec2 halfSize = rect.zw * 0.5;
    vec2 center = rect.xy + halfSize;
    float dist = sdf(fragPos - center, halfSize);

    float fill = 1.0 - smoothstep(-softness, softness, dist);
    float border = clamp(fill - (1.0 - smoothstep(-softness, softness, dist + borderWidth)), 0.0, 1.0);

    float fillAlpha = color.a * (fill - border);
    float borderAlpha = borderColor.a * border;

    vec4 fillColor = vec4(color.rgb * fillAlpha, fillAlpha);
    vec4 bordColor = vec4(borderColor.rgb * borderAlpha, borderAlpha);

    fragColor = bordColor + fillColor * (1.0 - bordColor.a);
}
