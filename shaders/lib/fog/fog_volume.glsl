const float vlSkyMinLight = 0.08;


float GetWaterPhase(const in float VoL) {
    // return DHG(VoL, -0.12, 0.68, 0.24);
    return HG(VoL, 0.36);
}


void ApplyVolumetricLighting(inout vec3 scatterFinal, inout vec3 transmitFinal, const in vec3 localViewDir, const in float nearDist, const in float farDist, const in float distTrans, in bool isWater, in bool isSky) {
    vec3 localStart = localViewDir * nearDist;
    vec3 localEnd = localViewDir * farDist;
    vec3 localRay = localEnd - localStart;

    float localRayLength = max(farDist - nearDist, 0.0);
    if (localRayLength < EPSILON) return;

    #ifdef EFFECT_TAA_ENABLED
        float dither = InterleavedGradientNoiseTime();
    #else
        float dither = InterleavedGradientNoise();
    #endif

    const float inverseStepCountF = rcp(VOLUMETRIC_SAMPLES);
    
    float stepLength = localRayLength / (VOLUMETRIC_SAMPLES);
    vec3 localStep = localViewDir * stepLength;

    #ifdef WORLD_SKY_ENABLED
        #ifdef RENDER_SHADOWS_ENABLED
            #ifdef IRIS_FEATURE_SSBO
                vec3 shadowViewStart = mul3(shadowModelViewEx, localStart);
                vec3 shadowViewEnd = mul3(shadowModelViewEx, localEnd);
            #else
                vec3 shadowViewStart = mul3(shadowModelView, localStart);
                vec3 shadowViewEnd = mul3(shadowModelView, localEnd);
            #endif

            vec3 shadowViewStep = (shadowViewEnd - shadowViewStart) * inverseStepCountF;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vec3 shadowClipStartCsm[4];
                vec3 shadowClipStepCsm[4];

                for (int c = 0; c < 4; c++) {
                    shadowClipStartCsm[c] = mul3(cascadeProjection[c], shadowViewStart) * 0.5 + 0.5;
                    shadowClipStartCsm[c].xy = shadowClipStartCsm[c].xy * 0.5 + shadowProjectionPos[c];

                    vec3 shadowClipEnd = mul3(cascadeProjection[c], shadowViewEnd) * 0.5 + 0.5;
                    shadowClipEnd.xy = shadowClipEnd.xy * 0.5 + shadowProjectionPos[c];

                    shadowClipStepCsm[c] = (shadowClipEnd - shadowClipStartCsm[c]) * inverseStepCountF;
                }
            #else
                // float shadowSampleBias = GetShadowOffsetBias();// (0.01 / 256.0);

                #ifdef IRIS_FEATURE_SSBO
                    vec3 shadowClipStart = mul3(shadowProjectionEx, shadowViewStart);
                    vec3 shadowClipEnd = mul3(shadowProjectionEx, shadowViewEnd);
                #else
                    vec3 shadowClipStart = mul3(shadowProjection, shadowViewStart);
                    vec3 shadowClipEnd = mul3(shadowProjection, shadowViewEnd);
                #endif

                vec3 shadowClipStep = (shadowClipEnd - shadowClipStart) * inverseStepCountF;
            #endif
        #endif
        
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
            vec3 localSkyLightDirection = mul3(gbufferModelViewInverse, shadowLightPosition);
            localSkyLightDirection = normalize(localSkyLightDirection);
            vec3 WorldSkyLightColor = GetSkyLightColor(localSunDirection);
        #endif

        float eyeBrightF = eyeBrightnessSmooth.y / 240.0;

        vec3 skyColorAmbient = phaseIso * eyeBrightF * WorldSkyAmbientColor;

        // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        //     float weatherF = 1.0 - 0.5 * _pow2(weatherStrength);
        // #else
        //     float weatherF = 1.0;// - 0.8 * _pow2(weatherStrength);
        // #endif

        //vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        vec3 skyLightColor = WorldSkyLightColor * VolumetricBrightnessSky;
        //skyLightColor *= smoothstep(0.0, 0.1, abs(localSunDirection.y));

        #ifdef RENDER_CLOUD_SHADOWS_ENABLED
            //vec3 lightWorldDir = mat3(gbufferModelViewInverse) * shadowLightPosition;
            // TODO: Why TF was this dividing by Y?
            vec3 lightWorldDir = localSkyLightDirection;// / localSkyLightDirection.y;
        #endif

        float VoL = dot(localSkyLightDirection, localViewDir);

        #if SKY_CLOUD_TYPE == CLOUDS_VANILLA
            vec2 cloudOffset = GetCloudOffset();
            vec3 camOffset = GetCloudCameraOffset();
        #endif

        float phaseSky = GetSkyPhase(VoL);
    #else
        float VoL = 1.0;
        float time = GetAnimationFactor();
    #endif

    #if defined WORLD_WATER_ENABLED
        // #if LIGHTING_VOLUMETRIC == VOL_TYPE_FANCY
            float phaseWater = GetWaterPhase(VoL);
        // #else
        //     float phaseWater = phaseIso;
        // #endif

        #if WATER_DEPTH_LAYERS > 1 //&& LIGHTING_VOLUMETRIC == VOL_TYPE_FANCY
            uvec2 uv = uvec2(gl_FragCoord.xy * exp2(VOLUMETRIC_RES));
            uint uvIndex = GetWaterDepthIndex(uv);

            float waterDepth[WATER_DEPTH_LAYERS+1];
            GetAllWaterDepths(uvIndex, waterDepth);
        #endif
    #endif

    #ifdef RENDER_SHADOWS_ENABLED
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            float shadowDepthRange = GetShadowRange(0);
        #else
            float shadowDepthRange = GetShadowRange();
        #endif
    #endif

    #ifdef DISTANT_HORIZONS
        float shadowDistFar = min(shadowDistance, 0.5*dhFarPlane);
    #else
        float shadowDistFar = min(shadowDistance, far);
    #endif

    #if defined(WORLD_SKY_ENABLED) && SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        float cloudDensity = 0.0;
        float cloudShadow = 1.0;
        float cloudLightning = 0.0;
        float cloudDist = 0.0;

        float cloudAlt = GetCloudAltitude();

        if (abs(localViewDir.y) > 0.0 && isEyeInWater == 0) {
            float cloudPlaneOffset = cloudAlt - cameraPosition.y;

            if (sign(cloudPlaneOffset) == sign(localViewDir.y)) {
                cloudDist = abs(cloudPlaneOffset / localViewDir.y);
                vec3 cloud_localPos = cloudDist * localViewDir;
                vec3 cloudWorldPos = cloud_localPos + cameraPosition;

                cloudDensity = SampleCloudDensity(cloudWorldPos);

                //if (cloudPlaneOffset > 0.0) {
                    float shadowStepDist = 4.0;
                    float shadowDensity = 0.0;//-cloudDensity;
                    for (float ii = dither; ii < 8.0; ii += 1.0) {
                        vec3 cloudShadow_worldPos = (shadowStepDist * ii) * localSkyLightDirection + cloudWorldPos;
                        shadowDensity += SampleCloudDensity(cloudShadow_worldPos) * shadowStepDist;
                        shadowStepDist *= 1.5;
                    }

                    if (shadowDensity > 0.0)
                        cloudShadow = exp(-2.0*AirExtinctFactor * shadowDensity);
                //}
                //else {
                //    cloudShadow = 10.0;
                //}

                // TODO: lightning
                if (lightningPosition.w > EPSILON) {
                    vec4 lightningDirectionStrength = GetLightningDirectionStrength(cloud_localPos);
                    //sampleLit += 0.3 * samplePhase * lightningDirectionStrength.w;

                    float shadowStepDist = 2.0;
                    float shadowDensity = 0.0;
                    for (float ii = dither; ii < 8.0; ii += 1.0) {
                        vec3 cloudShadow_worldPos = (shadowStepDist * ii) * lightningDirectionStrength.xyz + cloudWorldPos;
                        shadowDensity += SampleCloudDensity(cloudShadow_worldPos) * shadowStepDist;
                        shadowStepDist *= 1.5;
                    }

                    if (shadowDensity > 0.0) {
                        // TODO: fix phase
                        float shadow = exp(-10.0 * AirExtinctFactor * shadowDensity);
                        cloudLightning = phaseIso * shadow * lightningDirectionStrength.w;
                    }
                }
            }
        }
    #endif

    float caveFogF = 0.0;
    #ifdef SKY_CAVE_FOG_ENABLED
        caveFogF = GetCaveFogF();
    #endif

    #define VL_STEP_POWER 160
    float stepDistLastF = 0.0;

    for (int i = 0; i < VOLUMETRIC_SAMPLES; i++) {
        #if VL_STEP_POWER != 100
            const float VL_StepPower = VL_STEP_POWER * 0.01;
            float stepDistF = (i+1.0) / VOLUMETRIC_SAMPLES;
            stepDistF = pow(stepDistF, VL_StepPower);

            float stepDistDiff = stepDistF - stepDistLastF;
            float stepDistDither = fma(stepDistDiff, dither, stepDistLastF);
            stepDistLastF = stepDistF;

            vec3 traceLocalPos = fma(localRay, vec3(stepDistDither), localStart);
            float stepLength = stepDistDiff * localRayLength;
        #else
            float iStep = i + dither;// * step(1, i);
            vec3 traceLocalPos = fma(localStep, vec3(iStep), localStart);
        #endif

        vec3 traceWorldPos = traceLocalPos + cameraPosition;
        float traceDist = length(traceLocalPos);

        #if WORLD_CURVE_RADIUS > 0
            float traceAltitude = GetWorldAltitude(traceLocalPos);
            vec3 curvedLocalPos = GetWorldCurvedPosition(traceLocalPos);

            vec3 curvedWorldPos = curvedLocalPos;
            curvedWorldPos.xz += cameraPosition.xz;
        #else
            float traceAltitude = traceWorldPos.y;
        #endif

        #if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
            vec3 lpvPos = GetVoxelPosition(traceLocalPos);
            vec4 lpvSample = SampleLpv(lpvPos);
            float lpvFade = GetLpvFade(lpvPos);
        #endif

        float samplePhase = phaseIso;

        #ifdef WORLD_SKY_ENABLED
            samplePhase = phaseSky;
        #endif

        #if defined WORLD_WATER_ENABLED //&& LIGHTING_VOLUMETRIC == VOL_TYPE_FANCY
            #if WATER_DEPTH_LAYERS > 1
                isWater = false;
                
                if (waterDepth[0] < farDist) {
                    isWater = traceDist > waterDepth[0] && traceDist < waterDepth[1];
                    // waterDepthEye += max(traceDist - waterDepth[0], 0.0);
                }

                #if WATER_DEPTH_LAYERS >= 3
                    if (waterDepth[2] < farDist)
                        isWater = isWater || (traceDist > min(waterDepth[2], farDist) && traceDist < min(waterDepth[3], farDist));
                        // TODO: waterDepthEye
                #endif

                #if WATER_DEPTH_LAYERS >= 5
                    if (waterDepth[4] < farDist)
                        isWater = isWater || (traceDist > min(waterDepth[4], farDist) && traceDist < min(waterDepth[5], farDist));
                        // TODO: waterDepthEye
                #endif
            #endif

            // if (isWater) samplePhase = GetWaterPhase(VoL);
        #endif

        float sampleDensity = 0.0;
        vec3 sampleScattering = AirScatterColor;
        vec3 sampleExtinction = AirExtinctColor;
        vec3 sampleAmbient = vec3(AirAmbientF);

        #ifdef WORLD_WATER_ENABLED
            if (isWater) {
                sampleDensity = WaterDensityF;
                sampleExtinction = WaterAbsorbF;
                sampleScattering = WaterScatterF;
                sampleAmbient = vec3(WaterAmbientF);
                samplePhase = phaseWater;
            }
        #endif

        #ifdef WORLD_SKY_ENABLED
            vec3 sampleColor = skyLightColor;
            bool isCloudStep = false;

            if (!isWater) {
                sampleDensity = GetFinalFogDensity(traceWorldPos, traceAltitude, caveFogF);

                 #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
                    isCloudStep = cloudDensity > 0.0 && traceDist > cloudDist && traceDist - stepLength < cloudDist;

                    if (isCloudStep) {
                        sampleDensity = cloudDensity;
                        sampleColor *= cloudShadow;
                        sampleColor += cloudLightning;
                        stepLength = 10.0;
                    }
                 #endif
            }
        #else
            vec3 sampleColor = vec3(1.0);

            #ifdef IS_WORLD_SMOKE_ENABLED
                float smokeF = 0.25*SmokeLevelF;
                if (traceDist < 300.0) {
                    float texSmokeF = SampleSmokeOctaves(traceWorldPos, SmokeTraceOctaves, time);
                    smokeF = mix(texSmokeF, smokeF, _smoothstep(traceDist / 300.0));
                }

                sampleDensity = smokeF * SmokeDensityF;
                sampleScattering = vec3(SmokeScatterF);
                sampleExtinction = vec3(SmokeAbsorbF);
                sampleAmbient = SmokeAmbientF * (fogColor*0.75 + 0.25);
                samplePhase = phaseIso;

                #ifdef WORLD_END
                    const vec3 EndSmokeAmbientColor = 0.2*_RGBToLinear(vec3(0.698, 0.212, 0.89));
                    sampleAmbient = SmokeAmbientF * EndSmokeAmbientColor;
                #endif
            #endif
        #endif

        float sampleDepth = 0.0;

        #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED //&& SHADOW_TYPE != SHADOW_TYPE_NONE //&& VOLUMETRIC_BRIGHT_SKY > 0
            float sampleF = eyeBrightF;

            #if VL_STEP_POWER != 100
                vec3 shadowViewPos = mul3(shadowModelViewEx, traceLocalPos);
            #else
                vec3 shadowViewPos = fma(shadowViewStep, vec3(iStep), shadowViewStart);
            #endif

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vec3 shadowPos = vec3(-1.0);
                float shadowFade = 1.0;

                int cascade = GetShadowCascade(shadowViewPos, -0.01);
                float shadowDistF = 0.0;
                
                if (cascade >= 0) {
                    float shadowSampleBias = GetShadowOffsetBias(cascade);

                    #if VL_STEP_POWER != 100
                        shadowPos = mul3(cascadeProjection[cascade], shadowViewPos);
                        shadowPos = fma(shadowPos, vec3(0.5), vec3(0.5));

                        shadowPos.xy = fma(shadowPos.xy, vec2(0.5), shadowProjectionPos[cascade]);
                    #else
                        shadowPos = fma(shadowClipStepCsm[cascade], vec3(iStep), shadowClipStartCsm[cascade]);
                    #endif

                    //sampleF = CompareDepth(shadowPos, vec2(0.0), shadowSampleBias);
                    float texDepth = texture(shadowtex1, shadowPos.xy).r;
                    sampleF = step(shadowPos.z - shadowSampleBias, texDepth);

                    texDepth = texture(shadowtex0, shadowPos.xy).r;
                    sampleDepth = max(shadowPos.z - texDepth, 0.0) * shadowDepthRange;
                    shadowDistF = 1.0;
                    shadowFade = 0.0;
                }
            #else
                #if VL_STEP_POWER != 100
                    vec3 shadowNdcPos = mul3(shadowProjectionEx, shadowViewPos);
                #else
                    vec3 shadowNdcPos = fma(shadowClipStep, vec3(iStep), shadowClipStart);
                #endif

                shadowNdcPos = distort(shadowNdcPos);

                float shadowViewDist = length(shadowViewPos.xy);
                // float shadowDistFar = min(shadowDistance, far);
                float shadowFade = 1.0 - smoothstep(shadowDistFar - 20.0, shadowDistFar, shadowViewDist);
                shadowFade *= step(-1.0, shadowNdcPos.z);
                shadowFade *= step(shadowNdcPos.z, 1.0);
                shadowFade = 1.0 - shadowFade;

                vec3 shadowPos = fma(shadowNdcPos, vec3(0.5), vec3(0.5));

                if (shadowFade < 1.0) {
                    const float geoNoL = 1.0; // WARN: useless without geoNoL?
                    float shadowSampleBias = 0.0;//GetShadowOffsetBias(shadowNdcPos, geoNoL);
                    // float shadowSampleBias = 0.2 / -shadowDepthRange;
                    //sampleF = CompareDepth(shadowNdcPos, vec2(0.0), shadowSampleBias);

                    float texDepth = texture(shadowtex1, shadowPos.xy).r;
                    sampleF = step(shadowPos.z + shadowSampleBias, texDepth);

                    texDepth = texture(shadowtex0, shadowPos.xy).r;
                    sampleDepth = max(shadowPos.z - texDepth, 0.0) * shadowDepthRange;
                }
            #endif

            #ifdef SHADOW_COLORED
                float transparentShadowDepth = texture(shadowtex0, shadowPos.xy).r;

                if (shadowPos.z - transparentShadowDepth >= EPSILON && (shadowFade < 1.0)) {
                    vec3 shadowColor = texture(shadowcolor0, shadowPos.xy).rgb;
                    shadowColor = RGBToLinear(shadowColor);

                    float lum = luminance(shadowColor);
                    if (lum > 0.0) shadowColor /= lum;

                    // if (any(greaterThan(shadowColor, EPSILON3)))
                    //     shadowColor = normalize(shadowColor) * 1.73;

                    sampleColor *= shadowColor;
                }
            #endif
        #else
            float sampleF = 0.0;
        #endif

        #if !defined RENDER_WEATHER //&& LIGHTING_VOLUMETRIC == VOL_TYPE_FANCY
            if (isWater) {
                #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
                    // TODO: replace traceLocalPos with water surface pos

                    sampleColor *= SampleWaterCaustics(traceLocalPos, sampleDepth, 1.0);
                #endif

                //sampleColor *= exp(sampleDepth * WaterDensityF * -WaterAbsorbF);
            }
        #endif

        // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        #ifdef WORLD_SKY_ENABLED //&& SKY_CLOUD_TYPE != CLOUDS_NONE
            #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
                //float cloudAlt = GetCloudAltitude();

                if (traceWorldPos.y < cloudAlt && !isCloudStep) {
                    float cloudShadowDist = abs((cloudAlt - traceWorldPos.y) / localSkyLightDirection.y);
                    vec3 cloudShadowWorldPos = cloudShadowDist * localSkyLightDirection + traceWorldPos;
                    float cloudShadowDensity = SampleCloudDensity(cloudShadowWorldPos);

                    if (cloudShadowDensity > 0.0) {
                        sampleF *= exp(-10.0*AirExtinctFactor * cloudShadowDensity);
                    }
                }
            #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
                if (traceWorldPos.y < cloudHeight + 0.5*CloudPlaneHeight) {
                    float sampleCloudShadow = SampleCloudShadow(traceLocalPos, localSkyLightDirection, cloudOffset, camOffset, 0.0);

                    sampleF *= sampleCloudShadow * 0.5 + 0.5;
                }
            #endif
        #endif

        vec3 sampleLit = samplePhase * sampleF * sampleColor;

        #if defined WORLD_SKY_ENABLED && defined RENDER_COMPOSITE //&& VOLUMETRIC_BRIGHT_SKY > 0
            #if VOLUMETRIC_FAKE_SHADOW > 0
                // if (gl_FragCoord.x > 0.5*(viewWidth/exp2(VOLUMETRIC_RES)))
                    sampleLit *= exp(-VOLUMETRIC_FAKE_SHADOW * sampleExtinction * _pow2(sampleDensity));
            #endif

            if (lightningPosition.w > EPSILON) {
                vec4 lightningDirectionStrength = GetLightningDirectionStrength(traceLocalPos);
                //sampleLit += 0.3 * samplePhase * lightningDirectionStrength.w;

//                #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
//                    float shadowStepDist = 2.0;
//                    float shadowDensity = 0.0;
//                    for (float ii = dither; ii < 5.0; ii += 1.0) {
//                        vec3 cloudShadow_worldPos = (shadowStepDist * ii) * -lightningDirectionStrength.xyz + traceWorldPos;
//                        shadowDensity += SampleCloudDensity(cloudShadow_worldPos) * shadowStepDist;
//                        shadowStepDist *= 1.5;
//                    }
//
//                    if (shadowDensity > 0.0)
//                        lightningDirectionStrength.w *= exp(-AirExtinctFactor * shadowDensity);
//                #endif

                // TODO: fix phase
                //sampleLit += 0.3 * samplePhase * lightningDirectionStrength.w;
                sampleLit += 0.1*phaseIso * lightningDirectionStrength.w * _pow2(eyeBrightF);
            }
        #endif

        #if VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE > LIGHTING_MODE_BASIC && defined IRIS_FEATURE_SSBO
            vec3 blockLightAccum = vec3(0.0);

            #if LIGHTING_MODE == LIGHTING_MODE_TRACED && defined VOLUMETRIC_BLOCK_RT && !defined RENDER_WEATHER
                uint gridIndex;
                uint lightCount = GetVoxelLights(traceLocalPos, gridIndex);

                if (gridIndex != DYN_LIGHT_GRID_MAX) {
                    #if LIGHTING_TRACE_SAMPLE_MAX > 0
                        const int maxSampleCount = min(LIGHTING_TRACE_SAMPLE_MAX, 128);
                    #else
                        const int maxSampleCount = 128;
                    #endif

                    for (uint l = 0; l < min(lightCount, maxSampleCount); l++) {
                        uvec4 lightData = GetVoxelLight(gridIndex, l);

                        vec3 lightPos, lightColor;
                        float lightSize, lightRange;
                        ParseLightData(lightData, lightPos, lightSize, lightRange, lightColor);

                        lightRange *= VolumetricBlockRangeF;
                        lightColor = RGBToLinear(lightColor);

                        vec3 lightVec = traceLocalPos - lightPos;
                        if (length2(lightVec) >= _pow2(lightRange)) continue;
                        
                        #if defined VOLUMETRIC_BLOCK_RT && LIGHTING_MODE == LIGHTING_MODE_TRACED
                            uint traceFace = 1u << GetLightMaskFace(lightVec);
                            if ((lightData.z & traceFace) == traceFace) continue;

                            if ((lightData.z & 1u) == 1u) {
                                vec3 traceOrigin = GetVoxelPosition(lightPos);
                                vec3 traceEnd = traceOrigin + 0.999*lightVec;

                                bool traceSelf = ((lightData.z >> 1u) & 1u) == 1u;

                                lightColor *= TraceDDA(traceOrigin, traceEnd, lightRange, traceSelf);
                            }
                        #endif

                        float lightVoL = dot(normalize(-lightVec), localViewDir);
                        float lightPhase = phaseIso;// DHG(lightVoL, phaseF.Back, phaseF.Forward, phaseF.Direction);

                        float lightAtt = GetLightAttenuation(lightVec, lightRange).y;
                        blockLightAccum += lightAtt * lightColor * lightPhase;
                    }

                    blockLightAccum *= 15.0 * Lighting_Brightness;
                }
            #elif defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
                vec3 lpvLight = GetLpvFogBlockLight(lpvSample);

                #if VOLUMETRIC_FAKE_SHADOW > 0
                    // if (gl_FragCoord.x > 0.5*(viewWidth/exp2(VOLUMETRIC_RES)))
                        lpvLight *= exp(-VOLUMETRIC_FAKE_SHADOW * sampleExtinction * _pow2(sampleDensity));
                #endif

                blockLightAccum += 3.0 * phaseIso * lpvFade * lpvLight;
            #endif

            sampleLit += blockLightAccum * VolumetricBrightnessBlock;// * Lighting_Brightness;
        #endif

        #ifdef WORLD_SKY_ENABLED
            if (isCloudStep)
                sampleAmbient *= luminance(skyColorAmbient);
            else
                sampleAmbient *= skyColorAmbient;
        #endif

        vec3 lightF = sampleLit + sampleAmbient;

        float traceStepLen = stepLength;
        // if (i == VOLUMETRIC_SAMPLES-1) traceStepLen *= (1.0 - dither);
        // else if (i == 0) traceStepLen *= dither;

        ApplyScatteringTransmission(scatterFinal, transmitFinal, traceStepLen, lightF, sampleDensity, sampleScattering, sampleExtinction);

        //if (all(lessThan(transmitFinal, EPSILON3))) break;
    }

    #if defined(WORLD_SKY_ENABLED) && SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        if (isSky && cloudDensity > EPSILON) {
            #if VL_STEP_POWER != 100
                const float VL_StepPower = VL_STEP_POWER * 0.01;
                float stepDistLastF = (VOLUMETRIC_SAMPLES-1.0) / VOLUMETRIC_SAMPLES;
                stepDistLastF = pow(stepDistLastF, VL_StepPower);

                float stepDistDiff = 1.0 - stepDistLastF;
                float stepDistDither = fma(stepDistDiff, dither, stepDistLastF);

                vec3 localStep = localRay * stepDistDither;
            #endif

            float endWorldY = localEnd.y + cameraPosition.y;
            endWorldY -= (1.0-dither) * localStep.y;

            if (endWorldY <= cloudHeight) {
                float sampleF = eyeBrightF;
                vec3 sampleColor = skyLightColor * cloudShadow + cloudLightning;
                vec3 sampleLit = phaseSky * sampleF * sampleColor;

                vec3 sampleAmbient = vec3(AirAmbientF * luminance(skyColorAmbient));
                vec3 lightF = sampleLit + sampleAmbient;

                const float traceStepLen = 10.0;
                ApplyScatteringTransmission(scatterFinal, transmitFinal, traceStepLen, lightF, cloudDensity, AirScatterColor, AirExtinctColor);
            }
        }
    #endif
}
