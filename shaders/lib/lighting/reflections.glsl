vec3 GetReflectiveness(const in float NoVm, const in vec3 f0, const in float roughL) {
    return F_schlickRough(NoVm, f0, roughL) * MaterialReflectionStrength * (1.0 - roughL);
}

#ifdef WORLD_SKY_ENABLED
    vec3 GetSkyReflectionColor(const in vec3 reflectDir, const in float skyLight) {
        #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
            vec3 reflectColor;

            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 1) {
                    #ifndef IRIS_FEATURE_SSBO
                        vec3 WorldSkyLightColor = GetSkyLightColor();
                    #endif

                    vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
                    reflectColor = GetCustomWaterFogColor(localSunDirection.y);
                }
                else {
            #endif
                
                vec3 skyColorFinal = RGBToLinear(skyColor);
                reflectColor = GetCustomSkyFogColor(localSunDirection.y);
                reflectColor = GetSkyFogColor(skyColorFinal, reflectColor, reflectDir.y);

            #ifdef WORLD_WATER_ENABLED
                }
            #endif
        #else
            vec3 reflectColor = GetVanillaFogColor(fogColor, reflectDir.y);
            reflectColor = RGBToLinear(reflectColor);
        #endif

        float m = skyLight * 0.25;
        reflectColor *= smoothstep(-0.4, 0.0, reflectDir.y) * (1.0 - m) + m;

        return reflectColor * pow5(skyLight);
    }
#endif

vec3 ApplyReflections(const in vec3 viewPos, const in vec3 texViewNormal, const in float skyLight, const in float roughness) {
    vec3 viewDir = normalize(viewPos);
    vec3 reflectViewDir = reflect(viewDir, texViewNormal);

    #if REFLECTION_ROUGH_SCATTER > 0
        vec3 randomVec = normalize(hash32(gl_FragCoord.xy) * 2.0 - 1.0);
        if (dot(randomVec, texViewNormal) <= 0.0) randomVec = -randomVec;

        float roughScatterF = pow5(roughness) * ReflectionRoughScatterF;
        reflectViewDir = mix(reflectViewDir, randomVec, roughScatterF);
        reflectViewDir = normalize(reflectViewDir);
    #endif

    vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;
    //return reflectLocalDir * 0.5 + 0.5;

    #ifdef WORLD_SKY_ENABLED
        vec3 reflectColor = GetSkyReflectionColor(reflectLocalDir, skyLight);
    #else
        vec3 reflectColor = RGBToLinear(fogColor);
    #endif

    #if MATERIAL_REFLECTIONS == REFLECT_SCREEN && (defined RENDER_OPAQUE_POST_VL || defined RENDER_TRANSLUCENT_FINAL) // || defined RENDER_WATER)
        vec3 clipPos = unproject(gbufferProjection * vec4(viewPos, 1.0)) * 0.5 + 0.5;
        vec3 reflectClipPos = unproject(gbufferProjection * vec4(viewPos + reflectViewDir, 1.0)) * 0.5 + 0.5;
        vec3 clipRay = reflectClipPos - clipPos;

        //if (length2(clipRay) > EPSILON) clipRay = normalize(clipRay);
        //return clipRay * 0.5 + 0.5;

        int maxLod = int(log2(minOf(viewSize)));
        float roughMip = roughness * maxLod;

        vec4 reflection = GetReflectionPosition(depthtex1, clipPos, clipRay);
        vec3 col = GetRelectColor(reflection.xy, reflection.a, roughMip);

        #if WORLD_FOG_MODE != FOG_MODE_NONE
            if (reflection.z < 0.999999) {
                vec3 reflectViewPos = unproject(gbufferProjectionInverse * vec4(reflection.xyz * 2.0 - 1.0, 1.0));

                vec3 fogColorFinal = vec3(0.0);
                float fogF = 0.0;

                #ifdef WORLD_WATER_ENABLED
                    if (isEyeInWater == 1) {
                        // water fog

                        float fogDist = length(reflectViewPos - viewPos);
                        fogF = GetCustomWaterFogFactor(fogDist);

                        fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                    }
                    else {
                #endif

                    #ifndef DH_COMPAT_ENABLED
                        if (reflection.z < 1.0) {
                            vec3 reflectLocalPos = (gbufferModelViewInverse * vec4(reflectViewPos, 1.0)).xyz;

                            #ifdef WORLD_SKY_ENABLED
                                // sky fog

                                #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
                                    // TODO: apply fog to reflection

                                    float fogDist = GetVanillaFogDistance(reflectLocalPos);
                                    fogF = GetCustomSkyFogFactor(fogDist);

                                    vec3 skyColorFinal = RGBToLinear(skyColor);
                                    fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                                    fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, reflectLocalDir.y);
                                #elif WORLD_FOG_MODE == FOG_MODE_VANILLA
                                    // TODO: apply fog to reflection
                                #endif
                            #else
                                // no-sky fog

                                //vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

                                fogColorFinal = RGBToLinear(fogColor);
                                fogF = GetVanillaFogFactor(reflectLocalPos);
                            #endif
                        }
                    #endif

                #ifdef WORLD_WATER_ENABLED
                    }
                #endif

                col = mix(col, fogColorFinal, fogF);
            }
        #endif

        reflectColor = mix(reflectColor, col, reflection.a);
    #endif

    return reflectColor;// * skyReflectF;// * pow5(skyLight);
    //diffuse *= 1.0 - skyReflectF;
}
