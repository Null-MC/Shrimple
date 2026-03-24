vec3 GetAreaLightDir(const in vec3 viewNormal, const in vec3 viewDir, const in vec3 lightDir, const in float lightDist, const in float lightSize) {
    vec3 r = reflect(viewDir, viewNormal);
    vec3 L = lightDir * lightDist;
    vec3 centerToRay = dot(L, r) * r - L;
    vec3 closestPoint = centerToRay * saturate(lightSize / length(centerToRay)) + L;
    return normalize(closestPoint);
}

float D_GGX(const in float NoH, const in float alpha) {
    float a2 = _pow2(alpha);
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / max(PI * f * f, 1.e-7);
}

float V_Approx(const in float NoL, const in float NoV, const in float alpha) {
    float k = pow2(alpha + 1.0) / 8.0;
    float k_inv = 1.0 - k;

    float G_V = NoV / fma(NoV, k_inv, k);
    float G_L = NoL / fma(NoL, k_inv, k);
    return G_V * G_L;
}

vec3 SampleLightSpecular(vec3 albedo, vec3 normal, vec3 lightDir, vec3 viewDir, const in float NoLm, float roughL, float specularG) {
    vec3 H = normalize(lightDir + viewDir);
    float NoH = max(dot(normal, H), 0.0);
    float LoH = max(dot(lightDir, H), 0.0);
    float NoV = max(dot(normal, viewDir), 0.0);

    #ifdef MATERIAL_PBR_ENABLED
        LazanyiF L = mat_f0_lazanyi(albedo, specularG);
        vec3 F = F_lazanyi(LoH, L.f0, L.f82);

//        float smoothL = 1.0 - roughL;
//        float metalness = mat_metalness(specularData.g);
//        att *= 1.0 - metalness * smoothL;
    #else
        float f0 = mat_f0_lab(specularG);
        vec3 F = vec3(F_schlick(LoH, f0, 1.0));
    #endif

    float alpha = max(roughL, 0.006);
    return NoLm * D_GGX(NoH, alpha) * V_Approx(NoLm, NoV, alpha) * F; // * (1.0 - roughness)
}
