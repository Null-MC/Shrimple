const float phaseAir = phaseIso;

const float WorldAtmosphereMin =  82.0;
const float WorldAtmosphereMax = 400.0;


float GetSkyDensity(const in vec3 worldPos) {
    // float heightF = 1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY);
    // return AirDensityF * (1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY));

    float skyLightF = eyeBrightnessSmooth.y / 240.0;
    float densityFinal = GetAirDensity(skyLightF);

    #ifdef VOLUMETRIC_NOISE_ENABLED
        const float MinFogDensity = 0.06;

        vec3 texPosNear = worldPos * 0.12;
        float noiseNear = 1.0 - textureLod(TEX_CLOUDS, texPosNear.xzy, 0).r;

        vec3 texPosFar = worldPos * 0.004;
        float noiseFar = textureLod(TEX_CLOUDS, texPosFar.xzy, 0).r;

        float distF = smoothstep(0.0, 80.0, length(worldPos - cameraPosition));
        // float noise = mix(noiseNear, noiseFar, distF);
        // float noise = noiseFar * mix(noiseNear, 1.0, distF);
        // float noise = noiseNear*(1.0 - distF) + noiseFar * (1.0 - 0.5*distF);
        float noise = noiseFar * mix(noiseNear + 0.5, 1.0, distF);// * (1.0 - 0.5*distF);

        // densityFinal *= _pow3(noise) * 0.8 + 0.2;// * 0.5 + 0.5;
        float fogF = _smoothstep(noise);
        fogF = pow(fogF, 3.0 - weatherStrength) + MinFogDensity;// * 0.5 + 0.5;

        // TODO: this is an arbitrary multiply to match uniform density fog
        densityFinal *= fogF * 4.0;
    #endif

    return densityFinal;
}

float GetSkyAltitudeDensity(const in float altitude) {
    float heightF = 1.0 - saturate((altitude - WorldAtmosphereMin) / (WorldAtmosphereMax - WorldAtmosphereMin));
    return pow(heightF, 8);
}

// altitude: world-pos.y
float GetFinalFogDensity(const in vec3 worldPos, const in float altitude, const in float caveFogF) {
    // float heightF = 1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY);
    // return AirDensityF * (1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY));

    float densityFinal = GetSkyDensity(worldPos);

    #ifdef SKY_CAVE_FOG_ENABLED
        densityFinal = mix(densityFinal, CaveFogDensityF, caveFogF);
    #endif

    densityFinal *= GetSkyAltitudeDensity(altitude);

    return densityFinal;
}

float GetSkyPhase(const in float VoL) {
    return DHG(VoL, -0.12, 0.84, 0.26);
}
