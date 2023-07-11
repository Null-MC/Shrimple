float GetReflectiveness(const in float NoVm, const in float f0, const in float roughL) {
    return F_schlickRough(NoVm, f0, roughL) * (1.0 - roughL) * MaterialReflectionStrength;
}

vec3 GetSkyReflectionColor(const in vec3 reflectDir, const in float skyLight) {
    #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
        vec3 reflectColor;

        if (isEyeInWater == 1) {
            #ifndef IRIS_FEATURE_SSBO
                vec3 WorldSkyLightColor = GetSkyLightColor();
            #endif

            vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
            reflectColor = GetCustomWaterFogColor(localSunDirection.y);
        }
        else {
            vec3 skyColorFinal = RGBToLinear(skyColor);
            reflectColor = GetCustomSkyFogColor(localSunDirection.y);
            reflectColor = GetSkyFogColor(skyColorFinal, reflectColor, reflectDir.y);
        }
    #else
        vec3 reflectColor = GetVanillaFogColor(fogColor, reflectDir.y);
        reflectColor = RGBToLinear(reflectColor);
    #endif

    float m = skyLight * 0.25;
    reflectColor *= smoothstep(-0.4, 0.0, reflectDir.y) * (1.0 - m) + m;

    return reflectColor * pow(skyLight, 5.0);
}

void ApplyReflections(inout vec3 diffuse, inout vec3 specular, const in vec3 viewPos, const in vec3 texViewNormal, const in float skyReflectF, const in float skyLight, const in float roughness) {
    vec3 viewDir = normalize(viewPos);
    vec3 reflectViewDir = reflect(viewDir, texViewNormal);

    vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;
    vec3 reflectColor = GetSkyReflectionColor(reflectLocalDir, skyLight);

    #if MATERIAL_REFLECTIONS == REFLECT_SCREEN && (defined RENDER_TRANSLUCENT_FINAL) // || defined RENDER_WATER)
        vec3 clipPos = unproject(gbufferProjection * vec4(viewPos, 1.0)) * 0.5 + 0.5;
        vec3 reflectClipPos = unproject(gbufferProjection * vec4(viewPos + reflectViewDir, 1.0)) * 0.5 + 0.5;
        vec3 clipRay = reflectClipPos - clipPos;

        int maxLod = int(log2(min(viewWidth, viewHeight)));
        float roughMip = roughness * maxLod;

        vec4 reflection = GetReflectionPosition(depthtex1, clipPos, clipRay);
        vec3 col = GetRelectColor(reflection.xy, reflection.a, roughMip);

        #if WORLD_FOG_MODE != FOG_MODE_NONE
            vec3 reflectViewPos = unproject(gbufferProjectionInverse * vec4(reflection.xyz * 2.0 - 1.0, 1.0));

            vec3 fogColorFinal = vec3(0.0);
            float fogF = 0.0;

            if (isEyeInWater == 1) {
                // water fog

                float fogDist = length(reflectViewPos - viewPos);
                fogF = GetCustomWaterFogFactor(fogDist);

                fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
            }
            else if (reflection.z < 1.0) {
                #ifdef WORLD_SKY_ENABLED
                    // sky fog

                    #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
                        // TODO: apply fog to reflection

                        float fogDist = GetVanillaFogDistance(reflectViewPos);

                        fogF = GetCustomSkyFogFactor(fogDist);

                        vec3 skyColorFinal = RGBToLinear(skyColor);
                        fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                        fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, reflectLocalDir.y);
                    #elif WORLD_FOG_MODE == FOG_MODE_VANILLA
                        // TODO: apply fog to reflection
                    #endif
                #else
                    // no-sky fog

                    fogColorFinal = RGBToLinear(fogColor);
                    fogF = GetVanillaFogFactor(localPos);
                #endif
            }

            col = mix(col, fogColorFinal, fogF);
        #endif

        reflectColor = mix(reflectColor, col, reflection.a);
    #endif

    specular += reflectColor * skyReflectF;// * pow5(skyLight);
    diffuse *= 1.0 - skyReflectF;
}
