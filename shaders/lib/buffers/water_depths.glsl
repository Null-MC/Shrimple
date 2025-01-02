struct WaterDepthPixelData {
    // uint Count;                  // 4
    uint Depth[WATER_DEPTH_LAYERS]; // 16
};

#if defined RENDER_WATER || defined RENDER_WATER_DH || defined RENDER_OCEAN
    layout(binding = 7) buffer waterDepths
#elif defined RENDER_BEGIN
    layout(binding = 7) writeonly buffer waterDepths
#else
    layout(binding = 7) readonly buffer waterDepths
#endif
{
    WaterDepthPixelData WaterDepths[];
};

uint GetWaterDepthIndex(uvec2 uv) {
    return uint(fma(uv.y, uint(viewWidth), uv.x));
}
