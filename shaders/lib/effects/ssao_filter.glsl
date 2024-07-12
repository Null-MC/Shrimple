#ifdef RENDER_OPAQUE_FINAL
    #define SSAO_FILTER_DEPTHTEX depthtex1
#else
    #define SSAO_FILTER_DEPTHTEX depthtex0
#endif

float BilateralGaussianDepthBlur_5x(const in vec2 texcoord, const in float linearDepth) {
    const float g_sigmaXY = 2.0;
    const float g_sigmaV = 0.02;

    const float c_halfSamplesX = 1.0;
    const float c_halfSamplesY = 1.0;

    float total = 0.0;
    float accum = 0.0;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigmaXY, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigmaXY, ix);
            
            vec2 sampleTex = texcoord + vec2(ix, iy) * pixelSize;

            ivec2 iTexBlend = ivec2(sampleTex * viewSize);
            float sampleValue = texelFetch(BUFFER_SSAO, iTexBlend, 0).r;

            ivec2 iTexDepth = ivec2(sampleTex * viewSize);
            float sampleDepth = texelFetch(SSAO_FILTER_DEPTHTEX, iTexDepth, 0).r;
            float sampleDepthL = linearizeDepth(sampleDepth, near, farPlane);

            #ifdef DISTANT_HORIZONS
                float dhDepth = texelFetch(dhDepthTex, iTexDepth, 0).r;
                float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

                if (sampleDepth >= 1.0 || (dhDepthL < sampleDepthL && dhDepth > 0.0)) {
                    sampleDepthL = dhDepthL;
                    //sampleDepth = dhDepth;
                }
            #endif
            
            float fv = Gaussian(g_sigmaV, abs(sampleDepthL - linearDepth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return 0.0;
    return accum / total;
}
