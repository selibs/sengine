#version 450

layout(location = 0) in vec2 vertCoord;
layout(location = 0) out vec2 fragCoord;

void main() {
    gl_Position = vec4(vertCoord, 0.0, 1.0);
    fragCoord = vertCoord * 0.5 + 0.5;
}
