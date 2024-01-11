#define CLOUD_STEPS 24
#define CLOUD_SHADOW_STEPS 8
#define CLOUD_GROUND_SHADOW_STEPS 4
#define CLOUD_REFLECT_STEPS 12
#define CLOUD_REFLECT_SHADOW_STEPS 4

const float CloudSpeed = 0.01;


float GetCloudPhase(const in float VoL) {return DHG(VoL, -0.24, 0.76, 0.26);}

float GetCloudDither() {
    #ifndef RENDER_FRAG
        return 0.0;
    #elif defined EFFECT_TAA_ENABLED
        return InterleavedGradientNoiseTime();
    #else
        return InterleavedGradientNoise();
    #endif
}

float SampleCloudOctaves(const in vec3 worldPos, const in int octaveCount) {
    float sampleD = 0.0;

    float _str = pow(skyRainStrength, 0.333);

    for (int octave = 0; octave < octaveCount; octave++) {
        float scale = exp2(CloudMaxOctaves - octave);

        vec3 testPos = worldPos / CloudSize;

        testPos += CloudSpeed*worldTime * vec3(0.8, 0.2, 0.1);

        #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM_CUBE
            testPos = floor(testPos);
        #endif

        testPos /= scale;

        float sampleF = textureLod(texClouds, testPos.xzy * 0.25 * (octave+1), 0).r;
        sampleD += pow(sampleF, 2.4 - 1.4 * _str) * rcp(exp2(octave));
    }

    const float sampleMax = rcp(1.0 - rcp(exp2(octaveCount)));
    sampleD *= sampleMax;

    float z = saturate(worldPos.y / CloudHeight);
    sampleD *= sqrt(z - z*z) * 2.0;

    float threshold = mix(0.38, 0.59, _str);
    sampleD = max(sampleD - threshold, 0.0) / threshold;

    sampleD = _smoothstep(sampleD);
    return pow5(sampleD);
}

void GetCloudNearFar(const in vec3 worldPos, const in vec3 localViewDir, out vec3 cloudNear, out vec3 cloudFar) {
    float cloudOffset = cloudHeight - worldPos.y;// + 0.33;
    vec3 cloudPosHigh = vec3(localViewDir.xz * ((cloudOffset + CloudHeight) / localViewDir.y), cloudOffset + CloudHeight).xzy;
    vec3 cloudPosLow = vec3(localViewDir.xz * ((cloudOffset) / localViewDir.y), cloudOffset).xzy;

    cloudNear = vec3(0.0);
    cloudFar = vec3(0.0);

    if (cloudPosLow.y > 0.0) {
        // under clouds
        if (localViewDir.y > 0.0) {
            cloudNear = cloudPosLow;
            cloudFar = cloudPosHigh;
        }
    }
    else if (cloudPosHigh.y < 0.0) {
        // above clouds
        if (localViewDir.y < 0.0) {
            cloudNear = cloudPosHigh;
            cloudFar = cloudPosLow;
        }
    }
    else {
        // in clouds
        if (localViewDir.y > 0.0) cloudFar = cloudPosHigh;
        else if (localViewDir.y < 0.0) cloudFar = cloudPosLow;
        else {
            cloudFar = localViewDir * far;
        }
    }
}

float _TraceCloudShadow(const in vec3 worldPos, const in vec3 tracePos, const in float dither, const in int stepCount) {
    float sampleLit = 1.0;

    // const float shadowStepLen = 2.0;
    // vec3 shadowStep = localSkyLightDirection * shadowStepLen;
    vec3 sampleOffset = worldPos - vec3(0.0, cloudHeight, 0.0);

    vec3 shadowTracePos = tracePos;// + shadowStep * (i + dither);

    for (int i = 0; i < stepCount; i++) {
        float shadowStepLen = 0.5 * exp2(i);
        vec3 shadowStep = localSkyLightDirection * shadowStepLen;

        vec3 shadowSamplePos = shadowTracePos + shadowStep * dither;
        shadowTracePos += shadowStep;

        float shadowSampleF = SampleCloudOctaves(shadowSamplePos + sampleOffset, CloudShadowOctaves);
        float shadowSampleD = shadowSampleF * CloudDensityF;

        float shadowY = shadowSamplePos.y + sampleOffset.y;
        shadowSampleD *= step(0.0, shadowY) * step(shadowY, CloudHeight);

        sampleLit *= exp(shadowSampleD * CloudAbsorbF * -shadowStepLen);
    }

    return sampleLit;
}

