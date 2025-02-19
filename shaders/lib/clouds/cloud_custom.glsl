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
    vec3 samplePos = worldPos * 0.0001;
    samplePos.y = mod(samplePos.y + 0.002*cloudTime, 1.0);
    float noise1 = 1.0 - textureLod(TEX_CLOUDS, samplePos, 0).r;
    float noise2 = 1.0 - textureLod(TEX_CLOUDS, samplePos*3.0, 0).r;
    float noise = 0.7*noise1 + 0.3*noise2;

    noise = min(noise, max(1.0 - 0.05*abs(worldPos.y - cloudHeight), 0.0));

    float threshold = mix(0.42, 0.28, weatherStrength);
    noise = smoothstep(threshold, 1.0, noise);

    noise *= smoothstep(8000.0, 5000.0, distance(worldPos.xz, cameraPosition.xz));

    float densityF = mix(1.0, 4.0, weatherStrength);

    return noise * densityF;
}
