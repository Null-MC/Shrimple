vec2 ApplyScatteringTransmission(const in float traceDist, const in float inScattering, const in float density, const in float scatterF, const in float extinctF) {
    float outScattering = scatterF * density;
    float lightIntegral = inScattering * outScattering * traceDist;
    float transmittance = exp(-traceDist * extinctF * density);

    return vec2(lightIntegral, transmittance);
}

// vec2 ApplyScatteringTransmission(const in float traceDist, const in float inScattering, const in float density, const in float scatterF, const in float extinctF, const in int stepCount) {
//     float scatterFinal = 0.0;
//     float transmitFinal = 1.0;

//     for (int i = 0; i < stepCount; i++) {
//         vec2 stepScatterTransmit = ApplyScatteringTransmission(traceDist, inScattering, density, scatterF, extinctF);

//         scatterFinal += stepScatterTransmit.r * transmitFinal;
//         transmitFinal *= stepScatterTransmit.g;
//     }

//     return vec2(scatterFinal, transmitFinal);
// }

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in float extinctF) {
    vec3 outScattering = scatterF * density;
    vec3 lightIntegral = inScattering * outScattering * traceDist;
    float transmittance = exp(-traceDist * extinctF * density);

    return vec4(lightIntegral, transmittance);
}

// void ApplyScatteringTransmission(inout vec3 scatterFinal, inout vec3 transmitFinal, const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in vec3 extinctF) {
//     vec3 outScattering = scatterF * density;
//     vec3 lightIntegral = inScattering * outScattering * traceDist;
//     vec3 transmittance = exp(-traceDist * extinctF * density);

//     scatterFinal += lightIntegral * transmitFinal;
//     transmitFinal *= transmittance;
// }

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 inScattering, const in float density, const in float scatterF, const in float extinctF) {
    return ApplyScatteringTransmission(traceDist, inScattering, density, vec3(scatterF), extinctF);
}

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in float extinctF, const in int stepCount) {
    float stepDist = traceDist / stepCount;

    vec3 outScattering = scatterF * density;
    vec3 lightIntegral = inScattering * outScattering * stepDist;
    float transmittance = exp(-stepDist * extinctF * density);

    vec3 scatterFinal = vec3(0.0);
    float transmitFinal = 1.0;

    for (int i = 0; i < stepCount; i++) {
        scatterFinal += lightIntegral * transmitFinal;
        transmitFinal *= transmittance;
    }

    return vec4(scatterFinal, transmitFinal);
}

void ApplyScatteringTransmission(inout vec3 scatterFinal, inout vec3 transmitFinal, const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in vec3 extinctF, const in int stepCount) {
    float stepDist = traceDist / stepCount;

    vec3 outScattering = scatterF * density;
    vec3 lightIntegral = inScattering * outScattering * stepDist;
    vec3 transmittance = exp(-stepDist * extinctF * density);

    for (int i = 0; i < stepCount; i++) {
        scatterFinal += lightIntegral * transmitFinal;
        transmitFinal *= transmittance;
    }
}
