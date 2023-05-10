struct CollissionData {
    uint Count;         // 4
    uvec2 Bounds[5];    // 40
};

#ifdef RENDER_SETUP
    layout(std430, binding = 5) writeonly buffer collissionData
#else
    layout(std430, binding = 5) readonly buffer collissionData
#endif
{
    CollissionData CollissionMaps[];   // 44 * 1200 = 52800
};
