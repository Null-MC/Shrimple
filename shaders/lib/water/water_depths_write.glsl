void SetWaterDepth(const in float viewDist) {
    float farMax = far;
    #ifdef DISTANT_HORIZONS
        farMax = dhFarPlane;
    #endif
    
    uint uvIndex = GetWaterDepthIndex(uvec2(gl_FragCoord.xy));

    uint depthIs = uint(saturate(viewDist / farMax) * UINT32_MAX + 0.5);
    for (int i = 0; i < WATER_DEPTH_LAYERS; i++) {
        uint depthWas = atomicMin(WaterDepths[uvIndex].Depth[i], depthIs);
        depthIs = max(depthWas, depthIs);
    }
}
