vec3 mat_normal_lab(const in vec2 normalData) {
    vec2 normal_xy = fma(normalData.xy, vec2(2.0), vec2(-254.0/255.0));
    float normal_z = sqrt(max(1.0 - dot(normal_xy, normal_xy), 0.0));
    return vec3(normal_xy, normal_z);
}

vec3 mat_normal_old(const in vec3 normalData) {
    return normalize(fma(normalData, vec3(2.0), vec3(-1.0)));
}

vec3 mat_normal(const in vec3 normalData) {
    #if MATERIAL_FORMAT == MAT_LABPBR
        return mat_normal_lab(normalData.xy);
    #elif MATERIAL_FORMAT == MAT_OLDPBR
        return mat_normal_old(normalData);
    #else
        return vec3(0.0);
    #endif
}

float mat_occlusion_lab(const in float normal_a) {
    return normal_a;
}

float mat_occlusion_old() {
    return 1.0;
}

float mat_occlusion(const in float normal_a) {
    #if MATERIAL_FORMAT == MAT_LABPBR
        return mat_occlusion_lab(normal_a);
    #else
        return 1.0;
    #endif
}

float mat_roughness_lab(const in float specular_r) {
    return 1.0 - specular_r;
}

float mat_roughness_old(const in float specular_r) {
    return 1.0 - specular_r;
}

float mat_roughness(const in float specular_r) {
    #if MATERIAL_FORMAT == MAT_LABPBR
        return mat_roughness_lab(specular_r);
    #elif MATERIAL_FORMAT == MAT_OLDPBR
        return mat_roughness_old(specular_r);
    #else
        return 1.0;
    #endif
}

float mat_f0_lab(const in float specular_g) {
    // TODO: add HCM
    return clamp(specular_g, 0.0, 0.9);
}

float mat_f0_old(const in float specular_g) {
    return mix(0.04, 1.0, specular_g);
}

float mat_f0(const in float specular_g) {
    #if MATERIAL_FORMAT == MAT_LABPBR
        return mat_f0_lab(specular_g);
    #elif MATERIAL_FORMAT == MAT_OLDPBR
        return mat_f0_old(specular_g);
    #else
        return 0.04;
    #endif
}

float mat_metalness_lab(const in float specular_g) {
    return step((229.5/255.0), specular_g);
}

float mat_metalness_old(const in float specular_g) {
    return specular_g;
}

float mat_metalness(const in float specular_g) {
    #if MATERIAL_FORMAT == MAT_LABPBR
        return mat_metalness_lab(specular_g);
    #elif MATERIAL_FORMAT == MAT_OLDPBR
        return mat_metalness_old(specular_g);
    #else
        return 0.0;
    #endif
}

float mat_emission_lab(const in float specular_a) {
    return fract(specular_a);
}

float mat_emission_old(const in float specular_b) {
    return specular_b;
}

float mat_emission(const in vec4 specularData) {
    #if MATERIAL_FORMAT == MAT_LABPBR
        return mat_emission_lab(specularData.a);
    #elif MATERIAL_FORMAT == MAT_OLDPBR
        return mat_emission_old(specularData.b);
    #else
        return 0.0;
    #endif
}

float mat_sss_lab(const in float specular_b) {
    return max(specular_b - (64.0/255.0), 0.0) * (255.0/191.0);
}

float mat_sss_old() {
    return 0.0;
}

float mat_sss(const in float specular_b) {
    #if MATERIAL_FORMAT == MAT_LABPBR
        return mat_sss_lab(specular_b);
    #elif MATERIAL_FORMAT == MAT_OLDPBR
        return mat_sss_old();
    #else
        return 0.0;
    #endif
}


void TransformEmission(inout float emission) {
    const float MAT_EmissionScale = MATERIAL_EMISSION_SCALE;

    #if MATERIAL_EMISSION_POWER != 100
        const float MAT_EmissionPower = MATERIAL_EMISSION_POWER * 0.01;

        emission = pow(emission, MAT_EmissionPower) * MAT_EmissionScale;
    #else
        emission *= MAT_EmissionScale;
    #endif
}
