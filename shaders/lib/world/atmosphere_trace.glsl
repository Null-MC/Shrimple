const float phaseAir = phaseIso;

// const float WorldAtmosphereMin =  68.0;
const float WorldAtmosphereMax = 360.0;
const float WorldAtmosphereCurve = 12.0;
const float WorldAtmosphereCurveRain = 4.0;


float GetSkyAltitudeFactor(const in float altitude) {
    return saturate((altitude - WORLD_SEA_LEVEL) / (WorldAtmosphereMax - WORLD_SEA_LEVEL));
}

#ifdef VOLUMETRIC_NOISE_ENABLED
    float GetSkyDensityNoise(const in vec3 worldPos, const in float altitude) {
        const float MinFogDensity = 0.02;

        vec3 texPos = worldPos.xzy * vec3(1.0, 1.0, 4.0);

        float t = frameTimeCounter / 3600.0;
        vec3 o = 600.0 * vec3(t, t, 0.0);

        float n1 = textureLod(TEX_CLOUDS, (texPos + o*2.0) * 0.125, 0).r;
        float n2 = textureLod(TEX_CLOUDS, (texPos - o) * 0.030, 0).r;
        float noiseNear = 2.0 * sqrt((1.0 - n1) * n2);
        // float noiseNear = 2.0 * n1 * n2;

        float n3 = textureLod(TEX_CLOUDS, (texPos + o*2.0) * 0.0040, 0).r;
        float n4 = textureLod(TEX_CLOUDS, (texPos - o) * 0.0024, 0).r;
        float noiseFar = sqrt((1.0 - n4) * n3);

        float sampleDist = length(worldPos - cameraPosition);
        float distF = smoothstep(0.0, 80.0, sampleDist);
        float noise = noiseFar * mix(noiseNear + 0.2, 1.0, distF);

        float heightF = GetSkyAltitudeFactor(altitude);
        float thresholdMin = 0.5 * heightF;

        float fogF = smoothstep(thresholdMin, 1.0, noise);
        fogF = pow(fogF, 3.0) + MinFogDensity;// * 0.5 + 0.5;

        // float _far = 0.25 * dhFarPlane;
        // fogF *= smoothstep(SkyFar, _far, sampleDist);
        fogF *= exp(-0.001 * sampleDist);

        // TODO: this is an arbitrary multiply to match uniform density fog
        return saturate(fogF * 4.0);
    }
#endif

float GetSkyDensity() {
    // float heightF = 1.0 - smoothstep(WORLD_SEA_LEVEL, WorldAtmosphereMax, worldY);
    // return AirDensityF * (1.0 - smoothstep(WORLD_SEA_LEVEL, WorldAtmosphereMax, worldY));

    float skyLightF = eyeBrightnessSmooth.y / 240.0;
    float densityFinal = GetAirDensity(skyLightF);

    // #ifdef VOLUMETRIC_NOISE_ENABLED
    //     densityFinal *= GetSkyDensityNoise(worldPos);
    // #endif

    return max(densityFinal, 0.0);
}

float GetSkyAltitudeDensity(const in float altitude) {
    float heightF = 1.0 - GetSkyAltitudeFactor(altitude);

    float curve = mix(WorldAtmosphereCurve, WorldAtmosphereCurveRain, weatherStrength);
    float density = pow(heightF, curve);

    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        float z = altitude - cloudHeight;
        if (z > 0.0 && z < 64.0) density = 3.0;
    #endif

    return density;
}

// altitude: world-pos.y
float GetFinalFogDensity(const in vec3 worldPos, const in float altitude, const in float caveFogF) {
    // float heightF = 1.0 - smoothstep(WORLD_SEA_LEVEL, WorldAtmosphereMax, worldY);
    // return AirDensityF * (1.0 - smoothstep(WORLD_SEA_LEVEL, WorldAtmosphereMax, worldY));

    float densityFinal = GetSkyDensity();

    #ifdef SKY_CAVE_FOG_ENABLED
        densityFinal = mix(densityFinal, CaveFogDensityF, caveFogF);
    #endif

    #ifdef VOLUMETRIC_NOISE_ENABLED
        densityFinal *= GetSkyDensityNoise(worldPos, altitude);
    #endif

    densityFinal *= GetSkyAltitudeDensity(altitude);

    return densityFinal;
}

float GetSkyPhase(const in float VoL) {
    return DHG(VoL, -0.09, 0.91, 0.16);
}
