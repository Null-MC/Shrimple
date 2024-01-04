struct CollissionData {
    uint Count;                     // 4
    uvec2 Bounds[BLOCK_MASK_PARTS]; // 48
};

#ifdef RENDER_SETUP
    layout(binding = 5) writeonly buffer collissionData
#else
    layout(binding = 5) readonly buffer collissionData
#endif
{
    CollissionData CollissionMaps[];   // 52 * 1200 = 62400
};
