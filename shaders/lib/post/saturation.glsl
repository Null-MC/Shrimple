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

const mat3 mt1 = mat3(
    vec3(0.0, -2902.1955373783176, -8257.7997278925690),
    vec3(0.0, 1669.5803561666639, 2575.2827530017594),
    vec3(1.0, 1.3302673723350029, 1.8993753891711275));

const mat3 mt2 = mat3(
            vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
            vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
            vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));

// Valid from 1000 to 40000 K (and additionally 0 for pure full white)
vec3 colorTemperatureToRGB(const in float temperature) {
    mat3 m = temperature <= 6500.0 ? mt1 : mt2;
    vec3 s = m[0] / (clamp(temperature, 1000.0, 40000.0) + m[1]) + m[2];
    float f = smoothstep(1000.0, 0.0, temperature);
    return mix(saturate(s), vec3(1.0), f);
}

void ApplyPostGrading(inout vec3 color) {
    #if POST_BRIGHTNESS != 0 || POST_CONTRAST != 100 || POST_SATURATION != 100
        #ifdef IRIS_FEATURE_SSBO
            color = (matColorPost * vec4(color, 1.0)).rgb;
        #else
            mat4 matContrast = GetContrastMatrix(Post_ContrastF);
            mat4 matSaturation = GetSaturationMatrix(Post_SaturationF);

            color *= Post_BrightnessF;
            color = (matContrast * vec4(color, 1.0)).rgb;
            color = (matSaturation * vec4(color, 1.0)).rgb;
        #endif
    #endif

    const float postTemp = POST_TEMP * 100.0 + 50.0;
    // const float postTempStrength = 1.0;

    // vec3 colorOut = mix(color, color * colorTemperatureToRGB(postTemp), postTempStrength);
    vec3 colorOut = color * colorTemperatureToRGB(postTemp);

    float lum = luminance(color);
    float lumOut = luminance(colorOut);
    color = colorOut * (lum / max(lumOut, EPSILON));
}
