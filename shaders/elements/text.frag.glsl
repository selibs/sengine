#version 450

uniform vec4 color;
uniform sampler2D source;

layout(location = 1) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

void main() {
    float distance = texture(source, fragUV).r;
    float smoothing = max(fwidth(distance) * 1.0, 1.0 / 128.0);
    float alpha = smoothstep(0.5 - smoothing, 0.5 + smoothing, distance);
    fragColor = vec4(color.rgb, color.a * alpha);
}
