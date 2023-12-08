mat4 GetBrightnessMatrix(const in float brightness) {
    // return mat4(
    //     1.0, 0.0, 0.0, 0.0,
    //     0.0, 1.0, 0.0, 0.0,
    //     0.0, 0.0, 1.0, 0.0,
    //     vec3(brightness), 1.0);
    return mat4(
        vec4(brightness, 0.0, 0.0, 0.0),
        vec4(0.0, brightness, 0.0, 0.0),
        vec4(0.0, 0.0, brightness, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0));
}

mat4 GetContrastMatrix(const in float contrast) {
    float t = (1.0 - contrast) / 2.0;
    
    return mat4(
        contrast, 0.0, 0.0, 0.0,
        0.0, contrast, 0.0, 0.0,
        0.0, 0.0, contrast, 0.0,
          t,      t,     t, 1.0);
}

mat4 GetSaturationMatrix(const in float saturation) {
    const vec3 luminance = vec3(0.3086, 0.6094, 0.0820);
    
    float oneMinusSat = 1.0 - saturation;
    vec3 red = vec3(luminance.x * oneMinusSat) + vec3(saturation, 0.0, 0.0);
    vec3 green = vec3(luminance.y * oneMinusSat) + vec3(0.0, saturation, 0.0);
    vec3 blue = vec3(luminance.z * oneMinusSat) + vec3(0.0, 0.0, saturation);
    
    return mat4(
        vec4(red, 0.0),
        vec4(green, 0.0),
        vec4(blue, 0.0),
        vec4(vec3(0.0), 1.0));
}

void ApplyPostGrading(inout vec3 color) {
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
}
