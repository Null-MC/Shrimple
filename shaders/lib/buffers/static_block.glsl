struct StaticBlockData {        // 20 x 1024
    float wavingRange;          // 4
    uint wavingAttachment;      // 4

    float materialRough;        // 4
    float materialMetalF0;      // 4
    float materialSSS;          // 4
};

#ifdef RENDER_SETUP
    layout(std430, binding = 2) restrict writeonly buffer staticBlockData
#else
    layout(std430, binding = 2) restrict readonly buffer staticBlockData
#endif
{
    StaticBlockData StaticBlockMap[];
};
