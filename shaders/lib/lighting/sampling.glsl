float GetLightAttenuation(const in vec3 lightVec, const in float lightRange) {
    float lightDist = length(lightVec);
    float lightAtt = 1.0 - saturate(lightDist / lightRange);
    return _pow3(lightAtt);
}

float GetLightNoL(const in float geoNoL, const in vec3 texNormal, const in vec3 lightDir, const in float sss) {
    float NoL = 1.0;

    float texNoL = geoNoL;
    if (!all(lessThan(abs(texNormal), EPSILON3)))
        texNoL = dot(texNormal, lightDir);

    #if DYN_LIGHT_DIRECTIONAL > 0 || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        NoL = max(geoNoL, 0.0);
        //if (any(greaterThan(localNormal, EPSILON3)))
        //    NoL = dot(localNormal, lightDir);

        if (!all(lessThan(abs(texNormal), EPSILON3))) {
            NoL = min(NoL, max(texNoL, 0.0));
        }
    #endif

    #if MATERIAL_SSS != SSS_NONE
        NoL = mix(NoL, 0.2 + 0.6*abs(texNoL), sss);
    //#else
    //    NoL = max(NoL, 0.0);
    #endif

    #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
        NoL = mix(1.0, NoL, DynamicLightDirectionalF);
    #endif

    return NoL;
}

float SampleLightDiffuse(const in float NoV, const in float NoL, const in float LoH, const in float roughL) {
    float f90 = 0.5 + roughL * _pow2(LoH);
    float light_scatter = F_schlick(NoL, 1.0, f90);
    float view_scatter = F_schlick(NoV, 1.0, f90);
    return light_scatter * view_scatter * NoL;
}

float SampleLightSpecular(const in float NoVm, const in float NoLm, const in float NoHm, const in float F, const in float roughL) {
    float a = NoHm * roughL;
    float k = roughL / max(1.0 - _pow2(NoHm) + _pow2(a), 0.004);
    float D = min(_pow2(k) * invPI, 65504.0);

    float GGX_V = NoLm * (NoVm * (1.0 - roughL) + roughL);
    float GGX_L = NoVm * (NoLm * (1.0 - roughL) + roughL);
    float G = saturate(0.5 / (GGX_V + GGX_L));

    return D * G * F;
}
