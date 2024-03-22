#if defined RENDER_SETUP || defined RENDER_BEGIN //|| defined RENDER_SHADOW
    layout(binding = 1) buffer shadowData
#else
    layout(binding = 1) readonly buffer shadowData
#endif
{
    //#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED && LIGHTING_MODE != LIGHTING_MODE_NONE
            vec2 shadowViewBoundsMin;   // 8
            vec2 shadowViewBoundsMax;   // 8
        #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            float cascadeSize[4];           // 16
            vec2 shadowProjectionSize[4];   // 32
            vec2 shadowProjectionPos[4];    // 32
            mat4 cascadeProjection[4];      // 256
            vec2 cascadeViewMin[4];         // 32
            vec2 cascadeViewMax[4];         // 32
        #endif

        #if SHADOW_FILTER > 0
            vec2 pcfDiskOffset[max(SHADOW_PCF_SAMPLES, SHADOW_PCSS_SAMPLES)];     // 256
            vec2 pcssDiskOffset[max(SHADOW_PCF_SAMPLES, SHADOW_PCSS_SAMPLES)];    // 256
        #endif
    //#endif
};
