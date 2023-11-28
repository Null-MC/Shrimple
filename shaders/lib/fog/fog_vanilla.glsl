vec3 GetVanillaFogColor(const in vec3 fogColor, const in float viewUpF) {
    #ifdef WORLD_WATER_ENABLED //&& !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
        if (isEyeInWater == 1) return fogColor;
    #endif
    
    #ifdef WORLD_SKY_ENABLED
        return GetSkyFogColor(skyColor, fogColor, viewUpF);// * WorldSkyBrightnessF;
    #else
        return fogColor;
    #endif
}

//#if !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
    // float GetVanillaFogDistance(const in vec3 localPos) {
    //     vec3 fogPos = localPos;

    //     #if defined WORLD_SKY_ENABLED
    //         #if WORLD_FOG_SHAPE == FOG_SHAPE_CYLINDER
    //             fogPos.y = 0.0;
    //         #elif WORLD_FOG_SHAPE == FOG_SHAPE_DEFAULT
    //             if (fogShape == 1)
    //                 fogPos.y = 0.0;
    //         #endif
    //     #endif

    //     return length(fogPos);// * rcp(WorldFogScaleF);
    // }

    float GetVanillaFogFactor(const in vec3 localPos) {
        float fogDist = GetShapedFogDistance(localPos);
        return GetFogFactor(fogDist, fogStart, fogEnd, 1.0);
    }
//#endif

//#if defined RENDER_GBUFFER && !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED || defined RENDER_CLOUDS) // || defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
    void ApplyVanillaFog(inout vec4 color, const in vec3 localPos) {
        vec3 localViewDir = normalize(localPos);

        float fogF = GetVanillaFogFactor(localPos);
        vec3 fogColorFinal = GetVanillaFogColor(fogColor, localViewDir.y);
        fogColorFinal = RGBToLinear(fogColorFinal);

        color.rgb = mix(color.rgb, fogColorFinal, fogF);

        if (color.a > alphaTestRef)
            color.a = mix(color.a, 1.0, fogF);
    }

    void ApplyVanillaFog(inout vec3 color, const in vec3 localPos) {
        vec3 localViewDir = normalize(localPos);

        float fogF = GetVanillaFogFactor(localPos);
        vec3 fogColorFinal = GetVanillaFogColor(fogColor, localViewDir.y);
        fogColorFinal = RGBToLinear(fogColorFinal);

        color = mix(color, fogColorFinal, fogF);
    }
//#endif
