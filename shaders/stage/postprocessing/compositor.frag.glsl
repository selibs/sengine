#version 450

#define FXAA_SPAN_MAX 8.0
#define FXAA_REDUCE_MUL   (0.25 / FXAA_SPAN_MAX)
#define FXAA_REDUCE_MIN   (1.0 / 32.0)
#define FXAA_SUBPIX_SHIFT 0.75

uniform sampler2D textureMap;
uniform float params[7];
#define posterizeGamma params[0]
#define posterizeSteps params[1]
#define vignetteStrength params[2]
#define vignetteColor vec4(params[3], params[4], params[5], params[6])

layout(location = 0) in vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

vec3 posterize(vec3 col, float gamma, float steps) {
    col = pow(col, vec3(gamma));
    col = floor(col * steps) / steps;
    col = pow(col, vec3(1.0 / gamma));
    return col;
}

float vignette(vec2 coord) {
    coord *= 1.0 - coord.yx;
    return pow(coord.x * coord.y * 15.5, vignetteStrength);
}

void main() {
    // aa
    vec3 color = texture(textureMap, fragCoord).rgb;

    // posterize
    color = posterize(color, posterizeGamma, posterizeSteps);

    // vignette
    float vignetteFactor = vignette(fragCoord);
    color = mix(vignetteColor.rgb, color, vignetteFactor * vignetteColor.a);

    fragColor = vec4(color, 1.0);
}
