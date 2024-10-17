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
    float t = 0.5;//(1.0 - contrast) / 2.0;
    
    mat4 offset_up = BuildTranslationMatrix(vec3(t));
    mat4 offset_down = BuildTranslationMatrix(vec3(-t));
    mat4 scaling = BuildScalingMatrix(vec3(contrast));

    return offset_up * (scaling * offset_down);
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

mat4 GetPostMatrix() {
    mat4 matFinal = mat4(1.0);

    #if POST_BRIGHTNESS != 100
        mat4 matBrightness = GetBrightnessMatrix(Post_BrightnessF);
        matFinal = matBrightness * matFinal;
    #endif

    #if POST_CONTRAST != 100
        mat4 matContrast = GetContrastMatrix(Post_ContrastF);
        matFinal = matContrast * matFinal;
    #endif

    #if POST_SATURATION != 100
        mat4 matSaturation = GetSaturationMatrix(Post_SaturationF);
        matFinal = matSaturation * matFinal;
    #endif

    return matFinal;
}

void ApplyPostGrading(inout vec3 color) {
    #if POST_BRIGHTNESS != 0 || POST_CONTRAST != 100 || POST_SATURATION != 100
        #ifndef IRIS_FEATURE_SSBO
            mat4 matColorPost = GetPostMatrix();
        #endif

        color = (matColorPost * vec4(color, 1.0)).rgb;

        color = max(color, vec3(0.0));
    #endif

    vec3 colorOut = color;

    #if POST_TEMP != 65
        const float postTemp = POST_TEMP * 100.0 + 50.0;
        colorOut *= colorTemperatureToRGB(postTemp);
    #endif

    float lum = luminance(color);
    float lumOut = luminance(colorOut);
    color = colorOut * (lum / max(lumOut, EPSILON));
}
