vec4 BilateralGaussianDepthBlur_VL(const in vec2 texcoord, const in sampler2D blendSampler, const in vec2 blendTexSize, const in sampler2D depthSampler, const in vec2 depthTexSize, const in float depth, const in vec2 g_sigma) {
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    float total = 0.0;
    vec4 accum = vec4(0.0);

    vec2 blendPixelSize = rcp(blendTexSize);
    vec2 depthPixelSize = rcp(depthTexSize);
    vec2 depthTexcoord = texcoord * depthTexSize;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.x, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            
            vec2 sampleTex = vec2(ix, iy);

            vec2 texBlend = texcoord + sampleTex * blendPixelSize;
            vec4 sampleValue = textureLod(blendSampler, texBlend, 0);

            vec2 texDepth = texcoord + sampleTex * depthPixelSize;
            float sampleDepth = textureLod(depthSampler, texDepth, 0).r;
                        
            float fv = Gaussian(g_sigma.y, abs(sampleDepth - depth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    return accum / max(total, EPSILON);
}
