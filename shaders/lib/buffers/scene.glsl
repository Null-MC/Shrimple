#if defined RENDER_SETUP || defined RENDER_BEGIN
    layout(std430, binding = 0) buffer sceneData
#else
    layout(std430, binding = 0) readonly buffer sceneData
#endif
{
    vec3 localSunDirection;                  // 12
    vec3 localSkyLightDirection;             // 12
    vec3 WorldSkyLightColor;                 // 12
    mat4 gbufferModelViewProjectionInverse;  // 64
    mat4 gbufferPreviousModelViewProjection; // 64
    mat4 matColorPost;                       // 64

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
        mat4 shadowModelViewProjection;      // 64
    #endif
};
