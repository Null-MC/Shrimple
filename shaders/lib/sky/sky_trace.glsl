float GetTraceDither() {
    #ifndef RENDER_FRAG
        return 0.0;
    #elif defined EFFECT_TAA_ENABLED
        return InterleavedGradientNoiseTime();
    #else
        return InterleavedGradientNoise();
    #endif
}

void TraceSky(inout vec3 scatterFinal, inout vec3 transmitFinal, const in vec3 worldPos, const in vec3 localViewDir, const in float distMin, const in float distMax, const in int stepCount) {
    // float dither = GetTraceDither();

    #ifndef IRIS_FEATURE_SSBO
        vec3 localSunDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        vec3 WorldSkyLightColor = CalculateSkyLightColor(localSunDirection.y);

        vec3 localSkyLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    #endif

    float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
    vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

    float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
    #if SKY_TYPE == SKY_TYPE_CUSTOM
        vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * Sky_BrightnessF * eyeBrightF;
    #else
        vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
        skyColorFinal = RGBToLinear(skyColorFinal) * eyeBrightF;
    #endif

    #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
        float VoL = dot(localSkyLightDirection, localViewDir);
        float phaseSky = GetSkyPhase(VoL);
    #else
        const float phaseSky = phaseIso;
    #endif

    float traceDist = distMax - distMin;
    float stepLength = traceDist / stepCount;
    vec3 traceStep = localViewDir * stepLength;
    vec3 traceStart = localViewDir * distMin;

    for (uint i = 0; i < stepCount; i++) {
        //float stepDither = dither * step(i, stepCount-1);
        vec3 traceLocalPos = traceStep * i + traceStart;

        #if WORLD_CURVE_RADIUS > 0
            float traceAltitude = GetWorldAltitude(traceLocalPos);
            // vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
            // traceWorldPos.xz += worldPos.xz;
        #else
            vec3 traceWorldPos = traceLocalPos + worldPos;
            float traceAltitude = traceWorldPos.y;
        #endif

        float airDensity = GetSkyDensity(traceAltitude);

        // float traceStepLen = stepLength;
        // if (i == stepCount) traceStepLen *= (1.0 - dither);
        // else if (i == 0) traceStepLen *= dither;

        vec3 sampleLight = phaseSky * skyLightColor + AirAmbientF * skyColorFinal;
        // vec3 sampleLight = (phaseSky + AirAmbientF) * skyLightColor;
        ApplyScatteringTransmission(scatterFinal, transmitFinal, stepLength, sampleLight, airDensity, AirScatterColor, AirExtinctColor);
    }
}
