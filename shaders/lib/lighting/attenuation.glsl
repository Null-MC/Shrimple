float GetLightAttenuation(float lightDist, const in float lightRange, const in float lightRadius) {
    lightDist = max(lightDist - lightRadius, 0.0);
    float lightDistF = 1.0 - saturate(lightDist / lightRange);

    float invSq = 1.0 / (_pow2(lightDist) + lightRadius);
    float linear = pow5(lightDistF);

    return mix(linear, invSq, lightDistF);
}
