vec2 ApplyScatteringTransmission(const in float traceDist, const in float lightF, const in float scatterF, const in float extinctF) {
    float inScattering = scatterF * lightF;
    float transmittance = exp(-traceDist * extinctF);
    float scatteringIntegral = inScattering - inScattering * transmittance;

    return vec2(scatteringIntegral / extinctF, transmittance);
}

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 lightF, const in vec3 scatterF, const in float extinctF) {
    vec3 inScattering = scatterF * lightF;
    float transmittance = exp(-traceDist * extinctF);
    vec3 scatteringIntegral = inScattering - inScattering * transmittance;

    return vec4(scatteringIntegral / extinctF, transmittance);
}

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 lightF, const in float scatterF, const in float extinctF) {
    return ApplyScatteringTransmission(traceDist, lightF, vec3(scatterF), extinctF);
}

void ApplyScatteringTransmission(inout vec3 color, const in float traceDist, const in vec3 lightF, const in vec3 scatterF, const in vec3 extinctF) {
    vec3 inScattering = scatterF * lightF;
    vec3 transmittance = exp(-traceDist * extinctF);
    vec3 scatteringIntegral = inScattering - inScattering * transmittance;

    color = color * transmittance + scatteringIntegral / extinctF;
}
