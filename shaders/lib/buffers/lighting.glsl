#define LIGHT_MASK_UP 1u
#define LIGHT_MASK_DOWN 2u
#define LIGHT_MASK_NORTH 3u
#define LIGHT_MASK_SOUTH 4u
#define LIGHT_MASK_WEST 5u
#define LIGHT_MASK_EAST 6u


struct SceneLightData {
    vec3 position;
    float range;
    vec3 color;
    uint data;
};

struct LightCellData {
    uint LightCount;
    uint LightNeighborCount;
    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        uint[(LIGHT_BIN_SIZE3*DYN_LIGHT_MASK_STRIDE/32)] BlockMask;
    #endif
    uint[(LIGHT_BIN_SIZE3*DYN_LIGHT_MASK_STRIDE/32)] LightMask;
};

#ifdef RENDER_SHADOWCOMP
    layout(std430, binding = 1) restrict buffer globalLightingData
#elif defined RENDER_BEGIN
    layout(std430, binding = 1) restrict writeonly buffer globalLightingData
#else
    layout(std430, binding = 1) restrict readonly buffer globalLightingData
#endif
{
    uint SceneLightCount;
    uint SceneLightMaxCount;
    vec3 sceneViewUp;
    vec3 sceneViewRight;
    vec3 sceneViewDown;
    vec3 sceneViewLeft;

    SceneLightData SceneLights[];
};

#ifdef RENDER_SHADOWCOMP
    layout(std430, binding = 2) restrict buffer localLightingData
#elif defined RENDER_BEGIN || defined RENDER_SHADOW
    layout(std430, binding = 2) restrict writeonly buffer localLightingData
#else
    layout(std430, binding = 2) restrict readonly buffer localLightingData
#endif
{
    LightCellData SceneLightMaps[];
};

#ifdef RENDER_SHADOWCOMP
    layout(r32ui) uniform restrict uimage2D imgSceneLights;
#elif defined RENDER_SHADOW
    layout(r32ui) uniform restrict writeonly uimage2D imgSceneLights;
#else
    layout(r32ui) uniform restrict readonly uimage2D imgSceneLights;
#endif
