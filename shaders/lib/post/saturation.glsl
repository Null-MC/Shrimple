mat3 GetSaturationMatrix(const in float saturation) {
    const vec3 luminance = vec3(0.3086, 0.6094, 0.0820);
    
    float oneMinusSat = 1.0 - saturation;
    vec3 red = vec3(luminance.x * oneMinusSat) + vec3(saturation, 0.0, 0.0);
    vec3 green = vec3(luminance.y * oneMinusSat) + vec3(0.0, saturation, 0.0);
    vec3 blue = vec3(luminance.z * oneMinusSat) + vec3(0.0, 0.0, saturation);
    
    return mat3(red, green, blue);
}
