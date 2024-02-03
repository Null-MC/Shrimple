vec3 GetReflectiveness(const in float NoVm, const in vec3 f0, const in float roughL) {
    return F_schlickRough(NoVm, f0, roughL) * MaterialReflectionStrength * (1.0 - roughL);
}

#ifdef WORLD_SKY_ENABLED
    vec3 GetSkyReflectionColor(const in vec3 localPos, const in vec3 reflectDir, const in float skyLight, const in float roughness) {
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
            vec3 WorldSkyLightColor = GetSkyLightColor(localSunDirection);
        #endif

        #if SKY_TYPE == SKY_TYPE_CUSTOM
            vec3 reflectColor;

            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 1) {
                    // #ifndef IRIS_FEATURE_SSBO
                    //     vec3 WorldSkyLightColor = GetSkyLightColor();
                    // #endif

                    vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
                    reflectColor = GetCustomWaterFogColor(localSunDirection.y);
                }
                else {
            #endif
                
                // vec3 skyColorFinal = RGBToLinear(skyColor);
                // reflectColor = GetCustomSkyFogColor(localSunDirection.y);
                // reflectColor = GetSkyFogColor(skyColorFinal, reflectColor, reflectDir.y);
                //reflectColor = GetCustomSkyFogColor(localSunDirection.y) * WorldSkyBrightnessF;
                reflectColor = GetCustomSkyColor(localSunDirection.y, reflectDir.y) * WorldSkyBrightnessF;

                #if !defined MATERIAL_REFLECT_CLOUDS && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
                    // TODO
                #endif

            #ifdef WORLD_WATER_ENABLED
                }
            #endif
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            vec3 reflectColor = GetVanillaFogColor(fogColor, reflectDir.y);
            reflectColor = RGBToLinear(reflectColor);
        #else
            vec3 reflectColor = RGBToLinear(skyColor) * WorldSkyBrightnessF;
        #endif

        #if defined MATERIAL_REFLECT_CLOUDS && SKY_CLOUD_TYPE == CLOUDS_VANILLA && (!defined RENDER_GBUFFER || defined RENDER_WATER)
            vec3 lightWorldDir = reflectDir / reflectDir.y;

            const vec3 cloudColor = _RGBToLinear(vec3(0.8));
            const vec3 cloudColorRain = _RGBToLinear(vec3(0.139, 0.184, 0.192));

            vec2 cloudOffset = GetCloudOffset();
            vec3 camOffset = GetCloudCameraOffset();
            float cloudF = SampleClouds(localPos, lightWorldDir, cloudOffset, camOffset, max(roughness, 0.1));
            vec3 cloudColorFinal = WorldSkyLightColor * mix(cloudColor, cloudColorRain, rainStrength);
            reflectColor = mix(reflectColor, cloudColorFinal, cloudF);
        #endif

        if (isEyeInWater != 1) {
            float m = skyLight * 0.25;
            reflectColor *= smoothstep(-0.4, 0.0, reflectDir.y) * (1.0 - m) + m;
        }

        return reflectColor * pow5(skyLight);
    }
#endif

