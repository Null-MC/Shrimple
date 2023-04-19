#if SHADOW_COLORS == SHADOW_COLOR_ENABLED
    vec3 GetFinalShadowColor(const in float sss) {
        vec3 shadowColor = vec3(1.0);

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int tile = GetShadowCascade(shadowPos, ShadowPCFSize);

                if (tile >= 0)
                    shadowColor = GetShadowColor(shadowPos[tile], tile);
            #else
                float dither = InterleavedGradientNoise(gl_FragCoord.xy);
                float bias = dither * sss * (1.5 / 256.0);
                shadowColor = GetShadowColor(shadowPos, bias);
            #endif
        #endif

        // #if MATERIAL_SSS != SSS_NONE
        //     shadowColor *= mix(max(NoL, 0.0), abs(NoL), sss);
        // #else
        //     shadowColor *= max(NoL, 0.0);
        // #endif

        return shadowColor;
    }

    vec3 GetFinalShadowColor() {
        return GetFinalShadowColor(0.0);
    }
#else
    float GetFinalShadowFactor(const in float sss) {
        float shadow = 1.0;

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int tile = GetShadowCascade(shadowPos, ShadowPCFSize);

                if (tile >= 0)
                    shadow = GetShadowFactor(shadowPos[tile], tile);
            #else
                float bias = sss * (1.5 / 256.0);
                shadow = GetShadowFactor(shadowPos, bias);
            #endif
        #endif

        // #if MATERIAL_SSS != SSS_NONE
        //     shadowColor *= mix(max(NoL, 0.0), abs(NoL), sss);
        // #else
        //     shadowColor *= max(NoL, 0.0);
        // #endif

        return shadow;
    }

    float GetFinalShadowFactor() {
        return GetFinalShadowFactor(0.0);
    }
#endif
