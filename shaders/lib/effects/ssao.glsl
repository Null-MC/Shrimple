float GetSpiralOcclusion(const in vec3 viewPos, const in vec3 viewNormal) {
    const float inv = rcp(EFFECT_SSAO_SAMPLES);
    const float rStep = EFFECT_SSAO_RADIUS / float(EFFECT_SSAO_SAMPLES);

    #ifdef EFFECT_TAA_ENABLED
        float dither = InterleavedGradientNoiseTime();
    #else
        float dither = InterleavedGradientNoise();
    #endif

    float rotatePhase = dither * TAU;

    float radius = rStep;
    vec2 offset;

    float ao = 0.0;
    int sampleCount = 0;
    for (int i = 0; i < EFFECT_SSAO_SAMPLES; i++) {
        vec2 offset = vec2(
            sin(rotatePhase),
            cos(rotatePhase)
        ) * radius;

        radius += rStep;
        rotatePhase += GOLDEN_ANGLE;

        vec3 sampleViewPos = viewPos + vec3(offset, 0.0);
        vec3 sampleClipPos = unproject(gbufferProjection, sampleViewPos) * 0.5 + 0.5;
        //sampleClipPos = saturate(sampleClipPos);
        if (saturate(sampleClipPos.xy) != sampleClipPos.xy) continue;
        sampleCount++;

        float sampleClipDepth = textureLod(depthtex0, sampleClipPos.xy, 0.0).r;

        #ifdef DISTANT_HORIZONS
            mat4 projectionInv = gbufferProjectionInverse;

            if (sampleClipDepth >= 1.0) {
                sampleClipDepth = textureLod(dhDepthTex0, sampleClipPos.xy, 0.0).r;
                projectionInv = dhProjectionInverse;
            }

            if (sampleClipDepth >= 1.0) continue;

            sampleClipPos.z = sampleClipDepth;
            sampleViewPos = unproject(projectionInv, sampleClipPos * 2.0 - 1.0);
        #else
            if (sampleClipDepth >= 1.0) continue;

            sampleClipPos.z = sampleClipDepth;
            sampleViewPos = unproject(gbufferProjectionInverse, sampleClipPos * 2.0 - 1.0);
        #endif

        // sampleClipPos.z = sampleClipDepth;
        // sampleViewPos = unproject(gbufferProjectionInverse * vec4(sampleClipPos * 2.0 - 1.0, 1.0));

        vec3 diff = sampleViewPos - viewPos;
        float sampleDist = length(diff);
        vec3 sampleNormal = diff / sampleDist;

        float sampleNoLm = max(dot(viewNormal, sampleNormal) - EFFECT_SSAO_BIAS, 0.0) / (1.0 - EFFECT_SSAO_BIAS);
        float aoF = 1.0 - saturate(sampleDist / (EFFECT_SSAO_RADIUS));
        ao += sampleNoLm * aoF;// * pow(aoF, 1.5);
    }

    ao = saturate(ao / max(sampleCount, 1) * EFFECT_SSAO_STRENGTH);

    ao = pow(ao / (ao + 0.1), 4.0);

    return ao;
}
