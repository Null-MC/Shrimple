#ifdef RENDER_COMPOSITE_WATER_MASK
    layout(binding = 5) writeonly buffer waterMask
#else
    layout(binding = 5) readonly buffer waterMask
#endif
{
    uint WaterMask[];
};
