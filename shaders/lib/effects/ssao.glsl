const float SSAO_bias = EFFECT_SSAO_BIAS * 0.01;

#define EFFECT_SSAO_RT
const int SSAO_TRACE_SAMPLES = 6;


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

    #ifdef EFFECT_SSAO_RT
        float viewDist = length(viewPos);
        float radius = mix(0.6, 16.0, viewDist / 800.0);
    #else
        // const float inv = rcp(EFFECT_SSAO_SAMPLES);
        const float rStep = EFFECT_SSAO_RADIUS / float(EFFECT_SSAO_SAMPLES);

        float rotatePhase = dither * TAU;
        float radius = rStep;
    #endif

    float ao = 0.0;
    float maxWeight = 0.0;
    for (int i = 0; i < EFFECT_SSAO_SAMPLES; i++) {
        #ifdef EFFECT_SSAO_RT
            #ifdef EFFECT_TAA_ENABLED
                vec3 offset = hash33(vec3(gl_FragCoord.xy, frameCounter + i)) - 0.5;
            #else
                vec3 offset = hash33(vec3(gl_FragCoord.xy, i)) - 0.5;
            #endif

            offset = normalize(offset) * radius;// * dither;
            offset *= sign(dot(offset, viewNormal));

            //offset.z += viewDist * 0.001;
        #else
            vec3 offset = vec3(
                sin(rotatePhase),
                cos(rotatePhase),
                0.0) * radius;

            radius += rStep;
            rotatePhase += GOLDEN_ANGLE;
        #endif

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

        if (saturate(sampleClipPos.xy) != sampleClipPos.xy) continue;

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
            if (sampleClipDepth >= 1.0) continue;

            sampleClipPos.z = sampleClipDepth;
            sampleViewPos = unproject(gbufferProjectionInverse, sampleClipPos * 2.0 - 1.0);
        #endif

        // sampleClipPos.z = sampleClipDepth;
        // sampleViewPos = unproject(gbufferProjectionInverse * vec4(sampleClipPos * 2.0 - 1.0, 1.0));

        vec3 diff = sampleViewPos - viewPos;
        float sampleDist = length(diff);
        vec3 sampleNormal = diff / sampleDist;

        float sampleNoLm = max(dot(viewNormal, sampleNormal) - SSAO_bias, 0.0) / (1.0 - SSAO_bias);
        // float sampleNoLm = max(dot(viewNormal, sampleNormal), 0.0);

        #ifdef EFFECT_SSAO_RT
            float sampleWeight = 1.0;//saturate(sampleDist / radius);
        #else
            float sampleWeight = saturate(sampleDist / (EFFECT_SSAO_RADIUS));
            sampleWeight = 1.0 - sampleWeight;
        #endif

        // sampleWeight = pow(sampleWeight, 4.0);
//        sampleWeight = 1.0 - sampleWeight;

        #ifdef EFFECT_SSAO_RT
            // TODO: RT step check
            //float sampleOcclusion = 0.0;
            //float traceStepSize = 0.01;
            vec3 clipPos = unproject(projection, viewPos) * 0.5 + 0.5;
            // TODO: fix DH projection!

            //vec3 traceStep = normalize(sampleClipPos - clipPos) * traceStepSize;
            vec3 traceStep = (sampleClipPos - clipPos) / SSAO_TRACE_SAMPLES;
            vec3 traceClipPos = clipPos + dither*traceStep;

            bool hit = false;
            for (int i = 0; i < SSAO_TRACE_SAMPLES; i++) {
                float sampleNear = near;
                float sampleFar = farPlane;
                float sampleDepth = textureLod(depthtex0, traceClipPos.xy, 0).r;

                #ifdef DISTANT_HORIZONS
                    if (sampleDepth >= 1.0) {
                        sampleDepth = textureLod(dhDepthTex, traceClipPos.xy, 0).r;
                        sampleNear = dhNearPlane;
                        sampleFar = dhFarPlane;
                    }
                #endif

                float sampleDepthL = linearizeDepthFast(sampleDepth, sampleNear, sampleFar);
                float traceDepthL = linearizeDepthFast(traceClipPos.z, traceNear, traceFar);

                float thickness = 0.2 + 0.14*viewDist;

                if (traceDepthL > sampleDepthL + EPSILON && traceDepthL < sampleDepthL + thickness) hit = true;

                traceClipPos += traceStep;
                //traceStep *= 1.5;
            }

            if (!hit) sampleNoLm = 0.0;
        #endif

        ao += sampleNoLm * sampleWeight;
        maxWeight += sampleWeight;
    }

    #ifdef EFFECT_SSAO_RT
        ao = ao / max(maxWeight, 0.001);
        ao = pow(ao, rcp(EFFECT_SSAO_STRENGTH));
    #else
        ao = ao / max(maxWeight, 1.0);
        //ao = ao / max(maxWeight, 1.0) * EFFECT_SSAO_STRENGTH;
        //ao = ao / (ao + rcp(EFFECT_SSAO_STRENGTH));
        ao = smoothstep(0.0, 0.5, ao);
    #endif

    return ao;
}
