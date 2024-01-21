void VL_GaussianFilter(inout vec3 final, const in vec2 texcoord, const in float depthL) {
    const vec2 g_sigma = vec2(3.0, 2.0);
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    // #if VOLUMETRIC_RES == 2
    //     const float _offset = 2.0001;
    // #elif VOLUMETRIC_RES == 1
    //     const float _offset = 1.5000;
    // #else
    //     const float _offset = 1.0001;
    // #endif

    const int bufferScale = int(exp2(VOLUMETRIC_RES));
    const float bufferScaleInv = rcp(bufferScale);

    vec2 srcTexSize = viewSize * bufferScaleInv;
    ivec2 srcCenterCoord = ivec2(texcoord * srcTexSize);
    ivec2 depthCenterCoord = srcCenterCoord * bufferScale + int(0.5 * bufferScale);

    vec3 scatterFinal = vec3(0.0);
    vec3 transmitFinal = vec3(0.0);
    float total = 0.0;

    // vec2 srcPixelSize = rcp(srcTexSize);
    // vec2 depthPixelSize = rcp(viewSize);
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.x, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);

            ivec2 srcCoord = srcCenterCoord + ivec2(ix, iy);
            vec3 sampleScatter = texelFetch(BUFFER_VL_SCATTER, srcCoord, 0).rgb;
            vec3 sampleTransmit = texelFetch(BUFFER_VL_TRANSMIT, srcCoord, 0).rgb;

            // ivec2 depthCoord = ivec2(srcCoord / srcTexSize * viewSize + _offset * bufferScale);
            ivec2 depthCoord = depthCenterCoord + ivec2(ix, iy) * bufferScale;

            #ifdef RENDER_OPAQUE_POST_VL
                float sampleDepth = texelFetch(depthtex1, depthCoord, 0).r;
            #else
                float sampleDepth = texelFetch(depthtex0, depthCoord, 0).r;
            #endif
            
            float sampleDepthL = linearizeDepthFast(sampleDepth, near, farPlane);

            #ifdef DISTANT_HORIZONS
                #ifdef RENDER_OPAQUE_POST_VL
                    float dhDepth = texelFetch(dhDepthTex1, depthCoord, 0).r;
                #else
                    float dhDepth = texelFetch(dhDepthTex, depthCoord, 0).r;
                #endif

                float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

                if (dhDepthL < sampleDepthL || sampleDepth >= 1.0) {
                    sampleDepth = dhDepth;
                    sampleDepthL = dhDepthL;
                }
            #endif

            float fv = Gaussian(g_sigma.y, abs(sampleDepthL - depthL));
            
            float weight = fx*fy*fv;
            scatterFinal += weight * sampleScatter;
            transmitFinal += weight * sampleTransmit;
            total += weight;
        }
    }
    
    if (total > 0.0002) {
        total = max(total, EPSILON);
        scatterFinal /= total;
        transmitFinal /= total;
        final = final * transmitFinal + scatterFinal;
    }
}
