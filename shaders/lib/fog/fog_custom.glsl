const vec3 colorSkyDay     = _RGBToLinear(vec3(0.188, 0.396, 0.541));
const vec3 colorFogDay     = _RGBToLinear(vec3(0.439, 0.529, 0.612));

const vec3 colorSkyNight   = _RGBToLinear(vec3(0.095, 0.090, 0.106)) * 0.2;
const vec3 colorFogNight   = _RGBToLinear(vec3(0.276, 0.278, 0.288)) * 0.6;

const vec3 colorSkyHorizon = _RGBToLinear(vec3(0.306, 0.275, 0.471)) * 0.8;
const vec3 colorFogHorizon = _RGBToLinear(vec3(0.780, 0.490, 0.216)) * 0.8;

// const vec3 colorRainSkyDay = _RGBToLinear(vec3(0.332, 0.352, 0.399)) * 0.5;
const vec3 colorRainFogDay = _RGBToLinear(vec3(0.596, 0.596, 0.62)) * 0.2;


vec3 GetCustomSkyColor(const in vec3 localSunDir, const in vec3 localViewDir) {
    #ifdef WORLD_SKY_ENABLED
        float dayF = smoothstep(-0.1, 0.3, localSunDir.y);
        vec3 skyColor = LabMixLinear(colorSkyNight, colorSkyDay, dayF);

        float horizonF = GetSkyHorizonF(localSunDir.y);
        skyColor = LabMixLinear(skyColor, colorSkyHorizon, horizonF);

        vec3 fogColor = LabMixLinear(colorFogNight, colorFogDay, dayF);
        
        horizonF *= dot(localSunDir, localViewDir) * 0.5 + 0.5;
        fogColor = LabMixLinear(fogColor, colorFogHorizon, horizonF);

        vec3 rainFogColor = LabMixLinear(vec3(0.0), colorRainFogDay, dayF);
        fogColor = LabMixLinear(fogColor, rainFogColor, weatherStrength);

        return GetSkyFogColor(skyColor, fogColor, localViewDir.y);
    #else
        return RGBToLinear(fogColor);
    #endif
}

#ifdef WORLD_SKY_ENABLED
//    float GetCustomRainFogFactor(const in float fogDist) {
//        float rainFar = min(96, far);
//        float fogF = GetFogFactorL(fogDist, 0.0, rainFar, 1.0);
//        return 0.82*fogF * rainStrength;
//    }

//    vec3 GetCustomRainFogColor(const in float sunUpF) {
//        float eyeBrightness = eyeBrightnessSmooth.y / 240.0;
//        float skyBrightness = smoothstep(-0.1, 0.3, sunUpF);
//        return RGBToLinear(vec3(0.214, 0.242, 0.247)) * skyBrightness * eyeBrightness;
//    }

//    void ApplyCustomRainFog(inout vec3 color, const in float fogDist, const in float sunUpF) {
//        float fogF = GetCustomRainFogFactor(fogDist);
//        vec3 fogColorFinal = GetCustomRainFogColor(sunUpF);
//        color = LabMixLinear(color, fogColorFinal, fogF);
//    }
#endif

float GetCustomFogFactor(const in float fogDist) {
    #ifdef DISTANT_HORIZONS
        float fogFar = 0.5 * dhFarPlane;
    #else
        float fogFar = far;
    #endif

    #ifdef WORLD_SKY_ENABLED
        #ifdef DISTANT_HORIZONS
            const float startF = 0.60;
        #else
            const float startF = 0.85;
        #endif

        return GetFogFactor(fogDist, startF * fogFar, fogFar, 1.0);
    #else
        return GetFogFactor(fogDist, 0.0, fogFar, 1.0);
    #endif
}
