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
