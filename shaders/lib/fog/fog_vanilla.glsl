vec3 GetVanillaFogColor(const in vec3 fogColorL, const in float viewUpF) {
    #ifdef WORLD_WATER_ENABLED //&& !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
        if (isEyeInWater == 1) return fogColorL;
    #endif
    
    #ifdef WORLD_SKY_ENABLED
        return GetSkyFogColor(RGBToLinear(skyColor), fogColorL, viewUpF);
    #else
        return fogColorL;
    #endif
}

float GetVanillaFogFactor(const in vec3 localPos) {
    float fogDist = GetShapedFogDistance(localPos);

    #ifdef DISTANT_HORIZONS
        return GetFogFactor(fogDist, 0.2 * dhFarPlane, 0.5 * dhFarPlane, 1.0);
    #else
        return GetFogFactor(fogDist, fogStart, fogEnd, 1.0);
    #endif
}

void ApplyVanillaFog(inout vec4 color, const in vec3 localPos) {
    vec3 localViewDir = normalize(localPos);

    vec3 fogColorL = RGBToLinear(fogColor);
    float fogF = GetVanillaFogFactor(localPos);
    vec3 fogColorFinal = GetVanillaFogColor(fogColorL, localViewDir.y);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);

    if (color.a > alphaTestRef)
        color.a = mix(color.a, 1.0, fogF);
}

void ApplyVanillaFog(inout vec3 color, const in vec3 localPos) {
    vec3 localViewDir = normalize(localPos);

    vec3 fogColorL = RGBToLinear(fogColor);
    float fogF = GetVanillaFogFactor(localPos);
    vec3 fogColorFinal = GetVanillaFogColor(fogColorL, localViewDir.y);
    fogColorFinal = RGBToLinear(fogColorFinal);

    color = mix(color, fogColorFinal, fogF);
}
