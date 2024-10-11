vec3 F0ToIor(const in vec3 f0, const in vec3 medium) {
    vec3 sqrt_f0 = sqrt(max(f0, EPSILON));
    return (medium + sqrt_f0) / max(medium - sqrt_f0, EPSILON);
}

float F0ToIor(const in float f0, const in float medium) {
    float sqrt_f0 = sqrt(max(f0, EPSILON));
    return (medium + sqrt_f0) / max(medium - sqrt_f0, EPSILON);
}

vec3 IorToF0(const in vec3 ior, const in vec3 medium) {
    vec3 t = (ior - medium) / (ior + medium);
    return _pow2(t);
}

float IorToF0(const in float ior, const in float medium) {
    float t = (ior - medium) / (ior + medium);
    return _pow2(t);
}

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
#else
    vec3 ComplexFresnel(const in vec3 n, const in vec3 k, const in float c) {
        vec3 nn = n*n;
        vec3 kk = k*k;
        float cc = c*c;

        vec3 nc2 = 2.0 * n*c;
        vec3 nn_kk = nn + kk;

        vec3 rs_num = nn_kk - nc2 + cc;
        vec3 rs_den = nn_kk + nc2 + cc;
        vec3 rs = rs_num / rs_den;
        
        vec3 rp_num = nn_kk*cc - nc2 + 1.0;
        vec3 rp_den = nn_kk*cc + nc2 + 1.0;
        vec3 rp = rp_num / rp_den;
        
        return saturate(0.5 * (rs + rp));
    }
#endif
