struct VolumetricPhaseFactors {
    float Ambient;
    float ScatterF;
    float ExtinctF;
    float Direction;
    float Forward;
    float Back;
};

float ComputeVolumetricScattering(const in float VoL, const in float G_scattering) {
    float G_scattering2 = _pow2(G_scattering);

    return rcp(4.0 * PI) * ((1.0 - G_scattering2) / (pow(1.0 + G_scattering2 - (2.0 * G_scattering) * VoL, 1.5)));
}

#if LPV_SIZE > 0 && VOLUMETRIC_BRIGHT_BLOCK > 0
    const float vlWaterAmbient = 0.02;
#else
    const float vlWaterAmbient = 0.12;
#endif

const VolumetricPhaseFactors WaterPhaseF = VolumetricPhaseFactors(vlWaterAmbient, 0.024, 0.038, 0.72, 0.66, 0.26);

VolumetricPhaseFactors GetVolumetricPhaseFactors(const in vec3 sunDir) {
    VolumetricPhaseFactors result;

    #ifdef WORLD_SKY_ENABLED
        float densityF = sunDir.y * -0.2 + 0.8;
        float density = densityF * VolumetricDensityF;

        result.Ambient = 0.02 * densityF;

        result.Forward = mix(0.66, 0.26, rainStrength);
        result.Back = mix(0.32, 0.16, rainStrength);
        result.Direction = 0.75;

        result.ScatterF = mix(0.004, 0.018, rainStrength) * density;
        result.ExtinctF = mix(0.002, 0.015, rainStrength) * density;
    #else
        result.Ambient = 0.96;

        result.Forward = 0.6;
        result.Back = 0.2;
        result.Direction = 0.6;

        result.ScatterF = 0.006 * VolumetricDensityF;
        result.ExtinctF = 0.006 * VolumetricDensityF;
    #endif

    return result;
}
uniform float cloudTime;
#if !defined SHADOOW_COLOR_1
uniform sampler2D shadowcolor1;
#endif
#if  (defined RENDER_OPAQUE_VL || defined RENDER_TRANSLUCENT_VL || defined RENDER_OPAQUE_VL) && VOLUMETRIC_BRIGHT_BLOCK == 0
    uniform vec3 eyePosition;
#endif
float cloudshadow(in vec3 localPos, in vec3 lightWorldDir, vec2 cloudOffset, vec3 camOffset){
		vec3 vertexWorldPos = localPos + mod(eyePosition, 3072.0) + camOffset; // 3072 is one full cloud pattern
		float cloudHeightDifference = 192.0 - vertexWorldPos.y;

		vec3 cloudPos = vec3((vertexWorldPos.xz + lightWorldDir.xz * cloudHeightDifference + vec2(0.0, 4.0))/12.0 - cloudOffset.xy, cloudHeightDifference);
		cloudPos.xy *= 0.00390625;
        float cloud = 1.0 - texture2D(shadowcolor1, cloudPos.xy).a * 0.5 * step(0.0, cloudPos.z);
        return cloud*cloud;
}

