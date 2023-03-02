struct SceneLightData {
    vec3 position;
    float range;
    vec4 color;
};

struct LightCellData {
    uint LightCount;
    uint[LIGHT_MASK_SIZE] Mask;
};

#if defined RENDER_BEGIN || defined RENDER_SHADOW
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
