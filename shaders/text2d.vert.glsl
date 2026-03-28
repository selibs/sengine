#version 450

uniform mat3 mvp;
uniform vec4 rect;
uniform vec4 clipRect;
uniform float italicSlant;

layout(location = 0) in vec2 vertPos;
layout(location = 1) in vec2 vertUV;
layout(location = 1) out vec2 fragUV;

void main() {
    fragUV = clipRect.xy + vertPos * clipRect.zw;

    vec2 local = vertPos * rect.zw;
    local.x += italicSlant * (1.0 - vertPos.y) * rect.w;

    gl_Position = vec4((mvp * vec3(rect.xy + local, 1.0)).xy, 0.0, 1.0);
}
