#if OVERWORLD_SKY == SKY_ENHANCED
    #define FOG_HORIZON_F 0.08
#else
    #define FOG_HORIZON_F 0.02
#endif

const vec3 colorSkyDay     = pow(vec3(0.404, 0.639, 0.812), vec3(2.2));
const vec3 colorFogDay     = pow(vec3(0.608, 0.659, 0.710), vec3(2.2));

const vec3 colorSkyNight   = pow(vec3(0.106, 0.090, 0.149), vec3(2.2));
const vec3 colorFogNight   = pow(vec3(0.169, 0.220, 0.322), vec3(2.2));

const vec3 colorSkyHorizon = pow(vec3(0.290, 0.243, 0.529), vec3(2.2));
const vec3 colorFogHorizon = pow(vec3(0.980, 0.533, 0.118), vec3(2.2));

const vec3 colorRainSky = pow(vec3(0.557, 0.580, 0.671), vec3(2.2));
const vec3 colorRainFog = pow(vec3(0.329, 0.329, 0.388), vec3(2.2));


float fogify(const in float x, const in float w) {
    return w / (x * x + w);
}

float GetSkyHorizonF(const in float localSunDirY) {
    const float SkyHorizonOffset = -0.10;

    bool isDay = localSunDirY >= SkyHorizonOffset; //IsSkyLightSun(localSunDirY);
    float _max = isDay ? 0.8 : -0.1;

    return 1.0 - smoothstep(0.0, _max, localSunDirY - SkyHorizonOffset);
}

#if OVERWORLD_SKY == SKY_ENHANCED
    vec3 GetEnhancedSkyUpColor(const in vec3 localSunDir, const in float rainStrength, const in float skyDayF) {
        vec3 skyColorLab = mix(LinearToLab(colorSkyNight), LinearToLab(colorSkyDay), skyDayF);

        float horizonF = GetSkyHorizonF(localSunDir.y);
        skyColorLab = mix(skyColorLab, LinearToLab(colorSkyHorizon), horizonF);

        skyColorLab = mix(skyColorLab, LinearToLab(colorRainSky), rainStrength);

        return LabToLinear(skyColorLab) * mix(0.04, 1.0, skyDayF);
    }

    vec3 GetEnhancedSkyFogColor(const in vec3 localSunDir, const in vec3 localViewDir, const in float rainStrength, const in float skyDayF) {
//        float dayF = smoothstep(-0.1, 0.3, localSunDir.y);
        vec3 skyColorLab = mix(LinearToLab(colorSkyNight), LinearToLab(colorSkyDay), skyDayF);
        vec3 fogColorLab = mix(LinearToLab(colorFogNight), LinearToLab(colorFogDay), skyDayF);

        float horizonF = GetSkyHorizonF(localSunDir.y);
        skyColorLab = mix(skyColorLab, LinearToLab(colorSkyHorizon), horizonF);

        skyColorLab = mix(skyColorLab, LinearToLab(colorRainSky), rainStrength);
        fogColorLab = mix(fogColorLab, LinearToLab(colorRainFog), rainStrength);

        // directional horizon color
        horizonF *= dot(localSunDir, localViewDir) * 0.5 + 0.5;
        fogColorLab = mix(fogColorLab, LinearToLab(colorFogHorizon), horizonF);

        float fogF = fogify(max(localViewDir.y, 0.0), FOG_HORIZON_F);
        vec3 colorLab = mix(skyColorLab, fogColorLab, fogF);
        return LabToLinear(colorLab) * mix(0.04, 1.0, skyDayF);
    }
#endif

vec3 GetSkyFogColor(const in vec3 skyColorL, const in vec3 fogColorL, const in vec3 localSunDir, const in vec3 localViewDir, const in float rainStrength, const in float skyDayF) {
    #ifdef WORLD_NETHER
        return fogColorL;
    #elif defined(WORLD_END)
        return skyColorL;
    #else
        #if OVERWORLD_SKY == SKY_ENHANCED
            return GetEnhancedSkyFogColor(localSunDir, localViewDir, rainStrength, skyDayF);
        #else
            float fogF = fogify(max(localViewDir.y, 0.0), FOG_HORIZON_F);
            return LabMixLinear(skyColorL, fogColorL, fogF);
        #endif
    #endif
}

vec3 GetWaterFogColor(const in vec3 waterFogColorL, const in vec3 localSunDir, const in float rainStrength, const in float skyDayF) {
    #if OVERWORLD_SKY == SKY_ENHANCED
        // TODO: sample irradiance up instead?
        vec3 skyUpColor = GetEnhancedSkyUpColor(localSunDir, rainStrength, skyDayF);

        float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
        skyUpColor *= _pow2(eyeBrightF) * 0.92 + 0.08;

//        const vec3 waterFogColorL = pow(vec3(0.067, 0.416, 0.471), vec3(2.2));
        return waterFogColorL * skyUpColor;// * skyColorL;
    #else
        return fogColorL;
    #endif
}

vec3 GetSkyFogWaterColor(const in vec3 skyColorL, const in vec3 fogColorL, const in vec3 localSunDir, const in vec3 localViewDir, const in float rainStrength, const in float skyDayF) {
    if (isEyeInWater == 1) {
        const vec3 waterFogColorL = pow(vec3(0.067, 0.416, 0.471), vec3(2.2));
        return GetWaterFogColor(waterFogColorL, localSunDir, rainStrength, skyDayF);
    }

    vec3 color = GetSkyFogColor(skyColorL, fogColorL, sunLocalDir, localViewDir, rainStrength, skyDayF);

    #if OVERWORLD_SKY == SKY_ENHANCED
        float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
        color *= _pow2(eyeBrightF) * 0.92 + 0.08;
    #endif

    return color;
}

vec3 GetSkyFogWaterColor(const in vec3 skyColorL, const in vec3 fogColorL, const in vec3 localViewDir) {
    return GetSkyFogWaterColor(skyColorL, fogColorL, sunLocalDir, localViewDir, weatherStrength, skyDayF);
}

float GetBorderFogStrength(const in float viewDist) {
    #ifdef VOXY
        float _far = vxRenderDistance * 16.0;
    #elif defined(DISTANT_HORIZONS)
        float _far = 0.5 * dhFarPlane;
    #else
        #define _far far
    #endif

//    return smoothstep(0.94 * _far, _far, viewDist);
    float fogF = saturate(unmix(0.88 * _far, _far, viewDist));
    return _pow2(fogF);
    #undef _far
}

float GetEnvFogStrength(const in float viewDist, bool inWater) {
    #if defined(WORLD_OVERWORLD) && OVERWORLD_SKY == SKY_ENHANCED
        float density = inWater ? 0.02 : weatherDensity;
        return saturate(1.0 - exp(-density * viewDist));
    #else
        return smoothstep(fogStart, fogEnd, viewDist);
    #endif
}

float GetEnvFogStrength(const in float viewDist) {
    return GetEnvFogStrength(viewDist, isEyeInWater == 1);
}
