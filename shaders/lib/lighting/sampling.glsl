float GetLightAttenuation(const in vec3 lightVec, const in float lightRange) {
    float lightDist = length(lightVec);
    float lightAtt = 1.0 - saturate(lightDist / lightRange);
    return pow5(lightAtt);
}

float GetLightNoL(const in float geoNoL, const in vec3 texNormal, const in vec3 lightDir, const in float sss) {
    float NoL = 1.0;

    float texNoL = geoNoL;
    if (!all(lessThan(abs(texNormal), EPSILON3)))
        texNoL = dot(texNormal, lightDir);

    //#if LIGHTING_MODE == DYN_LIGHT_TRACED
        NoL = max(geoNoL, 0.0);
        //if (any(greaterThan(localNormal, EPSILON3)))
        //    NoL = dot(localNormal, lightDir);

        if (!all(lessThan(abs(texNormal), EPSILON3))) {
            NoL = max(texNoL, 0.0) * step(0.0, geoNoL);
        }
    //#endif

    #if MATERIAL_SSS != SSS_NONE
        NoL = mix(NoL, 0.25 + abs(texNoL), _pow2(sss));
    //#else
    //    NoL = max(NoL, 0.0);
    #endif

    // #if LIGHTING_MODE != DYN_LIGHT_TRACED
    //     NoL = mix(1.0, NoL, DynamicLightDirectionalF);
    // #endif

    return NoL;
}

float SampleLightDiffuse(const in float NoV, const in float NoL, const in float LoH, const in float roughL) {
    float f90 = 0.5 + roughL * _pow2(LoH);
    float light_scatter = F_schlick(NoL, 1.0, f90);
    float view_scatter = F_schlick(NoV, 1.0, f90);
    return light_scatter * view_scatter * NoL;
}

float GGX_D(const in float NoHm, const in float alpha) {
    float alpha2 = _pow2(alpha);

    float denom = _pow2(NoHm) * (alpha2 - 1.0) + 1.0;
    return alpha2 / (PI * _pow2(denom));
}

float GGX_V(const in float NoVm, const in float NoLm, const in float alpha) {
    float k = 0.5 * alpha;
    float gNoV = rcp(NoVm * (1.0 - k)  + k);
    float gNoL = rcp(NoLm * (1.0 - k)  + k);
    return gNoV*gNoL;
}

vec3 SampleLightSpecular(const in float NoVm, const in float NoLm, const in float NoHm, const in vec3 F, const in float roughL) {
    float alpha = max(roughL, ROUGH_MIN);
    //alpha = _pow2(alpha);

    float D = GGX_D(NoHm, alpha);
    float V = GGX_V(NoVm, NoLm, alpha);
    return NoLm * D * F * V;
}
