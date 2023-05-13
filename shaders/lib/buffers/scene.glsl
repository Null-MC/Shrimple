#if defined RENDER_SETUP || defined RENDER_BEGIN
    layout(std430, binding = 0) buffer sceneData
#else
    layout(std430, binding = 0) readonly buffer sceneData
#endif
{
    mat4 matColorPost;                       // 64

    vec3 localSunDirection;                  // 12
    vec3 localSkyLightDirection;             // 12

    vec3 WorldSunLightColor;                 // 12
    vec3 WorldMoonLightColor;                // 12
    vec3 WorldSkyLightColor;                 // 12
    //vec3 WeatherSkyLightColor;             // 12

    mat4 gbufferModelViewProjectionInverse;  // 64
    mat4 gbufferPreviousModelViewProjection; // 64
    mat4 shadowModelViewEx;                  // 64
    mat4 shadowProjectionEx;                 // 64

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
        mat4 shadowModelViewProjection;      // 64
    #endif
};
