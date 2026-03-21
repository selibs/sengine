#version 450

uniform mat3 VP;
uniform vec2 lightPos;

layout(location = 0) in vec4 vertData;
#define vertPos vertData.xy
#define depth vertData.z
#define factor vertData.w
layout(location = 1) in float opacity;
layout(location = 0) out float fragOpacity;

void main() {
    vec2 dir = vertPos - lightPos;
    vec2 pos = vertPos + dir * factor * 100;
    gl_Position = vec4((VP * vec3(pos, 1.0)).xy, depth, 1.0);
    fragOpacity = opacity;
}
