vec3 GetWaterAbsorption(const in float viewDist, const in vec3 waterAbsorbColorL) {
    return exp(-0.5 * min(viewDist, 8.0) * waterAbsorbColorL);
}

vec3 GetWaterAbsorption(const in float viewDist) {
    const vec3 waterAbsorbColor = vec3(0.090, 0.620, 0.988);
    const vec3 waterAbsorbColorL = pow(1.0 - waterAbsorbColor, vec3(2.2));
    return GetWaterAbsorption(viewDist, waterAbsorbColorL);
}
