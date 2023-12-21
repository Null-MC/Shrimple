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
    float f90 = 0.5 + 2.0*roughL * _pow2(LoH);
    float light_scatter = F_schlick(NoL, 1.0, f90);
    float view_scatter = F_schlick(NoV, 1.0, f90);
    return invPI * light_scatter * view_scatter * NoL;
}

float GGX_D(const in float NoHm, const in float alpha) {
    float alpha2 = _pow2(alpha);

    float denom = _pow2(NoHm) * (alpha2 - 1.0) + 1.0;
    return (alpha2 * NoHm) / (PI * _pow2(denom));
}

float SmithG(const in float NoV, const in float alpha2) {
    float a = _pow2(alpha2);
    float b = _pow2(NoV);

    return (2.0 * NoV) / (NoV + sqrt(a + b - a * b));
}

float GGX_V(const in float NoLm, const in float NoVm, const in float alpha) {
    //float k = 0.5 * alpha;
    // float gNoL = rcp(NoLm * (1.0 - k)  + k);
    // float gNoV = rcp(NoVm * (1.0 - k)  + k);
    float alpha2 = _pow2(alpha);
    float gNoL = SmithG(NoLm, alpha2);
    float gNoV = SmithG(NoVm, alpha2);
    return gNoL * gNoV;
}

// vec3 sample_ggx_ndf(vec2 Xi, float alpha) {
//     float alpha_sqr = alpha * alpha;
        
//     float phi = 2.0 * PI * Xi.x;
                 
//     float cos_theta = sqrt((1.0 - Xi.y) / (1.0 + (alpha_sqr - 1.0) * Xi.y));
//     float sin_theta = sqrt(1.0 - cos_theta * cos_theta);
    
//     //Microfacet normal
//     vec3 H;
//     {
//         H.x = sin_theta * cos(phi);
//         H.y = sin_theta * sin(phi);
//         H.z = cos_theta;
//     }
//     return H; 
// }

float NDF_GGX(const in float NoHm, const in float alpha) {
    float denominator = (NoHm * alpha - NoHm) * NoHm + 1.0;
    return alpha / max(PI * _pow2(denominator), EPSILON);
}

float ggx_smith_pdf(const in float NoHm, const in float alpha) {
   return NDF_GGX(NoHm, alpha) * NoHm;
}

vec3 SampleLightSpecular(const in float NoVm, const in float NoLm, float NoHm, const in float VoHm, const in vec3 F, const in float roughL) {
    if (NoLm < EPSILON || NoVm < EPSILON) return vec3(0.0);
    //NoHm = min(NoHm, 0.99);

    float alpha = max(roughL, 0.02);
    float D = GGX_D(NoHm, alpha);
    float V = GGX_V(NoLm, NoVm, alpha);

    float denominator = max(4.0 * NoLm * NoVm, EPSILON);
    vec3 brdf = (D * F * V) / denominator;

    float pdf = ggx_smith_pdf(NoHm, alpha) / max(4.0 * VoHm, EPSILON);
    return NoLm * brdf / max(pdf, EPSILON);
}