vec4 _TraceClouds(const in vec3 worldPos, const in vec3 localViewDir, const in float distMin, const in float distMax, const in int stepCount, const in int shadowStepCount) {
    float dither = GetCloudDither();

    float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
    vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

    float VoL = dot(localSkyLightDirection, localViewDir);
    float phaseCloud = GetCloudPhase(VoL);

    #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
        float phaseSky = DHG(VoL, -0.12, 0.78, 0.42);
    #else
        const float phaseSky = phaseIso;
    #endif

    float cloudDist = distMax - distMin;
    float stepLength = cloudDist / (stepCount + 1);
    vec3 traceStep = localViewDir * stepLength;
    vec3 traceStart = localViewDir * distMin;

    vec3 cloudOffset = worldPos - vec3(0.0, cloudHeight, 0.0);

    float transmitFinal = 1.0;
    vec3 scatterFinal = vec3(0.0);

    for (uint stepI = 0; stepI < stepCount; stepI++) {
        vec3 tracePos = traceStart + traceStep * (stepI + dither);

        vec3 cloudPos = tracePos + cloudOffset;

        float sampleCloudF = 0.0;
        if (cloudPos.y > 0.0 && cloudPos.y < CloudHeight) {
            sampleCloudF = SampleCloudOctaves(tracePos + cloudOffset, CloudTraceOctaves);
        }

        float sampleCloudShadow = _TraceCloudShadow(worldPos, tracePos, dither, shadowStepCount);

        // float fogDist = GetShapedFogDistance(tracePos);
        // sampleCloudF *= 1.0 - GetFogFactor(fogDist, 0.5 * CloudFar, CloudFar, 1.0);

        float inRange = 1.0;//step(distMin + stepLength * (stepI + dither), far);
        float airDensity = GetSkyDensity(worldPos.y + tracePos.y);

        float stepDensity = mix(inRange * airDensity, CloudDensityF, sampleCloudF);
        float stepAmbientF = mix(AirAmbientF, CloudAmbientF, sampleCloudF);
        float stepScatterF = mix(AirScatterF, CloudScatterF, sampleCloudF);
        float stepExtinctF = mix(AirExtinctF, CloudAbsorbF, sampleCloudF);
        float stepPhase = mix(phaseSky, phaseCloud, sampleCloudF);

        vec3 sampleLight = (stepPhase * sampleCloudShadow + stepAmbientF) * skyLightColor;
        vec4 scatterTransmit = ApplyScatteringTransmission(stepLength, sampleLight, stepDensity, stepScatterF, stepExtinctF);

        scatterFinal += scatterTransmit.rgb * transmitFinal;
        transmitFinal *= scatterTransmit.a;
    }

    return vec4(scatterFinal, transmitFinal);
}

vec4 _TraceCloudVL(const in vec3 worldPos, const in vec3 localViewDir, const in float distMin, const in float distMax, const in int stepCount, const in int shadowStepCount) {
    float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
    vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

    //float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0 + 0.02;
    // vec3 skyLightColor = WorldSkyLightColor * (1.0 - 0.9 * _pow2(skyRainStrength));

    float VoL = dot(localSkyLightDirection, localViewDir);
    float phaseCloud = GetCloudPhase(VoL);
    float phaseSky = DHG(VoL, -0.12, 0.78, 0.42);

    float cloudDist = distMax - distMin;
    vec3 cloudNear = localViewDir * distMin;
    float farMax = min(distMax, far);

    float cloudAbsorb = 1.0;
    vec3 cloudScatter = vec3(0.0);

    if (cloudDist > EPSILON) {
        if (distMin > 0.0) {
            float stepLength = min(distMin, farMax);

            vec3 sampleLight = (phaseSky + AirAmbientF) * skyLightColor;
            vec4 scatterTransmit = ApplyScatteringTransmission(stepLength, sampleLight, AirDensityF, AirScatterF, AirExtinctF);

            cloudScatter += scatterTransmit.rgb * cloudAbsorb;
            cloudAbsorb *= scatterTransmit.a;
        }

        float dither = GetCloudDither();

        float stepLength = cloudDist / (stepCount + 1);
        vec3 traceStep = localViewDir * stepLength;

        vec3 sampleOffset = worldPos + vec3(0.0, -cloudHeight, 0.0);

        for (uint stepI = 0; stepI < stepCount; stepI++) {
            vec3 tracePos = cloudNear + traceStep * (stepI + dither);

            float sampleCloudF = SampleCloudOctaves(tracePos + sampleOffset, CloudTraceOctaves);
            float sampleCloudShadow = _TraceCloudShadow(worldPos, tracePos, dither, shadowStepCount);

            //float fogDist = GetShapedFogDistance(tracePos);
            //sampleCloudF *= 1.0 - GetFogFactor(fogDist, 0.65 * CloudFar, CloudFar, 1.0);

            float inRange = 1.0;//step(distMin + stepLength * (stepI + dither), far);

            float stepDensity = mix(inRange * AirDensityF, CloudDensityF, sampleCloudF);
            float stepAmbientF = mix(AirAmbientF, CloudAmbientF, sampleCloudF);
            float stepScatterF = mix(AirScatterF, CloudScatterF, sampleCloudF);
            float stepExtinctF = mix(AirExtinctF, CloudAbsorbF, sampleCloudF);
            float stepPhase = mix(phaseSky, phaseCloud, sampleCloudF);

            vec3 sampleLight = (stepPhase * sampleCloudShadow + stepAmbientF) * skyLightColor;
            vec4 scatterTransmit = ApplyScatteringTransmission(stepLength, sampleLight, stepDensity, stepScatterF, stepExtinctF);

            cloudScatter += scatterTransmit.rgb * cloudAbsorb;
            cloudAbsorb *= scatterTransmit.a;
        }

        if (farMax > distMax) {
            float stepLength = farMax - distMax;

            vec3 sampleLight = (phaseSky + AirAmbientF) * skyLightColor;
            vec4 scatterTransmit = ApplyScatteringTransmission(stepLength, sampleLight, AirDensityF, AirScatterF, AirExtinctF);

            cloudScatter += scatterTransmit.rgb * cloudAbsorb;
            cloudAbsorb *= scatterTransmit.a;
        }
    }
    else {
        vec3 sampleLight = (phaseSky + AirAmbientF) * skyLightColor;
        vec4 scatterTransmit = ApplyScatteringTransmission(farMax, sampleLight, AirDensityF, AirScatterF, AirExtinctF);

        cloudScatter += scatterTransmit.rgb * cloudAbsorb;
        cloudAbsorb *= scatterTransmit.a;
    }

    return vec4(cloudScatter, cloudAbsorb);
}

