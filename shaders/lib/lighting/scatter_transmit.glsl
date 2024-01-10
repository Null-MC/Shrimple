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

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 lightF, const in float density, const in float scatterF, const in float extinctF) {
    return ApplyScatteringTransmission(traceDist, lightF, density, vec3(scatterF), extinctF);
}

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 inScattering, const in float density, const in vec3 scatterF, const in float extinctF, const in int stepCount) {
    float stepDist = traceDist / stepCount;

    vec3 scatterFinal = vec3(0.0);
    float transmitFinal = 1.0;

    for (int i = 0; i < stepCount; i++) {
        vec4 stepScatterTransmit = ApplyScatteringTransmission(stepDist, inScattering, density, scatterF, extinctF);

        scatterFinal += stepScatterTransmit.rgb * transmitFinal;
        transmitFinal *= stepScatterTransmit.a;
    }

    return vec4(scatterFinal, transmitFinal);
}

void ApplyScatteringTransmission(inout vec3 color, const in float traceDist, const in vec3 lightF, const in float density, const in vec3 scatterF, const in vec3 extinctF) {
    //vec3 extinctCoef = scatterF + extinctF;
    vec3 transmittance = exp(-traceDist * extinctF * density);

    vec3 inScattering = lightF;// * traceDist;
    vec3 outScattering = scatterF * density;// * traceDist;
    vec3 lightIntegral = inScattering * outScattering * traceDist;// * transmittance;

    // vec3 scatteringIntegral = inScattering - inScattering * transmittance;
    // if (any(greaterThan(extinctF, vec3(0.0)))) scatteringIntegral /= extinctF;

    color = (color + lightIntegral) * transmittance;
}
