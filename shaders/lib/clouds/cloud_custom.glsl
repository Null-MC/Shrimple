float GetCloudDither() {
    #ifndef RENDER_FRAG
        return 0.0;
    #elif defined EFFECT_TAA_ENABLED
        return InterleavedGradientNoiseTime();
    #else
        return InterleavedGradientNoise();
    #endif
}

float SampleCloudDensity(const in vec3 worldPos) {
    float cloudAlt = GetCloudAltitude();

    const float cloudScale = 1.0 / 512.0;

    vec2 windOffset = vec2(0.003, 0.007) * cloudTime;

    vec3 samplePos;
    samplePos.xz = 0.06 * cloudScale * (worldPos.xz - windOffset);
    samplePos.y = mod(0.004*cloudTime, 1.0);

    return textureLod(TEX_CLOUDS, samplePos, 0).r * 8.0
        - textureLod(TEX_CLOUDS, samplePos*vec2(24.0,1.0).xyx, 0).r * 0.4;
}
