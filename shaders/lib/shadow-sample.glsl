float SampleShadows(const in vec3 shadowPos) {
    #if SHADOW_PCF_SAMPLES > 1
        vec2 seed = gl_FragCoord.xy;
        #ifdef TAA_ENABLED
            seed += vec2(157,107) * frameCounter;
        #endif

        float dither = InterleavedGradientNoise(seed);
        float angle = fract(dither) * (PI * 2.0);
        float s = sin(angle), c = cos(angle);
        mat2 rotation = mat2(c, -s, s, c);

        const float pixelRadius = 3.0 / shadowMapResolution;
    #endif

    float shadow = 0.0;
    for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
        vec3 shadowSamplePos = shadowPos;
        #if SHADOW_PCF_SAMPLES > 1
            float r = sqrt((i + 0.5) / SHADOW_PCF_SAMPLES);
            float theta = i * GoldenAngle + PHI;

            vec2 pcfDiskOffset = vec2(cos(theta), sin(theta)) * r;
            shadowSamplePos.xy += (rotation * pcfDiskOffset) * pixelRadius;
        #endif

        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            shadow += texture(shadowtex0HW, shadowSamplePos).r;
        #else
            float shadowDepth = texture(shadowtex0, shadowSamplePos.xy).r;
            shadow += step(shadowSamplePos.z, shadowDepth);
        #endif
    }

    return max(shadow / float(SHADOW_PCF_SAMPLES), 0.0);
}
