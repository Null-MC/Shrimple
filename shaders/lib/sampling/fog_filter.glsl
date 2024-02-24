void VL_GaussianFilter(inout vec3 final, const in vec2 texcoord, const in float depthL) {
    const vec3 g_sigma = vec3(1.6, 1.6, 0.2);

    const int bufferScale = int(exp2(VOLUMETRIC_RES));
    const float bufferScaleInv = rcp(bufferScale);

    vec2 srcTexSize = viewSize * bufferScaleInv;
    ivec2 srcCenterCoord = ivec2(texcoord * srcTexSize);
    ivec2 depthCenterCoord = srcCenterCoord * bufferScale + int(0.5 * bufferScale + 0.25);
    // ivec2 depthCenterCoord = srcCenterCoord * bufferScale + (bufferScale - 1);

    vec3 scatterFinal = vec3(0.0);
    vec3 transmitFinal = vec3(0.0);
    float total = 0.0;
    
    for (float iy = -VOLUMETRIC_BLUR_SIZE; iy <= VOLUMETRIC_BLUR_SIZE; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -VOLUMETRIC_BLUR_SIZE; ix <= VOLUMETRIC_BLUR_SIZE; ix++) {
            float fx = Gaussian(g_sigma.x, ix);

            ivec2 srcCoord = srcCenterCoord + ivec2(ix, iy);
            vec3 sampleScatter = texelFetch(BUFFER_VL_SCATTER, srcCoord, 0).rgb;
            vec3 sampleTransmit = 1.0 - texelFetch(BUFFER_VL_TRANSMIT, srcCoord, 0).rgb;

            // ivec2 depthCoord = ivec2(srcCoord / srcTexSize * viewSize + _offset * bufferScale);
            ivec2 depthCoord = depthCenterCoord + ivec2(ix, iy) * bufferScale;

            #ifdef RENDER_OPAQUE_POST_VL
                float sampleDepth = texelFetch(depthtex1, depthCoord, 0).r;
            #else
                float sampleDepth = texelFetch(depthtex0, depthCoord, 0).r;
            #endif
            
            float sampleDepthL = linearizeDepth(sampleDepth, near, farPlane);

            #ifdef DISTANT_HORIZONS
                #ifdef RENDER_OPAQUE_POST_VL
                    float dhDepth = texelFetch(dhDepthTex1, depthCoord, 0).r;
                #else
                    float dhDepth = texelFetch(dhDepthTex, depthCoord, 0).r;
                #endif

                float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

                if (sampleDepth >= 1.0 || (dhDepthL < sampleDepthL && dhDepth > 0.0)) {
                    sampleDepth = dhDepth;
                    sampleDepthL = dhDepthL;
                }
            #endif

            float fv = Gaussian(g_sigma.z, 10.0*clamp(abs(sampleDepthL - depthL), 0.0, 0.2));
            
            float weight = fx*fy*fv;
            scatterFinal += weight * sampleScatter;
            transmitFinal += weight * sampleTransmit;
            total += weight;
        }
    }
    
    //if (total > 0.002) {
        //total = max(total, EPSILON);
        scatterFinal /= total;
        transmitFinal /= total;
        transmitFinal = 1.0 - transmitFinal;

        final = final * transmitFinal + scatterFinal;
    //}
}
