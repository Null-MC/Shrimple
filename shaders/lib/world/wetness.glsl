void ApplySkyWetness(inout vec3 albedo, inout float roughness, const in float porosity, const in vec3 localNormal, const in vec3 texNormal, const in float lmcoordY) {
    float skyLightCoord = saturate((lmcoordY - (0.5/16.0)) / (15.0/16.0));
    float skyWetness = max(15.0 * skyLightCoord - 14.0, 0.0);

    skyWetness *= max(rainStrength, wetness);

    skyWetness *= localNormal.y * 0.5 + 0.5;

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        skyWetness *= texNormal.y * 0.5 + 0.5;
    #endif

    albedo = pow(albedo, vec3(1.0 + 0.8 * skyWetness * porosity));

    float surfaceWetness = saturate(1.4 * skyWetness - porosity);

    float _roughL = max(_pow2(roughness), ROUGH_MIN);
    _roughL = mix(_roughL, 0.1, surfaceWetness);
    roughness = sqrt(max(_roughL, EPSILON));
}
