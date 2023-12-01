vec3 GetReflectiveness(const in float NoVm, const in vec3 f0, const in float roughL) {
    return F_schlickRough(NoVm, f0, roughL) * MaterialReflectionStrength * (1.0 - sqrt(roughL));
}

#ifdef WORLD_SKY_ENABLED
    vec3 GetSkyReflectionColor(const in vec3 localPos, const in vec3 reflectDir, const in float skyLight, const in float roughness) {
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
            vec3 WorldSkyLightColor = GetSkyLightColor(localSunDirection);
        #endif

        #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
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

            #ifdef WORLD_WATER_ENABLED
                }
            #endif
        #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
            vec3 reflectColor = GetVanillaFogColor(fogColor, reflectDir.y);
            reflectColor = RGBToLinear(reflectColor);
        #else
            vec3 reflectColor = RGBToLinear(skyColor) * WorldSkyBrightnessF;
        #endif

        #if defined MATERIAL_REFLECT_CLOUDS && WORLD_CLOUD_TYPE == CLOUDS_VANILLA && (!defined RENDER_GBUFFER || defined RENDER_WATER)
            vec3 lightWorldDir = reflectDir / reflectDir.y;

            const vec3 cloudColor = RGBToLinear(vec3(0.8));
            const vec3 cloudColorRain = RGBToLinear(vec3(0.139, 0.184, 0.192));

            vec2 cloudOffset = GetCloudOffset();
            vec3 camOffset = GetCloudCameraOffset();
            float cloudF = SampleClouds(localPos, lightWorldDir, cloudOffset, camOffset, max(roughness, 0.1));
            vec3 cloudColorFinal = WorldSkyLightColor * mix(cloudColor, cloudColorRain, rainStrength);
            reflectColor = mix(reflectColor, cloudColorFinal, cloudF);
        #endif

        float m = skyLight * 0.25;
        reflectColor *= smoothstep(-0.4, 0.0, reflectDir.y) * (1.0 - m) + m;

        return reflectColor * pow5(skyLight);
    }
#endif

