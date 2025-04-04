float GetCloudDither() {
    #ifndef RENDER_FRAG
        return 0.0;
    #elif defined EFFECT_TAA_ENABLED
        return InterleavedGradientNoiseTime();
    #else
        return InterleavedGradientNoise();
    #endif
}

//float unmix(const in float min, const in float max, const in float value) {
//    return saturate((value - min) / (max - min));
//}

float SampleCloudDensity(const in vec3 worldPos) {
    float cloudAlt = GetCloudAltitude();

    vec3 samplePos = worldPos * 0.0001;
    samplePos.y = mod(0.002*cloudTime, 1.0);

    float weight = 1.0;
    float maxWeight = 0.0;
    float noise = 0.0;
    for (int i = 0; i < SKY_CLOUD_DETAIL; i++) {
        float sampleNoise = 1.0 - textureLod(TEX_CLOUDS, samplePos, 0).r;
        noise += weight * sampleNoise;

        samplePos.xz *= 2.5;
        maxWeight += weight;
        weight *= 0.4;
    }

    noise /= maxWeight;

//    float noise1 = 1.0 - textureLod(TEX_CLOUDS, samplePos, 0).r;
//    float noise2 = 1.0 - textureLod(TEX_CLOUDS, samplePos*3.0, 0).r;
//    float noise3 = 1.0 - textureLod(TEX_CLOUDS, samplePos*16.0, 0).r;
//    float noise = 0.6*noise1 + 0.3*noise2 + 0.1*noise3;

    const float cloudScaleY = rcp(80);
    float heightDiff = abs(worldPos.y - cloudAlt);
    //noise = min(noise, max(1.0 - heightDiff*cloudScaleY, 0.0));
    noise = max(noise - heightDiff*cloudScaleY, 0.0);

    float threshold = mix(0.48, 0.36, weatherCloudStrength);
    //noise = smoothstep(threshold, 1.0, noise);
    noise = saturate(unmix(noise, threshold, 1.0));
    //noise = noise*noise;

    noise *= smoothstep(8000.0, 5000.0, distance(worldPos.xz, cameraPosition.xz));

    float densityF = mix(15.0, 25.0, weatherStrength);

    return noise * densityF;
}
