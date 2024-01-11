#define LIGHT_MASK_UP 1u
#define LIGHT_MASK_DOWN 2u
#define LIGHT_MASK_NORTH 3u
#define LIGHT_MASK_SOUTH 4u
#define LIGHT_MASK_WEST 5u
#define LIGHT_MASK_EAST 6u


#if LIGHTING_MODE != DYN_LIGHT_NONE
    #if defined RENDER_SHADOWCOMP || defined RENDER_SHADOW
        layout(binding = 4) buffer globalLightingData
    #elif defined RENDER_BEGIN
        layout(binding = 4) writeonly buffer globalLightingData
    #else
        layout(binding = 4) readonly buffer globalLightingData
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

        #if LIGHTING_MODE == DYN_LIGHT_TRACED
            uvec4 SceneLights[];
        #endif
    };

    #if LIGHTING_MODE == DYN_LIGHT_TRACED
        struct LightCellData {
            uint LightCount;
            uint LightNeighborCount;
            uint LightPreviousCount;
            uint GlobalLights[LIGHT_BIN_MAX_COUNT];
        };

        #if defined RENDER_SHADOWCOMP || defined RENDER_BEGIN || defined RENDER_GEOMETRY || defined RENDER_VERTEX
            layout(binding = 6) buffer localLightingData
        #else
            layout(binding = 6) readonly buffer localLightingData
        #endif
        {
            LightCellData SceneLightMaps[];     // 16 * N
        };
    #endif

    #if defined RENDER_BEGIN || defined RENDER_SHADOWCOMP || defined RENDER_GEOMETRY || defined RENDER_VERTEX
        layout(r32ui) uniform uimage2D imgLocalLightMask;
    #else
        layout(r32ui) uniform readonly uimage2D imgLocalLightMask;
    #endif
#endif
