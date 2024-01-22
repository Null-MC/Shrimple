struct VolumetricPhaseFactors {
    vec3  AmbientF;
    vec3  ScatterF;
    vec3 AbsorbF;
    float Direction;
    float Forward;
    float Back;
};

#ifdef WORLD_WATER_ENABLED
    // #ifdef WORLD_SKY_ENABLED
    //     //float skyLight = eyeBrightnessSmooth.y / 240.0;
    //     vec3 vlWaterAmbient = vec3(0.2, 0.8, 1.0) * mix(0.02, 0.002, skyRainStrength);// * (sqrt(skyLight) * 0.96 + 0.04);
    // #else
    //     const vec3 vlWaterAmbient = vec3(0.0040);
    // #endif

    VolumetricPhaseFactors WaterPhaseF = VolumetricPhaseFactors(
        vec3(WaterAmbientF),
        WaterScatterF,
        WaterAbsorbF,
        0.24, 0.68, -0.12);
#endif

VolumetricPhaseFactors GetVolumetricPhaseFactors() {
    VolumetricPhaseFactors result;

    result.Back = -0.12;
    result.Forward = 0.78;
    result.Direction = 0.42;

    result.AmbientF = vec3(AirAmbientF);
    result.ScatterF = AirScatterColor;
    result.AbsorbF = AirExtinctColor;

    #if defined WORLD_SKY_ENABLED && !(LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0)
        float skyLightF = eyeBrightnessSmooth.y / 240.0;
        result.AmbientF *= _pow2(skyLightF);
    #endif

    return result;
}

