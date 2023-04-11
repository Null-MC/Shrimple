float GetLightAttenuation(const in vec3 lightVec, const in float lightRange) {
    float lightDist = length(lightVec);
    float lightAtt = 1.0 - saturate(lightDist / lightRange);
    return pow(lightAtt, 5.0);
}

float GetLightNoL(const in vec3 localNormal, const in vec3 texNormal, const in vec3 lightDir, const in float sss) {
    float NoL = 1.0;

    #if DYN_LIGHT_DIRECTIONAL > 0 || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        if (any(greaterThan(localNormal, EPSILON3)))
            NoL = dot(localNormal, lightDir);

        if (any(greaterThan(texNormal, EPSILON3))) {
            float texNoL = dot(texNormal, lightDir);
            NoL = min(NoL, texNoL);
        }
    #endif

    #if MATERIAL_SSS != SSS_NONE
        NoL = mix(max(NoL, 0.0), abs(NoL), sss);
    #else
        NoL = max(NoL, 0.0);
    #endif

    #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
        NoL = mix(1.0, NoL, DynamicLightDirectionalF);
    #endif

    return NoL;
}

float SampleLightDiffuse(const in float NoLm, const in float F) {
    return NoLm * (1.0 - F);
}

float SampleLightSpecular(const in float NoVm, const in float NoLm, const in float NoHm, const in float F, const in float roughL) {
    float a = NoHm * roughL;
    float k = roughL / (1.0 - _pow2(NoHm) + _pow2(a));
    float D = min(_pow2(k) * rcp(PI), 65504.0);

    float GGX_V = NoLm * (NoVm * (1.0 - roughL) + roughL);
    float GGX_L = NoVm * (NoLm * (1.0 - roughL) + roughL);
    float G = saturate(0.5 / (GGX_V + GGX_L));

    return D * G * F;
}
