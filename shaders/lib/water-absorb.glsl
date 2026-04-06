const vec3 waterAbsorbColor = vec3(0.090, 0.620, 0.988);
const vec3 waterAbsorbColorL = pow(1.0 - waterAbsorbColor, vec3(2.2));

vec3 GetWaterAbsorption(const in float viewDist, const in vec3 absorbColorL) {
//    #ifdef WATER_COLOR_OVERRIDE
        return exp(-min(viewDist, 4.0) * waterAbsorbColorL);
//    #else
//        return exp(-min(viewDist, 4.0) * absorbColorL);
//    #endif
}

vec3 GetWaterAbsorption(const in float viewDist) {
    return GetWaterAbsorption(viewDist, waterAbsorbColorL);
}
