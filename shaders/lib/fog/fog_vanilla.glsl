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

float GetVanillaFogFactor(const in float fogDist) {
    #ifdef WORLD_WATER_ENABLED //&& !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
        if (isEyeInWater == 1) return GetFogFactor(fogDist, 0.0, fogEnd, 1.0);
    #endif

    #ifdef DISTANT_HORIZONS
        float envFogStart = 0.2 * dhFarPlane;
        float envFogEnd = 0.5 * dhFarPlane;
    #else
        float envFogStart = 0.0;//fogStart;
        float envFogEnd = far;//fogEnd;
    #endif

    // env fog
    float fogF = 0.2 * GetFogFactor(fogDist, envFogStart, envFogEnd, 1.0);

    // border fog
    float borderFogF = GetBorderFogFactor(fogDist);
    fogF = max(fogF, borderFogF);

    return fogF;
}

float GetVanillaFogFactor(const in vec3 localPos) {
    float fogDist = GetShapedFogDistance(localPos);

    return GetVanillaFogFactor(fogDist);
}

void ApplyVanillaFog(inout vec3 color, const in vec3 localPos) {
    vec3 localViewDir = normalize(localPos);
    float fogDist = GetShapedFogDistance(localPos);
    float fogF = GetVanillaFogFactor(fogDist);

    vec3 fogColorL = RGBToLinear(fogColor);
    vec3 fogColorFinal = GetVanillaFogColor(fogColorL, localViewDir.y);

    color = mix(color, fogColorFinal, fogF);
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
