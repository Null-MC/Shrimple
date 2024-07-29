const float vlSkyMinLight = 0.08;


float GetWaterPhase(const in float VoL) {return DHG(VoL, -0.12, 0.68, 0.24);}

void ApplyVolumetricLighting(inout vec3 scatterFinal, inout vec3 transmitFinal, const in vec3 localViewDir, const in float nearDist, const in float farDist, const in float distTrans, in bool isWater) {
    vec3 localStart = localViewDir * nearDist;
    vec3 localEnd = localViewDir * farDist;

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
                vec3 shadowClipStart[4];
                vec3 shadowClipStep[4];

                for (int c = 0; c < 4; c++) {
                    shadowClipStart[c] = mul3(cascadeProjection[c], shadowViewStart) * 0.5 + 0.5;
                    shadowClipStart[c].xy = shadowClipStart[c].xy * 0.5 + shadowProjectionPos[c];

                    vec3 shadowClipEnd = mul3(cascadeProjection[c], shadowViewEnd) * 0.5 + 0.5;
                    shadowClipEnd.xy = shadowClipEnd.xy * 0.5 + shadowProjectionPos[c];

                    shadowClipStep[c] = (shadowClipEnd - shadowClipStart[c]) * inverseStepCountF;
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

        // #if SKY_TYPE == SKY_TYPE_CUSTOM
        //     vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * Sky_BrightnessF * eyeBrightF;
        // #else
        //     vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
        //     skyColorFinal = RGBToLinear(skyColorFinal) * eyeBrightF;
        // #endif

        vec3 skyColorFinal = SampleSkyIrradiance(localViewDir) * Sky_BrightnessF * eyeBrightF;
        //skyColorFinal += vlSkyMinLight;

        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            float weatherF = 1.0 - 0.5 * _pow2(weatherStrength);
        #else
            float weatherF = 1.0 - 0.8 * _pow2(weatherStrength);
        #endif

        //vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;
        //skyLightColor *= smoothstep(0.0, 0.1, abs(localSunDirection.y));

        #if defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE != CLOUDS_NONE
            //vec3 lightWorldDir = mat3(gbufferModelViewInverse) * shadowLightPosition;
            // TODO: Why TF was this dividing by Y?
            vec3 lightWorldDir = localSkyLightDirection;// / localSkyLightDirection.y;
        #endif

        float VoL = dot(localSkyLightDirection, localViewDir);

        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            float cloudAlt = GetCloudAltitude();
            // vec3 cloudOffset = cameraPosition - vec3(0.0, cloudAlt, 0.0);
            vec2 cloudOffset = GetCloudOffset();
            float phaseCloud = GetCloudPhase(VoL);
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA //&& VOLUMETRIC_BRIGHT_SKY > 0
            vec2 cloudOffset = GetCloudOffset();
            vec3 camOffset = GetCloudCameraOffset();
        #endif
    #else
        float time = GetAnimationFactor();
    #endif

    #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY && WATER_DEPTH_LAYERS > 1
        uvec2 uv = uvec2(gl_FragCoord.xy * exp2(VOLUMETRIC_RES));
        uint uvIndex = uint(uv.y * viewWidth + uv.x);

        float waterDepth[WATER_DEPTH_LAYERS+1];
        GetAllWaterDepths(uvIndex, waterDepth);
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

    for (int i = 0; i < VOLUMETRIC_SAMPLES; i++) {
        float stepDither = dither;// * step(i, VOLUMETRIC_SAMPLES-1);

        float iStep = i + stepDither;// * step(1, i);
        vec3 traceLocalPos = localStep * iStep + localStart;
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
            vec3 lpvPos = GetLPVPosition(traceLocalPos);
            vec4 lpvSample = SampleLpv(lpvPos);
            float lpvFade = GetLpvFade(lpvPos);
        #endif

        #ifdef WORLD_SKY_ENABLED
            #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY && WATER_DEPTH_LAYERS > 1
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

            float samplePhase = isWater ? GetWaterPhase(VoL) : GetSkyPhase(VoL);
        #else
            float samplePhase = phaseIso;
        #endif

        float sampleDensity = AirDensityF;
        vec3 sampleScattering = AirScatterColor;
        vec3 sampleExtinction = AirExtinctColor;
        vec3 sampleAmbient = vec3(AirAmbientF);

        #ifdef WORLD_WATER_ENABLED
            if (isWater) {
                sampleDensity = WaterDensityF;
                sampleExtinction = WaterAbsorbF;
                sampleScattering = WaterScatterF;
                sampleAmbient = vec3(WaterAmbientF);
            }
        #endif

        vec3 sampleLit = vec3(0.0);

        #if defined WORLD_SKY_ENABLED && SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
            if (!isWater) {
                sampleDensity = GetSkyDensity(traceAltitude);

                #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                    // if (weatherStrength > EPSILON) {
                    //     const vec3 worldUp = vec3(0.0, 1.0, 0.0);
                    //     //float cloudUnder = TraceCloudDensity(traceWorldPos, worldUp, CLOUD_SHADOW_STEPS);
                    //     float cloudUnder = TraceCloudDensity(traceWorldPos, worldUp, CLOUD_GROUND_SHADOW_STEPS);
                    //     // cloudUnder = smoothstep(0.0, 0.5, cloudUnder) * _pow2(weatherStrength);
                    //     cloudUnder *= _pow2(weatherStrength);

                    //     sampleDensity = mix(sampleDensity, AirDensityRainF, cloudUnder);
                    //     sampleScattering = mix(sampleScattering, AirScatterColor_rain, cloudUnder);
                    //     sampleExtinction = mix(sampleExtinction, AirExtinctColor_rain, cloudUnder);
                    // }

                    // #if WORLD_CURVE_RADIUS > 0
                    //     float sampleCloudF = SampleClouds(curvedWorldPos, traceAltitude, CloudTraceOctaves);
                    // #else
                        float sampleCloudF = SampleClouds(traceWorldPos, cloudOffset);
                    // #endif

                    sampleDensity = mix(sampleDensity, CloudDensityF, sampleCloudF);
                    sampleScattering = mix(sampleScattering, CloudScatterColor, sampleCloudF);
                    sampleExtinction = mix(sampleExtinction, CloudAbsorbColor, sampleCloudF);
                    sampleAmbient = mix(sampleAmbient, vec3(CloudAmbientF), sampleCloudF);
                    samplePhase = mix(samplePhase, phaseCloud, sampleCloudF);
                #endif
            }
        #endif

        #if defined IS_WORLD_SMOKE_ENABLED && !defined WORLD_SKY_ENABLED
            float smokeF = SampleSmokeOctaves(traceWorldPos, SmokeTraceOctaves, time);

            sampleDensity = smokeF * SmokeDensityF;
            sampleScattering = vec3(SmokeScatterF);
            sampleExtinction = vec3(SmokeAbsorbF);
            sampleAmbient = SmokeAmbientF * (fogColor*0.75 + 0.25);
            samplePhase = phaseIso;

            #ifdef WORLD_END
                const vec3 EndSmokeAmbientColor = _RGBToLinear(vec3(0.698, 0.212, 0.89));
                sampleAmbient = SmokeAmbientF * EndSmokeAmbientColor;
            #endif
        #endif

        float sampleF = 1.0;
        float sampleDepth = 0.0;

        #ifdef WORLD_SKY_ENABLED
            vec3 sampleColor = skyLightColor;
        #else
            vec3 sampleColor = vec3(1.0);
        #endif

        #ifdef RENDER_SHADOWS_ENABLED //&& SHADOW_TYPE != SHADOW_TYPE_NONE //&& VOLUMETRIC_BRIGHT_SKY > 0
            vec3 shadowViewPos = shadowViewStep * iStep + shadowViewStart;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vec3 shadowPos = vec3(-1.0);
                float shadowFade = 1.0;

                int cascade = GetShadowCascade(shadowViewPos, -0.01);
                float shadowDistF = 0.0;
                
                if (cascade >= 0) {
                    float shadowSampleBias = GetShadowOffsetBias(cascade);

                    shadowPos = iStep * shadowClipStep[cascade] + shadowClipStart[cascade];
                    //sampleF = CompareDepth(shadowPos, vec2(0.0), shadowSampleBias);
                    float texDepth = texture(shadowtex1, shadowPos.xy).r;
                    sampleF = step(shadowPos.z - shadowSampleBias, texDepth);

                    texDepth = texture(shadowtex0, shadowPos.xy).r;
                    sampleDepth = max(shadowPos.z - texDepth, 0.0) * shadowDepthRange;
                    shadowDistF = 1.0;
                    shadowFade = 0.0;
                }
            #else
                vec3 shadowNdcPos = shadowClipStep * iStep + shadowClipStart;
                shadowNdcPos = distort(shadowNdcPos);

                float shadowViewDist = length(shadowViewPos.xy);
                // float shadowDistFar = min(shadowDistance, far);
                float shadowFade = 1.0 - smoothstep(shadowDistFar - 20.0, shadowDistFar, shadowViewDist);
                shadowFade *= step(-1.0, shadowNdcPos.z);
                shadowFade *= step(shadowNdcPos.z, 1.0);
                shadowFade = 1.0 - shadowFade;

                vec3 shadowPos = shadowNdcPos * 0.5 + 0.5;

                if (shadowFade < 1.0) {
                    const float geoNoL = 1.0; // WARN: useless without geoNoL?
                    float shadowSampleBias = GetShadowOffsetBias(shadowNdcPos, geoNoL);
                    // float shadowSampleBias = 0.2 / -shadowDepthRange;
                    //sampleF = CompareDepth(shadowNdcPos, vec2(0.0), shadowSampleBias);

                    float texDepth = texture(shadowtex1, shadowPos.xy).r;
                    sampleF = step(shadowPos.z - shadowSampleBias, texDepth);

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
        #endif

        #if WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY && !defined RENDER_WEATHER
            if (isWater) {
                #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
                    // TODO: replace traceLocalPos with water surface pos

                    sampleColor *= SampleWaterCaustics(traceLocalPos, sampleDepth, 1.0);
                #endif

                //sampleColor *= exp(sampleDepth * WaterDensityF * -WaterAbsorbF);
            }
        #endif

        // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        #if defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE != CLOUDS_NONE
            float cloudShadow = 1.0;

            #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                cloudShadow = TraceCloudShadow(traceWorldPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
                // float cloudShadow = _TraceCloudShadow(traceWorldPos, dither, CLOUD_SHADOW_STEPS);
                //sampleColor *= 1.0 - (1.0 - Shadow_CloudBrightnessF) * min(cloudF, 1.0);
            #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
                if (traceWorldPos.y < cloudHeight + 0.5*CloudHeight) {
                    cloudShadow = SampleCloudShadow(traceLocalPos, localSkyLightDirection, cloudOffset, camOffset, 0.0);
                    //sampleF *= 1.0 - (1.0 - Shadow_CloudBrightnessF) * min(cloudShadow, 1.0);
                }
            #endif

            sampleF *= cloudShadow * 0.5 + 0.5;
        #endif

        sampleLit += samplePhase * sampleF * sampleColor;

        #if defined WORLD_SKY_ENABLED && defined RENDER_COMPOSITE //&& VOLUMETRIC_BRIGHT_SKY > 0
            if (lightningStrength > EPSILON) {
                vec4 lightningDirectionStrength = GetLightningDirectionStrength(traceLocalPos);
                sampleLit += 0.4 * phaseIso * lightningDirectionStrength.w;

                // TODO: use phase function?
            }
        #endif

        #if VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE > LIGHTING_MODE_BASIC && defined IRIS_FEATURE_SSBO
            vec3 blockLightAccum = vec3(0.0);

            #if LIGHTING_MODE == LIGHTING_MODE_TRACED && defined VOLUMETRIC_BLOCK_RT && !defined RENDER_WEATHER
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
                        
                        #if defined VOLUMETRIC_BLOCK_RT && LIGHTING_MODE == LIGHTING_MODE_TRACED
                            uint traceFace = 1u << GetLightMaskFace(lightVec);
                            if ((lightData.z & traceFace) == traceFace) continue;

                            if ((lightData.z & 1u) == 1u) {
                                vec3 traceOrigin = GetVoxelBlockPosition(lightPos);
                                vec3 traceEnd = traceOrigin + 0.999*lightVec;

                                bool traceSelf = ((lightData.z >> 1u) & 1u) == 1u;

                                lightColor *= TraceDDA(traceOrigin, traceEnd, lightRange, traceSelf);
                            }
                        #endif

                        float lightVoL = dot(normalize(-lightVec), localViewDir);
                        //float lightPhase = DHG(lightVoL, phaseF.Back, phaseF.Forward, phaseF.Direction);

                        float lightAtt = GetLightAttenuation(lightVec, lightRange);
                        blockLightAccum += lightAtt * lightColor * samplePhase;
                    }

                    blockLightAccum *= 32.0 * Lighting_Brightness;
                }
            #elif defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
                vec3 lpvLight = GetLpvBlockLight(lpvSample);
                blockLightAccum += phaseIso * lpvLight * lpvFade;
            #endif

            sampleLit += blockLightAccum * VolumetricBrightnessBlock;// * Lighting_Brightness;
        #endif

        #ifdef WORLD_SKY_ENABLED
            sampleAmbient *= skyColorFinal;
        #endif

        vec3 lightF = sampleLit + sampleAmbient;

        float traceStepLen = stepLength;
        // if (i == VOLUMETRIC_SAMPLES-1) traceStepLen *= (1.0 - dither);
        // else if (i == 0) traceStepLen *= dither;

        ApplyScatteringTransmission(scatterFinal, transmitFinal, traceStepLen, lightF, sampleDensity, sampleScattering, sampleExtinction);

        //if (all(lessThan(transmitFinal, EPSILON3))) break;
    }
}
