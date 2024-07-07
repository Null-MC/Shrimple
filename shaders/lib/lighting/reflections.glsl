vec3 GetReflectiveness(const in float NoVm, const in vec3 f0, const in float roughL) {
    return F_schlickRough(NoVm, f0, roughL) * MaterialReflectionStrength * (1.0 - roughL);
}

#ifdef WORLD_SKY_ENABLED
    vec3 GetSkyReflectionColor(const in vec3 localPos, const in vec3 reflectDir, const in float skyLight, const in float roughness) {
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
            vec3 WorldSkyLightColor = GetSkyLightColor(localSunDirection);
        #endif

        // #if SKY_TYPE == SKY_TYPE_CUSTOM
        //     vec3 reflectColor;

        //     #ifdef WORLD_WATER_ENABLED
        //         if (isEyeInWater == 1) {
        //             // #ifndef IRIS_FEATURE_SSBO
        //             //     vec3 WorldSkyLightColor = GetSkyLightColor();
        //             // #endif

        //             vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        //             reflectColor = GetCustomWaterFogColor(localSunDirection.y);
        //         }
        //         else {
        //     #endif
                
        //         reflectColor = GetCustomSkyColor(localSunDirection.y, reflectDir.y) * Sky_BrightnessF;

        //         #if !defined MATERIAL_REFLECT_CLOUDS && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
        //             // TODO
        //         #endif

        //     #ifdef WORLD_WATER_ENABLED
        //         }
        //     #endif
        // #elif SKY_TYPE == SKY_TYPE_VANILLA
        //     vec3 reflectColor = GetVanillaFogColor(fogColor, reflectDir.y);
        //     reflectColor = RGBToLinear(reflectColor);
        // #else
        //     vec3 reflectColor = RGBToLinear(skyColor) * Sky_BrightnessF;
        // #endif

        vec2 uvSky = DirectionToUV(reflectDir);
        vec3 reflectColor = textureLod(texSky, uvSky, 0).rgb;

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

    #ifdef REFLECTION_ROUGH_SCATTER
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

    vec3 reflectLocalDir = normalize(mat3(gbufferModelViewInverse) * reflectViewDir);

    #ifdef WORLD_SKY_ENABLED
        //vec3 reflectColor = GetSkyReflectionColor(localPos, reflectLocalDir, skyLight, roughness);
        vec2 uvSky = DirectionToUV(reflectLocalDir);
        vec3 skyColor = textureLod(texSky, uvSky, 0).rgb;
        vec3 reflectColor = skyColor * pow5(skyLight);
    #else
        vec3 skyColor = RGBToLinear(fogColor) * Sky_BrightnessF;
        vec3 reflectColor = skyColor;
    #endif
    
    #ifndef IRIS_FEATURE_SSBO
        vec3 localSunDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    #endif

    float _far = far;
    #ifdef DISTANT_HORIZONS
        _far = 0.5*dhFarPlane;
    #endif

    float reflectDist = 0.0;
    float reflectDepth = 1.0;
    float reflectF = 0.0;

    #if MATERIAL_REFLECTIONS == REFLECT_SCREEN && (defined RENDER_OPAQUE_POST_VL || defined RENDER_TRANSLUCENT_FINAL) // || defined RENDER_WATER)
        vec3 reflectViewPos = viewPos + 0.5*viewDist*reflectViewDir;

        #ifdef DISTANT_HORIZONS
            vec3 clipPos = unproject(dhProjectionFull, viewPos) * 0.5 + 0.5;
            vec3 reflectClipPos = unproject(dhProjectionFull, reflectViewPos) * 0.5 + 0.5;
        #else
            vec3 clipPos = unproject(gbufferProjection, viewPos) * 0.5 + 0.5;
            vec3 reflectClipPos = unproject(gbufferProjection, reflectViewPos) * 0.5 + 0.5;
        #endif

        vec3 clipRay = reflectClipPos - clipPos;

        float maxLod = log2(minOf(viewSize));
        float roughMip = sqrt(roughness) * maxLod;

        vec4 reflection = GetReflectionPosition(depthtex0, clipPos, clipRay);
        vec3 col = GetRelectColor(reflection.xy, reflection.a, roughMip);
        reflectF = reflection.a;
        reflectDepth = reflection.z;

        if (reflection.z < 1.0 && reflection.a > 0.0) {
            reflectClipPos = reflection.xyz * 2.0 - 1.0;
            #ifdef DISTANT_HORIZONS
                reflectViewPos = unproject(dhProjectionFullInv, reflectClipPos);
            #else
                reflectViewPos = unproject(gbufferProjectionInverse, reflectClipPos);
            #endif

            reflectDist = min(length(reflectViewPos - viewPos), _far);

            #ifdef SKY_BORDER_FOG_ENABLED
                // #ifndef IRIS_FEATURE_SSBO
                //     vec3 localSunDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
                // #endif

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

                    #ifdef SKY_BORDER_FOG_ENABLED
                        if (reflection.z < 1.0) {
                            vec3 reflectLocalPos = mat3(gbufferModelViewInverse) * reflectViewPos;
                            fogColorFinal = skyColor;

                            #if SKY_TYPE == SKY_TYPE_CUSTOM
                                // fogColorFinal = GetCustomSkyColor(localSunDirection.y, reflectLocalDir.y);

                                float fogDist = GetShapedFogDistance(reflectLocalPos);
                                fogF = GetCustomFogFactor(fogDist);
                            #else
                                //fogColorFinal = RGBToLinear(fogColor);
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
        // else reflectDist = _far;

        if (reflection.z >= 1.0)
            reflectDist = _far;

        reflectColor = mix(reflectColor, col, reflectF);
    #elif MATERIAL_REFLECTIONS == REFLECT_SKY
        reflectDist = _far;
    #endif

    #ifdef DISTANT_HORIZONS
        float farMax = dhFarPlane;
    #else
        float farMax = far;
    #endif

    vec3 worldPos = cameraPosition + localPos;

    #if defined MATERIAL_REFLECT_CLOUDS && SKY_CLOUD_TYPE > CLOUDS_VANILLA && defined WORLD_SKY_ENABLED && (!defined RENDER_GBUFFER || defined RENDER_WATER)
        //float farMax = min(viewDist, far);
        bool isSkyFrag = reflectDepth >= 1.0 || reflectF <= 0.0;

        #if SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
            const float cloudDistNear = 0.0;
            float cloudDistFar = !isSkyFrag ? reflectDist : SkyFar;
        #else
            vec3 cloudNear, cloudFar;
            GetCloudNearFar(worldPos, reflectLocalDir, cloudNear, cloudFar);
            
            float cloudDistNear = length(cloudNear);
            float cloudDistFar = min(length(cloudFar), SkyFar);

            if (cloudDistNear > 0.0 || cloudDistFar > 0.0)
                cloudDistFar = !isSkyFrag ? min(cloudDistFar, reflectDist) : SkyFar;
        #endif

        if (cloudDistFar > cloudDistNear) {
            vec3 cloudScatter = vec3(0.0);
            vec3 cloudTransmit = vec3(1.0);
            _TraceClouds(cloudScatter, cloudTransmit, worldPos, reflectLocalDir, cloudDistNear, cloudDistFar, CLOUD_REFLECT_STEPS, CLOUD_REFLECT_SHADOW_STEPS);
            reflectColor = reflectColor * cloudTransmit + cloudScatter;
        }
    #else
        #ifdef WORLD_SKY_ENABLED
            #ifndef IRIS_FEATURE_SSBO
                // vec3 localSunDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
                vec3 WorldSkyLightColor = CalculateSkyLightColor(localSunDirection.y);
            #endif

            vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
        #endif

        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater == 1) {
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

                // float waterFogFar = min(16.0 / WaterDensityF, reflectDist);
                float waterFogFar = min(24.0, reflectDist);

                ApplyScatteringTransmission(reflectColor, waterFogFar, vlLight, WaterDensityF, WaterScatterF, WaterAbsorbColor, 8);
            }
            else {
        #endif

            #if defined WORLD_SKY_ENABLED && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
                if (reflectDist > 0.0) {
                    bool isSkyFrag = reflectDepth >= 1.0 || reflectF <= 0.0;
                    float _skyFar = !isSkyFrag ? reflectDist : farMax;

                    vec3 scatterFinal = vec3(0.0);
                    vec3 transmitFinal = vec3(1.0);
                    TraceSky(scatterFinal, transmitFinal, worldPos, reflectLocalDir, 0.0, _skyFar, 12);
                    reflectColor = reflectColor * transmitFinal + scatterFinal * pow5(skyLight);
                }
            #endif

        #ifdef WORLD_WATER_ENABLED
            }
        #endif
    #endif

    return reflectColor;
}
