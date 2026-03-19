float GetLightAttenuation_Diffuse(float lightDist, const in float lightRange, const in float lightRadius) {
    lightDist = max(lightDist - lightRadius, 0.0);
    float lightDistF = 1.0 - saturate(lightDist / lightRange);

    float invSq = 1.0 / (_pow2(lightDist) + lightRadius);
    float linear = pow5(lightDistF);

    return mix(linear, invSq, lightDistF);
}

float D_GGX(float NoH, float alpha) {
    float a2 = alpha * alpha;
    float denom = (NoH * NoH) * (a2 - 1.0) + 1.0;
    return a2 / max(PI * denom * denom, 0.000002);
}

float V_Approx(float NoL, float NoV, float alpha) {
    return 0.5 / mix(2.0 * NoL * NoV, NoL + NoV, alpha);
}