vec4 GetVolumetricLighting(const in VolumetricPhaseFactors phaseF, const in vec3 localViewDir, const in vec3 sunDir, const in float nearDist, const in float farDist) {
    vec3 localStart = localViewDir * (nearDist + 0.1);
    vec3 localEnd = localViewDir * (farDist - 0.1);
    float localRayLength = max(farDist - nearDist - 0.2, 0.0);
    if (localRayLength < EPSILON) return vec4(0.0, 0.0, 0.0, 1.0);

    //int stepCount = VOLUMETRIC_SAMPLES;
    //int stepCount = int(ceil((localRayLength / far) * (VOLUMETRIC_SAMPLES - 2))) + 2;
    float inverseStepCountF = rcp(VOLUMETRIC_SAMPLES);
    
    vec3 localStep = localViewDir * (localRayLength * inverseStepCountF);

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    #if VOLUMETRIC_BRIGHT_SKY > 0 && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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
            vec3 WorldSkyLightColor = GetSkyLightColor(sunDir);
        #endif

        float VoL = dot(-localSkyLightDirection, -localViewDir);

        vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        skyLightColor *= smoothstep(0.0, 0.1, abs(sunDir.y));
        skyLightColor *= VolumetricBrightnessSky;

        float skyPhaseForward = ComputeVolumetricScattering(VoL, phaseF.Forward);
        float skyPhaseBack = ComputeVolumetricScattering(VoL, -phaseF.Back);
        float skyPhase = mix(skyPhaseBack, skyPhaseForward, phaseF.Direction);
    #endif

    float localStepLength = localRayLength * inverseStepCountF;
    float sampleTransmittance = exp(-phaseF.ExtinctF * localStepLength);
    float extinctionInv = rcp(phaseF.ExtinctF);

    vec3 inScatteringBase = phaseF.Ambient * RGBToLinear(fogColor);

    #ifdef WORLD_SKY_ENABLED
        float eyeLightLevel = 0.2 + 0.8 * (eyeBrightnessSmooth.y / 240.0);
        inScatteringBase *= eyeLightLevel;
    #endif

    float transmittance = 1.0;
    vec3 scattering = vec3(0.0);
    
    vec3 lightWorldDir = mat3(gbufferModelViewInverse)*shadowLightPosition;
	lightWorldDir /= lightWorldDir.y;
    vec3 worldPos = vec3((-cloudTime)/12.0 , 192.0, 0.33);
    vec2 cloudOffset = worldPos.xz;
    cloudOffset = mod(mod(cloudOffset, vec2(256.0))+256.0, vec2(256.0));

    const float irisCamWrap = 1024.0;
    vec3 camOffset = (mod(cameraPosition.xyz, irisCamWrap) + min(sign(cameraPosition.xyz), 0.0) * irisCamWrap) - (mod(eyePosition.xyz, irisCamWrap) + min(sign(eyePosition.xyz), 0.0) * irisCamWrap);
    camOffset.xz -= ivec2(greaterThan(abs(camOffset.xz), vec2(10.0))) * irisCamWrap; // eyePosition precission issues can cause this to be wrong, since the camera is usally not farther than 5 blocks, this should be fine
    for (int i = 0; i <= VOLUMETRIC_SAMPLES; i++) {
        vec3 inScattering = inScatteringBase;

        float iStep = i + dither * step(i, (VOLUMETRIC_SAMPLES-1));
        //if (i < stepCount) iStep += dither;

        #if VOLUMETRIC_BRIGHT_SKY > 0 && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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

                    if (any(greaterThan(shadowColor, EPSILON3)))
                        shadowColor = normalize(shadowColor) * 1.73;

                    sampleColor *= shadowColor;
                }
            #endif

            inScattering += skyPhase * sampleF * sampleColor*cloudshadow(localStart+localStep*iStep, lightWorldDir,cloudOffset,camOffset);
        #endif

        #if VOLUMETRIC_BRIGHT_BLOCK > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined IRIS_FEATURE_SSBO
            vec3 traceLocalPos = localStep * iStep + localStart;
            vec3 blockLightAccum = vec3(0.0);

            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined VOLUMETRIC_BLOCK_RT
                uint gridIndex;
                uint lightCount = GetSceneLights(traceLocalPos, gridIndex);

                if (gridIndex != DYN_LIGHT_GRID_MAX) {
                    for (uint l = 0; l < min(lightCount, LIGHT_BIN_MAX_COUNT); l++) {
                        uvec4 lightData = GetSceneLight(gridIndex, l);

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
                                vec3 traceOrigin = GetLightGridPosition(lightPos);
                                vec3 traceEnd = traceOrigin + 0.999*lightVec;

                                //#if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                                //    lightColor *= TraceRay(traceOrigin, traceEnd, lightRange);
                                //#elif VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_TRACE_FULL
                                    lightColor *= TraceDDA(traceOrigin, traceEnd, lightRange);
                                //#else
                                //    lightColor *= TraceDDA_fast(traceOrigin, traceEnd, lightRange);
                                //#endif
                            }
                        #endif

                        float lightVoL = dot(normalize(-lightVec), localViewDir);
                        float lightPhaseForward = ComputeVolumetricScattering(lightVoL, phaseF.Forward);
                        float lightPhaseBack = ComputeVolumetricScattering(lightVoL, -phaseF.Back);
                        float lightPhase = mix(lightPhaseBack, lightPhaseForward, phaseF.Direction);

                        float lightAtt = GetLightAttenuation(lightVec, lightRange);
                        blockLightAccum += 20.0 * lightAtt * lightColor * lightPhase;
                    }
                }
            #elif LPV_SIZE > 0
                vec3 lpvPos = GetLPVPosition(traceLocalPos);
                vec3 voxelPos = GetLightGridPosition(traceLocalPos);
                //vec3 lpvTexcoord = GetLPVTexCoord(lpvPos);

                //if (saturate(lpvTexcoord) == lpvTexcoord) {
                    vec3 lpvLight = SampleLpvVoxel(voxelPos, lpvPos);

                    //float lum = luminance(blockLightAccum);
                    //blockLightAccum /= max(lum, EPSILON);

                    lpvLight /= 16.0 * LpvRangeF;
                    lpvLight /= 8.0 + luminance(lpvLight);

                    blockLightAccum += 0.5 * lpvLight * GetLpvFade(lpvPos);
                //}
            #endif

            inScattering += blockLightAccum * VolumetricBrightnessBlock;// * DynamicLightBrightness;
        #endif

        inScattering *= phaseF.ScatterF;

        vec3 scatteringIntegral = (inScattering - inScattering * sampleTransmittance) * extinctionInv;

        scattering += scatteringIntegral * transmittance;
        transmittance *= sampleTransmittance;
    }

    //scattering /= (scattering + 1.0);

    return vec4(scattering, transmittance);
}

vec4 GetVolumetricLighting(const in vec3 localViewDir, const in vec3 sunDir, const in float nearDist, const in float farDist) {
    VolumetricPhaseFactors phaseF;

    #if defined WORLD_WATER_ENABLED && !(defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED && defined RENDER_DEFERRED)
        if (isEyeInWater == 1) phaseF = WaterPhaseF;
        else {
    #endif
        phaseF = GetVolumetricPhaseFactors(sunDir);
    #if defined WORLD_WATER_ENABLED && !(defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED && defined RENDER_DEFERRED)
        }
    #endif

    return GetVolumetricLighting(phaseF, localViewDir, sunDir, nearDist, farDist);
}
