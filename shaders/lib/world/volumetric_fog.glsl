struct VolumetricPhaseFactors {
    vec3  Ambient;
    vec3  ScatterF;
    float ExtinctF;
    float Direction;
    float Forward;
    float Back;
};

#ifdef WORLD_WATER_ENABLED
    #ifdef WORLD_SKY_ENABLED
        float skyLight = eyeBrightnessSmooth.y / 240.0;
        vec3 vlWaterAmbient = vec3(0.2, 0.8, 1.0) * mix(0.06, 0.002, rainStrength) * skyLight;
    #else
        const vec3 vlWaterAmbient = vec3(0.0040);
    #endif

    VolumetricPhaseFactors WaterPhaseF = VolumetricPhaseFactors(vlWaterAmbient * WorldWaterDensityF, vlWaterScatterColorL * WorldWaterDensityF, rcp(waterDensitySmooth) * WorldWaterDensityF, 0.09, 0.924, 0.197);
#endif

VolumetricPhaseFactors GetVolumetricPhaseFactors() {
    VolumetricPhaseFactors result;

    #ifdef WORLD_SKY_ENABLED
        //float time = worldTime / 12000.0;
        //float timeShift = mod(time + 0.875, 1.0);
        //float dayF = sin(timeShift * PI);

        //const float dayHalfDensity = 0.5 * VolumetricSkyDayDensityF;
        //float densityF = (1.0 - dayHalfDensity) - dayHalfDensity * dayF;
        //float density = densityF * VolumetricDensityF;

        //float skyLight = eyeBrightnessSmooth.y / 240.0;


        result.Ambient = vec3(mix(0.001, 0.03, rainStrength));// * densityF);
        //ambientF = mix(0.004, ambientF, skyLight);
        //result.Ambient = vec3(0.004); //vec3(ambientF);

        result.Forward = 0.824;
        result.Back = 0.19;
        result.Direction = 0.09;

        float scatterF = 0.02;// * density;
        //scatterF = scatterF;//mix(0.048, scatterF, skyLight);
        result.ScatterF = scatterF * vec3(0.522, 0.759, 0.894);

        result.ExtinctF = mix(0.002, 0.006, rainStrength);// * density;
        //result.ExtinctF = mix(0.008, extinctF, skyLight);
    #else
        result.Ambient = vec3(0.96);

        result.Forward = 0.6;
        result.Back = 0.2;
        result.Direction = 0.6;

        result.ScatterF = 0.006 * VolumetricDensityF * RGBToLinear(fogColor);
        result.ExtinctF = 0.006 * VolumetricDensityF;
    #endif

    return result;
}

