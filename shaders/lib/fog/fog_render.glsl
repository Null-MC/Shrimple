void ApplyFog(inout vec4 color, const in vec3 localPos, const in vec3 localViewDir) {
    #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
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
            #ifdef WORLD_SKY_ENABLED
                vec3 skyColorFinal = RGBToLinear(skyColor);
                fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, localViewDir.y);
            #else
                fogColorFinal = GetVanillaFogColor(fogColor, localViewDir.y);
                fogColorFinal = RGBToLinear(fogColorFinal);
            #endif

            float fogDist  = GetShapedFogDistance(localPos);
            fogF = GetCustomFogFactor(fogDist);
        #ifdef WORLD_WATER_ENABLED
            }
        #endif

        color.rgb = mix(color.rgb, fogColorFinal * WorldSkyBrightnessF, fogF);

        if (color.a > alphaTestRef)
            color.a = mix(color.a, 1.0, fogF);
    #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
        ApplyVanillaFog(color, localPos);
    #endif
}
