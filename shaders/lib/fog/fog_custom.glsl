const vec3 colorSkyDay     = RGBToLinear(vec3(0.342, 0.542, 0.783)) * 0.4;
const vec3 colorFogDay     = RGBToLinear(vec3(0.680, 0.797, 0.823)) * 0.7;

const vec3 colorSkyNight   = RGBToLinear(vec3(0.095, 0.090, 0.106)) * 0.1;
const vec3 colorFogNight   = RGBToLinear(vec3(0.276, 0.278, 0.288)) * 0.3;

const vec3 colorSkyHorizon = RGBToLinear(vec3(0.502, 0.370, 0.626)) * 0.4;
const vec3 colorFogHorizon = RGBToLinear(vec3(0.854, 0.628, 0.281)) * 0.8;


#ifdef WORLD_WATER_ENABLED
    vec3 GetCustomWaterFogColor(const in float sunUpF) {
        //const vec3 _color = RGBToLinear(vec3(0.143, 0.230, 0.258));

        const float WaterMinBrightness = 0.04;

        float brightnessF = 1.0 - WaterMinBrightness;

        #ifdef WORLD_SKY_ENABLED
            float skyBrightness = smoothstep(-0.1, 0.3, sunUpF) * WorldSunBrightnessF;
            float weatherBrightness = 1.0 - 0.92 * rainStrength;
            float eyeBrightness = eyeBrightnessSmooth.y / 240.0;

            brightnessF *= skyBrightness * weatherBrightness * eyeBrightness;
        #endif

        vec3 color = 2.0 * RGBToLinear(WaterScatterColor) * RGBToLinear(WaterAbsorbColor);
        color = color / (color + 1.0);

        return color * (WaterMinBrightness + brightnessF);
    }

    float GetCustomWaterFogFactor(const in float fogDist) {
        float waterFogFar = min(waterDensitySmooth / WorldWaterDensityF, far);
        return GetFogFactor(fogDist, 0.0, waterFogFar, 0.65);
    }
#endif

vec3 GetCustomSkyColor(const in float sunUpF, const in float viewUpF) {
    #ifdef WORLD_SKY_ENABLED
        float dayF = smoothstep(-0.1, 0.3, sunUpF);
        vec3 skyColor = mix(colorSkyNight, colorSkyDay, dayF);
        vec3 fogColor = mix(colorFogNight, colorFogDay, dayF);

        float horizonF = smoothstep(0.0, 0.2, abs(sunUpF + 0.03));
        skyColor = mix(colorSkyHorizon, skyColor, horizonF);
        fogColor = mix(colorFogHorizon, fogColor, horizonF);

        const vec3 colorRainFogDay = RGBToLinear(vec3(0.04));

        vec3 rainSkyColor = mix(vec3(0.1), vec3(0.3), dayF);
        vec3 rainFogColor = mix(vec3(0.0), colorRainFogDay, dayF);

        skyColor = mix(skyColor, rainSkyColor, skyRainStrength);
        fogColor = mix(fogColor, rainFogColor, skyRainStrength);

        return GetSkyFogColor(skyColor, fogColor, viewUpF);
    #else
        return RGBToLinear(fogColor);
    #endif
}

#ifdef WORLD_SKY_ENABLED
    float GetCustomRainFogFactor(const in float fogDist) {
        float rainFar = min(96, far);
        float fogF = GetFogFactorL(fogDist, 0.0, rainFar, 1.0);
        return 0.82*fogF * rainStrength;
    }

    vec3 GetCustomRainFogColor(const in float sunUpF) {
        float eyeBrightness = eyeBrightnessSmooth.y / 240.0;
        float skyBrightness = smoothstep(-0.1, 0.3, sunUpF) * WorldSunBrightnessF;
        return RGBToLinear(vec3(0.214, 0.242, 0.247)) * skyBrightness * eyeBrightness;
    }

    void ApplyCustomRainFog(inout vec3 color, const in float fogDist, const in float sunUpF) {
        float fogF = GetCustomRainFogFactor(fogDist);
        vec3 fogColorFinal = GetCustomRainFogColor(sunUpF);
        color = mix(color, fogColorFinal, fogF);
    }
#endif

float GetCustomFogFactor(const in float fogDist) {
    #ifdef WORLD_SKY_ENABLED
        return GetFogFactor(fogDist, 0.85 * far, far, 1.0);
    #else
        return GetFogFactor(fogDist, 0.0, far, 1.0);
    #endif
}
