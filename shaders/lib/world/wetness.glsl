float GetSkyWetness(in vec3 worldPos, const in vec3 localNormal, in vec2 lmcoord) {
    lmcoord = saturate((lmcoord - (0.5/16.0)) / (15.0/16.0));

    float skyWetness = max(8.0 * lmcoord.y - 7.0, 0.0) * min(8.0 - 8.0 * lmcoord.x, 1.0);

    skyWetness *= smoothstep(0.0, 1.0, skyWetnessSmooth);//max(rainStrength, wetness);

    #ifdef WORLD_WATER_ENABLED
        if (vBlockId == BLOCK_WATER) return skyWetness;
    #endif

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

void ApplyWetnessPuddles(inout vec3 texNormal, const in vec3 localPos, const in float skyWetness, const in float porosity, const in float puddleF) {
    vec3 puddleNormal = vec3(0.0, 0.0, 1.0);

    #if WORLD_WETNESS_PUDDLES != PUDDLES_PIXEL
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

    float rippleTime = frameTimeCounter / 0.72;

    // #if WORLD_WATER_PIXEL > 0
    //     worldPos = floor(worldPos * WORLD_WATER_PIXEL) / WORLD_WATER_PIXEL;
    //     vec2 rippleTex = worldPos.xz * (WORLD_WATER_PIXEL/96.0);
    // #else
        #if WORLD_WETNESS_PUDDLES == PUDDLES_PIXEL || WORLD_WATER_PIXEL > 0
            worldPos = floor(worldPos * 32.0) / 32.0;
        #endif

        vec2 rippleTex = worldPos.xz * 0.3;
    //#endif

    vec3 rippleNormal;
    rippleNormal.xy = texture(TEX_RIPPLES, vec3(rippleTex, rippleTime)).rg * 2.0 - 1.0;
    rippleNormal.z = sqrt(max(1.0 - length2(rippleNormal.xy), EPSILON));

    float rippleF = 1.0 - min(viewDist * 0.06, 1.0);
    //rippleNormal = normalize(rippleNormal);

    rippleF *= _pow2(puddleF) * rainStrength;

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

void ApplySkyWetness(inout vec3 albedo, inout float roughness, const in float porosity, const in float skyWetness, const in float puddleF) {
    float saturation = max(skyWetness, 0.8 * puddleF) * sqrt(porosity);
    albedo = pow(albedo, vec3(1.0 + MaterialPorosityDarkenF * saturation));

    float surfaceWetness = saturate(2.0 * skyWetness - porosity);
    surfaceWetness = max(surfaceWetness, smoothstep(0.0, 0.2, puddleF));

    float _roughL = _pow2(roughness);
    _roughL = mix(_roughL, 0.06, surfaceWetness);
    roughness = sqrt(_roughL);
}
