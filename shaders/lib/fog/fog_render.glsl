void ApplyBorderFog(inout vec3 color, const in vec3 localPos, const in vec3 localViewDir, const in float far) {
    #ifndef IRIS_FEATURE_SSBO
        vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    #endif

    vec3 skyColorL = GetSkyColor(localSunDirection, localViewDir);
    float fogDist  = GetShapedFogDistance(localPos);

    float fogF = GetBorderFogFactor(fogDist, far);
    color = mix(color, skyColorL, fogF);
}

void ApplyBorderFog(inout vec3 color, const in vec3 localPos, const in vec3 localViewDir) {
    #ifndef IRIS_FEATURE_SSBO
        vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    #endif

    vec3 skyColorL = GetSkyColor(localSunDirection, localViewDir);
    float fogDist  = GetShapedFogDistance(localPos);

    float fogF = GetBorderFogFactor(fogDist);
    color = mix(color, skyColorL, fogF);
}

void ApplyFog(inout vec3 color, const in vec3 localPos, const in vec3 localViewDir) {
    #if SKY_TYPE == SKY_TYPE_CUSTOM
        vec3 fogColorFinal = vec3(0.0);
        float fogF = 0.0;

        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
        #endif

        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater == 1) {
                float viewDist = length(localPos);
                fogF = GetCustomWaterFogFactor(viewDist);
                fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
            }
            else {
        #endif
            fogColorFinal = GetSkyColor(localSunDirection, localViewDir);

            float fogDist  = GetShapedFogDistance(localPos);
            fogF = GetCustomFogFactor(fogDist);
        #ifdef WORLD_WATER_ENABLED
            }
        #endif

        color = mix(color, fogColorFinal, fogF);

    #elif SKY_TYPE == SKY_TYPE_VANILLA
        ApplyVanillaFog(color, localPos);
    #endif
}

void ApplyFog(inout vec4 color, const in vec3 localPos, const in vec3 localViewDir) {
    #if SKY_TYPE == SKY_TYPE_CUSTOM
        vec3 fogColorFinal = vec3(0.0);
        float fogF = 0.0;

        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
        #endif

        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater == 1) {
                float viewDist = length(localPos);
                fogF = GetCustomWaterFogFactor(viewDist);
                fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
            }
            else {
        #endif
            fogColorFinal = GetSkyColor(localSunDirection, localViewDir);

            float fogDist  = GetShapedFogDistance(localPos);
            fogF = GetCustomFogFactor(fogDist);
        #ifdef WORLD_WATER_ENABLED
            }
        #endif

        color.rgb = mix(color.rgb, fogColorFinal, fogF);

        if (color.a > alphaTestRef)
            color.a = mix(color.a, 1.0, fogF);
    #elif SKY_TYPE == SKY_TYPE_VANILLA
        ApplyVanillaFog(color, localPos);
    #endif
}
