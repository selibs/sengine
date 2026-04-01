#version 450

uniform mat3 mvp;

layout(location = 0) in vec2 vertPos;
layout(location = 1) in vec2 vertUV;
layout(location = 0) out vec2 fragUV;

void main() {
    fragUV = vertUV;
    gl_Position = vec4((mvp * vec3(vertPos, 1.0)).xy, 0.0, 1.0);
}
