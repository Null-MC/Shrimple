struct StaticLightData {
    uint Color;
    uint Offset;
    uint RangeSize;
};

#ifdef RENDER_SETUP
    layout(binding = 3) writeonly buffer staticLightData
#else
    layout(binding = 3) readonly buffer staticLightData
#endif
{
    StaticLightData StaticLightMap[];
};
