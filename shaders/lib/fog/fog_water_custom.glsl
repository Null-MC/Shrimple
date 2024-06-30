vec3 GetCustomWaterFogColor(const in float sunUpF) {
    //const vec3 _color = RGBToLinear(vec3(0.143, 0.230, 0.258));

    const float WaterMinBrightness = 0.04;

    float brightnessF = 1.0 - WaterMinBrightness;

    #ifdef WORLD_SKY_ENABLED
        float skyBrightness = smoothstep(-0.1, 0.3, sunUpF) * Sky_SunBrightnessF;
        float weatherBrightness = 1.0 - 0.92 * rainStrength;
        float eyeBrightness = eyeBrightnessSmooth.y / 240.0;

        brightnessF *= skyBrightness * weatherBrightness * eyeBrightness;
    #endif

    vec3 color = 2.0 * RGBToLinear(WaterScatterColor) * RGBToLinear(WaterAbsorbColor);
    color = color / (color + 1.0);

    return color * (WaterMinBrightness + brightnessF);
}

float GetCustomWaterFogFactor(const in float fogDist) {
    float waterFogFar = min(16.0 / WaterDensityF, far);

    #if WATER_VOL_FOG_TYPE != VOL_TYPE_NONE
        float waterFogNear = 0.65 * waterFogFar;
        const float waterFogPower = 1.0;
    #else
        const float waterFogNear = 0.0;
        const float waterFogPower = 0.65;
    #endif

    return GetFogFactor(fogDist, waterFogNear, waterFogFar, waterFogPower);
}
