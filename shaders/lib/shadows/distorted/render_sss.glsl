float GetSss_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float offsetBias, const in float sssBias) {
    float dither = GetShadowDither();

    float angle = fract(dither) * TAU;
    float s = sin(angle), c = cos(angle);
    mat2 rotation = mat2(c, -s, s, c);

    float shadow = 0.0;
    for (int i = 0; i < SHADOW_SSS_SAMPLES; i++) {
        #ifdef IRIS_FEATURE_SSBO
            vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
        #else
            float r = sqrt((i + 0.5) / SHADOW_SSS_SAMPLES);
            float theta = i * GoldenAngle + PHI;
            
            vec2 pcfDiskOffset = vec2(cos(theta), sin(theta)) * r;
            vec2 pixelOffset = (rotation * pcfDiskOffset) * pixelRadius;
        #endif

        float sampleBias = offsetBias + sssBias * InterleavedGradientNoiseTime(i);

        shadow += 1.0 - CompareDepth(shadowPos, pixelOffset, sampleBias);
    }

    return 1.0 - shadow * rcp(SHADOW_SSS_SAMPLES);
}

float GetSssFactor(const in vec3 shadowPos, const in float offsetBias, const in float sss) {
    float zRange = GetShadowRange();
    float sssBias = sss * MATERIAL_SSS_MAXDIST / zRange;

    float sssRadius = sss * MATERIAL_SSS_SCATTER;
    vec2 pixelRadius = GetShadowPixelRadius(shadowPos, sssRadius);
    float shadow_sss = GetSss_PCF(shadowPos, pixelRadius, offsetBias, sssBias);
    return sss * shadow_sss;
}
