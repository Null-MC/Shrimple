const vec3 worldSunColor         = RGBToLinear(vec3(0.909, 0.900, 0.866));
const vec3 worldHorizonColor     = RGBToLinear(vec3(0.813, 0.540, 0.120));
const vec3 worldMoonColor        = RGBToLinear(vec3(0.864, 0.860, 0.823));

// const float phaseAir = 0.25;
// const float AirAmbientF = 0.0;
// float AirScatterF = mix(0.002, 0.004, skyRainStrength);
// float AirExtinctF = mix(0.001, 0.008, skyRainStrength);

const float LightningRangeInv = rcp(200.0);
const float LightningBrightness = 20.0;


float GetSkyHorizonF(const in float celestialUpF) {
    return 1.0 - smoothstep(0.0, 0.5, abs(celestialUpF));
}

vec3 GetSkySunColor(const in float sunUpF) {
    float horizonF = GetSkyHorizonF(sunUpF);
    return mix(worldSunColor, worldHorizonColor, horizonF);
}

vec3 GetSkyMoonColor(const in float moonUpF) {
    float horizonF = GetSkyHorizonF(moonUpF);
    return mix(worldMoonColor, worldHorizonColor, horizonF);
}

#if !defined IRIS_FEATURE_SSBO || defined RENDER_BEGIN
    vec3 CalculateSkyLightColor(const in vec3 sunDir) {
        vec3 skyLightColor = sunDir.y > 0.0 ? worldSunColor : worldMoonColor;

        float sunF = smoothstep(-0.1, 0.2, sunDir.y);
        float brightness = mix(WorldMoonBrightnessF, WorldSunBrightnessF, sunF);

        float horizonF = GetSkyHorizonF(sunDir.y);
        skyLightColor = mix(skyLightColor, worldHorizonColor, horizonF) * brightness;

        #if MC_VERSION > 11900
            skyLightColor *= (1.0 - 0.99*smootherstep(darknessFactor));// + 0.04 * smootherstep(darknessLightFactor);
        #endif

        return skyLightColor;
    }
#endif

vec3 CalculateSkyLightWeatherColor(const in vec3 skyLightColor) {
    return skyLightColor * (1.0 - 0.8*skyRainStrength);
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
