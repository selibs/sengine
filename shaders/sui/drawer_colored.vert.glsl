#version 450

uniform mat3 model;
uniform vec4 rect;

layout(location = 0) in vec2 vertCoord;
layout(location = 0) out vec2 fragCoord;

void main() {
	vec2 uv = vertCoord * 0.5 + 0.5;
	fragCoord = rect.xy + uv * rect.zw;
	gl_Position = vec4((model * vec3(fragCoord, 1.0)).xy, 0.0, 1.0);
}
