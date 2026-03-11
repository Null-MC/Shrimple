#if OVERWORLD_SKY == SKY_ENHANCED
    #define FOG_HORIZON_F 0.08
#else
    #define FOG_HORIZON_F 0.02
#endif

const vec3 colorSkyDay     = pow(vec3(0.404, 0.639, 0.812), vec3(2.2));
const vec3 colorFogDay     = pow(vec3(0.608, 0.659, 0.710), vec3(2.2));

const vec3 colorSkyNight   = pow(vec3(0.095, 0.090, 0.106), vec3(2.2));
const vec3 colorFogNight   = pow(vec3(0.276, 0.278, 0.288), vec3(2.2));

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
    vec3 GetEnhancedSkyFogColor(const in vec3 skyColorL, const in vec3 localSunDir, const in vec3 localViewDir, const in float rainStrength) {
        float dayF = smoothstep(-0.1, 0.3, localSunDir.y);
        vec3 skyColorLab = mix(LinearToLab(colorSkyNight), LinearToLab(colorSkyDay), dayF);
        vec3 fogColorLab = mix(LinearToLab(colorFogNight), LinearToLab(colorFogDay), dayF);

        float horizonF = GetSkyHorizonF(localSunDir.y);
        skyColorLab = mix(skyColorLab, LinearToLab(colorSkyHorizon), horizonF);

        skyColorLab = mix(skyColorLab, LinearToLab(colorRainSky), rainStrength);
        fogColorLab = mix(fogColorLab, LinearToLab(colorRainFog), rainStrength);

        // directional horizon color
        horizonF *= dot(localSunDir, localViewDir) * 0.5 + 0.5;
        fogColorLab = mix(fogColorLab, LinearToLab(colorFogHorizon), horizonF);

        float fogF = fogify(max(localViewDir.y, 0.0), FOG_HORIZON_F);
        vec3 colorLab = mix(skyColorLab, fogColorLab, fogF);
        return LabToLinear(colorLab) * mix(0.04, 1.0, dayF);
    }
#endif

vec3 GetSkyFogColor(const in vec3 skyColorL, const in vec3 fogColorL, const in vec3 localSunDir, const in vec3 localViewDir, const in float rainStrength) {
    #ifdef WORLD_NETHER
        return fogColorL;
    #elif defined(WORLD_END)
        return skyColorL;
    #else
        #if OVERWORLD_SKY == SKY_ENHANCED
            return GetEnhancedSkyFogColor(skyColorL, localSunDir, localViewDir, rainStrength);
        #else
            float fogF = fogify(max(localViewDir.y, 0.0), FOG_HORIZON_F);
            return LabMixLinear(skyColorL, fogColorL, fogF);
        #endif
    #endif
}

vec3 GetSkyFogWaterColor(const in vec3 skyColorL, const in vec3 fogColorL, const in vec3 localSunDir, const in vec3 localViewDir, const in float rainStrength) {
    vec3 color;
    if (isEyeInWater == 1) {
        #if OVERWORLD_SKY == SKY_ENHANCED
            const vec3 waterFogColorL = pow(vec3(0.067, 0.416, 0.471), vec3(2.2));
            color = waterFogColorL * skyColorL;
        #else
            color = fogColorL;
        #endif
    }
    else {
        color = GetSkyFogColor(skyColorL, fogColorL, sunLocalDir, localViewDir, rainStrength);
    }

    #if OVERWORLD_SKY == SKY_ENHANCED
        float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
        color *= _pow2(eyeBrightF) * 0.92 + 0.08;
    #endif

    return color;
}

vec3 GetSkyFogWaterColor(const in vec3 skyColorL, const in vec3 fogColorL, const in vec3 localViewDir) {
    return GetSkyFogWaterColor(skyColorL, fogColorL, sunLocalDir, localViewDir, rainStrength);
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

float GetEnvFogStrength(const in float viewDist) {
    #if defined(WORLD_OVERWORLD) && OVERWORLD_SKY == SKY_ENHANCED
        float density;
        if (isEyeInWater == 1) {
            density = 0.02;
        } else {
            density = mix(0.001, 0.01, rainStrength);
        }

        return saturate(1.0 - exp(-density * viewDist));
    #else
        return smoothstep(fogStart, fogEnd, viewDist);
    #endif
}
