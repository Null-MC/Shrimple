vec4 BilateralGaussianDepthBlur_VL(const in vec2 texcoord, const in sampler2D blendSampler, const in vec2 depthTexSize, const in float depthL) {
    const float bufferScaleInv = rcp(exp2(VOLUMETRIC_RES));
    const vec2 g_sigma = vec2(3.0, 2.0);
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    #if VOLUMETRIC_RES == 2
        const float _offset = 2.0001;
    #elif VOLUMETRIC_RES == 1
        const float _offset = 1.5000;
    #else
        const float _offset = 1.0001;
    #endif

    vec2 blendTexSize = viewSize * bufferScaleInv;

    float total = 0.0;
    vec4 accum = vec4(0.0);

    vec2 blendPixelSize = rcp(blendTexSize);
    vec2 depthPixelSize = rcp(depthTexSize);
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.x, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);

            ivec2 texBlend = ivec2(texcoord * blendTexSize) + ivec2(ix, iy);
            vec4 sampleValue = texelFetch(blendSampler, texBlend, 0);

            ivec2 depthCoord = ivec2(texBlend / blendTexSize * depthTexSize + _offset);

            #ifdef RENDER_OPAQUE_POST_VL
                float sampleDepth = texelFetch(depthtex1, depthCoord, 0).r;
            #else
                float sampleDepth = texelFetch(depthtex0, depthCoord, 0).r;
            #endif

            // float _near = near;
            // float _far = far * 4.0;

            // #ifdef DISTANT_HORIZONS
            //     #ifdef RENDER_OPAQUE_POST_VL
            //         if (sampleDepth >= 1.0) {
            //             sampleDepth = texelFetch(dhDepthTex1, depthCoord, 0).r;
            //             _near = dhNearPlane;
            //             _far = dhFarPlane;
            //         }
            //     #else
            //         float sampleDepthOpaque = texelFetch(depthtex1, depthCoord, 0).r;
                    
            //         if (sampleDepth >= 1.0 || sampleDepth == sampleDepthOpaque) {
            //             sampleDepth = texelFetch(dhDepthTex, depthCoord, 0).r;
            //             _near = dhNearPlane;
            //             _far = dhFarPlane;
            //         }
            //     #endif
            //     // float sampleDepthOpaque = texelFetch(depthtex1, depthCoord, 0).r;
                
            //     if (sampleDepth >= 1.0) {// || sampleDepth == sampleDepthOpaque) {
            //         #ifdef RENDER_OPAQUE_POST_VL
            //             sampleDepth = texelFetch(dhDepthTex1, depthCoord, 0).r;
            //         #else
            //             sampleDepth = texelFetch(dhDepthTex, depthCoord, 0).r;
            //         #endif
            //         _near = dhNearPlane;
            //         _far = dhFarPlane;
            //     }
            // #endif

            // float sampleDepthL = linearizeDepthFast(sampleDepth, _near, _far);
            
            float farPlane = far * 4.0;
            float sampleDepthL = linearizeDepthFast(sampleDepth, near, farPlane);

            #ifdef DISTANT_HORIZONS
                #ifdef RENDER_OPAQUE_POST_VL
                    float dhDepth = textureLod(dhDepthTex1, texcoord, 0).r;
                #else
                    float dhDepth = textureLod(dhDepthTex, texcoord, 0).r;
                #endif

                float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

                if (dhDepthL < sampleDepthL || sampleDepth >= 1.0) {
                    sampleDepth = dhDepth;
                    sampleDepthL = dhDepthL;
                }
            #endif

            float fv = Gaussian(g_sigma.y, abs(sampleDepthL - depthL));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total < 0.0002) return vec4(0.0, 0.0, 0.0, 1.0);
    return accum / max(total, EPSILON);
}
