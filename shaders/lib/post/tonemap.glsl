vec3 tonemap_Tech(const in vec3 color) {
    const float c = rcp(TONEMAP_CONTRAST);
    vec3 a = color * min(vec3(1.0), 1.0 - exp(-c * color));
    a = mix(a, color, color * color);
    return a / (a + 0.6);
}

vec3 tonemap_BurgessModified(const in vec3 color) {
    vec3 max_color = color * min(vec3(1.0), 1.0 - exp(-1.0 / (luminance(color) * 0.1) * color));
    return max_color * (6.2 * max_color + 0.5) / (max_color * (6.2 * max_color + 1.7) + 0.06);
}

vec3 tonemap_ACESFit(const in vec3 x) {
    const float a = 1.9;
    const float b = 0.04;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;

    return clamp(x * (a * x+b) / (x * (c*x + d) + e), 0.0, 1.0);
}

void ApplyPostProcessing(inout vec3 color) {
    #ifdef TONEMAP_ENABLED
        color = tonemap_ACESFit(color);
    #endif

    color = LinearToRGB(color);
    color += Bayer16(gl_FragCoord.xy) / 255.0;
}
