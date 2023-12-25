float GetSkyWetness(in vec3 worldPos, const in vec3 localNormal, const in vec2 lmcoord) {
    float skyWetness = max(8.0 * lmcoord.y - 7.0, 0.0) * min(8.0 - 8.0 * lmcoord.x, 1.0);

    skyWetness *= smoothstep(0.0, 1.0, skyWetnessSmooth);//max(rainStrength, wetness);

    // #ifdef WORLD_WATER_ENABLED
    //     if (blockId == BLOCK_WATER) return skyWetness;
    // #endif

    skyWetness *= sqrt(localNormal.y * 0.5 + 0.5);

    //#if MATERIAL_NORMALS != NORMALMAP_NONE
    //    //skyWetness *= smoothstep(-0.8, 0.8, texNormal.y);
    //#endif

    #if WORLD_WETNESS_PUDDLES == PUDDLES_PIXEL
        worldPos = floor(worldPos * 16.0) / 16.0;
    #endif
    
    vec2 texPos = worldPos.xz + worldPos.y * 0.12;
    float wetnessNoise = textureLod(noisetex, texPos * 0.04, 0).r;
    wetnessNoise *= 1.0 - 0.7*textureLod(noisetex, texPos * 0.01, 0).g;

    float rf = min(wetness * 40.0, 1.0);
    vec2 s2 = 1.0 - textureLod(noisetex, texPos * 0.3, 0).rg;
    wetnessNoise = min(wetnessNoise, 1.0 - smoothstep(0.9 - 0.8 * rf, 1.0, s2.r * s2.g) * rf);

    return max(skyWetness - wetnessNoise, 0.0);
}

float GetWetnessPuddleF(const in float skyWetness, const in float porosity) {
    #if WORLD_WETNESS_PUDDLES != PUDDLES_NONE
        return smoothstep(0.6, 0.8, skyWetness - 0.1*_pow2(porosity));
    #else
        return 0.0;
    #endif
}

void ApplySkyWetness(inout vec3 albedo, const in float porosity, const in float skyWetness, const in float puddleF) {
    //float saturation = max(1.4 * skyWetness, 2.0 * puddleF) * porosity;
    //float saturation = max(sqrt(puddleF), smoothstep(0.0, 1.0, skyWetness)) * porosity;
    float saturation = min(pow(puddleF, 0.3) + smoothstep(0.0, 1.0, skyWetness), 1.0) * porosity;
    //float saturation = sqrt(puddleF) * porosity;
    saturation = MaterialPorosityDarkenF * saturation;//pow(saturation, 0.25);

    albedo = pow(albedo, vec3(1.0 + saturation)) / (1 + 0.5*saturation);
}

#if defined RENDER_GBUFFER
    void ApplyWetnessPuddles(inout vec3 texNormal, const in vec3 localPos, const in float skyWetness, const in float porosity, const in float puddleF) {
        vec3 puddleNormal = vec3(0.0, 0.0, 1.0);

        #if WORLD_WETNESS_PUDDLES == PUDDLES_FANCY
            float puddleF2 = smoothstep(0.6, 0.8, skyWetness);
            float puddleHeight = pow(puddleF2, 0.06) / (puddleF2 + 8.0);

            vec3 puddlePos = localPos.xzy;
            puddlePos.z += saturate(puddleHeight);// * (1.0 - porosity);

            vec3 nX = dFdx(puddlePos);
            vec3 nY = dFdy(puddlePos);

            if (abs(nX.z - nY.z) > EPSILON) {
                vec3 puddleEdgeNormal = normalize(cross(nY, nX));
                puddleEdgeNormal = mix(puddleEdgeNormal, vec3(0.0, 0.0, 1.0), _pow2(porosity));
                puddleNormal = normalize(puddleEdgeNormal);
            }
        #endif

        float mixF = smoothstep(0.0, 0.1, puddleF);
        texNormal = mix(texNormal, puddleNormal, mixF);
        texNormal = normalize(texNormal);
    }

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

        rippleF *= _pow2(puddleF) * skyRainStrength;

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

    void ApplySkyWetness(inout float roughness, const in float porosity, const in float skyWetness, const in float puddleF) {
        float surfaceWetness = saturate(2.0 * skyWetness - porosity);
        surfaceWetness = max(surfaceWetness, smoothstep(0.0, 0.2, puddleF));

        float _roughL = _pow2(roughness);
        _roughL = mix(_roughL, 0.0, surfaceWetness);
        roughness = sqrt(_roughL);
    }

    void ApplySkyWetness(inout vec3 albedo, inout float roughness, const in float porosity, const in float skyWetness, const in float puddleF) {
        ApplySkyWetness(albedo, porosity, skyWetness, puddleF);
        ApplySkyWetness(roughness, porosity, skyWetness, puddleF);
    }
#endif
