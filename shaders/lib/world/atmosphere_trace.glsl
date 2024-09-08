const float phaseAir = phaseIso;

const float WorldAtmosphereMin =  82.0;
const float WorldAtmosphereMax = 400.0;


#ifdef WORLD_SKY_ENABLED
    #if SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
        // float AirDensityF = mix(SkyDensityF, max(SkyDensityF, 0.16), weatherStrength);
        float AirDensityF = mix(SkyDensityF, min(SkyDensityF * 6.0, 1.0), weatherStrength);
    #else
        const float AirDensityF = 0.0;
    #endif

    const float AirDensityRainF = 0.08;
    const vec3 AirScatterColor_rain = _RGBToLinear(vec3(0.1));
    const vec3 AirExtinctColor_rain = _RGBToLinear(1.0 - vec3(0.698, 0.702, 0.722));

    const float AirAmbientF = 0.02;//mix(0.02, 0.0, weatherStrength);
    const vec3 AirScatterColor = _RGBToLinear(vec3(0.5));
    const vec3 AirExtinctColor = _RGBToLinear(1.0 - vec3(0.698, 0.702, 0.722));//mix(0.02, 0.006, weatherStrength);
#else
    const float AirDensityF = SkyDensityF;
    vec3 AirAmbientF = RGBToLinear(fogColor);

    const vec3 AirScatterColor = vec3(0.07);
    const vec3 AirExtinctColor = vec3(0.02);
#endif


float GetSkyDensity(const in vec3 worldPos) {
    // float heightF = 1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY);
    // return AirDensityF * (1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY));

    float densityFinal = AirDensityF;

    #ifdef VOLUMETRIC_NOISE_ENABLED
        vec3 texPosNear = worldPos * 0.12;
        float noiseNear = 1.0 - textureLod(TEX_CLOUDS, texPosNear.xzy, 0).r;

        vec3 texPosFar = worldPos * 0.004;
        float noiseFar = textureLod(TEX_CLOUDS, texPosFar.xzy, 0).r;

        float distF = smoothstep(0.0, 80.0, length(worldPos - cameraPosition));
        // float noise = mix(noiseNear, noiseFar, distF);
        // float noise = noiseFar * mix(noiseNear, 1.0, distF);
        float noise = noiseNear*(1.0 - distF) + noiseFar * (1.0 - 0.5*distF);

        // densityFinal *= _pow3(noise) * 0.8 + 0.2;// * 0.5 + 0.5;
        float fogF = _smoothstep(noise);
        fogF = pow(fogF, 2.0 - weatherStrength) + 0.18;// * 0.5 + 0.5;

        densityFinal *= fogF;
    #endif

    return densityFinal;
}

// altitude: world-pos.y
float GetFinalFogDensity(const in vec3 worldPos, const in float altitude, const in float caveFogF) {
    // float heightF = 1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY);
    // return AirDensityF * (1.0 - smoothstep(WorldAtmosphereMin, WorldAtmosphereMax, worldY));

    float densityFinal = GetSkyDensity(worldPos);

    #ifdef SKY_CAVE_FOG_ENABLED
        densityFinal = mix(densityFinal, CaveFogDensityF, caveFogF);
    #endif

    float heightF = 1.0 - saturate((altitude - WorldAtmosphereMin) / (WorldAtmosphereMax - WorldAtmosphereMin));
    densityFinal *= pow(heightF, 8);

    return densityFinal;
}

float GetSkyPhase(const in float VoL) {
    return DHG(VoL, -0.12, 0.84, 0.26);
}
