#define SKY_LIGHT_COLOR_DAY_R 255 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]
#define SKY_LIGHT_COLOR_DAY_G 245 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]
#define SKY_LIGHT_COLOR_DAY_B 215 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]

#define SKY_LIGHT_COLOR_HORIZON_R 205 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]
#define SKY_LIGHT_COLOR_HORIZON_G 130 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]
#define SKY_LIGHT_COLOR_HORIZON_B 55  // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]

#define SKY_LIGHT_COLOR_NIGHT_R 220 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]
#define SKY_LIGHT_COLOR_NIGHT_G 220 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]
#define SKY_LIGHT_COLOR_NIGHT_B 210 // [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185 190 195 200 205 210 215 220 225 230 235 240 245 250 255]

const vec3 worldSunColor     = _RGBToLinear(vec3(SKY_LIGHT_COLOR_DAY_R, SKY_LIGHT_COLOR_DAY_G, SKY_LIGHT_COLOR_DAY_B) / 255.0);
const vec3 worldHorizonColor = _RGBToLinear(vec3(SKY_LIGHT_COLOR_HORIZON_R, SKY_LIGHT_COLOR_HORIZON_G, SKY_LIGHT_COLOR_HORIZON_B) / 255.0);
const vec3 worldMoonColor    = _RGBToLinear(vec3(SKY_LIGHT_COLOR_NIGHT_R, SKY_LIGHT_COLOR_NIGHT_G, SKY_LIGHT_COLOR_NIGHT_B) / 255.0);

const float SkyHorizonOffset = -0.10;

const float LightningRangeInv = rcp(2000.0);
const float LightningBrightness = 5.0;
const float lightningSpeed = 2.0;


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

const float moonPhaseStrength[8] = float[](1.00, 0.75, 0.50, 0.25, 0.00, 0.25, 0.50, 0.75);

vec3 GetSkyMoonColor(const in float moonUpF) {
    float horizonF = GetSkyHorizonF(moonUpF);
    vec3 phaseColor = worldMoonColor * moonPhaseStrength[moonPhase];
    return mix(phaseColor, worldHorizonColor, horizonF);
}

#if !defined IRIS_FEATURE_SSBO || defined RENDER_BEGIN
    vec3 CalculateSkyLightColor(const in float localSunDirY, const in float moonBrightnessF, const in float sunBrightnessF) {
        bool isSun = IsSkyLightSun(localSunDirY);
        vec3 skyLightColor = isSun ? worldSunColor : (worldMoonColor * moonPhaseStrength[moonPhase]);

        float sunF = smoothstep(-0.1, 0.2, localSunDirY);
        float brightness = mix(moonBrightnessF, sunBrightnessF, sunF);

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

    vec3 CalculateSkyLightColor(const in float localSunDirY) {
        return CalculateSkyLightColor(localSunDirY, Sky_MoonBrightnessF, 1.0);
    }
#endif

vec3 CalculateSkyLightWeatherColor(const in vec3 skyLightColor) {
    #if SKY_CLOUD_TYPE == CLOUDS_VANILLA
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
