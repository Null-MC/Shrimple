#define LIGHT_MASK_UP 1u
#define LIGHT_MASK_DOWN 2u
#define LIGHT_MASK_NORTH 3u
#define LIGHT_MASK_SOUTH 4u
#define LIGHT_MASK_WEST 5u
#define LIGHT_MASK_EAST 6u


struct StaticLightData {
    uint Color;
    uint Offset;
    uint RangeSize;
};

#ifdef RENDER_SETUP
    layout(std430, binding = 2) restrict writeonly buffer staticLightData
#else
    layout(std430, binding = 2) restrict readonly buffer staticLightData
#endif
{
    StaticLightData StaticLightMap[];
};

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #if defined RENDER_SHADOWCOMP || defined RENDER_SHADOW
        layout(std430, binding = 3) restrict buffer globalLightingData
    #elif defined RENDER_BEGIN
        layout(std430, binding = 3) restrict writeonly buffer globalLightingData
    #else
        layout(std430, binding = 3) restrict readonly buffer globalLightingData
    #endif
    {
        uint SceneLightCount;       // 4
        uint SceneLightMaxCount;    // 4

        //vec3 HandLightPos1;       // 16
        //vec3 HandLightPos2;       // 16

        vec3 sceneViewUp;           // 16
        vec3 sceneViewRight;        // 16
        vec3 sceneViewDown;         // 16
        vec3 sceneViewLeft;         // 16

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            uvec4 SceneLights[];
        #endif
    };

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        struct LightCellData {
            uint LightCount;
            uint LightNeighborCount;
            uint LightPreviousCount;
            uint GlobalLights[LIGHT_BIN_MAX_COUNT];
        };

        #if defined RENDER_SHADOWCOMP || defined RENDER_SHADOW || defined RENDER_BEGIN
            layout(std430, binding = 5) restrict buffer localLightingData
        #else
            layout(std430, binding = 5) restrict readonly buffer localLightingData
        #endif
        {
            LightCellData SceneLightMaps[];     // 16 * N
        };
    #endif

    #if defined RENDER_BEGIN || defined RENDER_SHADOW || defined RENDER_SHADOWCOMP
        layout(r32ui) uniform restrict uimage2D imgLocalLightMask;
    #else
        layout(r32ui) uniform restrict readonly uimage2D imgLocalLightMask;
    #endif
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SIZE > 0
    #if defined RENDER_BEGIN || defined RENDER_SHADOW || defined RENDER_SHADOWCOMP
        layout(r16ui) uniform restrict uimage2D imgLocalBlockMask;
    #else
        layout(r16ui) uniform restrict readonly uimage2D imgLocalBlockMask;
    #endif
#endif
