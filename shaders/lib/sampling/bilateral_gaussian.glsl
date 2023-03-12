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

vec3 BilateralGaussianDepthBlurRGB_5x(const in vec2 texcoord, const in sampler2D blendSampler, const in vec2 blendTexSize, const in sampler2D depthSampler, const in vec2 depthTexSize, const in float linearDepth, const in vec3 g_sigma) {
    //float g_sigmaV = 0.03 * pow2(sigmaV) + 0.1;

    //float g_sigmaX = 3.0;
    //float g_sigmaY = 3.0;

    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    float total = 0.0;
    vec3 accum = vec3(0.0);

    vec2 blendPixelSize = rcp(blendTexSize);
    //vec2 blendTexcoord = texcoord * blendTexSize;
    vec2 depthTexcoord = texcoord * depthTexSize;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            
            vec2 sampleTex = vec2(ix, iy);

            vec2 texBlend = texcoord + sampleTex * blendPixelSize;
            vec3 sampleValue = textureLod(blendSampler, texBlend, 0).rgb;

            ivec2 iTexDepth = ivec2(depthTexcoord + sampleTex);
            float sampleDepth = texelFetch(depthSampler, iTexDepth, 0).r;
            float sampleLinearDepth = linearizeDepthFast(sampleDepth, near, far);
                        
            float fv = Gaussian(g_sigma.z, abs(sampleLinearDepth - linearDepth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return vec3(0.0);
    return accum / total;
}

vec3 BilateralGaussianDepthBlurRGB_7x(const in vec2 texcoord, const in sampler2D blendSampler, const in float blendTexScale, const in sampler2D depthSampler, const in vec2 depthTexSize, const in float linearDepth, const in vec3 g_sigma) {
    const float c_halfSamplesX = 3.0;
    const float c_halfSamplesY = 3.0;

    float total = 0.0;
    vec3 accum = vec3(0.0);

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 blendPixelSize = rcp(viewSize * blendTexScale);
    //vec2 depthPixelSize = rcp(depthTexSize);
    vec3 defaultColor;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            vec2 sampleTex = vec2(ix, iy);

            vec2 sampleBlendTex = texcoord + sampleTex * blendPixelSize;
            vec3 sampleValue = textureLod(blendSampler, sampleBlendTex, 0).rgb;

            if (abs(iy) < EPSILON && abs(ix) < EPSILON) defaultColor = sampleValue;

            ivec2 iTexDepth = ivec2(texcoord * depthTexSize + sampleTex);
            float sampleDepth = texelFetch(depthSampler, iTexDepth, 0).r;

            iTexDepth = ivec2(texcoord * viewSize + sampleTex / blendTexScale);
            float handClipDepth = texelFetch(depthtex2, iTexDepth, 0).r;
            if (handClipDepth > sampleDepth) {
                sampleDepth = sampleDepth * 2.0 - 1.0;
                sampleDepth /= MC_HAND_DEPTH;
                sampleDepth = sampleDepth * 0.5 + 0.5;
            }

            sampleDepth = linearizeDepthFast(sampleDepth, near, far);
            
            float fv = Gaussian(g_sigma.z, abs(sampleDepth - linearDepth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return defaultColor;
    return accum / total;
}
