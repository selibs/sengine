#version 450

layout(location = 0) in float fragOpacity;
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = vec4(vec3(0.0), fragOpacity);
}
