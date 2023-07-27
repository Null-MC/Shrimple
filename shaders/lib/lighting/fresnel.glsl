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
