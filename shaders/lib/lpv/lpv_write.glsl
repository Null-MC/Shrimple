void AddLpvLight(const in ivec3 imgCoord, const in vec3 lightColor, const in float lightRange) {
    if (clamp(imgCoord, ivec3(0), ivec3(SceneLPVSize-1)) != imgCoord) return;

    vec3 hsv = RgbToHsv(lightColor);
    hsv.z = lightRange / LpvBlockSkyRange.x;
    vec4 lightValue = vec4(HsvToRgb(hsv), 0.0);

    if (frameCounter % 2 == 0)
        imageStore(imgSceneLPV_2, imgCoord, lightValue);
    else
        imageStore(imgSceneLPV_1, imgCoord, lightValue);
}
