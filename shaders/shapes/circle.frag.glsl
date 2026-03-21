#version 450

uniform vec4 color;
uniform vec4 rect;
uniform float radius;
uniform float borderWidth;
uniform vec4 borderColor;

uniform vec2 center;

#define softness 0.5

layout(location = 0) in vec2 fragPos;
layout(location = 1) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

float sdf(vec2 p, vec2 center, float r) {
    return length(p - center) - r;
}

void main() {
    float maxRadius = min(rect.z, rect.w) * 0.5;
    float r = clamp(radius, 0.0, maxRadius);
    float dist = sdf(fragPos, center, r);

    float fill = 1.0 - smoothstep(-softness, softness, dist);
    float border = clamp(fill - (1.0 - smoothstep(-softness, softness, dist + borderWidth)), 0.0, 1.0);

    float fillAlpha = color.a * (fill - border);
    float borderAlpha = borderColor.a * border;

    vec4 fillColor = vec4(color.rgb * fillAlpha, fillAlpha);
    vec4 strokeColor = vec4(borderColor.rgb * borderAlpha, borderAlpha);

    fragColor = strokeColor + fillColor * (1.0 - strokeColor.a);
}
