#version 450

uniform mat3 model;
uniform mat3 projection;
uniform vec4 rect;

layout(location = 0) in vec2 vertPos;
layout(location = 0) out vec2 fragPos;
layout(location = 1) out vec2 fragUV;

void main() {
    fragUV = vertPos * 0.5 + 0.5;

    vec2 pos = rect.xy + fragUV * rect.zw;
    vec2 invPos = vec2(pos.x, rect.y + rect.w - (pos.y - rect.y));

    fragPos = (model * vec3(invPos, 1.0)).xy;
    gl_Position = vec4((projection * vec3((model * vec3(pos, 1.0)).xy, 1.0)).xy, 0.0, 1.0);
}

