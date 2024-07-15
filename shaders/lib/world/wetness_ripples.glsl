vec4 GetWetnessRipples(in vec3 worldPos, const in float viewDist, const in float puddleF) {
    //if (viewDist > 10.0) return;

    float rippleTime = GetAnimationFactor() / 0.72;

    // #if WATER_SURFACE_PIXEL_RES > 0
    //     worldPos = floor(worldPos * WATER_SURFACE_PIXEL_RES) / WATER_SURFACE_PIXEL_RES;
    //     vec2 rippleTex = worldPos.xz * (WATER_SURFACE_PIXEL_RES/96.0);
    // #else
        #if WORLD_WETNESS_PUDDLES == PUDDLES_PIXEL || WATER_SURFACE_PIXEL_RES > 0
            worldPos = floor(worldPos * 32.0) / 32.0;
        #endif

        vec2 rippleTex = worldPos.xz * 0.3;
    //#endif

    vec3 rippleNormal;
    rippleNormal.xy = texture(TEX_RIPPLES, vec3(rippleTex, rippleTime)).rg * 2.0 - 1.0;
    rippleNormal.z = sqrt(max(1.0 - length2(rippleNormal.xy), EPSILON));

    float rippleF = 1.0 - min(viewDist * 0.06, 1.0);
    //rippleNormal = normalize(rippleNormal);

    rippleF *= _pow2(puddleF) * weatherStrength;

    return vec4(rippleNormal, rippleF);
}

void ApplyWetnessRipples(inout vec3 texNormal, in vec4 rippleNormalStrength) {
    // #ifdef PHYSICS_OCEAN
    //     if (vBlockId == BLOCK_WATER) {
    //         texNormal += rippleNormalStrength.xzy * rippleNormalStrength.w;
    //     }
    //     else {
    // #endif
            texNormal = mix(texNormal, rippleNormalStrength.xyz, rippleNormalStrength.w);
    // #ifdef PHYSICS_OCEAN
    //     }
    // #endif

    texNormal = normalize(texNormal);
}
