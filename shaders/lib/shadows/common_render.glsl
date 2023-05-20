#ifdef SHADOW_COLORED
    vec3 GetFinalShadowColor(const in float sss) {
        vec3 shadowColor = vec3(1.0);

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);
            float bias = dither * sss;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int tile = GetShadowCascade(shadowPos, ShadowPCFSize);

                if (tile >= 0) {
                    bias *= MATERIAL_SSS_MAXDIST / (3.0 * far);
                    shadowColor = GetShadowColor(shadowPos[tile], tile, bias);
                }
            #else
                bias *= MATERIAL_SSS_MAXDIST / (2.0 * far);
                shadowColor = GetShadowColor(shadowPos, bias);
            #endif
        #endif

        return shadowColor;
    }

    vec3 GetFinalShadowColor() {
        return GetFinalShadowColor(0.0);
    }
#else
    float GetFinalShadowFactor(const in float sss) {
        float dither = InterleavedGradientNoise(gl_FragCoord.xy);
        float bias = dither * sss;
        float shadow = 1.0;

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int tile = GetShadowCascade(shadowPos, ShadowPCFSize);

                if (tile >= 0) {
                    bias *= MATERIAL_SSS_MAXDIST / (3.0 * far);
                    shadow = GetShadowFactor(shadowPos[tile], tile, bias);
                }
            #else
                bias *= MATERIAL_SSS_MAXDIST / (2.0 * far);
                shadow = GetShadowFactor(shadowPos, bias);
            #endif
        #endif

        return shadow;
    }

    float GetFinalShadowFactor() {
        return GetFinalShadowFactor(0.0);
    }
#endif
