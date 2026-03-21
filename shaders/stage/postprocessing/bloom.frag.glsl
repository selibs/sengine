#version 450

uniform sampler2D textureMap;
uniform vec2 resolution;
uniform vec3 params;
#define radius params[0]
#define threshold params[1]
#define intensity params[2]

layout(location = 0) in vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

vec3 bloom(sampler2D tex, vec2 uv) {
    vec2 texelSize = radius / resolution;

    vec3 col = vec3(0.0);
    col += texture(tex, uv + vec2(-1.0, -1.0) * texelSize, radius).rgb * (1.0 / 16.0);
    col += texture(tex, uv + vec2(0.0, -1.0) * texelSize, radius).rgb * (1.0 / 8.0);
    col += texture(tex, uv + vec2(1.0, -1.0) * texelSize, radius).rgb * (1.0 / 16.0);

    col += texture(tex, uv + vec2(-1.0, 0.0) * texelSize, radius).rgb * (1.0 / 8.0);
    col += texture(tex, uv + vec2(0.0, 0.0) * texelSize, radius).rgb * (1.0 / 4.0);
    col += texture(tex, uv + vec2(1.0, 0.0) * texelSize, radius).rgb * (1.0 / 8.0);

    col += texture(tex, uv + vec2(-1.0, 1.0) * texelSize, radius).rgb * (1.0 / 16.0);
    col += texture(tex, uv + vec2(0.0, 1.0) * texelSize, radius).rgb * (1.0 / 8.0);
    col += texture(tex, uv + vec2(1.0, 1.0) * texelSize, radius).rgb * (1.0 / 16.0);

    return col;
}

void main() {
    vec3 col = texture(textureMap, fragCoord).rgb;
    vec3 bloom = clamp(bloom(textureMap, fragCoord) - threshold, 0.0, 1.0) * 1.0 / (1.0 - threshold);
    fragColor = vec4(1.0 - (1.0 - col) * (1.0 - bloom * intensity), 1.0);
}
