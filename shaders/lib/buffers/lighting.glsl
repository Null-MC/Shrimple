struct SceneLightData {
    vec3 position;
    float range;
    vec4 color;
};

struct LightCellData {
    uint LightCount;
    #if DYN_LIGHT_RT_SHADOWS > 0
        uint[(LIGHT_BIN_SIZE3*DYN_LIGHT_MASK_STRIDE/32)] Mask;
    #else
        uint[(LIGHT_BIN_SIZE3/32)] Mask;
    #endif
};

#if defined RENDER_BEGIN || defined RENDER_SHADOW || defined RENDER_COMPOSITE_LIGHTS
    layout(std430, binding = 1) buffer globalLightingData
#else
    layout(std430, binding = 1) readonly buffer globalLightingData
#endif
{
    uint SceneLightCount;
    vec3 sceneViewUp;
    vec3 sceneViewRight;
    vec3 sceneViewDown;
    vec3 sceneViewLeft;

    #if DYN_LIGHT_TEMPORAL > 2
        vec3 lightCameraPosition[4];
        mat4 gbufferLightModelView[4];
        mat4 gbufferLightProjection[4];
    #endif

    SceneLightData SceneLights[];
};

#if defined RENDER_BEGIN || defined RENDER_SHADOW
    layout(std430, binding = 2) buffer localLightingData
#else
    layout(std430, binding = 2) readonly buffer localLightingData
#endif
{
    LightCellData[] SceneLightMaps;
};

#ifdef RENDER_SHADOW
    layout(r32ui) uniform restrict writeonly uimage2D imgSceneLights;
#else
    layout(r32ui) uniform restrict readonly uimage2D imgSceneLights;
#endif
