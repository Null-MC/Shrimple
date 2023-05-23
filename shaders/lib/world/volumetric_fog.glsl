float ComputeVolumetricScattering(const in float VoL, const in float G_scattering) {
    float G_scattering2 = _pow2(G_scattering);

    return rcp(4.0 * PI) * ((1.0 - G_scattering2) / (pow(1.0 + G_scattering2 - (2.0 * G_scattering) * VoL, 1.5)));
}

void GetVolumetricPhaseFactors(out float ambient, out float G_Forward, out float G_Back) {
    #ifdef WORLD_WATER_ENABLED
        if (isEyeInWater == 1) {
            ambient = 0.012;
            G_Forward = 0.26;
            G_Back = 0.16;
        }
        else {
    #endif
        #ifdef WORLD_SKY_ENABLED
            ambient = 0.012;
            G_Forward = mix(0.66, 0.26, rainStrength);
            G_Back = mix(0.36, 0.16, rainStrength);
        #else
            ambient = 0.14;
            G_Forward = 0.8;
            G_Back = 0.3;
        #endif
    #ifdef WORLD_WATER_ENABLED
        }
    #endif
}

void GetVolumetricCoeff(const in vec3 sunDir, out float scattering, out float extinction) {
    float density = (sunDir.y * -0.2 + 0.8) * VolumetricDensityF;

    #ifdef WORLD_SKY_ENABLED
        scattering = mix(0.032, 0.096, rainStrength) * density;
        extinction = mix(0.004, 0.012, rainStrength) * density;
    #else
        scattering = 0.016 * density;
        extinction = 0.016 * density;
    #endif
}

