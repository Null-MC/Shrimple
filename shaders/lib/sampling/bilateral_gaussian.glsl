float Gaussian(const in float sigma, const in float x) {
    return exp(-pow2(x) / (2.0 * pow2(sigma)));
}

float BilateralGaussianDepthBlur_5x(const in vec2 texcoord, const in sampler2D blendSampler, const in vec2 blendTexSize, const in sampler2D depthSampler, const in vec2 depthTexSize, const in float linearDepth, const in float g_sigmaV) {
    //float g_sigmaV = 0.03 * pow2(sigmaV) + 0.1;

    float g_sigmaX = 3.0;
    float g_sigmaY = 3.0;

    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    float total = 0.0;
    float accum = 0.0;

    vec2 blendPixelSize = rcp(blendTexSize);
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigmaY, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigmaX, ix);
            
            vec2 sampleTex = texcoord + vec2(ix, iy) * blendPixelSize;

            ivec2 iTexBlend = ivec2(sampleTex * blendTexSize);
            float sampleValue = texelFetch(blendSampler, iTexBlend, 0).r;

            ivec2 iTexDepth = ivec2(sampleTex * depthTexSize);
            float sampleDepth = texelFetch(depthSampler, iTexDepth, 0).r;
            float sampleLinearDepth = linearizeDepthFast(sampleDepth, near, far);
                        
            float fv = Gaussian(g_sigmaV, abs(sampleLinearDepth - linearDepth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return 0.0;
    return accum / total;
}

vec3 BilateralGaussianDepthBlurRGB_5x(const in vec2 texcoord, const in sampler2D blendSampler, const in vec2 blendTexSize, const in sampler2D depthSampler, const in vec2 depthTexSize, const in float linearDepth, const in float g_sigmaV) {
    //float g_sigmaV = 0.03 * pow2(sigmaV) + 0.1;

    float g_sigmaX = 3.0;
    float g_sigmaY = 3.0;

    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    float total = 0.0;
    vec3 accum = vec3(0.0);

    vec2 blendPixelSize = rcp(blendTexSize);
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigmaY, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigmaX, ix);
            
            vec2 sampleTex = texcoord + vec2(ix, iy) * blendPixelSize;

            ivec2 iTexBlend = ivec2(sampleTex * blendTexSize);
            vec3 sampleValue = texelFetch(blendSampler, iTexBlend, 0).rgb;

            ivec2 iTexDepth = ivec2(sampleTex * depthTexSize);
            float sampleDepth = texelFetch(depthSampler, iTexDepth, 0).r;
            float sampleLinearDepth = linearizeDepthFast(sampleDepth, near, far);
                        
            float fv = Gaussian(g_sigmaV, abs(sampleLinearDepth - linearDepth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return vec3(0.0);
    return accum / total;
}
