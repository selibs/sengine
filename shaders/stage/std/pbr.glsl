const float PI = 3.14159;

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    float factor = pow(1.0 - cosTheta, 5.0);
    return F0 + (1.0 - F0) * factor;
}

float distributionGGX(vec3 N, vec3 H, float roughnessE2) {
    float a = roughnessE2;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float denom = NdotH * (a2 - 1.0) + 1.0;
    return a2 / (PI * (denom * denom + 1e-4));
}

float geometrySchlickGGX(float NdotX, float k) {
    return NdotX / (NdotX * (1.0 - k) + k);
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughnessE2) {
    float k = roughnessE2 * 0.5;
    return geometrySchlickGGX(max(dot(N, V), 0.0), k) *
        geometrySchlickGGX(max(dot(N, L), 0.0), k);
}
