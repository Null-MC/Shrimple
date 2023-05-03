float fogify(float x, float w) {
    return w / (x * x + w);
}

vec3 GetFogColor(const in float NoUp) {
    vec3 fogColorFinal = RGBToLinear(fogColor);

    #if !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED)
        if (isEyeInWater == 1) return fogColorFinal;
    #endif

    fogColorFinal *= WorldSkyBrightnessF;
    
    #ifdef WORLD_SKY_ENABLED
        vec3 skyColorFinal = RGBToLinear(skyColor);
        return mix(skyColorFinal, fogColorFinal, fogify(max(NoUp, 0.0), 0.16));
    #else
        return fogColorFinal;
    #endif
}

vec3 GetFogColor(const in vec3 viewDir) {
    return GetFogColor(dot(viewDir, gbufferModelView[1].xyz));
}

#if !(defined RENDER_SKYBASIC || defined RENDER_SKYTEXTURED || defined RENDER_DEFERRED)
    float GetFogFactor(const in float dist, const in float start, const in float end, const in float density) {
        float distFactor = dist >= end ? 1.0 : smoothstep(start, end, dist);
        return saturate(pow(distFactor, density));
    }

    float GetVanillaFogFactor(const in vec3 localPos) {
        if (fogStart > far) return 0.0;

        vec3 fogPos = localPos;
        if (fogShape == 1)
            fogPos.y = 0.0;

        float viewDist = length(fogPos);
        return GetFogFactor(viewDist, fogStart, fogEnd, 1.0);
    }

    void ApplyFog(inout vec4 color, const in vec3 localPos) {
        float fogF = GetVanillaFogFactor(localPos);
        vec3 fogColorFinal = GetFogColor(normalize(localPos).y);
        color.rgb = mix(color.rgb, fogColorFinal, fogF);

        if (color.a > alphaTestRef)
            color.a = mix(color.a, 1.0, fogF);
    }
#endif
