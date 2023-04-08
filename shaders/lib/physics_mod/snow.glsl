float GetSnowDensity(const in vec3 worldPos) {
    // randomNormal = hashU33(uvec3((worldPos - 0.5) * 0.5 * 16.0));
    // randomNormal.z *= sign(randomNormal.z);
    // weight = PHYSICS_SNOW_NOISE * saturate(1.0 - viewDist / 120.0);
    // finalNormal = mix(vec3(0.0, 0.0, 1.0), randomNormal, weight);

    vec3 pos = worldPos * 64.0;
    vec3 posMin = floor(pos);
    vec3 posMax = ceil(pos);
    vec3 f = fract(pos);

    float density_x1y1z1 = hash13(posMin);
    float density_x2y1z1 = hash13(vec3(posMax.x, posMin.y, posMin.z));
    float density_x1y2z1 = hash13(vec3(posMin.x, posMax.y, posMin.z));
    float density_x2y2z1 = hash13(vec3(posMax.x, posMax.y, posMin.z));
    float density_x1y1z2 = hash13(vec3(posMin.x, posMin.y, posMax.z));
    float density_x2y1z2 = hash13(vec3(posMax.x, posMin.y, posMax.z));
    float density_x1y2z2 = hash13(vec3(posMin.x, posMax.y, posMax.z));
    float density_x2y2z2 = hash13(posMax);

    float density_y1z1 = mix(density_x1y1z1, density_x2y1z1, f.x);
    float density_y2z1 = mix(density_x1y2z1, density_x2y2z1, f.x);
    float density_z1 = mix(density_y1z1, density_y2z1, f.y);
    float density_y1z2 = mix(density_x1y1z2, density_x2y1z2, f.x);
    float density_y2z2 = mix(density_x1y2z2, density_x2y2z2, f.x);
    float density_z2 = mix(density_y1z2, density_y2z2, f.y);
    return mix(density_z1, density_z2, f.z);
}

vec3 GetSnowColor(const in vec3 worldPos) {
    const vec3 snowDark = vec3(0.758, 0.842, 0.869);
    const vec3 snowLight = vec3(0.837, 0.904, 0.901);

    float density = GetSnowDensity(worldPos);
    return mix(snowDark, snowLight, density);
}
