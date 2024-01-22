struct WaterDepthPixelData {
    bool IsWater;                   // 4
    uint Depth[WATER_DEPTH_LAYERS]; // 16
};

#if defined RENDER_WATER || defined RENDER_WATER_DH
    layout(binding = 7) buffer waterDepths
#elif defined RENDER_BEGIN
    layout(binding = 7) writeonly buffer waterDepths
#else
    layout(binding = 7) readonly buffer waterDepths
#endif
{
    WaterDepthPixelData WaterDepths[];
};

#if defined RENDER_WATER || defined RENDER_WATER_DH
    void SetWaterDepth(const in float viewDist) {
        float farMax = far;
        #ifdef DISTANT_HORIZONS
            farMax = dhFarPlane;
        #endif
        
        uvec2 uv = uvec2(gl_FragCoord.xy);
        uint uvIndex = uint(uv.y * viewWidth + uv.x);
        WaterDepths[uvIndex].IsWater = true;

        uint depthIs = uint(saturate(viewDist / farMax) * UINT32_MAX + 0.5);
        for (int i = 0; i < WATER_DEPTH_LAYERS; i++) {
            uint depthWas = atomicMin(WaterDepths[uvIndex].Depth[i], depthIs);
            depthIs = max(depthWas, depthIs);
        }
    }
#endif

#ifndef RENDER_BEGIN
    void GetAllWaterDepths(const in uint uvIndex, out float waterDepth[WATER_DEPTH_LAYERS+1]) {
        float farMax = far;
        #ifdef DISTANT_HORIZONS
            farMax = dhFarPlane;
        #endif

        WaterDepthPixelData waterPixel = WaterDepths[uvIndex];

        if (isEyeInWater == 1) waterDepth[0] = 0.0;
        else waterDepth[WATER_DEPTH_LAYERS] = farMax;

        int o = isEyeInWater == 1 ? 1 : 0;
        for (int i = 0; i < WATER_DEPTH_LAYERS; i++) {
            waterDepth[i+o] = saturate(waterPixel.Depth[i] * uint32MaxInv) * farMax;
        }
    }
#endif
