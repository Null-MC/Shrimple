float GetLightAttenuation_Diffuse(float lightDist, const in float lightRange, const in float lightRadius) {
    lightDist = max(lightDist - lightRadius, 0.0);
    float lightDistF = 1.0 - saturate(lightDist / lightRange);

    float invSq = 1.0 / (_pow2(lightDist) + lightRadius);
    float linear = pow5(lightDistF);

    return mix(linear, invSq, lightDistF);
}

vec3 GetAreaLightDir(const in vec3 viewNormal, const in vec3 viewDir, const in vec3 lightDir, const in float lightDist, const in float lightSize) {
    vec3 r = reflect(viewDir, viewNormal);
    vec3 L = lightDir * lightDist;
    vec3 centerToRay = dot(L, r) * r - L;
    vec3 closestPoint = centerToRay * saturate(lightSize / length(centerToRay)) + L;
    return normalize(closestPoint);
}

float D_GGX(const in float NoH, const in float alpha) {
//    float a2 = alpha * alpha;
//    float denom = (NoH * NoH) * (a2 - 1.0) + 1.0;
//    return a2 / max(PI * denom * denom, 0.000002);
    float a2 = alpha * alpha;
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * f * f);
}

float V_Approx(const in float NoL, const in float NoV, const in float alpha) {
//    return 0.5 / mix(2.0 * NoL * NoV, NoL + NoV, alpha);
    float k = (alpha + 1.0) * (alpha + 1.0) / 8.0;
    float G_V = NoV / (NoV * (1.0 - k) + k);
    float G_L = NoL / (NoL * (1.0 - k) + k);
    return G_V * G_L;
}
