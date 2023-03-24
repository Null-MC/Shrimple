float GetSnowDensity() {
    randomNormal = hashU33(uvec3((worldPos - 0.5) * 0.5 * 16.0));
    randomNormal.z *= sign(randomNormal.z);
    weight = PHYSICS_SNOW_NOISE * saturate(1.0 - viewDist / 120.0);
    finalNormal = mix(vec3(0.0, 0.0, 1.0), randomNormal, weight);
}