vec4 GetVolumetricLighting(const in vec3 localViewDir, const in vec3 sunDir, const in float nearDist, const in float farDist, const in float distTrans, in bool isWater) {
    vec3 localStart = localViewDir * nearDist;
    vec3 localEnd = localViewDir * farDist;
    float localRayLength = max(farDist - nearDist, 0.0);
    if (localRayLength < EPSILON) return vec4(0.0, 0.0, 0.0, 1.0);

    #if WATER_DEPTH_LAYERS > 1 && defined WORLD_WATER_ENABLED
        VolumetricPhaseFactors phaseAir = GetVolumetricPhaseFactors();
        VolumetricPhaseFactors phaseWater = WaterPhaseF;
    #elif defined WORLD_WATER_ENABLED
        VolumetricPhaseFactors phaseF = isWater ? WaterPhaseF : GetVolumetricPhaseFactors();
    #else
        VolumetricPhaseFactors phaseF = GetVolumetricPhaseFactors();
    #endif

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    //int stepCount = VOLUMETRIC_SAMPLES;
    int stepCount = VOLUMETRIC_SAMPLES;//int(ceil((localRayLength / far) * (VOLUMETRIC_SAMPLES - 2 + dither))) + 2;
    float inverseStepCountF = rcp(stepCount);
    
    vec3 localStep = localViewDir * (localRayLength * inverseStepCountF);

    #if VOLUMETRIC_BRIGHT_SKY > 0 && defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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
        
    #if VOLUMETRIC_BRIGHT_SKY > 0 && defined WORLD_SKY_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
            vec3 WorldSkyLightColor = GetSkyLightColor(sunDir);
        #endif

        #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
            vec3 skyLightColor = 0.5 + 0.5 * GetCustomSkyFogColor(sunDir.y);
        #else
            vec3 skyLightColor = RGBToLinear(fogColor);
        #endif

        //vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        skyLightColor *= 2.0 * WorldSkyLightColor * VolumetricBrightnessSky;
        skyLightColor *= smoothstep(0.0, 0.1, abs(sunDir.y));

        float VoL = dot(localSkyLightDirection, localViewDir);

        #if WATER_DEPTH_LAYERS > 1 && defined WORLD_WATER_ENABLED
            float skyPhaseAir = DHG(VoL, -phaseAir.Back, phaseAir.Forward, phaseAir.Direction);
            float skyPhaseWater = DHG(VoL, -phaseWater.Back, phaseWater.Forward, phaseWater.Direction);
        #else
            float skyPhase = DHG(VoL, -phaseF.Back, phaseF.Forward, phaseF.Direction);
        #endif

        #ifdef RENDER_CLOUD_SHADOWS_ENABLED
            //vec3 lightWorldDir = mat3(gbufferModelViewInverse) * shadowLightPosition;
            vec3 lightWorldDir = localSkyLightDirection / localSkyLightDirection.y;

            vec2 cloudOffset = GetCloudOffset();
            vec3 camOffset = GetCloudCameraOffset();
        #endif
    #endif

    float localStepLength = localRayLength * inverseStepCountF;
    //float sampleTransmittance = exp(-phaseF.ExtinctF * localStepLength);

    #ifdef WORLD_WATER_ENABLED
        vec3 ambientWater = vec3(0.0);
    #endif

    #if defined WORLD_WATER_ENABLED && WATER_DEPTH_LAYERS > 1
        uvec2 uv = uvec2(gl_FragCoord.xy * exp2(VOLUMETRIC_RES));
        uint uvIndex = uint(uv.y * viewWidth + uv.x);

        float waterDepth[WATER_DEPTH_LAYERS+1];
        GetAllWaterDepths(uvIndex, distTrans, waterDepth);

        float extinctionInvAir = rcp(phaseAir.ExtinctF);
        float extinctionInvWater = rcp(phaseWater.ExtinctF);

        #ifdef WORLD_SKY_ENABLED
            float eyeLightF = eyeBrightnessSmooth.y / 240.0;
            vec3 skyLightAmbient = eyeLightF * skyLightColor * (1.0 - 0.9 * rainStrength);
            ambientWater = vec3(0.2, 0.8, 1.0) * skyLightAmbient * 0.02;
        #else
            ambientWater = vec3(0.0040);
        #endif
    #else
        float extinctionInv = rcp(phaseF.ExtinctF);
        vec3 ambientBase = phaseF.Ambient;
    #endif

    float transmittance = 1.0;
    vec3 scattering = vec3(0.0);

    for (int i = 0; i <= stepCount; i++) {
        if (i == stepCount) {
            localStepLength *= 1.0 - dither;
            dither = 0.0;
        }

        float iStep = i + dither;
        //if (i < stepCount) iStep += dither;

        vec3 traceLocalPos = localStep * iStep + localStart;
        float traceDist = length(traceLocalPos);

        #if LPV_SIZE > 0
            vec3 lpvPos = GetLPVPosition(traceLocalPos);
            vec3 voxelPos = GetVoxelBlockPosition(traceLocalPos);
            vec4 lpvSample = SampleLpvVoxel(voxelPos, lpvPos);

            // #ifdef WORLD_WATER_ENABLED
            //     float lpvSkyLightF = sqrt(saturate(lpvSample.a / LPV_SKYLIGHT_RANGE));
            //     ambientWater = 0.25 * vec3(0.2, 0.8, 1.0) * lpvSkyLightF * skyLightColor * (1.0 - 0.9 * rainStrength);
            // #endif
        #endif

        //vec3 inScattering = ambientBase;

        #ifdef WORLD_WATER_ENABLED
            float waterDepthEye = 0.0;

            #if LPV_SIZE > 0
                float lpvSkyLightF = sqrt(saturate(lpvSample.a / LPV_SKYLIGHT_RANGE));
                ambientWater = 0.25 * vec3(0.2, 0.8, 1.0) * lpvSkyLightF;
            #elif WORLD_SKY_ENABLED
                ambientWater = 0.25 * vec3(0.2, 0.8, 1.0) * skyLightColor * (1.0 - 0.9 * rainStrength);
            #endif
        #endif

        #if defined WORLD_WATER_ENABLED && WATER_DEPTH_LAYERS > 1
            if (isEyeInWater == 1) {
                isWater = traceDist < waterDepth[0] + 0.001;
                waterDepthEye += min(traceDist, waterDepth[0]);

                #if WATER_DEPTH_LAYERS >= 2
                    if (waterDepth[1] < farDist)
                        isWater = isWater || (traceDist > min(waterDepth[1], farDist) && traceDist < min(waterDepth[2], farDist));
                        // TODO: waterDepthEye
                #endif

                #if WATER_DEPTH_LAYERS >= 4
                    if (waterDepth[3] < farDist)
                        isWater = isWater || (traceDist > min(waterDepth[3], farDist) && traceDist < min(waterDepth[4], farDist));
                        // TODO: waterDepthEye
                #endif
            }
            else {
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
            }

            VolumetricPhaseFactors phaseF = isWater ? phaseWater : phaseAir;

            vec3 inScattering = isWater ? ambientWater : phaseAir.Ambient;
        #else
            vec3 inScattering = ambientBase;

            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 1)
                    waterDepthEye = traceDist;
                else {
                    // TODO: get dist from water to trace
                    waterDepthEye = 0.0;
                }
            #endif
        #endif

        #if VOLUMETRIC_BRIGHT_SKY > 0 && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            float sampleF = 1.0;
            vec3 sampleColor = skyLightColor;
            float sampleDepth = 0.0;

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

                    texDepth = texture(shadowtex0, traceShadowClipPos.xy).r;
                    sampleDepth = max(traceShadowClipPos.z - texDepth, 0.0) * (far * 3.0);
                }
            #else
                float sampleBias = GetShadowOffsetBias();// (0.01 / 256.0);

                vec3 traceShadowClipPos = shadowClipStep * iStep + shadowClipStart;
                traceShadowClipPos = distort(traceShadowClipPos);
                traceShadowClipPos = traceShadowClipPos * 0.5 + 0.5;

                //sampleF = CompareDepth(traceShadowClipPos, vec2(0.0), sampleBias);
                float texDepth = texture(shadowtex1, traceShadowClipPos.xy).r;
                sampleF = step(traceShadowClipPos.z - sampleBias, texDepth);

                texDepth = texture(shadowtex0, traceShadowClipPos.xy).r;
                sampleDepth = max(traceShadowClipPos.z - texDepth, 0.0) * (256.0);
            #endif

            #ifdef SHADOW_COLORED
                float transparentShadowDepth = texture(shadowtex0, traceShadowClipPos.xy).r;

                if (traceShadowClipPos.z - transparentShadowDepth >= EPSILON) {
                    vec3 shadowColor = texture(shadowcolor0, traceShadowClipPos.xy).rgb;
                    shadowColor = RGBToLinear(shadowColor);

                    if (any(greaterThan(shadowColor, EPSILON3)))
                        shadowColor = normalize(shadowColor) * 1.73;

                    sampleColor *= shadowColor;
                }
            #endif

            #ifndef RENDER_WEATHER
                if (isWater) {
                    #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
                        // TODO: replace traceLocalPos with water surface pos

                        float causticLight = SampleWaterCaustics(traceLocalPos);
                        causticLight = 6.0 * pow(causticLight, 1.0 + 1.0 * Water_WaveStrength);
                        sampleColor *= 0.5 + 0.5*mix(1.0, causticLight, Water_CausticStrength);
                    #endif

                    sampleColor *= exp(sampleDepth * -WaterAbsorbColorInv);
                }
            #endif

            #if defined RENDER_CLOUD_SHADOWS_ENABLED && defined WORLD_SKY_ENABLED
                if (traceLocalPos.y < 192.0) {
                    float cloudF = SampleCloudShadow(traceLocalPos, lightWorldDir, cloudOffset, camOffset);
                    sampleColor *= 1.0 - (1.0 - ShadowCloudBrightnessF) * min(cloudF, 1.0);
                }
            #endif

            #if WATER_DEPTH_LAYERS > 1 && defined WORLD_WATER_ENABLED
                sampleF *= isWater ? skyPhaseWater : skyPhaseAir;
            #else
                sampleF *= skyPhase;
            #endif

            inScattering += sampleF * sampleColor;
        #endif

        float sampleDensity = isWater ? 1.0 : VolumetricDensityF;

        #if VOLUMETRIC_BRIGHT_BLOCK > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined IRIS_FEATURE_SSBO
            vec3 blockLightAccum = vec3(0.0);

            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined VOLUMETRIC_BLOCK_RT && !defined RENDER_WEATHER
                uint gridIndex;
                uint lightCount = GetVoxelLights(traceLocalPos, gridIndex);

                if (gridIndex != DYN_LIGHT_GRID_MAX) {
                    for (uint l = 0; l < min(lightCount, LIGHT_BIN_MAX_COUNT); l++) {
                        uvec4 lightData = GetVoxelLight(gridIndex, l);

                        vec3 lightPos, lightColor;
                        float lightSize, lightRange;
                        ParseLightData(lightData, lightPos, lightSize, lightRange, lightColor);

                        lightRange *= VolumetricBlockRangeF;
                        lightColor = RGBToLinear(lightColor);

                        vec3 lightVec = traceLocalPos - lightPos;
                        if (length2(lightVec) >= _pow2(lightRange)) continue;
                        
                        #if defined VOLUMETRIC_BLOCK_RT && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                            uint traceFace = 1u << GetLightMaskFace(lightVec);
                            if ((lightData.z & traceFace) == traceFace) continue;

                            if ((lightData.z & 1u) == 1u) {
                                vec3 traceOrigin = GetVoxelBlockPosition(lightPos);
                                vec3 traceEnd = traceOrigin + 0.999*lightVec;

                                lightColor *= TraceDDA(traceOrigin, traceEnd, lightRange);
                            }
                        #endif

                        float lightVoL = dot(normalize(-lightVec), localViewDir);
                        float lightPhase = DHG(lightVoL, -phaseF.Back, phaseF.Forward, phaseF.Direction);

                        float lightAtt = GetLightAttenuation(lightVec, lightRange);
                        blockLightAccum += 20.0 * lightAtt * lightColor * lightPhase;
                    }
                }
            #elif LPV_SIZE > 0
                //vec3 lpvPos = GetLPVPosition(traceLocalPos);
                //vec3 voxelPos = GetVoxelBlockPosition(traceLocalPos);
                //vec4 lpvSample = SampleLpvVoxel(voxelPos, lpvPos);

                vec3 lpvLight = saturate(lpvSample.rgb / LpvBlockLightF);
                //lpvLight = sqrt(lpvLight / LpvBlockLightF);

                //lpvLight = sqrt(lpvLight / LpvRangeF);
                //lpvLight /= 1.0 + lpvLight;

                //lpvLight *= 0.3*LPV_BRIGHT_BLOCK;
                //lpvLight *= 0.25;

                if (isWater) {
                    lpvLight *= 0.0;//exp(-waterDepthEye * WaterAbsorbColorInv);
                    //sampleDensity *= 2.0;
                }
                else {
                    float viewDistF = max(1.0 - traceDist*rcp(LPV_BLOCK_SIZE/2), 0.0);
                    float skyLightF = sqrt(saturate(lpvSample.a/LPV_SKYLIGHT_RANGE));

                    skyLightF = smoothstep(1.0, 0.85, skyLightF) * viewDistF;
                    lpvLight *= skyLightF*0.96 + 0.04;
                }

                blockLightAccum += lpvLight * GetLpvFade(lpvPos);
            #endif

            inScattering += blockLightAccum * VolumetricBrightnessBlock;// * DynamicLightBrightness;
        #endif

        if (!isWater) {
            sampleDensity *= 1.0 - smoothstep(50.0, 420.0, traceLocalPos.y + cameraPosition.y);
        }

        inScattering *= phaseF.ScatterF * sampleDensity;
        float sampleTransmittance = exp(-phaseF.ExtinctF * localStepLength * sampleDensity);
        vec3 scatteringIntegral = inScattering - inScattering * sampleTransmittance;

        #if WATER_DEPTH_LAYERS > 1 && defined WORLD_WATER_ENABLED
            scatteringIntegral *= isWater ? extinctionInvWater : extinctionInvAir;
        #else
            scatteringIntegral *= extinctionInv;
        #endif

        scattering += scatteringIntegral * transmittance;
        transmittance *= sampleTransmittance;
    }

    return vec4(scattering, transmittance);
}

vec4 GetVolumetricLighting(const in vec3 localViewDir, const in vec3 sunDir, const in float nearDist, const in float farDist, const in float distTrans) {
    bool isWater = false;
    
    #if defined WORLD_WATER_ENABLED && defined RENDER_DEFERRED && (!defined MATERIAL_REFRACT_ENABLED || (defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED))
        if (isEyeInWater == 1) isWater = true;
    #endif

    return GetVolumetricLighting(localViewDir, sunDir, nearDist, farDist, distTrans, isWater);
}
