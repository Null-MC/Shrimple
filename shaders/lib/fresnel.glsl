float F_schlick(const in float cos_theta, const in float f0, const in float f90) {
    float invCosTheta = saturate(1.0 - cos_theta);
    return f0 + (f90 - f0) * pow5(invCosTheta);
}

vec3 F_schlick(const in float cos_theta, const in vec3 f0, const in float f90) {
    float invCosTheta = saturate(1.0 - cos_theta);
    return f0 + (f90 - f0) * pow5(invCosTheta);
}

vec3 A_lazanyi(const in vec3 f0, const in vec3 f82) {
    const float cosThetaMax = acos(1.0 / 7.0);
    const float max5 = pow5(cosThetaMax);
    const float denom = cosThetaMax * pow6(cosThetaMax);

    return saturate((f0 + (1.0 - f0) * max5 - f82) / denom);
}

vec3 F_lazanyi(const in float cosTheta, const in vec3 f0, const in vec3 f82) {
    float cosTheta_inv = saturate(1.0 - cosTheta);
    return saturate(f0 + (1.0 - f0) * pow5(cosTheta_inv) - A_lazanyi(f0, f82) * cosTheta * pow6(cosTheta_inv));
}
