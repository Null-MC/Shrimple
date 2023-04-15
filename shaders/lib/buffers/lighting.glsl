#define LIGHT_MASK_UP 1u
#define LIGHT_MASK_DOWN 2u
#define LIGHT_MASK_NORTH 3u
#define LIGHT_MASK_SOUTH 4u
#define LIGHT_MASK_WEST 5u
#define LIGHT_MASK_EAST 6u


#ifdef RENDER_SHADOWCOMP
    layout(std430, binding = 1) restrict buffer globalLightingData
#elif defined RENDER_BEGIN
    layout(std430, binding = 1) restrict writeonly buffer globalLightingData
#elif defined RENDER_SHADOW
    layout(std430, binding = 1) restrict buffer globalLightingData
#else
    layout(std430, binding = 1) restrict readonly buffer globalLightingData
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
    uint LightMask[(LIGHT_BIN_SIZE3*DYN_LIGHT_MASK_STRIDE/32)];
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

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    struct BlockCellData {
        uint BlockMask[(LIGHT_BIN_SIZE3*DYN_LIGHT_MASK_STRIDE/32)];
        #ifdef DYN_LIGHT_OCTREE
            uint OctreeMask[DYN_LIGHT_OCTREE_SIZE];
        #endif
    };

    #ifdef RENDER_SHADOWCOMP
        layout(std430, binding = 3) restrict buffer localBlockData
    #elif defined RENDER_BEGIN || defined RENDER_SHADOW
        layout(std430, binding = 3) restrict writeonly buffer localBlockData
    #else
        layout(std430, binding = 3) restrict readonly buffer localBlockData
    #endif
    {
        BlockCellData SceneBlockMaps[];
    };
#endif
