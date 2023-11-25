vec3 worldSunColor         = vec3(0.889, 0.864, 0.691) * WorldSunBrightnessF;
vec3 worldSunColorHorizon  = vec3(0.813, 0.540, 0.120) * WorldSunBrightnessF;
vec3 worldMoonColorHorizon = vec3(0.717, 0.708, 0.621) * WorldMoonBrightnessF;
vec3 worldMoonColor        = vec3(0.864, 0.860, 0.823) * WorldMoonBrightnessF;

const float AirAmbientF = 0.0;
const float AirScatterF = mix(0.002, 0.004, rainStrength);
const float AirExtinctF = mix(0.001, 0.008, rainStrength);


float GetSkyHorizonF(const in float celestialUpF) {
    return smoothstep(0.0, 0.7, celestialUpF);
}

vec3 GetSkySunColor(const in float sunUpF) {
    float horizonF = GetSkyHorizonF(sunUpF);
    return mix(worldSunColorHorizon, worldSunColor, horizonF);
}

vec3 GetSkyMoonColor(const in float moonUpF) {
    float horizonF = GetSkyHorizonF(moonUpF);
    return mix(worldMoonColorHorizon, worldMoonColor, horizonF);
}

#if !defined IRIS_FEATURE_SSBO || defined RENDER_BEGIN
    vec3 CalculateSkyLightColor(const in vec3 sunDir) {
        vec3 skyLightColor = sunDir.y > 0.0 ? worldSunColor : worldMoonColor;
        vec3 skyLightHorizonColor = sunDir.y > 0.0 ? worldSunColorHorizon : worldMoonColorHorizon;

        float horizonF = GetSkyHorizonF(sunDir.y);
        return mix(skyLightHorizonColor, skyLightColor, horizonF);
    }
#endif

vec3 CalculateSkyLightWeatherColor(const in vec3 skyLightColor) {
    return skyLightColor * (1.0 - 0.6*rainStrength);
}

#ifndef RENDER_BEGIN
    vec3 GetSkyLightColor(const in vec3 sunDir) {
        #ifdef IRIS_FEATURE_SSBO
            return WorldSkyLightColor;
        #else
            return CalculateSkyLightColor(sunDir);
        #endif
    }

    vec3 GetSkyLightColor() {
        #ifdef IRIS_FEATURE_SSBO
            return WorldSkyLightColor;
        #else
            vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            return CalculateSkyLightColor(localSunDirection);
        #endif
    }

    // vec3 GetSkyLightWeatherColor(const in vec3 skyLightColor) {
    //     #ifdef IRIS_FEATURE_SSBO
    //         return WeatherSkyLightColor;
    //     #else
    //         return CalculateSkyLightWeatherColor(skyLightColor);
    //     #endif
    // }
#endif