vec3 ApplyReflections(const in vec3 localPos, const in vec3 viewPos, const in vec3 texViewNormal, const in float skyLight, in float roughness) {
    vec3 viewDir = normalize(viewPos);
    vec3 reflectViewDir = reflect(viewDir, texViewNormal);

    //float viewDist = length(localPos);
    //float distF = 32.0 / (viewDist + 32.0);
    //roughness = pow(roughness, 0.5 + 0.5 * distF);

    #if REFLECTION_ROUGH_SCATTER > 0
        vec3 randomVec = normalize(hash32(gl_FragCoord.xy) * 2.0 - 1.0);
        if (dot(randomVec, texViewNormal) <= 0.0) randomVec = -randomVec;

        float roughScatterF = pow3(roughness) * ReflectionRoughScatterF;// * (1.0 - distF);
        reflectViewDir = mix(reflectViewDir, randomVec, roughScatterF);
        reflectViewDir = normalize(reflectViewDir);
    #endif

    vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;
    //return reflectLocalDir * 0.5 + 0.5;

    #ifdef WORLD_SKY_ENABLED
        vec3 reflectColor = GetSkyReflectionColor(localPos, reflectLocalDir, skyLight, roughness);
    #else
        vec3 reflectColor = RGBToLinear(fogColor);
    #endif

    float reflectDist = 0.0;
    float reflectDepth = 1.0;

    #if MATERIAL_REFLECTIONS == REFLECT_SCREEN && (defined RENDER_OPAQUE_POST_VL || defined RENDER_TRANSLUCENT_FINAL) // || defined RENDER_WATER)
        vec3 clipPos = unproject(gbufferProjection * vec4(viewPos, 1.0)) * 0.5 + 0.5;
        vec3 reflectClipPos = unproject(gbufferProjection * vec4(viewPos + reflectViewDir, 1.0)) * 0.5 + 0.5;
        vec3 clipRay = reflectClipPos - clipPos;

        //if (length2(clipRay) > EPSILON) clipRay = normalize(clipRay);
        //return clipRay * 0.5 + 0.5;

        //vec2 viewSize = vec2(viewWidth, viewHeight);
        int maxLod = int(log2(minOf(viewSize)));
        float roughMip = roughness * maxLod + 0.5;

        vec4 reflection = GetReflectionPosition(depthtex0, clipPos, clipRay);
        vec3 col = GetRelectColor(reflection.xy, reflection.a, roughMip);

        if (reflection.z < 1.0 && reflection.a > 0.0) {
            vec3 reflectViewPos = unproject(gbufferProjectionInverse * vec4(reflection.xyz * 2.0 - 1.0, 1.0));

            reflectDist = length(reflectViewPos - viewPos);
            reflectDepth = reflection.z;

            #if WORLD_FOG_MODE != FOG_MODE_NONE //&& WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
                #ifndef IRIS_FEATURE_SSBO
                    vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
                #endif

                vec3 fogColorFinal = vec3(0.0);
                float fogF = 0.0;

                #ifdef WORLD_WATER_ENABLED
                    if (isEyeInWater == 1) {
                        // water fog

                        float fogDist = length(reflectViewPos - viewPos);
                        fogF = GetCustomWaterFogFactor(fogDist);

                        #ifdef WORLD_SKY_ENABLED
                            fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                        #else
                            fogColorFinal = GetCustomWaterFogColor(-1.0);
                        #endif
                    }
                    else {
                #endif

                    #if !defined DH_COMPAT_ENABLED && WORLD_FOG_MODE != FOG_MODE_NONE
                        if (reflection.z < 1.0) {
                            vec3 reflectLocalPos = (gbufferModelViewInverse * vec4(reflectViewPos, 1.0)).xyz;

                            #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
                                fogColorFinal = GetCustomSkyColor(localSunDirection.y, reflectLocalDir.y);

                                float fogDist = GetShapedFogDistance(reflectLocalPos);
                                fogF = GetCustomFogFactor(fogDist);
                            #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
                                fogColorFinal = RGBToLinear(fogColor);
                                fogF = GetVanillaFogFactor(reflectLocalPos);
                            #endif
                        }
                    #endif

                #ifdef WORLD_WATER_ENABLED
                    }
                #endif

                col = mix(col, fogColorFinal, fogF);
            #endif
        }
        else reflectDist = far;

        reflectColor = mix(reflectColor, col, reflection.a);
    #elif MATERIAL_REFLECTIONS == REFLECT_SKY
        reflectDist = far;
    #endif

    #if defined MATERIAL_REFLECT_CLOUDS && WORLD_CLOUD_TYPE == CLOUDS_CUSTOM && defined WORLD_SKY_ENABLED && (!defined RENDER_GBUFFER || defined RENDER_WATER)
        vec4 cloudScatterTransmit = TraceCloudVL(cameraPosition + localPos, reflectLocalDir, reflectDist, reflectDepth, CLOUD_REFLECT_STEPS, CLOUD_REFLECT_SHADOW_STEPS);
        reflectColor = reflectColor * cloudScatterTransmit.a + cloudScatterTransmit.rgb;
    #else
        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater == 1) {
                //float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0 + 0.02;
                const float WaterAmbientF = 0.0;

                vec3 vlLight = (0.25 + WaterAmbientF) * WorldSkyLightColor * pow5(skyLight);// * eyeSkyLightF;
                ApplyScatteringTransmission(reflectColor, reflectDist, vlLight, 0.4*vlWaterScatterColorL, WaterAbsorbColorInv);
            }
            else {
        #endif

            // TODO: Limit reflectDist < cloudNear

            vec3 vlLight = (phaseAir + AirAmbientF) * WorldSkyLightColor * pow5(skyLight);
            vec4 scatterTransmit = ApplyScatteringTransmission(reflectDist, vlLight, AirScatterF, AirExtinctF);
            reflectColor = reflectColor * scatterTransmit.a + scatterTransmit.rgb;

        #ifdef WORLD_WATER_ENABLED
            }
        #endif
    #endif

    return reflectColor;
}
