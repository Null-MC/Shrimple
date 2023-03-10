vec3 tonemap_Tech(const in vec3 color) {
    const float c = rcp(TONEMAP_CONTRAST);
    vec3 a = color * min(vec3(1.0), 1.0 - exp(-c * color));
    a = mix(a, color, color * color);
    return a / (a + 0.6);
}
