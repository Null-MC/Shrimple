void setLuminance(inout vec3 color, const in float targetLuminance) {
    color *= (targetLuminance / luminance(color));
}

vec3 tonemap_Tech(const in vec3 color, const in float contrast) {
    float c = rcp(contrast);
    vec3 a = color * min(vec3(1.0), 1.0 - exp(-c * color));
    a = mix(a, color, color * color);
    return a / (a + 0.6);
}

vec3 tonemap_ReinhardExtendedLuminance(in vec3 color, const in float maxWhiteLuma) {
    float luma_old = luminance(color);
    float numerator = luma_old * (1.0 + luma_old / _pow2(maxWhiteLuma));
    float luma_new = numerator / (1.0 + luma_old);
    setLuminance(color, luma_new);
    return color;
}

vec3 tonemap_ACESFit2(const in vec3 color) {
    const mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777);

    const mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602);

    vec3 v = m1 * color;
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return clamp(m2 * (a / b), 0.0, 1.0);
}

vec3 tonemap_FilmicHejl2015(const in vec3 color) {
    vec3 va = 1.425 * color + 0.05;
    vec3 vf = ((color * va + 0.004) / ((color * (va + 0.55) + 0.0491))) - 0.0821;
    return vf / 0.918;
}

vec3 tonemap_Lottes(const in vec3 color) {
    const vec3 a = vec3(1.6);
    const vec3 d = vec3(0.977);
    const vec3 hdrMax = vec3(8.0);
    const vec3 midIn = vec3(0.18);
    const vec3 midOut = vec3(0.267);

    const vec3 b =
        (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
        ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
        
    const vec3 c =
        (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
        ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

    return pow(color, a) / (pow(color, a * d) * b + c);
}

void ApplyPostTonemap(inout vec3 color) {
    #if POST_TONEMAP == 4
        //color = tonemap_Tech(color, 0.2);
        color = tonemap_Lottes(0.6 * color);
    #elif POST_TONEMAP == 3
        color = tonemap_FilmicHejl2015(0.7 * color);
    #elif POST_TONEMAP == 2
        color = tonemap_ACESFit2(color + 0.002);
    #elif POST_TONEMAP == 1
        color = tonemap_ReinhardExtendedLuminance(color, PostWhitePoint);
    #endif
}
