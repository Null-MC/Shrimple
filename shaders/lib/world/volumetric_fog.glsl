float ComputeVolumetricScattering(const in float VoL, const in float G_scattering) {
    float G_scattering2 = pow2(G_scattering);

    return rcp(4.0 * PI) * ((1.0 - G_scattering2) / (pow(1.0 + G_scattering2 - (2.0 * G_scattering) * VoL, 1.5)));
}

vec4 GetVolumetricLighting(const in vec3 localViewDir, const in float nearDist, const in float farDist) {
    #ifdef WORLD_SKY_ENABLED
        float scatterF = mix(0.032, 0.096, rainStrength) * VolumetricDensityF;
        float extinction = mix(0.004, 0.012, rainStrength) * VolumetricDensityF;
    #else
        float scatterF = 0.016 * VolumetricDensityF;
        float extinction = 0.016 * VolumetricDensityF;
    #endif

    vec3 localStart = localViewDir * (nearDist + 0.1);
    vec3 localEnd = localViewDir * (farDist - 0.1);
    float localRayLength = max(farDist - nearDist - 0.2, 0.0);
    if (localRayLength < EPSILON) return vec4(0.0, 0.0, 0.0, 1.0);

    int stepCount = int(ceil((localRayLength / far) * (VOLUMETRIC_SAMPLES - 2))) + 2;
    float inverseStepCountF = rcp(stepCount);
    
    vec3 localStep = localViewDir * (localRayLength * inverseStepCountF);

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    #ifdef WORLD_SKY_ENABLED
        const float ambient = 0.012;
        float G_Forward = mix(0.56, 0.26, rainStrength);
        float G_Back = mix(0.26, 0.16, rainStrength);
        const float G_mix = 0.7;
    #else
        const float ambient = 0.14;
        float G_Forward = 0.6;
        float G_Back = 0.5;
        const float G_mix = 0.5;
    #endif

    #if defined VOLUMETRIC_CELESTIAL && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        vec3 shadowViewStart = (shadowModelView * vec4(localStart, 1.0)).xyz;
        vec3 shadowViewEnd = (shadowModelView * vec4(localEnd, 1.0)).xyz;
        vec3 shadowViewStep = (shadowViewEnd - shadowViewStart) * inverseStepCountF;

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowClipStart[4];
            vec3 shadowClipStep[4];
            for (int c = 0; c < 4; c++) {
                shadowClipStart[c] = (cascadeProjection[c] * vec4(shadowViewStart, 1.0)).xyz * 0.5 + 0.5;
                shadowClipStart[c].xy = shadowClipStart[c].xy * 0.5 + shadowProjectionPos[c];

                vec3 shadowClipEnd = (cascadeProjection[c] * vec4(shadowViewEnd, 1.0)).xyz * 0.5 + 0.5;
                shadowClipEnd.xy = shadowClipEnd.xy * 0.5 + shadowProjectionPos[c];

                shadowClipStep[c] = (shadowClipEnd - shadowClipStart[c]) * inverseStepCountF;
            }
        #else
            vec3 shadowClipStart = (shadowProjection * vec4(shadowViewStart, 1.0)).xyz;
            vec3 shadowClipEnd = (shadowProjection * vec4(shadowViewEnd, 1.0)).xyz;
            vec3 shadowClipStep = (shadowClipEnd - shadowClipStart) * inverseStepCountF;
        #endif
        
        vec3 localLightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
        float VoL = dot(localLightDir, localViewDir);

        vec3 skyLightColor = 0.8*RGBToLinear(fogColor) + 0.02;

        float skyPhaseForward = ComputeVolumetricScattering(VoL, G_Forward);
        float skyPhaseBack = ComputeVolumetricScattering(VoL, -G_Back);
        float skyPhase = mix(skyPhaseBack, skyPhaseForward, G_mix);
    #endif

    float localStepLength = localRayLength * inverseStepCountF;

    float transmittance = 1.0;
    vec3 scattering = vec3(0.0);
    for (int i = 0; i < stepCount; i++) {
        vec3 inScattering = ambient * fogColor;

        #ifdef WORLD_SKY_ENABLED
            inScattering *= (eyeBrightnessSmooth.y / 240.0); //vec3(0.008);
        #endif

        #if defined VOLUMETRIC_CELESTIAL && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            const float sampleBias = 0.0;

            float sampleF = 0.0;
            vec3 sampleColor = skyLightColor;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vec3 shadowViewPos = shadowViewStep * (i + dither) + shadowViewStart;
                vec3 traceShadowClipPos = vec3(0.0);

                int cascade = GetShadowCascade(shadowViewPos, -1.0);
                
                if (cascade >= 0) {
                    traceShadowClipPos = shadowClipStart[cascade] + (i + dither) * shadowClipStep[cascade];
                    sampleF = CompareDepth(traceShadowClipPos, vec2(0.0), sampleBias);
                }
            #else
                vec3 traceShadowClipPos = shadowClipStep * (i + dither) + shadowClipStart;
                traceShadowClipPos = distort(traceShadowClipPos);
                traceShadowClipPos = traceShadowClipPos * 0.5 + 0.5;

                sampleF = CompareDepth(traceShadowClipPos, vec2(0.0), sampleBias);
            #endif

            #ifdef SHADOW_COLOR
                float transparentShadowDepth = SampleTransparentDepth(traceShadowClipPos.xy, vec2(0.0));

                if (traceShadowClipPos.z - transparentShadowDepth >= EPSILON) {
                    vec3 shadowColor = GetShadowColor(traceShadowClipPos.xy);

                    if (!any(greaterThan(shadowColor, EPSILON3))) shadowColor = vec3(1.0);
                    shadowColor = normalize(shadowColor) * 1.73;

                    sampleColor *= shadowColor;
                }
            #endif

            inScattering += skyPhase * sampleF * sampleColor;
        #endif

        vec3 traceLocalPos = localStep * (i + dither) + localStart;

        #if VOLUMETRIC_BLOCK_MODE != VOLUMETRIC_BLOCK_NONE && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined IRIS_FEATURE_SSBO
            uint gridIndex;
            uint lightCount = GetSceneLights(traceLocalPos, gridIndex);
            vec3 blockLightAccum = vec3(0.0);

            if (gridIndex != DYN_LIGHT_GRID_MAX) {
                for (uint i = 0; i < lightCount; i++) {
                    SceneLightData light = GetSceneLight(gridIndex, i);

                    vec3 lightVec = traceLocalPos - light.position;
                    if (dot(lightVec, lightVec) >= pow2(light.range)) continue;
                    
                    vec3 lightColor = light.color;
                    #if VOLUMETRIC_BLOCK_MODE != VOLUMETRIC_BLOCK_EMIT && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                        uint traceFace = 1u << GetLightMaskFace(lightVec);
                        if ((light.data & traceFace) == traceFace) continue;

                        if ((light.data & 1u) == 1u) {
                            vec3 traceOrigin = GetLightGridPosition(light.position);
                            vec3 traceEnd = traceOrigin + 0.999*lightVec;

                            #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                                lightColor *= TraceRay(traceOrigin, traceEnd, light.range);
                            #elif VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_TRACE_FULL
                                lightColor *= TraceDDA(traceOrigin, traceEnd, light.range);
                            #else
                                lightColor *= TraceDDA_fast(traceOrigin, traceEnd, light.range);
                            #endif
                        }
                    #endif

                    float lightVoL = dot(normalize(-lightVec), localViewDir);
                    float lightPhaseForward = ComputeVolumetricScattering(lightVoL, G_Forward);
                    float lightPhaseBack = ComputeVolumetricScattering(lightVoL, G_Back);
                    float lightPhase = mix(lightPhaseBack, lightPhaseForward, G_mix);

                    blockLightAccum += SampleLight(lightVec, 1.0, light.range) * lightColor * lightPhase;
                }
            }

            // if (!firstPersonCamera) {
            //     vec2 noiseSample = GetDynLightNoise(vec3(0.0));

            //     if (heldBlockLightValue > 0) {
            //         vec3 lightLocalPos = (gbufferModelViewInverse * vec4(HandLightOffsetR, 1.0)).xyz;
            //         if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;

            //         vec3 lightVec = lightLocalPos - traceLocalPos;
            //         if (dot(lightVec, lightVec) < pow2(heldBlockLightValue)) {
            //             vec3 lightColor = GetSceneItemLightColor(heldItemId, noiseSample);

            //             #if VOLUMETRIC_BLOCK_MODE != VOLUMETRIC_BLOCK_EMIT && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            //                 vec3 traceOrigin = GetLightGridPosition(lightLocalPos);
            //                 vec3 traceEnd = traceOrigin - 0.99*lightVec;

            //                 #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
            //                     lightColor *= TraceRay(traceOrigin, traceEnd, heldBlockLightValue);
            //                 #elif VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_TRACE_FULL
            //                     lightColor *= TraceDDA(traceEnd, traceOrigin, heldBlockLightValue);
            //                 #else
            //                     lightColor *= TraceDDA_fast(traceEnd, traceOrigin, heldBlockLightValue);
            //                 #endif
            //             #endif

            //             float lightVoL = dot(normalize(lightVec), localViewDir);
            //             float lightPhaseForward = ComputeVolumetricScattering(lightVoL, G_Forward);
            //             float lightPhaseBack = ComputeVolumetricScattering(lightVoL, G_Back);
            //             float lightPhase = mix(lightPhaseBack, lightPhaseForward, G_mix);

            //             blockLightAccum += SampleLight(lightVec, 1.0, heldBlockLightValue) * lightColor * lightPhase;
            //         }
            //     }

            //     if (heldBlockLightValue2 > 0) {
            //         vec3 lightLocalPos = (gbufferModelViewInverse * vec4(HandLightOffsetL, 1.0)).xyz;
            //         if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;

            //         vec3 lightVec = lightLocalPos - traceLocalPos;
            //         if (dot(lightVec, lightVec) < pow2(heldBlockLightValue2)) {
            //             vec3 lightColor = GetSceneItemLightColor(heldItemId2, noiseSample);

            //             #if VOLUMETRIC_BLOCK_MODE != VOLUMETRIC_BLOCK_EMIT && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            //                 vec3 traceOrigin = GetLightGridPosition(lightLocalPos);
            //                 vec3 traceEnd = traceOrigin - 0.99*lightVec;

            //                 #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
            //                     lightColor *= TraceRay(traceOrigin, traceEnd, heldBlockLightValue2);
            //                 #elif VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_TRACE_FULL
            //                     lightColor *= TraceDDA(traceEnd, traceOrigin, heldBlockLightValue2);
            //                 #else
            //                     lightColor *= TraceDDA_fast(traceEnd, traceOrigin, heldBlockLightValue2);
            //                 #endif
            //             #endif

            //             float lightVoL = dot(normalize(lightVec), localViewDir);
            //             float lightPhaseForward = ComputeVolumetricScattering(lightVoL, G_Forward);
            //             float lightPhaseBack = ComputeVolumetricScattering(lightVoL, G_Back);
            //             float lightPhase = mix(lightPhaseBack, lightPhaseForward, G_mix);
                        
            //             blockLightAccum += SampleLight(lightVec, 1.0, heldBlockLightValue2) * lightColor * lightPhase;
            //         }
            //     }
            // }

            inScattering += 0.5*blockLightAccum * DynamicLightBrightness;
        #endif

        inScattering *= scatterF;

        float sampleTransmittance = exp(-extinction * localStepLength);
        vec3 scatteringIntegral = (inScattering - inScattering * sampleTransmittance) / extinction;

        scattering += scatteringIntegral * transmittance;
        transmittance *= sampleTransmittance;
    }

    return vec4(scattering, transmittance);
}
