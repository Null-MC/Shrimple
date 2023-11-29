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

vec3 GetCustomSkyFogColor(const in float sunUpF) {
    #ifdef WORLD_SKY_ENABLED
        const vec3 colorHorizon = RGBToLinear(vec3(0.894, 0.635, 0.360)) * 0.3;
        const vec3 colorNight   = RGBToLinear(vec3(0.177, 0.170, 0.192));
        const vec3 colorDay     = RGBToLinear(vec3(0.724, 0.891, 0.914)) * 0.5;

        #ifdef VL_BUFFER_ENABLED
            const float weatherDarkF = 0.3;
        #else
            const float weatherDarkF = 0.9;
        #endif

        float dayF = smoothstep(-0.1, 0.3, sunUpF);
        vec3 color = mix(colorNight, colorDay, dayF);

        float horizonF = smoothstep(0.0, 0.45, abs(sunUpF - 0.15));
        color = mix(colorHorizon, color, horizonF);

        // TODO: blindness

        float weatherBrightness = 1.0 - weatherDarkF * smoothstep(0.0, 1.0, rainStrength);
        return color * weatherBrightness;
    #else
        return RGBToLinear(fogColor);
    #endif
}

// float GetCustomSkyFogFactor(const in float fogDist) {
//     #ifdef VL_BUFFER_ENABLED
//         return GetFogFactor(fogDist, 0.75 * far, far, 1.0);
//     #elif WORLD_SKY_ENABLED
//         const float WorldFogRainySkyDensityF = 0.5;

//         float fogStart = WorldFogSkyStartF * far * (1.0 - rainStrength);
//         float density = mix(WorldFogSkyDensityF, WorldFogRainySkyDensityF, rainStrength);
//         return GetFogFactor(fogDist, fogStart, far, density);
//     #else
//         return 0.0;
//     #endif
// }

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
        #ifdef VL_BUFFER_ENABLED
            return GetFogFactor(fogDist, 0.75 * far, far, 1.0);
        #else
            //const float WorldFogRainySkyDensityF = 0.5;

            // float fogStart = WorldFogSkyStartF * far * (1.0 - rainStrength);
            // float density = mix(WorldFogSkyDensityF, WorldFogRainySkyDensityF, rainStrength);
            // return GetFogFactor(fogDist, fogStart, far, density);
            
            return GetFogFactor(fogDist, 0.85*far, far, 2.0);
        #endif
    #else
        return GetFogFactor(fogDist, 0.0, far, 1.0);
    #endif
}