void ApplyVolumetricLighting(inout vec3 scatterFinal, inout vec3 transmitFinal, const in vec3 localViewDir, const in float nearDist, const in float farDist, const in float distTrans, in bool isWater) {
    vec3 localStart = localViewDir * nearDist;
    vec3 localEnd = localViewDir * farDist;
    float localRayLength = max(farDist - nearDist, 0.0);
    if (localRayLength < EPSILON) {
        // return vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
        #if WATER_DEPTH_LAYERS > 1
            VolumetricPhaseFactors phaseAir = GetVolumetricPhaseFactors();
            VolumetricPhaseFactors phaseWater = WaterPhaseF;
        #else
            VolumetricPhaseFactors phaseF = isWater ? WaterPhaseF : GetVolumetricPhaseFactors();
        #endif
    #else
        VolumetricPhaseFactors phaseF = GetVolumetricPhaseFactors();
    #endif

    #ifdef EFFECT_TAA_ENABLED
        float dither = InterleavedGradientNoiseTime();
    #else
        float dither = InterleavedGradientNoise();
    #endif

    //int stepCount = VOLUMETRIC_SAMPLES;
    //int stepCount = VOLUMETRIC_SAMPLES;//int(ceil((localRayLength / far) * (VOLUMETRIC_SAMPLES - 2 + dither))) + 2;
    const float inverseStepCountF = rcp(VOLUMETRIC_SAMPLES+1);
    
    float stepLength = localRayLength * inverseStepCountF;
    vec3 localStep = localViewDir * stepLength;

    #ifdef WORLD_SKY_ENABLED
        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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
        #endif
        
        #ifndef IRIS_FEATURE_SSBO
        #endif

        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
            vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
            vec3 WorldSkyLightColor = GetSkyLightColor(localSunDirection);
        #endif

        // #if SKY_TYPE == SKY_TYPE_CUSTOM
        //     vec3 skyLightColor = 0.5 + 0.5 * GetCustomSkyFogColor(localSunDirection.y);
        // #else
        //     vec3 skyLightColor = RGBToLinear(fogColor);
        // #endif

        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
        #else
            float weatherF = 1.0 - 0.8 * _pow2(skyRainStrength);
        #endif

        //vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;
        //skyLightColor *= smoothstep(0.0, 0.1, abs(localSunDirection.y));

        #if defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE != CLOUDS_NONE
            //vec3 lightWorldDir = mat3(gbufferModelViewInverse) * shadowLightPosition;
            vec3 lightWorldDir = localSkyLightDirection / localSkyLightDirection.y;
        #endif

        float VoL = dot(localSkyLightDirection, localViewDir);

        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            vec3 cloudOffset = cameraPosition - vec3(0.0, cloudHeight, 0.0);
            float phaseCloud = GetCloudPhase(VoL);
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA //&& VOLUMETRIC_BRIGHT_SKY > 0
            vec2 cloudOffset = GetCloudOffset();
            vec3 camOffset = GetCloudCameraOffset();
        #endif

        #if WATER_DEPTH_LAYERS > 1 && defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
            float skyPhaseAir = DHG(VoL, phaseAir.Back, phaseAir.Forward, phaseAir.Direction);
            float skyPhaseWater = DHG(VoL, phaseWater.Back, phaseWater.Forward, phaseWater.Direction);
        #else
            float skyPhase = DHG(VoL, phaseF.Back, phaseF.Forward, phaseF.Direction);
        #endif
    #else
        #if WATER_DEPTH_LAYERS > 1 && defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
            float skyPhaseAir = phaseIso;
            float skyPhaseWater = phaseIso;
        #else
            float skyPhase = phaseIso;
        #endif

        float time = GetAnimationFactor();
    #endif

    #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY && WATER_DEPTH_LAYERS > 1
        uvec2 uv = uvec2(gl_FragCoord.xy * exp2(VOLUMETRIC_RES));
        uint uvIndex = uint(uv.y * viewWidth + uv.x);

        float waterDepth[WATER_DEPTH_LAYERS+1];
        GetAllWaterDepths(uvIndex, waterDepth);
    #endif

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        float shadowDepthRange = far * 3.0;
    #else
        float shadowDepthRange = -2.0 / shadowProjectionEx[2][2];
    #endif

    #ifdef DISTANT_HORIZONS
        float shadowDistFar = min(shadowDistance, 0.5*dhFarPlane);
    #else
        float shadowDistFar = min(shadowDistance, far);
    #endif

    // float transmittance = 1.0;
    // vec3 scattering = vec3(0.0);

    for (int i = 0; i <= VOLUMETRIC_SAMPLES; i++) {
        // if (i == VOLUMETRIC_SAMPLES) {
        //     stepLength *= 1.0 - dither;
        //     dither = 0.0;
        // }

        float iStep = i + dither;
        vec3 traceLocalPos = localStep * iStep + localStart;
        float traceDist = length(traceLocalPos);

        #if LPV_SIZE > 0
            vec3 lpvPos = GetLPVPosition(traceLocalPos);
            vec4 lpvSample = SampleLpv(lpvPos, vec3(0.0));
            float lpvFade = GetLpvFade(lpvPos);
        #endif

        #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
            float waterDepthEye = 0.0;
        #endif

        #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY && WATER_DEPTH_LAYERS > 1
            if (waterDepth[0] < farDist) {
                isWater = traceDist > waterDepth[0] && traceDist < waterDepth[1];
                waterDepthEye += max(traceDist - waterDepth[0], 0.0);
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

            VolumetricPhaseFactors phaseF = isWater ? phaseWater : phaseAir;
            float samplePhase = isWater ? skyPhaseWater : skyPhaseAir;
        #else
            float samplePhase = skyPhase;
        #endif

        float sampleDensity = AirDensityF;
        #ifdef WORLD_WATER_ENABLED
            if (isWater) sampleDensity = WaterDensityF;
        #endif

        vec3 sampleExtinction = phaseF.AbsorbF;
        vec3 sampleScattering = phaseF.ScatterF;
        vec3 sampleAmbient = phaseF.AmbientF;
        vec3 sampleLit = vec3(0.0);

        // #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
        //     // float waterDepthEye = 0.0;

        //     #ifdef WORLD_SKY_ENABLED
        //         #if LPV_SIZE > 0
        //             float lpvSkyLightF = GetLpvSkyLight(lpvSample);
        //             ambientWater = 0.25 * vec3(0.2, 0.8, 1.0) * skyLightColor * lpvSkyLightF;
        //         //#else
        //         //    ambientWater = 0.015 * vec3(0.2, 0.8, 1.0) * skyLightColor;
        //         #endif
        //     #endif
        // #endif

        #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY && WATER_DEPTH_LAYERS > 1
            sampleAmbient = isWater ? phaseWater.AmbientF : phaseAir.AmbientF;
        #else
            #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
                if (isEyeInWater == 1)
                    waterDepthEye = traceDist;
                else {
                    // TODO: get dist from water to trace
                    waterDepthEye = 0.0;
                }
            #endif
        #endif

        #if defined WORLD_SKY_ENABLED && SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
            if (!isWater) {
                sampleDensity = GetSkyDensity(cameraPosition.y + traceLocalPos.y);
                //sampleDensity *= 1.0 - smoothstep(62.0, 420.0, traceLocalPos.y + cameraPosition.y);

                #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                    if (skyRainStrength > EPSILON) {
                        const vec3 worldUp = vec3(0.0, 1.0, 0.0);
                        //float cloudUnder = TraceCloudDensity(cameraPosition + traceLocalPos, worldUp, CLOUD_SHADOW_STEPS);
                        float cloudUnder = TraceCloudDensity(cameraPosition + traceLocalPos, worldUp, CLOUD_GROUND_SHADOW_STEPS);
                        cloudUnder = smoothstep(0.0, 0.5, cloudUnder) * skyRainStrength;

                        sampleDensity = mix(sampleDensity, AirDensityRainF, cloudUnder);
                        sampleScattering = mix(sampleScattering, AirScatterColor_rain, cloudUnder);
                        sampleExtinction = mix(sampleExtinction, AirExtinctColor_rain, cloudUnder);
                    }

                    vec3 cloudPos = traceLocalPos + cloudOffset;

                    if (cloudPos.y > 0.0 && cloudPos.y < CloudHeight) {
                        float sampleCloudF = SampleCloudOctaves(cloudPos, CloudTraceOctaves);

                        sampleDensity = mix(sampleDensity, CloudDensityF, sampleCloudF);
                        sampleScattering = mix(sampleScattering, CloudScatterColor, sampleCloudF);
                        sampleExtinction = mix(sampleExtinction, CloudAbsorbColor, sampleCloudF);
                        sampleAmbient = mix(sampleAmbient, vec3(CloudAmbientF), sampleCloudF);
                        samplePhase = mix(samplePhase, phaseCloud, sampleCloudF);
                    }
                #endif
            }
        #endif

        #ifdef WORLD_SKY_ENABLED
            //sampleAmbient *= skyLightColor;

            // #if LPV_SIZE > 0
            //     float lpvSkyLightF = GetLpvSkyLight(lpvSample);
            //     //sampleAmbient *= 1.0 - (1.0 - lpvSkyLightF) * lpvFade;
            // #endif
        #elif defined WORLD_SMOKE
            float smokeF = SampleSmokeOctaves(traceLocalPos + cameraPosition, SmokeTraceOctaves, time);

            sampleDensity = smokeF * SmokeDensityF;
            sampleScattering = vec3(SmokeScatterF);
            sampleExtinction = vec3(SmokeAbsorbF);
            sampleAmbient = SmokeAmbientF * (0.25 + 0.75*fogColor);
            samplePhase = phaseIso;
        #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE //&& VOLUMETRIC_BRIGHT_SKY > 0
            //float eyeLightF = eyeBrightnessSmooth.y / 240.0;

            float sampleF = 1.0;//_pow2(eyeLightF);
            vec3 sampleColor = skyLightColor;
            float sampleDepth = 0.0;

            vec3 shadowViewPos = shadowViewStep * iStep + shadowViewStart;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                // vec3 shadowViewPos = shadowViewStep * iStep + shadowViewStart;
                vec3 traceShadowClipPos = vec3(-1.0);
                float shadowFade = 1.0;

                int cascade = GetShadowCascade(shadowViewPos, -0.01);
                float shadowDistF = 0.0;
                
                if (cascade >= 0) {
                    float sampleBias = GetShadowOffsetBias(cascade);// 0.01 / (far * 3.0);
                    traceShadowClipPos = shadowClipStart[cascade] + iStep * shadowClipStep[cascade];
                    //sampleF = CompareDepth(traceShadowClipPos, vec2(0.0), sampleBias);
                    float texDepth = texture(shadowtex1, traceShadowClipPos.xy).r;
                    sampleF = step(traceShadowClipPos.z - sampleBias, texDepth);

                    texDepth = texture(shadowtex0, traceShadowClipPos.xy).r;
                    sampleDepth = max(traceShadowClipPos.z - texDepth, 0.0) * shadowDepthRange;
                    shadowDistF = 1.0;
                    shadowFade = 0.0;
                }
            #else
                float sampleBias = GetShadowOffsetBias();// (0.01 / 256.0);

                vec3 traceShadowClipPos = shadowClipStep * iStep + shadowClipStart;
                traceShadowClipPos = distort(traceShadowClipPos);
                traceShadowClipPos = traceShadowClipPos * 0.5 + 0.5;

                // vec3 shadowViewPos = (shadowModelView * vec4(vIn.localPos, 1.0)).xyz;
                float shadowViewDist = length(shadowViewPos.xy);
                // float shadowDistFar = min(shadowDistance, far);
                float shadowFade = 1.0 - smoothstep(shadowDistFar - 20.0, shadowDistFar, shadowViewDist);
                shadowFade *= step(-1.0, traceShadowClipPos.z);
                shadowFade *= step(traceShadowClipPos.z, 1.0);
                shadowFade = 1.0 - shadowFade;

                if (shadowFade < 1.0) {
                    //sampleF = CompareDepth(traceShadowClipPos, vec2(0.0), sampleBias);
                    float texDepth = texture(shadowtex1, traceShadowClipPos.xy).r;
                    sampleF = step(traceShadowClipPos.z - sampleBias, texDepth);

                    texDepth = texture(shadowtex0, traceShadowClipPos.xy).r;
                    sampleDepth = max(traceShadowClipPos.z - texDepth, 0.0) * shadowDepthRange;
                }
            #endif

            #ifdef SHADOW_COLORED
                float transparentShadowDepth = texture(shadowtex0, traceShadowClipPos.xy).r;

                if (traceShadowClipPos.z - transparentShadowDepth >= EPSILON && (shadowFade < 1.0)) {
                    vec3 shadowColor = texture(shadowcolor0, traceShadowClipPos.xy).rgb;
                    shadowColor = RGBToLinear(shadowColor);

                    if (any(greaterThan(shadowColor, EPSILON3)))
                        shadowColor = normalize(shadowColor) * 1.73;

                    sampleColor *= shadowColor;
                }
            #endif

            #if WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY && !defined RENDER_WEATHER
                if (isWater) {
                    #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
                        // TODO: replace traceLocalPos with water surface pos

                        float causticLight = SampleWaterCaustics(traceLocalPos, sampleDepth, 1.0);
                        // causticLight = 6.0 * pow(causticLight, 1.0 + 1.0 * Water_WaveStrength);
                        // sampleColor *= 0.5 + 0.5*mix(1.0, causticLight, causticDepthF * Water_CausticStrength);
                        sampleColor *= 0.5 + 0.5*causticLight;
                    #endif

                    sampleColor *= exp(sampleDepth * WaterDensityF * -WaterAbsorbF);
                }
            #endif

            #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED
                #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                    float cloudShadow = TraceCloudShadow(cameraPosition + traceLocalPos, lightWorldDir, CLOUD_SHADOW_STEPS);
                    // float cloudShadow = _TraceCloudShadow(cameraPosition, traceLocalPos, dither, CLOUD_SHADOW_STEPS);
                    //sampleColor *= 1.0 - (1.0 - ShadowCloudBrightnessF) * min(cloudF, 1.0);
                    sampleF *= cloudShadow;
                #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
                    //if (traceLocalPos.y < cloudHeight + CouldHeight) {
                        float cloudShadow = SampleCloudShadow(traceLocalPos, lightWorldDir, cloudOffset, camOffset);
                        sampleF *= 1.0 - (1.0 - ShadowCloudBrightnessF) * min(cloudShadow, 1.0);
                        //sampleF *= cloudShadow;
                    //}
                #endif
            #endif

            sampleLit += samplePhase * sampleF * sampleColor;
        #endif

        // #if defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
        //     if (skyRainStrength > EPSILON) {
        //         const vec3 worldUp = vec3(0.0, 1.0, 0.0);
        //         float cloudUnder = 1.0 - TraceCloudShadow(cameraPosition + traceLocalPos, worldUp, CLOUD_SHADOW_STEPS);
        //         sampleExtinction = mix(sampleExtinction, 0.02, cloudUnder * skyRainStrength);
        //     }
        // #endif

        #if defined WORLD_SKY_ENABLED && defined RENDER_COMPOSITE //&& VOLUMETRIC_BRIGHT_SKY > 0
            if (lightningStrength > EPSILON) {
                vec4 lightningDirectionStrength = GetLightningDirectionStrength(traceLocalPos);
                sampleLit += 0.4 * phaseIso * lightningDirectionStrength.w;

                // TODO: use phase function?
            }
        #endif

        #if VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != DYN_LIGHT_NONE && defined IRIS_FEATURE_SSBO
            vec3 blockLightAccum = vec3(0.0);

            #if LIGHTING_MODE == DYN_LIGHT_TRACED && defined VOLUMETRIC_BLOCK_RT && !defined RENDER_WEATHER
                uint gridIndex;
                uint lightCount = GetVoxelLights(traceLocalPos, gridIndex);

                if (gridIndex != DYN_LIGHT_GRID_MAX) {
                    for (uint l = 0; l < min(lightCount, 8); l++) {
                        uvec4 lightData = GetVoxelLight(gridIndex, l);

                        vec3 lightPos, lightColor;
                        float lightSize, lightRange;
                        ParseLightData(lightData, lightPos, lightSize, lightRange, lightColor);

                        lightRange *= VolumetricBlockRangeF;
                        lightColor = RGBToLinear(lightColor);

                        vec3 lightVec = traceLocalPos - lightPos;
                        if (length2(lightVec) >= _pow2(lightRange)) continue;
                        
                        #if defined VOLUMETRIC_BLOCK_RT && LIGHTING_MODE == DYN_LIGHT_TRACED
                            uint traceFace = 1u << GetLightMaskFace(lightVec);
                            if ((lightData.z & traceFace) == traceFace) continue;

                            if ((lightData.z & 1u) == 1u) {
                                vec3 traceOrigin = GetVoxelBlockPosition(lightPos);
                                vec3 traceEnd = traceOrigin + 0.999*lightVec;

                                lightColor *= TraceDDA(traceOrigin, traceEnd, lightRange);
                            }
                        #endif

                        float lightVoL = dot(normalize(-lightVec), localViewDir);
                        float lightPhase = DHG(lightVoL, phaseF.Back, phaseF.Forward, phaseF.Direction);

                        float lightAtt = GetLightAttenuation(lightVec, lightRange);
                        blockLightAccum += lightAtt * lightColor * lightPhase;
                    }

                    blockLightAccum *= 9.0 * DynamicLightBrightness;
                }
            #elif LPV_SIZE > 0
                vec3 lpvLight = vec3(0.0);

                #ifdef LPV_GI
                    if (!isWater) {
                #endif
                    lpvLight = 64.0 * GetLpvBlockLight(lpvSample, 3.0) * DynamicLightBrightness;

                    //float viewDistF = max(1.0 - traceDist*rcp(LPV_BLOCK_SIZE/2), 0.0);
                    //float skyLightF = 0.5 * GetLpvSkyLight(lpvSample);
                    //lpvLight += skyLightF * DynamicLightAmbientF;

                    //skyLightF = smoothstep(1.0, 0.85, skyLightF) * viewDistF;
                    //lpvLight = skyLightF*0.96 + 0.04;
                #ifdef LPV_GI
                    }
                #endif

                blockLightAccum += phaseIso * lpvLight * lpvFade;
            #endif

            sampleLit += blockLightAccum * VolumetricBrightnessBlock;// * DynamicLightBrightness;
        #endif

        #ifdef WORLD_SKY_ENABLED
            sampleAmbient *= skyLightColor;
        #endif

        //vec3 lightF = (sampleLit + sampleAmbient);
        vec3 lightF = sampleLit + sampleAmbient;

        ApplyScatteringTransmission(scatterFinal, transmitFinal, stepLength, lightF, sampleDensity, sampleScattering, sampleExtinction);

        // scatterFinal += scatterTransmit.rgb * transmitFinal;
        // transmitFinal *= scatterTransmit.a;
    }
}

// vec4 GetVolumetricLighting(const in vec3 localViewDir, const in vec3 sunDir, const in float nearDist, const in float farDist, const in float distTrans) {
//     bool isWater = false;
    
//     #if defined WORLD_WATER_ENABLED && defined RENDER_DEFERRED && (!defined MATERIAL_REFRACT_ENABLED || (defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED))
//         if (isEyeInWater == 1) isWater = true;
//     #endif

//     return GetVolumetricLighting(localViewDir, sunDir, nearDist, farDist, distTrans, isWater);
// }
