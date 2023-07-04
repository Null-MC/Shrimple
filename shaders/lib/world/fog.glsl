float fogify(float x, float w) {
    return w / (x * x + w);
}

float GetFogFactor(const in float dist, const in float start, const in float end, const in float density) {
    if (dist >= end) return 1.0;

    float distF = saturate((dist - start) / (end - start));
    return smoothstep(0.0, 1.0, pow(distF, density));
}

#ifdef WORLD_SKY_ENABLED
    vec3 GetSkyFogColor(const in vec3 skyColor, const in vec3 fogColor, const in float viewUpF) {
        //#ifdef WORLD_SKY_ENABLED
            #ifdef VL_BUFFER_ENABLED
                vec3 fogColorFinal = skyColor;// * 0.5;
            #else
                float fogF = fogify(max(viewUpF, 0.0), 0.06);

                vec3 fogColorFinal = mix(skyColor, fogColor, fogF);
            #endif

            return fogColorFinal * WorldSkyBrightnessF;
        //#else
        //    return fogColorFinal * WorldSkyBrightnessF;
        //#endif
    }
#endif

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
    vec3 GetCustomWaterFogColor(const in float sunUpF) {
        const vec3 _color = RGBToLinear(vec3(0.031, 0.096, 0.227));
        const float WaterMinBrightness = 0.04;

        float brightnessF = 1.0 - WaterMinBrightness;

        #ifdef WORLD_SKY_ENABLED
            float skyBrightness = smoothstep(-0.1, 0.3, sunUpF) * WorldSunBrightnessF;
            float weatherBrightness = 1.0 - 0.92 * rainStrength;
            float eyeBrightness = eyeBrightnessSmooth.y / 240.0;

            brightnessF *= skyBrightness * weatherBrightness * eyeBrightness;
        #endif

        return _color * (WaterMinBrightness + brightnessF);
    }

    float GetCustomWaterFogFactor(const in float fogDist) {
        return GetFogFactor(fogDist, 0.0, min(48.0, far), 0.5);
    }

    #ifdef WORLD_SKY_ENABLED
        vec3 GetCustomSkyFogColor(const in float sunUpF) {
            const vec3 colorHorizon = RGBToLinear(vec3(0.894, 0.635, 0.360));
            const vec3 colorNight   = RGBToLinear(vec3(0.177, 0.170, 0.192));
            const vec3 colorDay     = RGBToLinear(vec3(0.724, 0.891, 0.914));

            #ifdef VL_BUFFER_ENABLED
                const float weatherDarkF = 0.3;
            #else
                const float weatherDarkF = 0.9;
            #endif

            float dayF = smoothstep(-0.1, 0.3, sunUpF);
            vec3 color = mix(colorNight, colorDay, dayF);

            float horizonF = smoothstep(0.0, 0.45, abs(sunUpF - 0.15));
            color = mix(colorHorizon, color, horizonF);

            float weatherBrightness = 1.0 - weatherDarkF * smoothstep(0.0, 1.0, rainStrength);
            return color * weatherBrightness;
        }

        float GetCustomSkyFogFactor(const in float fogDist) {
            #ifdef VL_BUFFER_ENABLED
                return GetFogFactor(fogDist, 0.75 * far, far, 1.0);
            #else
                const float WorldFogRainySkyDensityF = 0.5;

                float fogStart = WorldFogSkyStartF * far * (1.0 - rainStrength);
                float density = mix(WorldFogSkyDensityF, WorldFogRainySkyDensityF, rainStrength);
                return GetFogFactor(fogDist, fogStart, far, density);
            #endif
        }
    #endif
#endif

#if !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
    float GetVanillaFogDistance(const in vec3 localPos) {
        //if (fogStart > far) return 0.0;

        vec3 fogPos = localPos;
        // if (fogShape == 1)
        //     fogPos.y = 0.0;

        #ifdef WORLD_SKY_ENABLED
            fogPos.y = 0.0;
        #endif

        return length(fogPos);// * rcp(WorldFogScaleF);
    }

    float GetVanillaFogFactor(const in vec3 localPos) {
        float fogDist = GetVanillaFogDistance(localPos);
        return GetFogFactor(fogDist, fogStart, fogEnd, 1.0);
    }
#endif

#if defined RENDER_GBUFFER && !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED || defined RENDER_CLOUDS) // || defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
    #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
        void ApplyWaterFog(inout vec4 color, const in vec3 localPos, const in float waterDepth) {
        }

        void ApplySkyFog(inout vec4 color, const in vec3 localPos, const in float waterDepth) {
        }
    #endif

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
        ApplyVanillaFog(color, localPos);
    }
#endif
