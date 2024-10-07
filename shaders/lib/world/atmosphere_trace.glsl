const float phaseAir = phaseIso;

// const float WorldAtmosphereMin =  68.0;
const float WorldAtmosphereMax = 360.0;
const float WorldAtmosphereCurve = 12.0;
const float WorldAtmosphereCurveRain = 4.0;


#ifdef VOLUMETRIC_NOISE_ENABLED
    float GetSkyDensityNoise(const in vec3 worldPos) {
        const float MinFogDensity = 0.06;

        vec3 texPos = worldPos.xzy * vec3(1.0, 1.0, 4.0);

        float t = frameTimeCounter / 3600.0;
        vec3 o = 600.0 * vec3(t, t, 0.0);

        float n1 = textureLod(TEX_CLOUDS, (texPos + o*2.0) * 0.125, 0).r;
        float n2 = textureLod(TEX_CLOUDS, (texPos - o) * 0.030, 0).r;
        float noiseNear = 2.0 * sqrt((1.0 - n1) * n2);
        // float noiseNear = 2.0 * n1 * n2;

        float n3 = textureLod(TEX_CLOUDS, (texPos + o*2.0) * 0.0040, 0).r;
        float n4 = textureLod(TEX_CLOUDS, (texPos - o) * 0.0024, 0).r;
        float noiseFar = sqrt((1.0 - n3) * n4);

        float distF = smoothstep(0.0, 80.0, length(worldPos - cameraPosition));
        // float noise = mix(noiseNear, noiseFar, distF);
        // float noise = noiseFar * mix(noiseNear, 1.0, distF);
        // float noise = noiseNear*(1.0 - distF) + noiseFar * (1.0 - 0.5*distF);
        float noise = noiseFar * mix(noiseNear + 0.2, 1.0, distF);// * (1.0 - 0.5*distF);

        float fogF = smootherstep(noise);
        fogF = pow(fogF, 3.0 - weatherStrength) + MinFogDensity;// * 0.5 + 0.5;

        // TODO: this is an arbitrary multiply to match uniform density fog
        return saturate(fogF * 2.0);
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
    float heightF = 1.0 - saturate((altitude - WORLD_SEA_LEVEL) / (WorldAtmosphereMax - WORLD_SEA_LEVEL));

    float curve = mix(WorldAtmosphereCurve, WorldAtmosphereCurveRain, weatherStrength);
    return pow(heightF, curve);
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
        densityFinal *= GetSkyDensityNoise(worldPos);
    #endif

    densityFinal *= GetSkyAltitudeDensity(altitude);

    return densityFinal;
}

float GetSkyPhase(const in float VoL) {
    return DHG(VoL, -0.09, 0.91, 0.16);
}
