float GetSkyWetness(in vec3 worldPos, const in vec3 localNormal, const in vec2 lmcoord) {
    float skyWetness = max(8.0 * lmcoord.y - 7.0, 0.0) * min(8.0 - 8.0 * lmcoord.x, 1.0);

    skyWetness *= _smoothstep(skyWetnessSmooth);//max(rainStrength, wetness);

    skyWetness *= sqrt(localNormal.y * 0.5 + 0.5);

    #if WORLD_WETNESS_PUDDLES == PUDDLES_PIXEL
        worldPos = floor(worldPos * 16.0) / 16.0;
    #endif

    #if WORLD_WETNESS_PUDDLES != PUDDLES_FULL
        vec2 texPos = worldPos.xz + worldPos.y * 0.12;
        float wetnessNoise = textureLod(noisetex, texPos * 0.04, 0).r;
        wetnessNoise *= 1.0 - 0.7*textureLod(noisetex, texPos * 0.01, 0).g;

        float rf = min(wetness * 40.0, 1.0);
        vec2 s2 = 1.0 - textureLod(noisetex, texPos * 0.3, 0).rg;
        wetnessNoise = min(wetnessNoise, 1.0 - smoothstep(0.9 - 0.8 * rf, 1.0, s2.r * s2.g) * rf);

        return max(skyWetness - wetnessNoise, 0.0);
    #else
        return skyWetness;
    #endif
}

float GetWetnessPuddleF(const in float skyWetness, const in float porosity) {
    #if WORLD_WETNESS_PUDDLES != PUDDLES_NONE
        return smoothstep(0.6, 0.8, skyWetness - 0.1*_pow2(porosity));
    #else
        return 0.0;
    #endif
}

void ApplyWetness(inout vec3 albedo, const in float wetness) {
    albedo *= 1.0 - 0.36*wetness;
    albedo = pow(albedo, vec3(1.0 + wetness));
}

void ApplySkyWetness(inout vec3 albedo, const in float porosity, const in float skyWetness, const in float puddleF) {
    // float saturation = pow(puddleF, 0.3) + _smoothstep(skyWetness);
    float surfaceWetness = saturate(2.0 * skyWetness - porosity);
    surfaceWetness = max(surfaceWetness, smoothstep(0.0, 0.2, puddleF));

    surfaceWetness = saturate(MaterialPorosityDarkenF * surfaceWetness);
    ApplyWetness(albedo, surfaceWetness);
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
