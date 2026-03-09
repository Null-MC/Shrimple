const float ShadowPixelRadius = 1.8 / shadowMapResolution;


float GetShadowDither() {
    vec2 seed = gl_FragCoord.xy;

    #ifdef TAA_ENABLED
        seed += vec2(71.83, 83.71) * frameCounter;
    #endif

    return InterleavedGradientNoise(seed);
}

float SampleShadows(const in vec3 shadowPos) {
    #if SHADOW_PCF_SAMPLES > 1
        float dither = GetShadowDither();
        float angle = fract(dither) * (PI * 2.0);
        float s = sin(angle), c = cos(angle);
        mat2 rotation = mat2(c, -s, s, c);
    #endif

    float shadow = 0.0;
    for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
        vec3 shadowSamplePos = shadowPos;
        #if SHADOW_PCF_SAMPLES > 1
            float r = sqrt((i + 0.5) / SHADOW_PCF_SAMPLES);
            float theta = i * GoldenAngle + PHI;

            vec2 pcfDiskOffset = vec2(cos(theta), sin(theta)) * r;
            shadowSamplePos.xy += (rotation * pcfDiskOffset) * ShadowPixelRadius;
        #endif

        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            shadow += texture(TEX_SHADOW, shadowSamplePos).r;
        #else
            float shadowDepth = texture(TEX_SHADOW, shadowSamplePos.xy).r;
            shadow += step(shadowSamplePos.z, shadowDepth);
        #endif
    }

    return max(shadow / float(SHADOW_PCF_SAMPLES), 0.0);
}
