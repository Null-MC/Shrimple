const float SSAO_bias = EFFECT_SSAO_BIAS * 0.01;

#define EFFECT_SSAO_RT


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
    float maxWeight = 0.0;
    for (int i = 0; i < EFFECT_SSAO_SAMPLES; i++) {
        #ifdef EFFECT_SSAO_RT
            vec3 offset = hash33(vec3(gl_FragCoord.xy, i + frameCounter)) - 0.5;
            offset = normalize(offset) * EFFECT_SSAO_RADIUS * dither;
            offset *= sign(dot(offset, viewNormal));
        #else
            vec3 offset = vec3(
                sin(rotatePhase),
                cos(rotatePhase),
                0.0) * radius;

            radius += rStep;
            rotatePhase += GOLDEN_ANGLE;
        #endif

        vec3 sampleViewPos = viewPos + offset;
        // sampleViewPos.z += 0.5;
        vec3 sampleClipPos = unproject(gbufferProjection, sampleViewPos) * 0.5 + 0.5;

        if (saturate(sampleClipPos.xy) != sampleClipPos.xy) continue;

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

        // float sampleNoLm = max(dot(viewNormal, sampleNormal) - SSAO_bias, 0.0) / (1.0 - SSAO_bias);
        float sampleNoLm = max(dot(viewNormal, sampleNormal), 0.0);

        float sampleWeight = saturate(sampleDist / (EFFECT_SSAO_RADIUS));

        // sampleWeight = pow(sampleWeight, 4.0);
        sampleWeight = 1.0;// - sampleWeight;

        ao += sampleNoLm * sampleWeight;
        maxWeight += sampleWeight;
    }

    #ifdef EFFECT_SSAO_RT
        ao = ao / max(maxWeight, 1.0);
        ao = pow(ao, rcp(EFFECT_SSAO_STRENGTH));
    #else
        ao = ao / max(maxWeight, 1.0) * EFFECT_SSAO_STRENGTH;
        ao = ao / (ao + rcp(EFFECT_SSAO_STRENGTH));
    #endif

    return ao;
}
