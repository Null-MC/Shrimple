float fogify(float x, float w) {
    return w / (x * x + w);
}

float GetFogFactorL(const in float dist, const in float start, const in float end, const in float density) {
    if (dist >= end) return 1.0;

    float distF = saturate((dist - start) / (end - start));
    return pow(distF, density);
}

float GetFogFactor(const in float dist, const in float start, const in float end, const in float density) {
    if (dist >= end) return 1.0;

    float distF = saturate((dist - start) / (end - start));
    return smoothstep(0.0, 1.0, pow(distF, density));
}

float GetShapedFogDistance(const in vec3 localPos) {
    vec3 fogPos = localPos;

    #if defined WORLD_SKY_ENABLED
        #if WORLD_FOG_SHAPE == FOG_SHAPE_CYLINDER
            fogPos.y = 0.0;
        #elif WORLD_FOG_SHAPE == FOG_SHAPE_DEFAULT
            if (fogShape == 1)
                fogPos.y = 0.0;
        #endif
    #endif

    return length(fogPos);
}

vec3 GetSkyFogColor(const in vec3 skyColor, const in vec3 fogColor, const in float viewUpF) {
    float fogF = fogify(max(viewUpF, 0.0), 0.06);

    // #ifdef WORLD_SKY_ENABLED
    //     fogF = mix(fogF, 1.0, rainStrength);
    // #endif

    return mix(skyColor, fogColor, fogF);

    //return fogColorFinal;// * WorldSkyBrightnessF;
}
