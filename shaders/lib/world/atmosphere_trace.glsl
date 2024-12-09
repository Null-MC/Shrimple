const float phaseAir = phaseIso;

const float WorldAtmosphereMax = 480.0;
const float WorldAtmosphereCurve = 12.0;
const float WorldAtmosphereCurveRain = 4.0;


float GetSkyAltitudeFactor(const in float altitude) {
    return saturate((altitude - WORLD_SEA_LEVEL) / (WorldAtmosphereMax - WORLD_SEA_LEVEL));
}

#ifdef VOLUMETRIC_NOISE_ENABLED
    float GetSkyDensityNoise(const in vec3 worldPos, const in float altitude) {
        const float MinFogDensity = 0.0;

        vec3 texPos = worldPos.xzy * vec3(1.0, 1.0, 4.0);

        float t = frameTimeCounter / 3600.0;
        vec3 o = 600.0 * vec3(t, t, 0.0);

        float sampleDist = length(worldPos - cameraPosition);

        float fogF = 1.0 - textureLod(TEX_CLOUDS, (texPos - o) * 0.003, 0).r;
        fogF = _pow2(fogF);

        if (sampleDist < 120.0) {
            float noiseNear = textureLod(TEX_CLOUDS, (texPos - o) * 0.05, 0).r;
            noiseNear = noiseNear*2.0 - 1.0;
            noiseNear = _pow2(noiseNear);

            float distF = smoothstep(120.0, 0.0, sampleDist);

            fogF += 0.2 * noiseNear * distF;
        }

        fogF = 8.0 * _pow2(fogF);

        fogF *= exp(-0.002 * sampleDist);

        return 0.2 + fogF;
    }
#endif

float GetSkyDensity() {
    float skyLightF = eyeBrightnessSmooth.y / 240.0;
    float densityFinal = GetAirDensity(skyLightF);

    return max(densityFinal, 0.0);
}

float GetSkyAltitudeDensity(const in float altitude) {
    float heightF = 1.0 - GetSkyAltitudeFactor(altitude);

    float curve = mix(WorldAtmosphereCurve, WorldAtmosphereCurveRain, weatherStrength);
    float density = pow(heightF, curve);

    // #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
    //     float z = altitude - cloudHeight;
    //     if (z > 0.0 && z < 20.0) density = 12.0;
    // #endif

    return density;
}

// altitude: world-pos.y
float GetFinalFogDensity(const in vec3 worldPos, const in float altitude, const in float caveFogF) {
    float densityFinal = GetSkyDensity();

    #ifdef SKY_CAVE_FOG_ENABLED
        densityFinal = mix(densityFinal, FogDensity_Cave, caveFogF);
    #endif

    #ifdef VOLUMETRIC_NOISE_ENABLED
        densityFinal *= GetSkyDensityNoise(worldPos, altitude);
    #endif

    densityFinal *= GetSkyAltitudeDensity(altitude);

    return densityFinal;
}

float GetSkyPhase(const in float VoL) {
    return HG(VoL, 0.24);
    // return DHG(VoL, -0.03, 0.86, 0.16);
}
