vec2 ApplyScatteringTransmission(const in float traceDist, const in float inScattering, const in float density, const in float scatterF, const in float extinctF) {
    float lightIntegral = inScattering * scatterF * density * traceDist;
    float transmittance = exp(-traceDist * extinctF * density);

    return vec2(lightIntegral, transmittance);
}

void ApplyScatteringTransmission(inout vec3 scatterFinal, inout vec3 transmitFinal, const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in vec3 extinctF) {
    scatterFinal += inScattering * scatterF * density * traceDist * transmitFinal;
    transmitFinal *= exp(-traceDist * extinctF * density);
}

void ApplyScatteringTransmission(inout vec3 scatterFinal, inout vec3 transmitFinal, const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in vec3 extinctF, const in int stepCount) {
    float stepDist = traceDist / stepCount;

    vec3 lightIntegral = inScattering * scatterF * density * stepDist;
    vec3 stepTransmittance = exp(-stepDist * extinctF * density);

    for (int i = 0; i < stepCount; i++) {
        scatterFinal += lightIntegral * transmitFinal;
        transmitFinal *= stepTransmittance;
    }
}

void ApplyScatteringTransmission(inout vec3 colorFinal, const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in vec3 extinctF, const in int stepCount) {
    vec3 scatterFinal = vec3(0.0);
    vec3 transmitFinal = vec3(1.0);
    ApplyScatteringTransmission(scatterFinal, transmitFinal, traceDist, inScattering, density, scatterF, extinctF, stepCount);
    colorFinal = colorFinal * transmitFinal + scatterFinal;
}
