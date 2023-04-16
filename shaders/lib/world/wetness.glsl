float GetSkyWetness(const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in float lmcoordY) {
    float skyLightCoord = saturate((lmcoordY - (0.5/16.0)) / (15.0/16.0));
    float skyWetness = saturate(10.0 * skyLightCoord - 8.5);

    skyWetness *= max(rainStrength, wetness);

    skyWetness *= localNormal.y * 0.5 + 0.5;

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        skyWetness *= texNormal.y * 0.5 + 0.5;
    #endif

    vec3 worldPos = localPos + cameraPosition;
    vec2 texPos = worldPos.xz + worldPos.y * 0.01;

    float wetnessNoise = textureLod(noisetex, texPos * 0.04, 0).r;
    wetnessNoise *= 1.0 - 0.7*textureLod(noisetex, texPos * 0.01, 0).g;

    return max(skyWetness - wetnessNoise, 0.0);
}

void ApplySkyWetness(inout vec3 albedo, inout float roughness, const in float porosity, const in float skyWetness) {
    float puddle = smoothstep(0.26, 0.42, skyWetness - 0.4*porosity);

    float saturation = max(1.5 * skyWetness, puddle) * porosity;
    albedo = pow(albedo, vec3(1.0 + saturation));

    float surfaceWetness = saturate(max(skyWetness - 0.3*porosity, puddle));

    float _roughL = max(_pow2(roughness), ROUGH_MIN);
    _roughL = mix(_roughL, 0.1, surfaceWetness);
    roughness = sqrt(max(_roughL, EPSILON));
}
