#version 450

#define gamma vec3(5.2)
#define invGamma (1.0 / gamma)

#ifdef S2D_PP_DOF_QUALITY
#if S2D_PP_DOF_QUALITY == 0
#define quality 4.0
#elif S2D_PP_DOF_QUALITY == 1
#define quality 8.0
#else
#define quality 16.0
#endif
#else
#define quality 4.0
#endif

uniform sampler2D depthMap;
uniform sampler2D textureMap;
uniform float focusDistance;
uniform float blurSize;

layout(location = 0) in vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

vec3 blur(sampler2D tex, vec2 uv, float size, float ratio) {
    vec3 col = vec3(0.0);
    float W = 0.0;

    for (float y = -1.0; y <= 1.0; y += 1.0 / quality) {
        for (float x = -1.0; x <= 1.0; x += 1.0 / quality) {
            vec2 p = vec2(x, y);
            vec2 offset = p * size * vec2(1.0, ratio);

            float w = 1.0 - smoothstep(0.0, 1.0, length(p));
            col += pow(texture(tex, uv + offset).rgb, gamma) * w;
            W += w;
        }
    }

    return pow(col / W, invGamma);
}

void main() {
    vec2 R = textureSize(textureMap, 0);
    float depth = texture(depthMap, fragCoord).r;
    float f = abs(depth - focusDistance);
    vec3 color = blur(textureMap, fragCoord, f * blurSize, R.x / R.y);

    fragColor = vec4(color, 1.0);
}
