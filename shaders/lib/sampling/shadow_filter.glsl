float shadow_GaussianFilter(const in vec2 texcoord, const in float linearDepth) {
    float g_sigmaX = 3.0;
    float g_sigmaY = 3.0;
    float g_sigmaV = 3.0 / linearDepth;

    float total = 0.0;
    float accum = 0.0;

    vec2 blendPixelSize = rcp(viewSize);
    
    for (float iy = -SHADOW_BLUR_SIZE; iy <= SHADOW_BLUR_SIZE; iy++) {
        float fy = Gaussian(g_sigmaY, iy);

        for (float ix = -SHADOW_BLUR_SIZE; ix <= SHADOW_BLUR_SIZE; ix++) {
            float fx = Gaussian(g_sigmaX, ix);
            
            vec2 sampleTex = texcoord + vec2(ix, iy) * blendPixelSize;

            ivec2 iTexBlend = ivec2(sampleTex * viewSize);
            float sampleValue = texelFetch(BUFFER_DEFERRED_SHADOW, iTexBlend, 0).r;

            ivec2 depthCoord = ivec2(sampleTex * viewSize);

            #ifdef RENDER_OPAQUE_FINAL
                float sampleDepth = texelFetch(depthtex1, depthCoord, 0).r;
            #else
                float sampleDepth = texelFetch(depthtex0, depthCoord, 0).r;
            #endif

            float sampleDepthL = linearizeDepthFast(sampleDepth, near, farPlane);

            #ifdef DISTANT_HORIZONS
                #ifdef RENDER_OPAQUE_FINAL
                    float dhDepth = texelFetch(dhDepthTex1, depthCoord, 0).r;
                #else
                    float dhDepth = texelFetch(dhDepthTex, depthCoord, 0).r;
                #endif

                float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

                if (dhDepthL < sampleDepthL || sampleDepth >= 1.0) {
                    //sampleDepth = dhDepth;
                    sampleDepthL = dhDepthL;
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

vec3 shadow_GaussianFilterRGB(const in vec2 texcoord, const in float linearDepth) {
    //float g_sigmaV = 0.03 * _pow2(sigmaV) + 0.1;
    const vec3 g_sigma = vec3(3.0, 3.0, 0.25);

    //float g_sigmaX = 3.0;
    //float g_sigmaY = 3.0;

    float total = 0.0;
    vec3 accum = vec3(0.0);

    vec2 blendPixelSize = rcp(viewSize);
    //vec2 blendTexcoord = texcoord * viewSize;
    vec2 depthTexcoord = texcoord * viewSize;
    
    for (float iy = -SHADOW_BLUR_SIZE; iy <= SHADOW_BLUR_SIZE; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -SHADOW_BLUR_SIZE; ix <= SHADOW_BLUR_SIZE; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            
            vec2 sampleTex = vec2(ix, iy);

            vec2 texBlend = texcoord + sampleTex * blendPixelSize;
            vec3 sampleValue = textureLod(BUFFER_DEFERRED_SHADOW, texBlend, 0).rgb;

            ivec2 depthCoord = ivec2(depthTexcoord + sampleTex);

            #ifdef RENDER_OPAQUE_FINAL
                float sampleDepth = texelFetch(depthtex1, depthCoord, 0).r;
            #else
                float sampleDepth = texelFetch(depthtex0, depthCoord, 0).r;
            #endif

            float sampleDepthL = linearizeDepthFast(sampleDepth, near, farPlane);
            
            #ifdef DISTANT_HORIZONS
                #ifdef RENDER_OPAQUE_FINAL
                    float dhDepth = texelFetch(dhDepthTex1, depthCoord, 0).r;
                #else
                    float dhDepth = texelFetch(dhDepthTex, depthCoord, 0).r;
                #endif

                float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

                if (dhDepthL < sampleDepthL || sampleDepth >= 1.0) {
                    //sampleDepth = dhDepth;
                    sampleDepthL = dhDepthL;
                }
            #endif

            float fv = Gaussian(g_sigma.z, abs(sampleDepthL - linearDepth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return vec3(0.0);
    return accum / total;
}
