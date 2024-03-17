vec2 ApplyScatteringTransmission(const in float traceDist, const in float inScattering, const in float density, const in float scatterF, const in float extinctF) {
    float lightIntegral = inScattering * scatterF * density;
    float transmittance = exp(-traceDist * extinctF * density);

    return vec2(lightIntegral, transmittance);
}

// vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in float extinctF) {
//     vec3 outScattering = scatterF * density;
//     vec3 lightIntegral = inScattering * outScattering;// * traceDist;
//     float transmittance = exp(-traceDist * extinctF * density);

//     return vec4(lightIntegral, transmittance);
// }

void ApplyScatteringTransmission(inout vec3 scatterFinal, inout vec3 transmitFinal, const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in vec3 extinctF) {
    transmitFinal *= exp(-traceDist * extinctF * density);
    scatterFinal += inScattering * scatterF * density * transmitFinal;
}

// vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 inScattering, const in float density, const in float scatterF, const in float extinctF) {
//     return ApplyScatteringTransmission(traceDist, inScattering, density, vec3(scatterF), extinctF);
// }

// vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in float extinctF, const in int stepCount) {
//     float stepDist = traceDist / stepCount;

//     vec3 stepLightIntegral = inScattering * scatterF * density;
//     float stepTransmittance = exp(-stepDist * extinctF * density);

//     vec3 scatterFinal = vec3(0.0);
//     float transmitFinal = 1.0;

//     for (int i = 0; i < stepCount; i++) {
//         transmitFinal *= stepTransmittance;
//         scatterFinal += stepLightIntegral * transmitFinal;
//     }

//     return vec4(scatterFinal, transmitFinal);
// }

void ApplyScatteringTransmission(inout vec3 scatterFinal, inout vec3 transmitFinal, const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in vec3 extinctF, const in int stepCount) {
    float stepDist = traceDist / stepCount;

    vec3 lightIntegral = inScattering * scatterF * density * stepDist;
    vec3 stepTransmittance = exp(-stepDist * extinctF * density);

    for (int i = 0; i < stepCount; i++) {
        transmitFinal *= stepTransmittance;
        scatterFinal = lightIntegral * transmitFinal + scatterFinal;
    }
}

void ApplyScatteringTransmission(inout vec3 colorFinal, const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in vec3 extinctF, const in int stepCount) {
    vec3 scatterFinal = vec3(0.0);
    vec3 transmitFinal = vec3(1.0);
    ApplyScatteringTransmission(scatterFinal, transmitFinal, traceDist, inScattering, density, scatterF, extinctF, stepCount);
    colorFinal = colorFinal * transmitFinal + scatterFinal;
}
