#version 450

uniform mat3 mvp;
uniform vec4 rect;

layout(location = 0) in vec2 vertPos;
layout(location = 0) out vec2 fragPos;
layout(location = 1) out vec2 fragUV;

void main() {
    fragUV = vec2(vertPos.x, 1.0 - vertPos.y);
    fragPos = rect.xy + fragUV * rect.zw;
    
    vec3 pos = mvp * vec3(rect.xy + vertPos * rect.zw, 1.0);
    gl_Position = vec4(pos.xy, 0.0, 1.0);
}

