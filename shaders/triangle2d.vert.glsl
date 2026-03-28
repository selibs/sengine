#version 450

uniform mat3 mvp;

layout(location = 0) in vec2 vertPos;
layout(location = 1) in vec2 vertUV;

void main() {
    gl_Position = vec4((mvp * vec3(vertPos, 1.0)).xy, 0.0, 1.0);
}