vec3 ApplyReflections(const in vec3 localPos, const in vec3 viewPos, const in vec3 texViewNormal, const in float skyLight, in float roughness) {
    if (all(lessThan(abs(texViewNormal), EPSILON3))) return vec3(0.0);

    float viewDist = length(viewPos);
    vec3 viewDir = viewPos / viewDist;
    vec3 reflectViewDir = reflect(viewDir, texViewNormal);

    //float distF = 32.0 / (viewDist + 32.0);
    //roughness = pow(roughness, 0.5 + 0.5 * distF);

    #if REFLECTION_ROUGH_SCATTER > 0
        #ifdef EFFECT_TAA_ENABLED
            vec3 seed = vec3(gl_FragCoord.xy, 1.0 + frameCounter);
        #else
            vec3 seed = vec3(gl_FragCoord.xy, 1.0);
        #endif

        vec3 randomVec = normalize(hash33(seed) * 2.0 - 1.0);
        if (dot(randomVec, texViewNormal) <= 0.0) randomVec = -randomVec;

        float roughScatterF = pow2(roughness);// * ReflectionRoughScatterF;// * (1.0 - distF);
        reflectViewDir = mix(reflectViewDir, randomVec, roughScatterF);
        reflectViewDir = normalize(reflectViewDir);
    #endif

    vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;
    //if (all(lessThan(abs(reflectLocalDir), EPSILON3))) return vec3(0.0);
    reflectLocalDir = normalize(reflectLocalDir);
    //return reflectLocalDir * 0.5 + 0.5;


    #ifdef WORLD_SKY_ENABLED
        vec3 reflectColor = GetSkyReflectionColor(localPos, reflectLocalDir, skyLight, roughness);
    #else
        vec3 reflectColor = RGBToLinear(fogColor) * WorldSkyBrightnessF;
    #endif

    // #if SKY_CLOUD_TYPE != CLOUDS_NONE
    //     float farMax = SkyFar;
    // #else
    //     float farMax = far;
    // #endif

    float reflectDist = 0.0;
    float reflectDepth = 1.0;
    float reflectF = 0.0;

    #if MATERIAL_REFLECTIONS == REFLECT_SCREEN && (defined RENDER_OPAQUE_POST_VL || defined RENDER_TRANSLUCENT_FINAL) // || defined RENDER_WATER)
        vec3 reflectViewPos = viewPos + 0.5*viewDist*reflectViewDir;

        #ifdef DISTANT_HORIZONS
            vec3 clipPos = unproject(dhProjectionFull * vec4(viewPos, 1.0)) * 0.5 + 0.5;
            vec3 reflectClipPos = unproject(dhProjectionFull * vec4(reflectViewPos, 1.0)) * 0.5 + 0.5;
        #else
            vec3 clipPos = unproject(gbufferProjection * vec4(viewPos, 1.0)) * 0.5 + 0.5;
            vec3 reflectClipPos = unproject(gbufferProjection * vec4(reflectViewPos, 1.0)) * 0.5 + 0.5;
        #endif

        // clipPos.z += 0.002;
        // reflectClipPos.z += 0.002;

        vec3 clipRay = reflectClipPos - clipPos;

        //if (length2(clipRay) > EPSILON) clipRay = normalize(clipRay);
        //return clipRay * 0.5 + 0.5;

        //vec2 viewSize = vec2(viewWidth, viewHeight);
        float maxLod = log2(minOf(viewSize));
        float roughMip = sqrt(roughness) * maxLod;

        vec4 reflection = GetReflectionPosition(depthtex0, clipPos, clipRay);
        vec3 col = GetRelectColor(reflection.xy, reflection.a, roughMip);
        reflectF = reflection.a;
        reflectDepth = reflection.z;
    // return col;

        if (reflection.z < 1.0 && reflection.a > 0.0) {
            reflectClipPos = reflection.xyz * 2.0 - 1.0;
            #ifdef DISTANT_HORIZONS
                reflectViewPos = unproject(dhProjectionFullInv * vec4(reflectClipPos, 1.0));
            #else
                reflectViewPos = unproject(gbufferProjectionInverse * vec4(reflectClipPos, 1.0));
            #endif

            float _far = far;
            #ifdef DISTANT_HORIZONS
                _far = 0.5*dhFarPlane;
            #endif

            reflectDist = min(length(reflectViewPos - viewPos), _far);

            #ifdef SKY_BORDER_FOG_ENABLED
                #ifndef IRIS_FEATURE_SSBO
                    vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
                #endif

                vec3 fogColorFinal = vec3(0.0);
                float fogF = 0.0;

                #ifdef WORLD_WATER_ENABLED
                    if (isEyeInWater == 1) {
                        // water fog

                        #if SKY_TYPE == SKY_TYPE_CUSTOM
                            //float fogDist = length(reflectViewPos - viewPos);
                            fogF = GetCustomWaterFogFactor(reflectDist);

                            #ifdef WORLD_SKY_ENABLED
                                fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                            #else
                                fogColorFinal = GetCustomWaterFogColor(-1.0);
                            #endif
                        #else
                            // TODO
                        #endif
                    }
                    else {
                #endif

                    #if !defined DH_COMPAT_ENABLED && defined SKY_BORDER_FOG_ENABLED
                        if (reflection.z < 1.0) {
                            vec3 reflectLocalPos = (gbufferModelViewInverse * vec4(reflectViewPos, 1.0)).xyz;

                            #if SKY_TYPE == SKY_TYPE_CUSTOM
                                fogColorFinal = GetCustomSkyColor(localSunDirection.y, reflectLocalDir.y);

                                float fogDist = GetShapedFogDistance(reflectLocalPos);
                                fogF = GetCustomFogFactor(fogDist);
                            #elif SKY_TYPE == SKY_TYPE_VANILLA
                                fogColorFinal = RGBToLinear(fogColor);
                                fogF = GetVanillaFogFactor(reflectLocalPos);
                            #endif
                        }
                    #endif

                #ifdef WORLD_WATER_ENABLED
                    }
                #endif

                col = mix(col, fogColorFinal, fogF * (1.0 - reflectF));
            #endif
        }
        else reflectDist = far;

        reflectColor = mix(reflectColor, col, reflectF);
    #elif MATERIAL_REFLECTIONS == REFLECT_SKY
        reflectDist = far;
    #endif

    // return reflectColor;

    #ifdef DISTANT_HORIZONS
        float farMax = max(SkyFar, 0.5*dhFarPlane);
    #else
        float farMax = SkyFar;
    #endif

    #if defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
        #ifdef DISTANT_HORIZONS
            // TODO
        #else
            if (reflectDist >= far) reflectDist = farMax;
        #endif
    #endif

    #if defined MATERIAL_REFLECT_CLOUDS && SKY_CLOUD_TYPE > CLOUDS_VANILLA && defined WORLD_SKY_ENABLED && (!defined RENDER_GBUFFER || defined RENDER_WATER)
        vec3 worldPos = cameraPosition + localPos;

        vec3 cloudNear, cloudFar;
        GetCloudNearFar(worldPos, reflectLocalDir, cloudNear, cloudFar);
        
        float cloudDistNear = length(cloudNear);
        float cloudDistFar = length(cloudFar);

        cloudDistNear = min(cloudDistNear, farMax);
        cloudDistFar = min(cloudDistFar, farMax);

        #ifdef DISTANT_HORIZONS
            // TODO
        #else
            if (reflectDist < far) cloudDistFar = min(cloudDistFar, reflectDist);
        #endif

        // if (cloudDistNear < viewDist || depthOpaque >= 0.9999)
        //     cloudDistFar = min(cloudDistFar, min(viewDist, SkyFar));
        // else {
        //     cloudDistNear = 0.0;
        //     cloudDistFar = 0.0;
        // }

        //float farMax = min(viewDist, far);

        if (cloudDistFar > cloudDistNear) {
            //vec4 cloudScatterTransmit = TraceCloudVL(cameraPosition + localPos, reflectLocalDir, reflectDist, reflectDepth, CLOUD_REFLECT_STEPS, CLOUD_REFLECT_SHADOW_STEPS);
            vec4 cloudScatterTransmit = _TraceCloudVL(worldPos, reflectLocalDir, cloudDistNear, cloudDistFar, CLOUD_REFLECT_STEPS, CLOUD_REFLECT_SHADOW_STEPS);
            reflectColor = reflectColor * cloudScatterTransmit.a + cloudScatterTransmit.rgb;
        }
    #else
        #ifdef WORLD_SKY_ENABLED
            vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        #endif

        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater == 1) {
                // const float WaterAmbientF = 0.0;

                // vec3 vlLight = (0.25 + WaterAmbientF) * WorldSkyLightColor * pow5(skyLight);// * eyeSkyLightF;
                // ApplyScatteringTransmission(reflectColor, reflectDist, vlLight, WaterScatterF, WaterAbsorbF);
                
                float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0;

                #ifdef WORLD_SKY_ENABLED
                    eyeSkyLightF *= 1.0 - 0.8 * rainStrength;
                #endif
                
                eyeSkyLightF += 0.02;

                vec3 vlLight = vec3(phaseIso + WaterAmbientF);

                #ifdef WORLD_SKY_ENABLED
                    vlLight *= skyLightColor * eyeSkyLightF;
                #endif
                // ApplyScatteringTransmission(reflectColor, reflectDist, vlLight, 1.0, WaterScatterF, WaterAbsorbF);

                float waterFogFar = min(16.0 / WaterDensityF, reflectDist);

                ApplyScatteringTransmission(reflectColor, waterFogFar, vlLight, WaterDensityF, WaterScatterF, WaterAbsorbColor, 8);
            }
            else {
        #endif

            #if SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
                #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
                    float VoL = dot(localSkyLightDirection, reflectLocalDir);
                    float phaseSky = GetSkyPhase(VoL);
                    vec3 vlLight = vec3(phaseSky + AirAmbientF);
                #else
                    vec3 vlLight = vec3(phaseIso + AirAmbientF);
                #endif

                float reflectFogDist = reflectDist;

                #ifdef WORLD_SKY_ENABLED
                    vlLight *= skyLightColor * pow5(skyLight);

                    reflectFogDist = min(reflectFogDist, farMax);
                    // TODO: Limit reflectDist < cloudNear
                #endif

                if (reflectFogDist > 1.0) {
                    ApplyScatteringTransmission(reflectColor, reflectFogDist, vlLight, AirDensityF, AirScatterColor, AirExtinctColor, 8);
                }
            #endif

        #ifdef WORLD_WATER_ENABLED
            }
        #endif
    #endif

    return reflectColor;
}
