float GetSkyWetness(in vec3 worldPos, const in vec3 localNormal, const in vec3 texNormal, in vec2 lmcoord) {
    lmcoord = saturate((lmcoord - (0.5/16.0)) / (15.0/16.0));

    float skyWetness = max(8.0 * lmcoord.y - 7.0, 0.0) * min(8.0 - 8.0 * lmcoord.x, 1.0);

    skyWetness *= smoothstep(0.0, 1.0, wetness);//max(rainStrength, wetness);

    #ifdef WORLD_WATER_ENABLED
        if (vBlockId == BLOCK_WATER) return skyWetness;
    #endif

    skyWetness *= pow(localNormal.y * 0.5 + 0.5, 0.5);

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        //skyWetness *= smoothstep(-0.8, 0.8, texNormal.y);
    #endif

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
        return smoothstep(0.6, 0.8, skyWetness - 0.2*_pow2(porosity));
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
            puddleEdgeNormal = mix(vec3(0.0, 0.0, 1.0), puddleEdgeNormal, _pow2(1.0 - porosity));
            puddleNormal = normalize(puddleEdgeNormal);
        }
    #endif

    float mixF = smoothstep(0.0, 0.1, puddleF);
    texNormal = mix(texNormal, puddleNormal, mixF);
    texNormal = normalize(texNormal);
}

void ApplyWetnessRipples(inout vec3 texNormal, in vec3 worldPos, const in float viewDist, const in float puddleF) {
    float rippleTime = frameTimeCounter / 0.72;

    #if WORLD_WETNESS_PUDDLES == PUDDLES_PIXEL
        worldPos = floor(worldPos * 32.0) / 32.0;
    #endif

    vec3 rippleNormal;
    vec2 rippleTex = worldPos.xz * 0.3;
    rippleNormal.xy = texture(TEX_RIPPLES, vec3(rippleTex, rippleTime)).rg * 2.0 - 1.0;
    rippleNormal.z = sqrt(max(1.0 - length2(rippleNormal.xy), EPSILON));

    rippleNormal.z *= viewDist;
    rippleNormal = normalize(rippleNormal);

    #if WORLD_WATER_WAVES != WATER_WAVES_NONE || defined PHYSICS_OCEAN
        if (vBlockId == BLOCK_WATER) {
            texNormal += rippleNormal.xzy * _pow2(puddleF) * rainStrength;
        }
        else {
    #endif
            texNormal = mix(texNormal, rippleNormal, _pow2(puddleF) * rainStrength);
    #if WORLD_WATER_WAVES != WATER_WAVES_NONE || defined PHYSICS_OCEAN
        }
    #endif

    texNormal = normalize(texNormal);
}

void ApplySkyWetness(inout vec3 albedo, inout float roughness, const in float porosity, const in float skyWetness, const in float puddleF) {
    float saturation = max(1.6 * skyWetness, puddleF) * pow(porosity, 0.5);
    albedo = pow(albedo, vec3(1.0 + saturation));

    float surfaceWetness = saturate(max(2.0 * skyWetness - porosity, puddleF));

    float _roughL = max(_pow2(roughness), ROUGH_MIN);
    _roughL = mix(_roughL, 0.06, surfaceWetness);
    roughness = sqrt(max(_roughL, EPSILON));
}
