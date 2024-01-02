struct WaterDepthPixelData {
    bool IsWater;                   // 4
    uint Depth[WATER_DEPTH_LAYERS]; // 16
};

#ifdef RENDER_WATER
    layout(std430, binding = 7) buffer waterDepths
#elif defined RENDER_BEGIN
    layout(std430, binding = 7) writeonly buffer waterDepths
#else
    layout(std430, binding = 7) readonly buffer waterDepths
#endif
{
    WaterDepthPixelData WaterDepths[];
};

#ifdef RENDER_WATER
    void SetWaterDepth(const in float viewDist) {
        uvec2 uv = uvec2(gl_FragCoord.xy);
        uint uvIndex = uint(uv.y * viewWidth + uv.x);
        WaterDepths[uvIndex].IsWater = true;

        uint depthIs = uint(saturate(viewDist / far) * UINT32_MAX + 0.5);
        for (int i = 0; i < WATER_DEPTH_LAYERS; i++) {
            uint depthWas = atomicMin(WaterDepths[uvIndex].Depth[i], depthIs);
            depthIs = max(depthWas, depthIs);
        }
    }
#endif

#ifndef RENDER_BEGIN
    void GetAllWaterDepths(const in uint uvIndex, out float waterDepth[WATER_DEPTH_LAYERS+1]) {
        WaterDepthPixelData waterPixel = WaterDepths[uvIndex];

        if (isEyeInWater == 1) waterDepth[0] = 0.0;
        else waterDepth[WATER_DEPTH_LAYERS] = far;

        int o = isEyeInWater == 1 ? 1 : 0;
        for (int i = 0; i < WATER_DEPTH_LAYERS; i++) {
            waterDepth[i+o] = saturate(waterPixel.Depth[i] * uint32MaxInv) * far;
        }
    }
#endif
