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

// const vec3 colorRainSkyDay = pow(vec3(0.332, 0.352, 0.399), vec3(2.2)) * 0.5;
const vec3 colorRainFogDay = pow(vec3(0.596, 0.596, 0.620), vec3(2.2)) * 0.2;


float fogify(const in float x, const in float w) {
    return w / (x * x + w);
}

//bool IsSkyLightSun(const in float localSunDirY) {
//    return localSunDirY >= SkyHorizonOffset;
//}

float GetSkyHorizonF(const in float localSunDirY) {
    const float SkyHorizonOffset = -0.10;

    bool isDay = localSunDirY >= SkyHorizonOffset; //IsSkyLightSun(localSunDirY);
    float _max = isDay ? 0.8 : -0.1;

    return 1.0 - smoothstep(0.0, _max, localSunDirY - SkyHorizonOffset);
}

vec3 GetSkyFogColor(const in vec3 skyColorL, const in vec3 fogColorL, const in vec3 localSunDir, const in vec3 localViewDir) {
    if (isEyeInWater == 1) return fogColorL;

    #ifdef WORLD_NETHER
        return fogColorL;
    #elif defined(WORLD_END)
        return skyColorL;
    #else
        #if OVERWORLD_SKY == SKY_ENHANCED
//            vec3 localSunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);

            float dayF = smoothstep(-0.1, 0.3, localSunDir.y);
            vec3 _skyColor = LabMixLinear(colorSkyNight, colorSkyDay, dayF);

            float horizonF = GetSkyHorizonF(localSunDir.y);
            _skyColor = LabMixLinear(_skyColor, colorSkyHorizon, horizonF);

            vec3 _fogColor = LabMixLinear(colorFogNight, colorFogDay, dayF);

            horizonF *= dot(localSunDir, localViewDir) * 0.5 + 0.5;
            _fogColor = LabMixLinear(_fogColor, colorFogHorizon, horizonF);

            vec3 rainFogColor = LabMixLinear(vec3(0.0), colorRainFogDay, dayF);
            _fogColor = LabMixLinear(_fogColor, rainFogColor, rainStrength);

            float fogF = fogify(max(localViewDir.y, 0.0), FOG_HORIZON_F);
            return LabMixLinear(_skyColor, _fogColor, fogF) * mix(0.2, 1.0, dayF);
        #else
            float fogF = fogify(max(localViewDir.y, 0.0), FOG_HORIZON_F);
            return LabMixLinear(skyColorL, fogColorL, fogF);
        #endif
    #endif
}

vec3 GetSkyFogColor(const in vec3 skyColorL, const in vec3 fogColorL, const in vec3 localViewDir) {
    return GetSkyFogColor(skyColorL, fogColorL, sunLocalDir, localViewDir);
}

float GetBorderFogStrength(const in float viewDist) {
    #ifdef VOXY
        float _far = vxRenderDistance * 16.0;
    #elif defined(DISTANT_HORIZONS)
        float _far = 0.5 * dhFarPlane;
    #else
        #define _far far
    #endif

    return smoothstep(0.94 * _far, _far, viewDist);
}
