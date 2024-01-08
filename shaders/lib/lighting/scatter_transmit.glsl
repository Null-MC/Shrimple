vec2 ApplyScatteringTransmission(const in float traceDist, const in float lightF, const in float density, const in float scatterF, const in float extinctF) {
    //float extinctCoef = scatterF + extinctF;
    float transmittance = exp(-traceDist * extinctF * density);

    float inScattering = lightF;// * traceDist;
    float outScattering = scatterF * density;// * traceDist;
    float lightIntegral = inScattering * outScattering * traceDist * transmittance;

    // float scatteringIntegral = inScattering - inScattering * transmittance;
    // if (extinctF > 0.0) scatteringIntegral /= extinctF;

    return vec2(lightIntegral, transmittance);
}

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 lightF, const in float density, const in vec3 scatterF, const in float extinctF) {
    //vec3 extinctCoef = scatterF + extinctF;
    float transmittance = exp(-traceDist * extinctF * density);

    vec3 inScattering = lightF;// * traceDist;
    vec3 outScattering = scatterF * density;// * traceDist;
    vec3 lightIntegral = inScattering * outScattering * traceDist * transmittance;

    // vec3 scatteringIntegral = inScattering - inScattering * transmittance;
    // if (extinctF > 0.0) scatteringIntegral /= extinctF;

    return vec4(lightIntegral, transmittance);
}

vec4 ApplyScatteringTransmission(const in float traceDist, const in vec3 lightF, const in float density, const in float scatterF, const in float extinctF) {
    return ApplyScatteringTransmission(traceDist, lightF, density, vec3(scatterF), extinctF);
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
