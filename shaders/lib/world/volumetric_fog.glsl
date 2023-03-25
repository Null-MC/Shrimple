float ComputeVolumetricScattering(const in float VoL, const in float G_scattering) {
    float G_scattering2 = pow2(G_scattering);

    return rcp(4.0 * PI) * ((1.0 - G_scattering2) / (pow(1.0 + G_scattering2 - (2.0 * G_scattering) * VoL, 1.5)));
}

vec4 GetVolumetricLighting(const in vec3 localViewDir, const in float nearDist, const in float farDist) {
    const float scatterF = 0.032 * AtmosphereDensityF;
    const float extinction = 0.009 * AtmosphereDensityF;

    vec3 localStart = localViewDir * nearDist;
    vec3 localEnd = localViewDir * farDist;
    float localRayLength = farDist - nearDist;

    int stepCount = int(ceil((localRayLength / far) * (ATMOS_VL_SAMPLES - 2))) + 2;
    float inverseStepCountF = rcp(stepCount);
    
    vec3 localStep = localViewDir * (localRayLength * inverseStepCountF);

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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

        // #if defined RENDER_GBUFFER && !defined RENDER_SKYBASIC
        //     vec3 skyLightColor = textureLod(lightmap, vec2(0.5/16.0, 15.5/16.0), 0).rgb;
        // #else
        //     vec3 skyLightColor = textureLod(TEX_LIGHTMAP, vec2(0.5/16.0, 15.5/16.0), 0).rgb;
        // #endif

        vec3 skyLightColor = skyColor + 0.02;

        float phase = mix(
            ComputeVolumetricScattering(VoL, -0.16),
            ComputeVolumetricScattering(VoL,  0.44),
            0.62);
    #endif

    float localStepLength = localRayLength * inverseStepCountF;

    float transmittance = 1.0;
    vec3 scattering = vec3(0.0);
    for (int i = 0; i < stepCount; i++) {
        vec3 inScattering = 0.02 * fogColor; //vec3(0.008);

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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

            inScattering += phase * sampleF * sampleColor;
        #endif

        vec3 traceLocalPos = localStep * (i + dither) + localStart;

        #if DYN_LIGHT_VL_MODE != 0 && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined IRIS_FEATURE_SSBO
            uint gridIndex;
            int lightCount = GetSceneLights(traceLocalPos, gridIndex);

            if (gridIndex != -1u) {
                vec3 accumDiffuse = vec3(0.0);

                for (int i = 0; i < lightCount; i++) {
                    SceneLightData light = GetSceneLight(gridIndex, i);

                    vec3 lightVec = traceLocalPos - light.position;
                    uint traceFace = 1u << GetLightMaskFace(lightVec);
                    if ((light.data & traceFace) == traceFace) continue;
                    if (dot(lightVec, lightVec) >= pow2(light.range)) continue;

                    vec3 lightColor = light.color;
                    #if DYN_LIGHT_VL_MODE == 2
                        if ((light.data & 1u) == 1u) {
                            vec3 traceOrigin = GetLightGridPosition(light.position);
                            vec3 traceEnd = traceOrigin + 0.99*lightVec;

                            #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                                lightColor *= TraceRay(traceOrigin, traceEnd, light.range);
                            #else
                                lightColor *= TraceDDA_fast(traceEnd, traceOrigin, light.range);
                            #endif
                        }
                    #endif

                    accumDiffuse += SampleLight(lightVec, 1.0, light.range) * lightColor;
                }

                inScattering += 0.04 * accumDiffuse * DynamicLightBrightness;
            }
        #endif

        inScattering *= scatterF;

        float sampleTransmittance = exp(-extinction * localStepLength);
        vec3 scatteringIntegral = (inScattering - inScattering * sampleTransmittance) / extinction;

        scattering += scatteringIntegral * transmittance;
        transmittance *= sampleTransmittance;
    }

    return vec4(scattering, transmittance);
}
