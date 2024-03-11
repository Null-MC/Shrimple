void AddLpvLight(const in ivec3 imgCoord, const in vec3 lightColor, const in float lightRange) {
    if (clamp(imgCoord, ivec3(0), ivec3(SceneLPVSize-1)) != imgCoord) return;

    // lightValue.rgb = lightColor * (exp2(lightRange * DynamicLightRangeF) - 1.0);
    // lightValue.rgb = _pow2(lightColor) * (exp2(lightRange * DynamicLightRangeF) - 1.0);

    // float range2 = exp2(lightRange * DynamicLightRangeF);

    vec4 lightValue = vec4(0.0);
    lightValue.rgb = RgbToHsv(lightColor);
    // lightValue.b *= max(range2 - 1.0, 0.0);
    lightValue.b = lightRange / LPV_VALUE_SCALE;

    if (frameCounter % 2 == 0)
        imageStore(imgSceneLPV_2, imgCoord, lightValue);
    else
        imageStore(imgSceneLPV_1, imgCoord, lightValue);
}
