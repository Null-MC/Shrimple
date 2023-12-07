struct WaterDepthPixelData {
    bool IsWater;                   // 4
    uint Depth[WATER_DEPTH_LAYERS]; // 16
};

#ifdef RENDER_WATER
    layout(std430, binding = 6) buffer waterDepths
#elif defined RENDER_BEGIN
    layout(std430, binding = 6) writeonly buffer waterDepths
#else
    layout(std430, binding = 6) readonly buffer waterDepths
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
    float GetWaterDepth(const in uint uvIndex, const in int depthIndex) {
        uint depth = WaterDepths[uvIndex].Depth[depthIndex];
        return saturate(depth * uint32MaxInv) * far;
    }

    void GetAllWaterDepths(const in uint uvIndex, const in float transDist, out float waterDepth[WATER_DEPTH_LAYERS+1]) {
        int o = isEyeInWater == 1 ? 1 : 0;

        if (isEyeInWater == 1) waterDepth[0] = 0.0;
        else waterDepth[WATER_DEPTH_LAYERS] = far;

        // waterDepth[0] = GetWaterDepth(uvIndex, 0);
        // if (isEyeInWater == 1 && transDist < waterDepth[0] - 0.1) {
        //     waterDepth[1] = waterDepth[0];
        //     waterDepth[0] = transDist;
        //     o = 1;
        // }
        // else {
        //     waterDepth[WATER_DEPTH_LAYERS] = far;
        // }

        for (int i = 0; i < WATER_DEPTH_LAYERS; i++)
            waterDepth[i+o] = GetWaterDepth(uvIndex, i);
    }
#endif