vec4 GetVolumetricLighting(const in vec3 localViewDir, const in vec3 sunDir, const in float nearDist, const in float farDist) {
    float scatterF, extinction;
    GetVolumetricCoeff(sunDir, scatterF, extinction);

    vec3 localStart = localViewDir * (nearDist + 0.1);
    vec3 localEnd = localViewDir * (farDist - 0.1);
    float localRayLength = max(farDist - nearDist - 0.2, 0.0);
    if (localRayLength < EPSILON) return vec4(0.0, 0.0, 0.0, 1.0);

    int stepCount = VOLUMETRIC_SAMPLES;
    //int stepCount = int(ceil((localRayLength / far) * (VOLUMETRIC_SAMPLES - 2))) + 2;
    float inverseStepCountF = rcp(stepCount);
    
    vec3 localStep = localViewDir * (localRayLength * inverseStepCountF);

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    float ambient, G_Forward, G_Back;
    GetVolumetricPhaseFactors(ambient, G_Forward, G_Back);
    const float G_mix = 0.7;

    #if defined VOLUMETRIC_CELESTIAL && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #ifdef IRIS_FEATURE_SSBO
            vec3 shadowViewStart = (shadowModelViewEx * vec4(localStart, 1.0)).xyz;
            vec3 shadowViewEnd = (shadowModelViewEx * vec4(localEnd, 1.0)).xyz;
        #else
            vec3 shadowViewStart = (shadowModelView * vec4(localStart, 1.0)).xyz;
            vec3 shadowViewEnd = (shadowModelView * vec4(localEnd, 1.0)).xyz;
        #endif

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
            #ifdef IRIS_FEATURE_SSBO
                vec3 shadowClipStart = (shadowProjectionEx * vec4(shadowViewStart, 1.0)).xyz;
                vec3 shadowClipEnd = (shadowProjectionEx * vec4(shadowViewEnd, 1.0)).xyz;
            #else
                vec3 shadowClipStart = (shadowProjection * vec4(shadowViewStart, 1.0)).xyz;
                vec3 shadowClipEnd = (shadowProjection * vec4(shadowViewEnd, 1.0)).xyz;
            #endif

            vec3 shadowClipStep = (shadowClipEnd - shadowClipStart) * inverseStepCountF;
        #endif
        
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
        #endif

        float VoL = dot(-localSkyLightDirection, -localViewDir);

        #ifndef IRIS_FEATURE_SSBO
            vec3 WorldSkyLightColor = GetSkyLightColor(sunDir);
        #endif

        vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        skyLightColor *= WorldSkyLightColor * smoothstep(0.0, 0.1, abs(sunDir.y));

        float skyPhaseForward = ComputeVolumetricScattering(VoL, G_Forward);
        float skyPhaseBack = ComputeVolumetricScattering(VoL, -G_Back);
        float skyPhase = mix(skyPhaseBack, skyPhaseForward, G_mix);
    #endif

    float localStepLength = localRayLength * inverseStepCountF;
    float sampleTransmittance = exp(-extinction * localStepLength);
    float extinctionInv = rcp(extinction);

    #ifdef WORLD_SKY_ENABLED
        float eyeLightLevel = (eyeBrightnessSmooth.y / 240.0);
    #endif

    float transmittance = 1.0;
    vec3 scattering = vec3(0.0);
    for (int i = 0; i <= stepCount; i++) {
        vec3 inScattering = ambient * fogColor;

        #ifdef WORLD_SKY_ENABLED
            inScattering *= eyeLightLevel;
        #endif

        float iStep = i;// + dither;
        if (i < stepCount) iStep += dither;

        #if defined VOLUMETRIC_CELESTIAL && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            float sampleF = 1.0;
            vec3 sampleColor = skyLightColor;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vec3 shadowViewPos = shadowViewStep * iStep + shadowViewStart;
                vec3 traceShadowClipPos = vec3(-1.0);

                int cascade = GetShadowCascade(shadowViewPos, -0.01);
                
                if (cascade >= 0) {
                    float sampleBias = GetShadowOffsetBias(cascade);// 0.01 / (far * 3.0);
                    traceShadowClipPos = shadowClipStart[cascade] + iStep * shadowClipStep[cascade];
                    //sampleF = CompareDepth(traceShadowClipPos, vec2(0.0), sampleBias);
                    float texDepth = texture(shadowtex1, traceShadowClipPos.xy).r;
                    sampleF = step(traceShadowClipPos.z - sampleBias, texDepth);
                }
            #else
                float sampleBias = GetShadowOffsetBias();// (0.01 / 256.0);

                vec3 traceShadowClipPos = shadowClipStep * iStep + shadowClipStart;
                traceShadowClipPos = distort(traceShadowClipPos);
                traceShadowClipPos = traceShadowClipPos * 0.5 + 0.5;

                //sampleF = CompareDepth(traceShadowClipPos, vec2(0.0), sampleBias);
                float texDepth = texture(shadowtex1, traceShadowClipPos.xy).r;
                sampleF = step(traceShadowClipPos.z - sampleBias, texDepth);
            #endif

            #ifdef SHADOW_COLORED
                float transparentShadowDepth = texture(shadowtex0, traceShadowClipPos.xy).r;

                if (traceShadowClipPos.z - transparentShadowDepth >= EPSILON) {
                    vec3 shadowColor = texture(shadowcolor0, traceShadowClipPos.xy).rgb;
                    shadowColor = RGBToLinear(shadowColor);

                    if (!any(greaterThan(shadowColor, EPSILON3))) shadowColor = vec3(1.0);
                    shadowColor = normalize(shadowColor) * 1.73;

                    sampleColor *= shadowColor;
                }
            #endif

            inScattering += skyPhase * sampleF * sampleColor;
        #endif

        vec3 traceLocalPos = localStep * iStep + localStart;

        #if VOLUMETRIC_BLOCK_MODE != VOLUMETRIC_BLOCK_NONE && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined IRIS_FEATURE_SSBO
            vec3 blockLightAccum = vec3(0.0);

            #if LPV_SIZE > 0 && VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_EMIT
                vec3 lpvPos = GetLPVPosition(traceLocalPos);
                vec3 lpvTexcoord = GetLPVTexCoord(lpvPos);

                if (saturate(lpvTexcoord) == lpvTexcoord) {
                    int frameIndex = frameCounter % 2;
                    blockLightAccum = textureLod(frameIndex == 0 ? texLPV_1 : texLPV_2, lpvTexcoord, 0).rgb / 16.0;
                    blockLightAccum /= 1.0 + luminance(blockLightAccum);

                    float lpvFade = GetLpvFade(lpvPos);
                    blockLightAccum *= smoothstep(0.0, 1.0, lpvFade);
                }
            #else
                uint gridIndex;
                uint lightCount = GetSceneLights(traceLocalPos, gridIndex);

                if (gridIndex != DYN_LIGHT_GRID_MAX) {
                    for (uint l = 0; l < lightCount; l++) {
                        uvec4 lightData = GetSceneLight(gridIndex, l);

                        vec3 lightPos, lightColor;
                        float lightSize, lightRange;
                        ParseLightData(lightData, lightPos, lightSize, lightRange, lightColor);

                        lightRange *= VolumetricBlockRangeF;
                        lightColor = RGBToLinear(lightColor);

                        vec3 lightVec = traceLocalPos - lightPos;
                        if (length2(lightVec) >= _pow2(lightRange)) continue;
                        
                        #if VOLUMETRIC_BLOCK_MODE != VOLUMETRIC_BLOCK_EMIT && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                            uint traceFace = 1u << GetLightMaskFace(lightVec);
                            if ((lightData.z & traceFace) == traceFace) continue;

                            if ((lightData.z & 1u) == 1u) {
                                vec3 traceOrigin = GetLightGridPosition(lightPos);
                                vec3 traceEnd = traceOrigin + 0.999*lightVec;

                                #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                                    lightColor *= TraceRay(traceOrigin, traceEnd, lightRange);
                                #elif VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_TRACE_FULL
                                    lightColor *= TraceDDA(traceOrigin, traceEnd, lightRange);
                                #else
                                    lightColor *= TraceDDA_fast(traceOrigin, traceEnd, lightRange);
                                #endif
                            }
                        #endif

                        float lightVoL = dot(normalize(-lightVec), localViewDir);
                        float lightPhaseForward = ComputeVolumetricScattering(lightVoL, G_Forward);
                        float lightPhaseBack = ComputeVolumetricScattering(lightVoL, G_Back);
                        float lightPhase = mix(lightPhaseBack, lightPhaseForward, G_mix);

                        float lightAtt = GetLightAttenuation(lightVec, lightRange);
                        blockLightAccum += 6.0 * lightAtt * lightColor * lightPhase;
                    }
                }
            #endif

            // if (!firstPersonCamera) {
            //     vec2 noiseSample = GetDynLightNoise(vec3(0.0));

            //     if (heldBlockLightValue > 0) {
            //         vec3 lightLocalPos = (gbufferModelViewInverse * vec4(HandLightOffsetR, 1.0)).xyz;
            //         if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;

            //         vec3 lightVec = lightLocalPos - traceLocalPos;
            //         if (dot(lightVec, lightVec) < _pow2(heldBlockLightValue)) {
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
            //         if (dot(lightVec, lightVec) < _pow2(heldBlockLightValue2)) {
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

            inScattering += blockLightAccum * DynamicLightBrightness;
        #endif

        inScattering *= scatterF;

        vec3 scatteringIntegral = (inScattering - inScattering * sampleTransmittance) * extinctionInv;

        scattering += scatteringIntegral * transmittance;
        transmittance *= sampleTransmittance;
    }

    scattering /= (scattering + 1.0);

    return vec4(scattering, transmittance);
}
