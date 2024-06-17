vec3 GetVanillaFogColor(const in vec3 fogColor, const in float viewUpF) {
    #ifdef WORLD_WATER_ENABLED //&& !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
        if (isEyeInWater == 1) return fogColor;
    #endif
    
    #ifdef WORLD_SKY_ENABLED
        return GetSkyFogColor(skyColor, fogColor, viewUpF);// * Sky_BrightnessF;
    #else
        return fogColor;
    #endif
}

float GetVanillaFogFactor(const in vec3 localPos) {
    float fogDist = GetShapedFogDistance(localPos);
    return GetFogFactor(fogDist, fogStart, fogEnd, 1.0);
}

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
