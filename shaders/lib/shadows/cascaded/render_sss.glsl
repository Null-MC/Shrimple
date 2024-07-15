float GetSss_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
    float dither = GetShadowDither();
    float angle = fract(dither) * TAU;
    float s = sin(angle), c = cos(angle);
    mat2 rotation = mat2(c, -s, s, c);

    float shadow = 0.0;
    for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
        vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
        shadow += 1.0 - CompareDepth(shadowPos, pixelOffset, bias);
    }

    return 1.0 - shadow * rcp(SHADOW_PCF_SAMPLES);
}

// PCF
float GetSssFactor(const in vec3 shadowPos, const in int cascade, const in float sss) {
    float sssRadius = sss * MATERIAL_SSS_SCATTER;
    vec2 pixelRadius = GetPixelRadius(sssRadius, cascade);
    float offsetBias = GetShadowOffsetBias(cascade);

    // float sssBias = sss * MATERIAL_SSS_MAXDIST / zRange;

    float shadow_sss = GetSss_PCF(shadowPos, pixelRadius, offsetBias);
    return sss * shadow_sss;
}
