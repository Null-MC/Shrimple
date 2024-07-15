#define SKY_LIGHT_COLOR_DAY_R 255 // [0]
#define SKY_LIGHT_COLOR_DAY_G 247 // [0]
#define SKY_LIGHT_COLOR_DAY_B 217 // [0]

#define SKY_LIGHT_COLOR_HORIZON_R 207 // [0]
#define SKY_LIGHT_COLOR_HORIZON_G 138 // [0]
#define SKY_LIGHT_COLOR_HORIZON_B 31  // [0]

#define SKY_LIGHT_COLOR_NIGHT_R 220 // [0]
#define SKY_LIGHT_COLOR_NIGHT_G 219 // [0]
#define SKY_LIGHT_COLOR_NIGHT_B 210 // [0]

const vec3 worldSunColor     = _RGBToLinear(vec3(SKY_LIGHT_COLOR_DAY_R, SKY_LIGHT_COLOR_DAY_G, SKY_LIGHT_COLOR_DAY_B) / 255.0);
const vec3 worldHorizonColor = _RGBToLinear(vec3(SKY_LIGHT_COLOR_HORIZON_R, SKY_LIGHT_COLOR_HORIZON_G, SKY_LIGHT_COLOR_HORIZON_B) / 255.0);
const vec3 worldMoonColor    = _RGBToLinear(vec3(SKY_LIGHT_COLOR_NIGHT_R, SKY_LIGHT_COLOR_NIGHT_G, SKY_LIGHT_COLOR_NIGHT_B) / 255.0);

const float SkyHorizonOffset = -0.10;

const float LightningRangeInv = rcp(200.0);
const float LightningBrightness = 20.0;


bool IsSkyLightSun(const in float localSunDirY) {
    return localSunDirY >= SkyHorizonOffset;
}

float GetSkyHorizonF(const in float localSunDirY) {
    //float horizonF = smoothstep(0.0, 0.6, abs(localSunDirY + 0.12));
    // float horizonF = abs(localSunDirY + 0.12);
    // return 1.0 - saturate(horizonF);

    bool isDay = IsSkyLightSun(localSunDirY);
    float _max = isDay ? 0.8 : -0.1;

    return 1.0 - smoothstep(0.0, _max, localSunDirY - SkyHorizonOffset);
}

vec3 GetSkyLightDirection(const in vec3 localSunDir) {
    return IsSkyLightSun(localSunDir.y) ? localSunDir : -localSunDir;
}

vec3 GetSkySunColor(const in float localSunDirY) {
    float horizonF = GetSkyHorizonF(localSunDirY);
    return mix(worldSunColor, worldHorizonColor, horizonF);
}

vec3 GetSkyMoonColor(const in float moonUpF) {
    float horizonF = GetSkyHorizonF(moonUpF);
    return mix(worldMoonColor, worldHorizonColor, horizonF);
}

#if !defined IRIS_FEATURE_SSBO || defined RENDER_BEGIN
    vec3 CalculateSkyLightColor(const in float localSunDirY) {
        bool isSun = IsSkyLightSun(localSunDirY);
        vec3 skyLightColor = isSun ? worldSunColor : worldMoonColor;

        float sunF = smoothstep(-0.1, 0.2, localSunDirY);
        float brightness = mix(Sky_MoonBrightnessF, Sky_SunBrightnessF, sunF);

        // float horizonF = GetSkyHorizonF(localSunDirY);
        float horizonF = 1.0 - (isSun
            ? smoothstep(0.0, 1.0,  localSunDirY)
            : smoothstep(0.0, 0.4, -localSunDirY));

        skyLightColor = mix(skyLightColor, worldHorizonColor, horizonF) * brightness;

        #if MC_VERSION > 11900
            skyLightColor *= (1.0 - 0.99*smootherstep(darknessFactor));// + 0.04 * smootherstep(darknessLightFactor);
        #endif

        return skyLightColor;
    }
#endif

vec3 CalculateSkyLightWeatherColor(const in vec3 skyLightColor) {
    #if SKY_CLOUD_TYPE <= CLOUDS_VANILLA
        return skyLightColor * (1.0 - 0.8*weatherStrength);
    #else
        return skyLightColor;
    #endif
}

#ifndef RENDER_BEGIN
    vec3 GetSkyLightColor(const in vec3 sunDir) {
        #ifdef IRIS_FEATURE_SSBO
            return WorldSkyLightColor;
        #else
            return CalculateSkyLightColor(sunDir.y);
        #endif
    }

    vec3 GetSkyLightColor() {
        #ifdef IRIS_FEATURE_SSBO
            return WorldSkyLightColor;
        #else
            vec3 localSunDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
            return CalculateSkyLightColor(localSunDirection.y);
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
