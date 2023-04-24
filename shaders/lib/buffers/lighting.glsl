#define LIGHT_MASK_UP 1u
#define LIGHT_MASK_DOWN 2u
#define LIGHT_MASK_NORTH 3u
#define LIGHT_MASK_SOUTH 4u
#define LIGHT_MASK_WEST 5u
#define LIGHT_MASK_EAST 6u


#ifdef RENDER_SHADOWCOMP
    layout(std430, binding = 2) restrict buffer globalLightingData
#elif defined RENDER_BEGIN
    layout(std430, binding = 2) restrict writeonly buffer globalLightingData
#elif defined RENDER_SHADOW
    layout(std430, binding = 2) restrict buffer globalLightingData
#else
    layout(std430, binding = 2) restrict readonly buffer globalLightingData
#endif
{
    uint SceneLightCount;
    uint SceneLightMaxCount;

    vec3 HandLightPos1;
    vec3 HandLightPos2;

    vec3 sceneViewUp;
    vec3 sceneViewRight;
    vec3 sceneViewDown;
    vec3 sceneViewLeft;

    uvec4 SceneLights[];
};

struct LightCellData {
    uint LightCount;
    uint LightNeighborCount;
    uint GlobalLights[LIGHT_BIN_MAX_COUNT];
    //uint LightMask[(LIGHT_BIN_SIZE3*DYN_LIGHT_MASK_STRIDE/32)];
};

#ifdef RENDER_SHADOWCOMP
    layout(std430, binding = 3) restrict buffer localLightingData
#elif defined RENDER_BEGIN || defined RENDER_SHADOW
    layout(std430, binding = 3) restrict writeonly buffer localLightingData
#else
    layout(std430, binding = 3) restrict readonly buffer localLightingData
#endif
{
    LightCellData SceneLightMaps[];
};

#if defined RENDER_BEGIN || defined RENDER_SHADOW || defined RENDER_SHADOWCOMP
    layout(r32ui) uniform restrict uimage2D imgLocalLightMask;
#else
    layout(r32ui) uniform restrict readonly uimage2D imgLocalLightMask;
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #if defined RENDER_BEGIN || defined RENDER_SHADOW || defined RENDER_SHADOWCOMP
        layout(r32ui) uniform restrict uimage2D imgLocalBlockMask;
    #else
        layout(r32ui) uniform restrict readonly uimage2D imgLocalBlockMask;
    #endif
#endif
