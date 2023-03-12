#if SHADOW_COLORS == SHADOW_COLOR_ENABLED
    vec3 GetFinalShadowColor() {
        vec3 shadowColor = vec3(1.0);

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int tile = GetShadowCascade(shadowPos, ShadowPCFSize);

                if (tile >= 0)
                    shadowColor = GetShadowColor(shadowPos[tile], tile);
            #else
                shadowColor = GetShadowColor(shadowPos);
            #endif
        #endif

        return mix(shadowColor * max(vLit, 0.0), vec3(1.0), ShadowBrightnessF);
    }
#else
    float GetFinalShadowFactor() {
        float shadow = 1.0;

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int tile = GetShadowCascade(shadowPos, ShadowPCFSize);

                if (tile >= 0)
                    shadow = GetShadowFactor(shadowPos[tile], tile);
            #else
                shadow = GetShadowFactor(shadowPos);
            #endif
        #endif

        return shadow * max(vLit, 0.0);
    }
#endif
