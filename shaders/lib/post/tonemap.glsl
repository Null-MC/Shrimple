vec3 tonemap_Tech(const in vec3 color, const in float contrast) {
    const float c = rcp(contrast);
    vec3 a = color * min(vec3(1.0), 1.0 - exp(-c * color));
    a = mix(a, color, color * color);
    return a / (a + 0.6);
}

void setLuminance(inout vec3 color, const in float targetLuminance) {
    color *= (targetLuminance / luminance(color));
}

vec3 tonemap_ReinhardExtendedLuminance(in vec3 color, const in float maxWhiteLuma) {
    float luma_old = luminance(color);
    float numerator = luma_old * (1.0 + luma_old / _pow2(maxWhiteLuma));
    float luma_new = numerator / (1.0 + luma_old);
    setLuminance(color, luma_new);
    return color;
}

void ApplyPostProcessing(inout vec3 color) {
    #ifdef TONEMAP_ENABLED
        color = tonemap_Tech(color, 1.0);
        //color = tonemap_ReinhardExtendedLuminance(color, 1.5);
    #endif

    #if POST_BRIGHTNESS != 0 || POST_CONTRAST != 100 || POST_SATURATION != 100
        #ifdef IRIS_FEATURE_SSBO
            color = (matColorPost * vec4(color, 1.0)).rgb;
        #else
            mat4 matContrast = GetContrastMatrix(PostContrastF);
            //mat4 matBrightness = GetBrightnessMatrix(PostBrightnessF);
            mat4 matSaturation = GetSaturationMatrix(PostSaturationF);

            color *= PostBrightnessF;
            color = (matContrast * vec4(color, 1.0)).rgb;
            color = (matSaturation * vec4(color, 1.0)).rgb;
        #endif
    #endif

    color = LinearToRGB(color, GAMMA_OUT);
    //color += Bayer16(gl_FragCoord.xy) / 255.0;
}
