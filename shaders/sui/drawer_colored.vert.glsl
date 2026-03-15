#version 450

uniform mat3 model;
uniform vec2 viewport;

layout(location = 0) in vec2 vertCoord;
layout(location = 0) out vec2 fragCoord;

void main() {
    vec3 transformed = model * vec3(vertCoord, 1.0);
    gl_Position = vec4(transformed.xy, 0.0, 1.0);
    vec2 uv = transformed.xy * 0.5 + 0.5;
    fragCoord = vec2(uv.x * viewport.x, (1.0 - uv.y) * viewport.y);
}
