// AgX
// https://github.com/sobotka/AgX
// https://www.shadertoy.com/view/cd3XWr

// Mean error^2: 3.6705141e-06
vec3 agxDefaultContrastApprox(vec3 x) {
    vec3 x2 = x * x;
    vec3 x4 = x2 * x2;
  
    return + 15.5     * x4 * x2
           - 40.14    * x4 * x
           + 31.96    * x4
           - 6.868    * x2 * x
           + 0.4298   * x2
           + 0.1191   * x
           - 0.00232;
}

vec3 agx(vec3 val) {
    const mat3 agx_mat = mat3(
        0.842479062253094, 0.0423282422610123, 0.0423756549057051,
        0.0784335999999992,  0.878468636469772,  0.0784336,
        0.0792237451477643, 0.0791661274605434, 0.879142973793104);
        
    const float min_ev = -12.47393f;
    const float max_ev = 4.026069f;
    
    // Input transform
    val = agx_mat * val;
      
    // Log2 space encoding
    val = clamp(log2(val), min_ev, max_ev);
    val = (val - min_ev) / (max_ev - min_ev);
      
    // Apply sigmoid function approximation
    val = agxDefaultContrastApprox(val);
    
    return val;
}

vec3 agxEotf(vec3 val) {
    const mat3 agx_mat_inv = mat3(
        1.19687900512017, -0.0528968517574562, -0.0529716355144438,
        -0.0980208811401368, 1.15190312990417, -0.0980434501171241,
        -0.0990297440797205, -0.0989611768448433, 1.15107367264116);
        
    // Undo input transform
    val = agx_mat_inv * val;
    
    // I enabled this line to do linear to srgb in line 180 for all tonemappings.
    // sRGB IEC 61966-2-1 2.2 Exponent Reference EOTF Display   
    // val = pow(val, vec3(2.2));
    
    return val;
}

vec3 agxLook(vec3 val) {
    const vec3 lw = vec3(0.2126, 0.7152, 0.0722);
    float luma = dot(val, lw);
    
    // Default look
    vec3 offset = vec3(0.0);
    vec3 slope = vec3(1.0);
    vec3 power = vec3(1.0, 1.0, 1.0);
    float sat = 1.2;
    
    // ASC CDL
    val = pow(val * slope + offset, power);
    return luma + sat * (val - luma);
}

vec3 tonemap_AgX(vec3 color) {
    color = agx(color);
    color = agxLook(color);
    color = agxEotf(color);
    color = pow(color, vec3(2.2));
    return color;
}

//====================

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
    const vec3 a = vec3(1.4);
    const vec3 d = vec3(0.977);
    const vec3 hdrMax = vec3(2.0);
    const vec3 midIn = vec3(0.28);
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
    #if POST_TONEMAP == 5
        color = tonemap_AgX(color);
    #elif POST_TONEMAP == 4
        //color = tonemap_Tech(color, 0.2);
        color = tonemap_Lottes(color);
    #elif POST_TONEMAP == 3
        color = tonemap_FilmicHejl2015(color);
    #elif POST_TONEMAP == 2
        color = tonemap_ACESFit2(color);
    #elif POST_TONEMAP == 1
        color = tonemap_ReinhardExtendedLuminance(color, PostWhitePoint);
    #endif
}
