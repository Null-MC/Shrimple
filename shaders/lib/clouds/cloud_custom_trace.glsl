// float GetCloudPhase(const in float VoL) {return DHG(VoL, -0.36, 0.64, 0.5);}
float GetCloudPhase(const in float VoL) {return DHG(VoL, -0.16, 0.84, 0.18);}

#ifdef RENDER_FRAG
    vec3 GetSkyColorUp() {
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * WorldSkyBrightnessF;
        #else
            vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
            skyColorFinal = RGBToLinear(skyColorFinal);
        #endif

        float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
        return skyColorFinal * eyeBrightF;
    }

    void _TraceClouds(inout vec3 scatterFinal, inout vec3 transmitFinal, const in vec3 worldPos, const in vec3 localViewDir, const in float distMin, const in float distMax, const in int stepCount, const in int shadowStepCount) {
        float dither = GetCloudDither();

        float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
        vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

        vec3 skyColorFinal = GetSkyColorUp();

        float VoL = dot(localSkyLightDirection, localViewDir);
        float phaseCloud = GetCloudPhase(VoL);

        #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
            float phaseSky = GetSkyPhase(VoL);
        #else
            const float phaseSky = phaseIso;
        #endif

        float cloudDist = distMax - distMin;
        float stepLength = cloudDist / stepCount;
        vec3 traceStep = localViewDir * stepLength;
        vec3 traceStart = localViewDir * distMin;

        // float cloudAlt = GetCloudAltitude();
        //vec3 cloudOffset = worldPos - vec3(0.0, cloudAlt, 0.0);
        vec2 cloudOffset = GetCloudOffset();
        //vec3 camOffset = GetCloudCameraOffset();

        for (uint i = 0; i <= stepCount; i++) {
            float stepDither = dither * step(i, stepCount-1);
            vec3 traceLocalPos = traceStep * (i + stepDither) + traceStart;

            #if WORLD_CURVE_RADIUS > 0
                float traceAltitude = GetWorldAltitude(traceLocalPos);
                vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
                traceWorldPos.xz += worldPos.xz;
            #else
                vec3 traceWorldPos = traceLocalPos + worldPos;
                float traceAltitude = traceWorldPos.y;
            #endif

            //vec3 cloudPos = traceLocalPos + cloudOffset;

            float sampleCloudF;// = 0.0;
            //if (cloudPos.y > 0.0 && cloudPos.y < CloudHeight) {
                // sampleCloudF = SampleCloudOctaves(traceWorldPos, traceAltitude, CloudTraceOctaves);
                sampleCloudF = SampleClouds(traceWorldPos, cloudOffset);
            //}

            float sampleCloudShadow = TraceCloudShadow(traceWorldPos, localSkyLightDirection, shadowStepCount);
            // float sampleCloudShadow = _TraceCloudShadow(worldPos, traceLocalPos, dither, shadowStepCount);
            //sampleCloudShadow = sampleCloudShadow * 0.7 + 0.3;

            // float fogDist = GetShapedFogDistance(traceLocalPos);
            // sampleCloudF *= 1.0 - GetFogFactor(fogDist, 0.5 * SkyFar, SkyFar, 1.0);

            float airDensity = GetSkyDensity(traceAltitude);

            float stepDensity = mix(airDensity, CloudDensityF, sampleCloudF);
            float stepAmbientF = mix(AirAmbientF, CloudAmbientF, sampleCloudF);
            vec3 stepScatterF = mix(AirScatterColor, CloudScatterColor, sampleCloudF);
            vec3 stepExtinctF = mix(AirExtinctColor, CloudAbsorbColor, sampleCloudF);
            float stepPhase = mix(phaseSky, phaseCloud, sampleCloudF);

            float traceStepLen = stepLength;
            if (i == stepCount) traceStepLen *= (1.0 - dither);
            else if (i == 0) traceStepLen *= dither;

            vec3 sampleLight = stepPhase * sampleCloudShadow * skyLightColor;// + stepAmbientF * skyColorFinal;

            sampleLight += stepAmbientF * skyColorFinal + 0.08;

            ApplyScatteringTransmission(scatterFinal, transmitFinal, traceStepLen, sampleLight * stepLength, stepDensity, stepScatterF, stepExtinctF);
        }
    }

    void TraceCloudSky(inout vec3 scatterFinal, inout vec3 transmitFinal, const in vec3 worldPos, const in vec3 localViewDir, const in float distMin, const in float distMax, const in int stepCount, const in int shadowStepCount) {
        float dither = GetCloudDither();

        float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
        vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

        vec3 skyColorFinal = GetSkyColorUp();

        float VoL = dot(localSkyLightDirection, localViewDir);

        #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
            float phaseSky = GetSkyPhase(VoL);
        #else
            const float phaseSky = phaseIso;
        #endif

        float cloudDist = distMax - distMin;
        float stepLength = cloudDist / stepCount;
        vec3 traceStep = localViewDir * stepLength;
        vec3 traceStart = localViewDir * distMin;

        for (uint i = 0; i < stepCount; i++) {
            float stepDither = dither;// * step(i, stepCount-1);
            vec3 traceLocalPos = traceStep * (i + stepDither) + traceStart;

            #if WORLD_CURVE_RADIUS > 0
                float traceAltitude = GetWorldAltitude(traceLocalPos);
                vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
                traceWorldPos.xz += worldPos.xz;
            #else
                vec3 traceWorldPos = traceLocalPos + worldPos;
                float traceAltitude = traceWorldPos.y;
            #endif

            float sampleCloudShadow = TraceCloudShadow(traceWorldPos, localSkyLightDirection, shadowStepCount);

            float airDensity = GetSkyDensity(traceAltitude);

            float traceStepLen = stepLength;
            // if (i == stepCount) traceStepLen *= (1.0 - dither);
            // else if (i == 0) traceStepLen *= dither;

            vec3 sampleLight = phaseSky * sampleCloudShadow * skyLightColor + AirAmbientF * skyColorFinal;
            ApplyScatteringTransmission(scatterFinal, transmitFinal, traceStepLen, sampleLight * stepLength, airDensity, AirScatterColor, AirExtinctColor);
        }
    }
#endif
