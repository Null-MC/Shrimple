void AddLpvLight(const in ivec3 imgCoord, const in vec3 lightColor, const in float lightRange) {
    if (clamp(imgCoord, ivec3(0), ivec3(SceneLPVSize-1)) != imgCoord) return;

    vec4 lightValue = vec4(0.0);
    lightValue.rgb = RgbToHsv(lightColor);
    lightValue.b = lightRange / LPV_BLOCKLIGHT_SCALE;

    if (frameCounter % 2 == 0)
        imageStore(imgSceneLPV_2, imgCoord, lightValue);
    else
        imageStore(imgSceneLPV_1, imgCoord, lightValue);
}
