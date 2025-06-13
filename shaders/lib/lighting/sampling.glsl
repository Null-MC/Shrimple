// xy: diffuse, specular
vec2 GetLightAttenuation(const in vec3 lightVec, const in float lightRange) {
    float lightDist = length(lightVec);
    float r = saturate(lightDist/lightRange);

    float f1 = saturate(rcp(r + 1.0));
    float f2 = 1.0 - r;

    return vec2(min(f1, _pow2(f2)));
//    float lightAtt = 1.0 - saturate(lightDist / lightRange);
//    return vec2(pow5(lightAtt), _pow2(lightAtt));
}

// TODO: remove SSS
float GetLightNoL(const in float geoNoL, const in vec3 texNormal, const in vec3 lightDir, const in float sss) {
    float NoL = 1.0;

    float texNoL = geoNoL;
    if (!all(lessThan(abs(texNormal), EPSILON3)))
        texNoL = dot(texNormal, lightDir);

    NoL = max(geoNoL, 0.0);

    if (!all(lessThan(abs(texNormal), EPSILON3))) {
        NoL = max(texNoL, 0.0) * step(0.0, geoNoL);
    }

    return saturate(NoL);
}

float SampleLightDiffuse(const in float NoV, const in float NoL, const in float LoH, const in float roughL) {
    float f90 = 0.5 + 2.0*roughL * _pow2(LoH);
    float light_scatter = F_schlick(NoL, 1.0, f90);
    float view_scatter = F_schlick(NoV, 1.0, f90);
    // return NoL * light_scatter * view_scatter;
    return light_scatter * view_scatter;
}

float G1V(const in float NoV, const in float k) {
    return rcp(NoV * (1.0 - k) + k);
}

vec3 SampleLightSpecular(const in float NoL, const in float NoH, const in float LoH, const in vec3 F, const in float roughL) {
    // if (NoL <= 0.0) return vec3(0.0);

    float alpha = max(roughL, ROUGH_MIN);

    // D
    float alpha2 = _pow2(alpha);
    float denom = _pow2(NoH) * (alpha2 - 1.0) + 1.0;
    float D = alpha2 / (PI * _pow2(denom));

    // V
    float k = alpha / 2.0;
    float k2 = _pow2(k);
    float V = rcp(_pow2(LoH) * (1.0 - k2) + k2);

    return NoL * clamp((D * V), 0.0, 1000.0) * F;
}
