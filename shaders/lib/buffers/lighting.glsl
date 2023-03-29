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
    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
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
    uint SceneLightMaxCount;
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
    #ifndef MC_GL_VENDOR_NVIDIA
        LightCellData[(LIGHT_SIZE_XZ*LIGHT_SIZE_XZ*LIGHT_SIZE_Y)] SceneLightMaps;
    #else
        LightCellData[] SceneLightMaps;
    #endif
};

#ifdef RENDER_SHADOW
    layout(r32ui) uniform restrict writeonly uimage2D imgSceneLights;
#else
    layout(r32ui) uniform restrict readonly uimage2D imgSceneLights;
#endif
