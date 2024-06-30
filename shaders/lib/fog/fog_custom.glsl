const vec3 colorSkyDay     = _RGBToLinear(vec3(0.176, 0.369, 0.612)) * 0.7;
const vec3 colorFogDay     = _RGBToLinear(vec3(0.541, 0.600, 0.651)) * 0.7;

const vec3 colorSkyNight   = _RGBToLinear(vec3(0.095, 0.090, 0.106)) * 0.1;
const vec3 colorFogNight   = _RGBToLinear(vec3(0.276, 0.278, 0.288)) * 0.3;

const vec3 colorSkyHorizon = _RGBToLinear(vec3(0.306, 0.275, 0.471)) * 0.4;
const vec3 colorFogHorizon = _RGBToLinear(vec3(0.788, 0.655, 0.298)) * 0.4;

const vec3 colorRainSkyDay = _RGBToLinear(vec3(0.332, 0.352, 0.399)) * 0.5;
const vec3 colorRainFogDay = _RGBToLinear(vec3(0.097, 0.092, 0.106)) * 0.5;


vec3 GetCustomSkyColor(const in float sunUpF, const in float viewUpF) {
    #ifdef WORLD_SKY_ENABLED
        float dayF = smoothstep(-0.1, 0.3, sunUpF);
        vec3 skyColor = mix(colorSkyNight, colorSkyDay, dayF);

        //float horizonF = smoothstep(0.0, 0.6, abs(sunUpF + 0.06));
        float horizonF = GetSkyHorizonF(sunUpF);
        skyColor = mix(skyColor, colorSkyHorizon, horizonF);

        #if SKY_VOL_FOG_TYPE == VOL_TYPE_NONE || SKY_CLOUD_TYPE <= CLOUDS_VANILLA
            vec3 fogColor = mix(colorFogNight, colorFogDay, dayF);
            
            fogColor = mix(fogColor, colorFogHorizon, horizonF);

            vec3 rainFogColor = mix(vec3(0.0), colorRainFogDay, dayF);
            fogColor = mix(fogColor, rainFogColor, skyRainStrength);
        #endif

        #if SKY_CLOUD_TYPE <= CLOUDS_VANILLA
            vec3 rainSkyColor = mix(vec3(0.1), colorRainSkyDay, dayF);
            skyColor = mix(skyColor, rainSkyColor, skyRainStrength);
        #endif

        #if SKY_VOL_FOG_TYPE == VOL_TYPE_NONE || SKY_CLOUD_TYPE <= CLOUDS_VANILLA
            return GetSkyFogColor(skyColor, fogColor, viewUpF);
        #else
            return skyColor;
        #endif
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
        float skyBrightness = smoothstep(-0.1, 0.3, sunUpF) * Sky_SunBrightnessF;
        return RGBToLinear(vec3(0.214, 0.242, 0.247)) * skyBrightness * eyeBrightness;
    }

    void ApplyCustomRainFog(inout vec3 color, const in float fogDist, const in float sunUpF) {
        float fogF = GetCustomRainFogFactor(fogDist);
        vec3 fogColorFinal = GetCustomRainFogColor(sunUpF);
        color = mix(color, fogColorFinal, fogF);
    }
#endif

float GetCustomFogFactor(const in float fogDist) {
    #ifdef DISTANT_HORIZONS
        float fogFar = 0.5 * dhFarPlane;
    #else
        float fogFar = far;
    #endif

    #ifdef WORLD_SKY_ENABLED
        return GetFogFactor(fogDist, 0.85 * fogFar, fogFar, 1.0);
    #else
        return GetFogFactor(fogDist, 0.0, fogFar, 1.0);
    #endif
}
