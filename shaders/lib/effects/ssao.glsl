//const float SSAO_bias = EFFECT_SSAO_BIAS * 0.01;


float GetSpiralOcclusion(const in vec3 viewPos, const in vec3 viewNormal) {
    #ifdef EFFECT_TAA_ENABLED
        vec2 texSize = textureSize(texBlueNoise, 0);
        vec2 coord = (gl_FragCoord.xy + vec2(71.0, 83.0) * frameCounter) / texSize;
        float dither = textureLod(texBlueNoise, fract(coord), 0).r;

        //float dither = InterleavedGradientNoiseTime();
    #else
        vec2 texSize = textureSize(texBlueNoise, 0);
        vec2 coord = gl_FragCoord.xy / texSize;
        float dither = textureLod(texBlueNoise, coord, 0).r;

        //float dither = InterleavedGradientNoise();
    #endif

    float viewDist = length(viewPos);
    float max_radius = min(EFFECT_SSAO_RADIUS, viewDist);

    // const float inv = rcp(EFFECT_SSAO_SAMPLES);
    float rStep = max_radius / EFFECT_SSAO_SAMPLES;

    float rotatePhase = dither * TAU;
    float radius = rStep;

    float ao = 0.0;
    float maxWeight = 0.0;
    for (int i = 0; i < EFFECT_SSAO_SAMPLES; i++) {
        vec3 offset = vec3(
            sin(rotatePhase),
            cos(rotatePhase),
        0.0) * radius;

        radius += rStep;
        rotatePhase += GOLDEN_ANGLE;

        vec3 sampleViewPos = viewPos + offset;

        #ifdef DISTANT_HORIZONS
            mat4 projection = gbufferProjection;
            float traceNear = near;
            float traceFar = farPlane;
            if (abs(sampleViewPos.z) > dhNearPlane) {
                projection = dhProjection;
                traceNear = dhNearPlane;
                traceFar = dhFarPlane;
            }

            vec3 sampleClipPos = unproject(projection, sampleViewPos);
        #else
            vec3 sampleClipPos = unproject(gbufferProjection, sampleViewPos);
        #endif

        sampleClipPos = fma(sampleClipPos, vec3(0.5), vec3(0.5));

        if (saturate(sampleClipPos.xy) != sampleClipPos.xy) {
            //maxWeight += 1.0;
            continue;
        }

        float sampleClipDepth = textureLod(depthtex0, sampleClipPos.xy, 0.0).r;

        #ifdef DISTANT_HORIZONS
            mat4 projectionInv = gbufferProjectionInverse;

            if (sampleClipDepth >= 1.0) {
                sampleClipDepth = textureLod(dhDepthTex, sampleClipPos.xy, 0.0).r;
                //projection = dhProjection;
                projectionInv = dhProjectionInverse;
            }

            if (sampleClipDepth >= 1.0) {
                maxWeight += 1.0;
                continue;
            }

            sampleClipPos.z = sampleClipDepth;
            sampleViewPos = unproject(projectionInv, sampleClipPos * 2.0 - 1.0);
        #else
            if (sampleClipDepth >= 1.0) {
                maxWeight += 1.0;
                continue;
            }

            sampleClipPos.z = sampleClipDepth;
            sampleViewPos = unproject(gbufferProjectionInverse, sampleClipPos * 2.0 - 1.0);
        #endif

        // sampleClipPos.z = sampleClipDepth;
        // sampleViewPos = unproject(gbufferProjectionInverse * vec4(sampleClipPos * 2.0 - 1.0, 1.0));

        //sampleViewPos.z -= 0.2;

        vec3 diff = sampleViewPos - viewPos;
        float sampleDist = length(diff);
        vec3 sampleNormal = diff / sampleDist;

        //float sampleNoLm = max(dot(viewNormal, sampleNormal) - SSAO_bias, 0.0) / (1.0 - SSAO_bias);
        float sampleNoLm = max(dot(viewNormal, sampleNormal), 0.0);

        float sampleWeight = saturate(sampleDist / (EFFECT_SSAO_RADIUS));
        sampleWeight = 1.0 - sampleWeight;

        // sampleWeight = pow(sampleWeight, 4.0);
//        sampleWeight = 1.0 - sampleWeight;

        ao += sampleNoLm * sampleWeight;
        maxWeight += sampleWeight;
    }

    ao = ao / max(maxWeight, 1.0);
    //ao = ao / max(maxWeight, 1.0) * EFFECT_SSAO_STRENGTH;
    //ao = ao / (ao + rcp(EFFECT_SSAO_STRENGTH));
    ao = smoothstep(0.0, 1.0, ao * EFFECT_SSAO_STRENGTH);

    return ao;
}
