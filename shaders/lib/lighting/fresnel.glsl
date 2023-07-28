float F_schlick(const in float cos_theta, const in float f0, const in float f90) {
    float invCosTheta = saturate(1.0 - cos_theta);
    return f0 + (f90 - f0) * pow5(invCosTheta);
}

float F_schlickRough(const in float cos_theta, const in float f0, const in float rough) {
    float invCosTheta = saturate(1.0 - cos_theta);
    return f0 + (max(1.0 - rough, f0) - f0) * pow5(invCosTheta);
}

vec3 F_schlickRough(const in float cos_theta, const in vec3 f0, const in float rough) {
    float invCosTheta = saturate(1.0 - cos_theta);
    return f0 + (max(vec3(1.0 - rough), f0) - f0) * pow5(invCosTheta);
}

#ifdef HCM_LAZANYI
    vec3 F_Lazanyi(const in float cosTheta, const in vec3 f0, const in vec3 f82) {
        float invCosTheta = saturate(1.0 - cos_theta);
        vec3 a = 17.6513846 * (f0 - f82) + 8.16666667 * (1.0 - f0);
        return saturate(f0 + (1.0 - f0) * pow5(invCosTheta) - a * cosTheta * pow6(invCosTheta));
    }

    vec3 F_LazanyiRough(const in float cosTheta, const in vec3 f0, const in vec3 f82, const in float rough) {
        float invCosTheta = saturate(1.0 - cos_theta);
        vec3 a = 17.6513846 * (f0 - f82) + 8.16666667 * (1.0 - f0);
        return saturate(f0 + (max(vec3(1.0 - rough), f0) - f0) * pow5(invCosTheta) - a * cosTheta * pow6(invCosTheta));
    }
#endif
