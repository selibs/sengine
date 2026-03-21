#version 450

uniform sampler2D textureMap;

layout(location = 0) in vec2 fragUV;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 color = texture(textureMap, fragUV);
    fragColor = vec4(color.rgb * color.a, color.a);
}
