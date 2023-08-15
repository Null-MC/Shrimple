float SampleWaterCaustics(const in vec3 localPos) {
    float causticTime = 0.5 * frameTimeCounter;

    vec3 shadowViewPos = localPos + fract(cameraPosition*0.01)*100.0 + vec3(1.0, 0.25, 0.0) * Water_WaveStrength * causticTime;
    shadowViewPos = mat3(shadowModelViewEx) * shadowViewPos;

    vec3 causticCoord = vec3(0.1/Water_WaveStrength * shadowViewPos.xy, causticTime);
    float causticLight = textureLod(texCaustics, causticCoord.yxz, 0).r;
    return RGBToLinear(causticLight);
}
