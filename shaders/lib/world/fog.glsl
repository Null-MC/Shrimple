float fogify(float x, float w) {
    return w / (x * x + w);
}

float GetFogFactorL(const in float dist, const in float start, const in float end, const in float density) {
    if (dist >= end) return 1.0;

    float distF = saturate((dist - start) / (end - start));
    return pow(distF, density);
}

float GetFogFactor(const in float dist, const in float start, const in float end, const in float density) {
    if (dist >= end) return 1.0;

    float distF = saturate((dist - start) / (end - start));
    return smoothstep(0.0, 1.0, pow(distF, density));
}

vec3 GetSkyFogColor(const in vec3 skyColor, const in vec3 fogColor, const in float viewUpF) {
    float fogF = fogify(max(viewUpF, 0.0), 0.06);

    #ifdef WORLD_SKY_ENABLED
        fogF = mix(fogF, 1.0, rainStrength);
    #endif

    vec3 fogColorFinal = mix(skyColor, fogColor, fogF);

    return fogColorFinal * WorldSkyBrightnessF;
}

vec3 GetVanillaFogColor(const in vec3 fogColor, const in float viewUpF) {
    #ifdef WORLD_WATER_ENABLED //&& !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
        if (isEyeInWater == 1) return fogColor;
    #endif
    
    #ifdef WORLD_SKY_ENABLED
        return GetSkyFogColor(skyColor, fogColor, viewUpF);
    #else
        return fogColor;
    #endif
}

#ifdef WORLD_FOG_MODE == FOG_MODE_CUSTOM
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
            const vec3 colorHorizon = RGBToLinear(vec3(0.894, 0.635, 0.360)) * 0.7;
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

    float GetCustomSkyFogFactor(const in float fogDist) {
        #ifdef VL_BUFFER_ENABLED
            return GetFogFactor(fogDist, 0.75 * far, far, 1.0);
        #elif WORLD_SKY_ENABLED
            const float WorldFogRainySkyDensityF = 0.5;

            float fogStart = WorldFogSkyStartF * far * (1.0 - rainStrength);
            float density = mix(WorldFogSkyDensityF, WorldFogRainySkyDensityF, rainStrength);
            return GetFogFactor(fogDist, fogStart, far, density);
        #else
            return 0.0;
        #endif
    }

    #ifdef WORLD_SKY_ENABLED
        void ApplyCustomRainFog(inout vec3 color, const in float fogDist, const in float sunUpF) {
            float rainFar = min(96, far);
            float fogF = GetFogFactorL(fogDist, 0.0, rainFar, 1.0);

            float eyeBrightness = eyeBrightnessSmooth.y / 240.0;
            float skyBrightness = smoothstep(-0.1, 0.3, sunUpF) * WorldSunBrightnessF;
            vec3 fogColorFinal = RGBToLinear(vec3(0.214, 0.242, 0.247)) * skyBrightness * eyeBrightness;

            color = mix(color, fogColorFinal, 0.82*fogF * rainStrength);
        }
    #endif

    float GetCustomFogFactor(const in float fogDist) {
        #ifdef WORLD_SKY_ENABLED
            #ifdef VL_BUFFER_ENABLED
                return GetFogFactor(fogDist, 0.75 * far, far, 1.0);
            #else
                const float WorldFogRainySkyDensityF = 0.5;

                float fogStart = WorldFogSkyStartF * far * (1.0 - rainStrength);
                float density = mix(WorldFogSkyDensityF, WorldFogRainySkyDensityF, rainStrength);
                return GetFogFactor(fogDist, fogStart, far, density);
            #endif
        #else
            return GetFogFactor(fogDist, 0.0, far, 1.0);
        #endif
    }
#endif

#if !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
    float GetVanillaFogDistance(const in vec3 localPos) {
        vec3 fogPos = localPos;

        #if defined WORLD_SKY_ENABLED
            #if WORLD_FOG_SHAPE == FOG_SHAPE_CYLINDER
                fogPos.y = 0.0;
            #elif WORLD_FOG_SHAPE == FOG_SHAPE_DEFAULT
                if (fogShape == 1)
                    fogPos.y = 0.0;
            #endif
        #endif

        return length(fogPos);// * rcp(WorldFogScaleF);
    }

    float GetVanillaFogFactor(const in vec3 localPos) {
        float fogDist = GetVanillaFogDistance(localPos);
        return GetFogFactor(fogDist, fogStart, fogEnd, 1.0);
    }
#endif

#if defined RENDER_GBUFFER && !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED || defined RENDER_CLOUDS) // || defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
    // #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
    //     void ApplyWaterFog(inout vec4 color, const in vec3 localPos, const in float waterDepth) {
    //     }

    //     void ApplySkyFog(inout vec4 color, const in vec3 localPos, const in float waterDepth) {
    //     }
    // #endif

    void ApplyVanillaFog(inout vec4 color, const in vec3 localPos) {
        vec3 localViewDir = normalize(localPos);

        float fogF = GetVanillaFogFactor(localPos);
        vec3 fogColorFinal = GetVanillaFogColor(fogColor, localViewDir.y);
        fogColorFinal = RGBToLinear(fogColorFinal);

        color.rgb = mix(color.rgb, fogColorFinal, fogF);

        if (color.a > alphaTestRef)
            color.a = mix(color.a, 1.0, fogF);
    }

    void ApplyFog(inout vec4 color, const in vec3 localPos, const in vec3 localViewDir) {
        #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
            vec3 fogColorFinal = vec3(0.0);
            float fogF = 0.0;

            #ifndef IRIS_FEATURE_SSBO
                vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
            #endif

            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 1) {
                    float viewDist = length(localPos);
                    fogF = GetCustomWaterFogFactor(viewDist);
                    fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                }
                else {
            #endif
                #ifdef WORLD_SKY_ENABLED
                    vec3 skyColorFinal = RGBToLinear(skyColor);
                    fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                    fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, localViewDir.y);
                #else
                    fogColorFinal = GetVanillaFogColor(fogColor, localViewDir.y);
                    fogColorFinal = RGBToLinear(fogColorFinal);
                #endif

                float fogDist  = GetVanillaFogDistance(vLocalPos);
                fogF = GetCustomFogFactor(fogDist);
            #ifdef WORLD_WATER_ENABLED
                }
            #endif

            color.rgb = mix(color.rgb, fogColorFinal, fogF);

            if (color.a > alphaTestRef)
                color.a = mix(color.a, 1.0, fogF);
        #else
            ApplyVanillaFog(color, vLocalPos);
        #endif
    }
#endif