vec4 TraceCloudVL(const in vec3 worldPos, const in vec3 localViewDir, const in float viewDist, const in float depthOpaque, const in int stepCount, const in int shadowStepCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localViewDir, cloudNear, cloudFar);
    
    float cloudDistNear = length(cloudNear);
    float cloudDistFar = length(cloudFar);

    if (cloudDistNear < viewDist || depthOpaque >= 0.9999)
        cloudDistFar = min(cloudDistFar, min(viewDist, far));
    else {
        cloudDistNear = 0.0;
        cloudDistFar = 0.0;
    }

    //float farMax = min(viewDist, far);

    return _TraceCloudVL(worldPos, localViewDir, cloudDistNear, cloudDistFar, stepCount, shadowStepCount);
}

float TraceCloudShadow(const in vec3 worldPos, const in vec3 localLightDir, const in int stepCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
    
    float cloudDistNear = min(length(cloudNear), far);
    float cloudDistFar = min(length(cloudFar), far);
    float cloudDist = cloudDistFar - cloudDistNear;
    float cloudAbsorb = 1.0;

    if (cloudDist > EPSILON) {
        float dither = GetCloudDither();
    
        float cloudStepLen = cloudDist / (stepCount + 1);
        vec3 cloudStep = localLightDir * cloudStepLen;

        vec3 sampleOffset = worldPos - vec3(0.0, cloudHeight, 0.0);

        for (uint stepI = 0; stepI < stepCount; stepI++) {
            vec3 tracePos = cloudNear + cloudStep * (stepI + dither);

            float sampleF = SampleCloudOctaves(tracePos + sampleOffset, CloudShadowOctaves);
            float sampleD = sampleF * CloudDensityF;

            float shadowY = tracePos.y + sampleOffset.y;
            sampleD *= step(0.0, shadowY) * step(shadowY, CloudHeight);

            // float fogDist = GetShapedFogDistance(tracePos);
            // sampleD *= 1.0 - GetFogFactor(fogDist, 0.65 * CloudFar, CloudFar, 1.0);

            float stepAbsorb = exp(cloudStepLen * sampleD * -CloudAbsorbF);

            cloudAbsorb *= stepAbsorb;
        }
    }

    return cloudAbsorb;
}

float TraceCloudDensity(const in vec3 worldPos, const in vec3 localLightDir, const in int sampleCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
    float cloudDist = length(cloudFar) - length(cloudNear);
    float cloudDensity = 0.0;

    if (cloudDist > EPSILON) {
        float dither = GetCloudDither();
    
        float cloudStepLen = cloudDist / sampleCount;
        vec3 cloudStep = localLightDir * cloudStepLen;

        vec3 sampleOffset = worldPos - vec3(0.0, cloudHeight, 0.0);

        for (uint stepI = 0; stepI < sampleCount; stepI++) {
            vec3 tracePos = cloudNear + cloudStep * (stepI + dither);

            float sampleF = SampleCloudOctaves(tracePos + sampleOffset, CloudShadowOctaves);

            float shadowY = tracePos.y + sampleOffset.y;
            sampleF *= step(0.0, shadowY) * step(shadowY, CloudHeight);

            cloudDensity += sampleF;
        }
    }

    return cloudDensity / sampleCount;
}
