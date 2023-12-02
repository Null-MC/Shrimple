vec4 BilateralGaussianDepthBlur_VL(const in vec2 texcoord, const in sampler2D blendSampler, const in vec2 blendTexSize, const in sampler2D depthSampler, const in vec2 depthTexSize, const in float depthL, const in vec2 g_sigma) {
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    float total = 0.0;
    vec4 accum = vec4(0.0);

    vec2 blendPixelSize = rcp(blendTexSize);
    vec2 depthPixelSize = rcp(depthTexSize);
    //vec2 depthTexcoord = texcoord * depthTexSize;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.x, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            
            ivec2 sampleTex = ivec2(ix, iy);

            //vec2 texBlend = texcoord + sampleTex * blendPixelSize;
            ivec2 texBlend = ivec2(texcoord * blendTexSize) + sampleTex;
            //vec4 sampleValue = textureLod(blendSampler, texBlend, 0);
            vec4 sampleValue = texelFetch(blendSampler, texBlend, 0);

            //vec2 texDepth = texcoord + sampleTex * depthPixelSize;
            ivec2 texDepth = ivec2(texcoord * depthTexSize) + sampleTex;
            //float sampleDepth = textureLod(depthSampler, texDepth, 0).r;
            float sampleDepth = texelFetch(depthSampler, texDepth, 0).r;
            float sampleDepthL = linearizeDepthFast(sampleDepth, near, far);
            
            float fv = Gaussian(g_sigma.y, abs(sampleDepthL - depthL));
            //float fv = Gaussian(g_sigma.y, abs(linearizeDepthFast(sampleDepth, near, far) - linearizeDepthFast(depth, near, far)));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    return accum / max(total, EPSILON);
}
