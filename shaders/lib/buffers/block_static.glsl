struct BlockCollisionData {
    uvec2 Bounds[BLOCK_MASK_PARTS]; // 8 x6=48
    uint Count;                     // 4
};

struct StaticBlockData {        // 80 x1280 =102400
    uint lightType;             // 4

    float materialRough;        // 4
    float materialMetalF0;      // 4
    float materialSSS;          // 4

    #if WORLD_WIND_STRENGTH > 0
        float wavingRange;          // 4
        uint wavingAttachment;      // 4
    #endif

    #ifdef IS_LPV_ENABLED
        uint lpv_data;              // 4
    #endif

    #ifdef IS_TRACING_ENABLED
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


#ifdef IS_LPV_ENABLED
    // TODO: add more mask data

    uint BuildBlockLpvData(uint mixMask, float mixWeight) {
        uint data = uint(saturate(mixWeight) * 255.0);

        data = data | (mixMask << 8);

        return data;
    }

    void ParseBlockLpvData(const in uint data, out uint mixMask, out float mixWeight) {
        mixWeight = (data & 0xFF) / 255.0;

        mixMask = (data >> 8) & 0xFF;
    }
#endif
