struct StaticBlockData {        // 24 x 1280
    float wavingRange;          // 4
    uint wavingAttachment;      // 4

    float materialRough;        // 4
    float materialMetalF0;      // 4
    float materialSSS;          // 4

    uint lightType;               // 4
};

#ifdef RENDER_SETUP
    layout(binding = 2) restrict writeonly buffer staticBlockData
#else
    layout(binding = 2) restrict readonly buffer staticBlockData
#endif
{
    StaticBlockData StaticBlockMap[];
};
