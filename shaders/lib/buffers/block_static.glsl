struct BlockCollisionData {
    uvec2 Bounds[BLOCK_MASK_PARTS]; // 8 x6=48
    uint Count;                     // 4
};

struct StaticBlockData {        // 76 x1280 =97280
    uint lightType;             // 4

    float materialRough;        // 4
    float materialMetalF0;      // 4
    float materialSSS;          // 4

    #ifdef WORLD_WAVING_ENABLED
        float wavingRange;          // 4
        uint wavingAttachment;      // 4
    #endif

    #if LIGHTING_MODE == DYN_LIGHT_TRACED || LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        BlockCollisionData Collisions;    // 52
    #endif
};

#ifdef RENDER_SETUP
    layout(binding = 2) writeonly buffer staticBlockData
#else
    layout(binding = 2) readonly buffer staticBlockData
#endif
{
    StaticBlockData StaticBlockMap[];
};
