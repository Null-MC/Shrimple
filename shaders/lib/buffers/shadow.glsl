#if defined RENDER_SETUP || defined RENDER_BEGIN || defined RENDER_SHADOW
    layout(std430, binding = 0) buffer shadowData
#else
    layout(std430, binding = 0) readonly buffer shadowData
#endif
{
    vec2 pcfDiskOffset[32];     // 256
    vec2 pcssDiskOffset[32];    // 256

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        float cascadeSize[4];           // 16
        vec2 shadowProjectionSize[4];   // 32
        vec2 shadowProjectionPos[4];    // 32
        mat4 cascadeProjection[4];      // 256
        vec2 cascadeViewMin[4];         // 32
        vec2 cascadeViewMax[4];         // 32
    #endif
};
