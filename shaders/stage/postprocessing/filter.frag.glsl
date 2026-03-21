#version 450

uniform sampler2D textureMap;
uniform mat3 kernel;

layout(location = 0) in vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

vec3 convolve3x3(sampler2D tex, vec2 coord, mat3 kernel) {
    vec2 R = textureSize(textureMap, 0);
    vec2 texelSize = 1.0 / R;

    vec3 col = vec3(0.0);
    vec2 offset;
    for (int i = 0; i < 3; i++) {
        offset.x = texelSize.x * (i - 1);
        for (int j = 0; j < 3; j++) {
            offset.y = texelSize.y * (j - 1);
            col += texture(tex, coord + offset).rgb * kernel[i][j];
        }
    }
    return col;
}

void main() {
    vec3 col = convolve3x3(textureMap, fragCoord, kernel);
    fragColor = vec4(col, 1.0);
}
