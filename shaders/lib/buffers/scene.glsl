#if defined RENDER_SETUP || defined RENDER_BEGIN
    layout(binding = 0) buffer sceneData
#else
    layout(binding = 0) readonly buffer sceneData
#endif
{
    vec3 HandLightPos1;                      // 12
    uint HandLightType1;                     //  4

    vec3 HandLightPos2;                      // 12
    uint HandLightType2;                     //  4

    uint HandLightTypePrevious1;             //  4
    uint HandLightTypePrevious2;             //  4
    int worldTimeCurrent;                    //  4
    int worldTimePrevious;                   //  4

    mat4 matColorPost;                       // 64

    vec3 localSunDirection;                  // 12
    vec3 localSkyLightDirection;             // 12

    vec3 WorldSunLightColor;                 // 12
    vec3 WorldMoonLightColor;                // 12
    vec3 WorldSkyLightColor;                 // 12
    //vec3 WeatherSkyLightColor;             // 12

    //mat4 gbufferModelViewProjection;         // 64
    mat4 gbufferModelViewProjectionInverse;  // 64
    mat4 gbufferPreviousModelViewProjection; // 64
    //mat4 gbufferPreviousModelViewProjectionInverse; // 64
    mat4 shadowModelViewEx;                  // 64
    mat4 shadowProjectionEx;                 // 64

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
        mat4 shadowModelViewProjection;      // 64
    #endif

    #ifdef DISTANT_HORIZONS
        mat4 dhProjectionFull;              // 64
        mat4 dhProjectionFullInv;           // 64
        mat4 dhProjectionFullPrev;          // 64
    #endif

    vec3 lightningPosition;                  // 12
};
