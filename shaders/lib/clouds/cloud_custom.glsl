float GetCloudPhase(const in float VoL) {return DHG(VoL, -0.36, 0.64, 0.5);}

float GetCloudDither() {
    #ifndef RENDER_FRAG
        return 0.0;
    #elif defined EFFECT_TAA_ENABLED
        return InterleavedGradientNoiseTime();
    #else
        return InterleavedGradientNoise();
    #endif
}

float SampleCloudOctaves(in vec3 worldPos, const in float altitude, const in int octaveCount) {
    float _str = pow(skyRainStrength, 0.333);
    float cloudTimeF = mod((cloudTime/3072.0), 1.0) * SKY_CLOUD_SPEED;
    float sampleD = 0.0;

    const vec3 sampleScale = vec3(0.5, 0.5, 1.0);
    const float sampleDensity = 1.3;

    for (int octave = 0; octave < octaveCount; octave++) {
        float scale = exp2(CloudMaxOctaves - octave);

        vec3 testPos = worldPos / CloudSize;

        #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM_CUBE
            testPos = floor(testPos);
        #endif

        testPos /= scale;

        testPos.x += cloudTimeF;

        float sampleF = textureLod(texClouds, testPos.xzy * sampleScale * (octave+1), 0).r;
        sampleD += pow(sampleF, 2.0 - 0.5*_str) * rcp(exp2(octave));
    }

    const float sampleMaxInv = rcp(1.0 - rcp(exp2(octaveCount)));
    sampleD = saturate(sampleD * sampleMaxInv * sampleDensity);

    float cloudAlt = GetCloudAltitude();
    float z = saturate((altitude - cloudAlt) / CloudHeight);
    sampleD *= sqrt(z - z*z) * 2.0;

    const float CloudCoverMinF = SKY_CLOUD_COVER_MIN * 0.01;
    const float CloudCoverMin = 1.0 - sqrt(CloudCoverMinF);

    // float threshold = mix(CloudCoverMin, 0.0, _str);
    float threshold = CloudCoverMin * (1.0 - _str);
    sampleD = max(sampleD - threshold, 0.0) / (1.0 - threshold);

    sampleD = _smoothstep(sampleD);
    return pow5(sampleD);
}

float SampleCloudOctaves(in vec3 worldPos, const in int octaveCount) {
    return SampleCloudOctaves(worldPos, worldPos.y, octaveCount);
}

float raySphere(const in vec3 ro, const in vec3 rd, const in vec3 sph, const in float rad) {
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - rad*rad;
    float t = b*b - c;
    if (t > 0.0) t = -b - sqrt(t);
    return t;
}

void GetCloudNearFar(const in vec3 worldPos, const in vec3 localViewDir, out vec3 cloudNear, out vec3 cloudFar) {
    cloudNear = vec3(0.0);
    cloudFar = vec3(0.0);

    float cloudAlt = GetCloudAltitude();

    #if WORLD_CURVE_RADIUS > 0
        vec3 worldCenter = cameraPosition;
        worldCenter.y = -WorldCurveRadius;

        float radiusNear = WorldCurveRadius + cloudAlt;
        float radiusFar = radiusNear + CloudHeight;
        float distNear = raySphere(worldPos, localViewDir, worldCenter, radiusNear);
        float distFar = raySphere(worldPos, localViewDir, worldCenter, radiusFar);

        if (distFar > distNear && distNear > 0.0) {
            // under clouds
            cloudNear = localViewDir * distNear;
            cloudFar = localViewDir * distFar;
        }
        else if (distFar < distNear && distFar > 0.0) {
            // above clouds
            cloudNear = localViewDir * distFar;
            cloudFar = localViewDir * distNear;
        }
        else if (distFar > 0.0) {
            // in clouds
            cloudFar = localViewDir * distNear;
        }
    #else
        float cloudOffset = cloudAlt - worldPos.y;
        vec3 cloudPosHigh = vec3(localViewDir.xz * ((cloudOffset + CloudHeight) / localViewDir.y), cloudOffset + CloudHeight).xzy;
        vec3 cloudPosLow = vec3(localViewDir.xz * ((cloudOffset) / localViewDir.y), cloudOffset).xzy;

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
    #endif
}

float TraceCloudShadow(const in vec3 worldPos, const in vec3 localLightDir, const in int stepCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
    
    float cloudDistNear = min(length(cloudNear), SkyFar);
    float cloudDistFar = min(length(cloudFar), SkyFar);
    float cloudDist = cloudDistFar - cloudDistNear;
    float cloudAbsorb = 1.0;

    if (cloudDist > EPSILON) {
        float dither = GetCloudDither();
    
        float cloudStepLen = cloudDist / (stepCount + 1);
        vec3 cloudStep = localLightDir * cloudStepLen;

        float cloudAlt = GetCloudAltitude();
        // vec3 sampleOffset = worldPos - vec3(0.0, cloudAlt, 0.0);

        for (uint i = 0; i < stepCount; i++) {
            vec3 traceLocalPos = cloudNear + cloudStep * (i + dither);

            #if WORLD_CURVE_RADIUS > 0
                float traceAltitude = GetWorldAltitude(traceLocalPos);
                vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
                traceWorldPos.xz += worldPos.xz;
            #else
                vec3 traceWorldPos = traceLocalPos + worldPos;
                float traceAltitude = traceWorldPos.y;
            #endif

            float sampleF = SampleCloudOctaves(traceWorldPos, traceAltitude, CloudShadowOctaves);
            float sampleD = sampleF * CloudDensityF;

            // float shadowY = traceLocalPos.y + sampleOffset.y;
            // sampleD *= step(0.0, shadowY) * step(shadowY, CloudHeight);

            // float fogDist = GetShapedFogDistance(traceLocalPos);
            // sampleD *= 1.0 - GetFogFactor(fogDist, 0.65 * SkyFar, SkyFar, 1.0);

            float traceStepLen = cloudStepLen;
            if (i == 0) traceStepLen *= dither;

            float stepAbsorb = exp(traceStepLen * sampleD * -CloudAbsorbF);

            cloudAbsorb *= stepAbsorb;
        }
    }

    return cloudAbsorb;
}

float _TraceCloudShadow(in vec3 worldPos, const in float dither, const in int stepCount) {
    //float cloudAlt = GetCloudAltitude();
    // vec3 sampleOffset = worldPos - vec3(0.0, cloudAlt, 0.0);
    float sampleLit = 1.0;

    for (int i = 0; i < stepCount; i++) {
        float shadowStepLen = 0.5 * exp2(i);
        vec3 shadowStep = localSkyLightDirection * shadowStepLen;

        vec3 shadowSamplePos = worldPos + shadowStep * dither;
        worldPos += shadowStep;

        #if WORLD_CURVE_RADIUS > 0
            float traceAltitude = GetWorldAltitude(shadowSamplePos - cameraPosition);
            vec3 traceWorldPos = GetWorldCurvedPosition(shadowSamplePos - cameraPosition);
            traceWorldPos.xz += worldPos.xz;
        #else
            vec3 traceWorldPos = shadowSamplePos + worldPos;
            float traceAltitude = traceWorldPos.y;
        #endif

        float shadowSampleF = SampleCloudOctaves(traceWorldPos, traceAltitude, CloudShadowOctaves);
        float shadowSampleD = shadowSampleF * CloudDensityF;

        // float shadowY = shadowSamplePos.y + sampleOffset.y;
        // shadowSampleD *= step(0.0, shadowY) * step(shadowY, CloudHeight);

        float traceStepLen = shadowStepLen;
        if (i == 0) traceStepLen *= dither;

        sampleLit *= exp(shadowSampleD * CloudAbsorbF * -traceStepLen);
    }

    return pow(sampleLit, 10.0);
}

void _TraceClouds(inout vec3 scatterFinal, inout vec3 transmitFinal, const in vec3 worldPos, const in vec3 localViewDir, const in float distMin, const in float distMax, const in int stepCount, const in int shadowStepCount) {
    float dither = GetCloudDither();

    float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
    vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

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

    float cloudAlt = GetCloudAltitude();
    //vec3 cloudOffset = worldPos - vec3(0.0, cloudAlt, 0.0);

    for (uint i = 0; i < stepCount; i++) {
        vec3 traceLocalPos = traceStart + traceStep * (i + dither);

        #if WORLD_CURVE_RADIUS > 0
            float traceAltitude = GetWorldAltitude(traceLocalPos);
            vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
            traceWorldPos.xz += worldPos.xz;
        #else
            vec3 traceWorldPos = traceLocalPos + worldPos;
            float traceAltitude = traceWorldPos.y;
        #endif

        //vec3 cloudPos = traceLocalPos + cloudOffset;

        float sampleCloudF = 0.0;
        //if (cloudPos.y > 0.0 && cloudPos.y < CloudHeight) {
            sampleCloudF = SampleCloudOctaves(traceWorldPos, traceAltitude, CloudTraceOctaves);
        //}

        float sampleCloudShadow = TraceCloudShadow(traceWorldPos, localSkyLightDirection, shadowStepCount);
        // float sampleCloudShadow = _TraceCloudShadow(worldPos, traceLocalPos, dither, shadowStepCount);

        // float fogDist = GetShapedFogDistance(traceLocalPos);
        // sampleCloudF *= 1.0 - GetFogFactor(fogDist, 0.5 * SkyFar, SkyFar, 1.0);

        float airDensity = GetSkyDensity(traceAltitude);

        float stepDensity = mix(airDensity, CloudDensityF, sampleCloudF);
        float stepAmbientF = mix(AirAmbientF, CloudAmbientF, sampleCloudF);
        vec3 stepScatterF = mix(AirScatterColor, CloudScatterColor, sampleCloudF);
        vec3 stepExtinctF = mix(AirExtinctColor, CloudAbsorbColor, sampleCloudF);
        float stepPhase = mix(phaseSky, phaseCloud, sampleCloudF);

        float traceStepLen = stepLength;
        if (i == 0) traceStepLen *= dither;

        vec3 sampleLight = (stepPhase * sampleCloudShadow + stepAmbientF) * skyLightColor;
        ApplyScatteringTransmission(scatterFinal, transmitFinal, traceStepLen, sampleLight, stepDensity, stepScatterF, stepExtinctF);
    }
}

// void _TraceCloudVL(inout vec3 cloudScatter, inout vec3 cloudAbsorb, const in vec3 worldPos, const in vec3 localViewDir, const in float distMin, const in float distMax, const in int stepCount, const in int shadowStepCount) {
//     float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
//     vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

//     //float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0 + 0.02;
//     // vec3 skyLightColor = WorldSkyLightColor * (1.0 - 0.9 * _pow2(skyRainStrength));

//     float VoL = dot(localSkyLightDirection, localViewDir);
//     float phaseCloud = GetCloudPhase(VoL);
//     float phaseSky = GetSkyPhase(VoL);

//     float cloudDist = distMax - distMin;
//     vec3 cloudNear = localViewDir * distMin;
//     float farMax = min(distMax, far);

//     if (cloudDist > EPSILON) {
//         if (distMin > 0.0) {
//             float stepLength = min(distMin, farMax);

//             vec3 sampleLight = (phaseSky + AirAmbientF) * skyLightColor;
//             ApplyScatteringTransmission(cloudScatter, cloudAbsorb, stepLength, sampleLight, AirDensityF, AirScatterColor, AirExtinctColor, 8);
//         }

//         float dither = GetCloudDither();

//         float stepLength = cloudDist / (stepCount + 1);
//         vec3 traceStep = localViewDir * stepLength;

//         float cloudAlt = GetCloudAltitude();
//         // vec3 sampleOffset = worldPos - vec3(0.0, cloudAlt, 0.0);

//         for (uint stepI = 0; stepI < stepCount; stepI++) {
//             vec3 traceLocalPos = cloudNear + traceStep * (stepI + dither);

//             #if WORLD_CURVE_RADIUS > 0
//                 float traceAltitude = GetWorldAltitude(traceLocalPos);
//                 vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
//                 traceWorldPos.xz += worldPos.xz;
//             #else
//                 vec3 traceWorldPos = traceLocalPos + worldPos;
//                 float traceAltitude = traceWorldPos.y;
//             #endif

//             float sampleCloudF = SampleCloudOctaves(traceWorldPos, CloudTraceOctaves);
//             float sampleCloudShadow = _TraceCloudShadow(traceWorldPos, dither, shadowStepCount);

//             //float fogDist = GetShapedFogDistance(traceLocalPos);
//             //sampleCloudF *= 1.0 - GetFogFactor(fogDist, 0.65 * SkyFar, SkyFar, 1.0);

//             float stepDensity = mix(AirDensityF, CloudDensityF, sampleCloudF);
//             float stepAmbientF = mix(AirAmbientF, CloudAmbientF, sampleCloudF);
//             vec3 stepScatterF = mix(AirScatterColor, CloudScatterColor, sampleCloudF);
//             vec3 stepExtinctF = mix(AirExtinctColor, CloudAbsorbColor, sampleCloudF);
//             float stepPhase = mix(phaseSky, phaseCloud, sampleCloudF);

//             vec3 sampleLight = (stepPhase * sampleCloudShadow + stepAmbientF) * skyLightColor;
//             ApplyScatteringTransmission(cloudScatter, cloudAbsorb, stepLength, sampleLight, stepDensity, stepScatterF, stepExtinctF, 8);
//         }

//         if (farMax > distMax) {
//             float stepLength = farMax - distMax;

//             vec3 sampleLight = (phaseSky + AirAmbientF) * skyLightColor;
//             ApplyScatteringTransmission(cloudScatter, cloudAbsorb, stepLength, sampleLight, AirDensityF, AirScatterColor, AirExtinctColor, 8);
//         }
//     }
//     else {
//         vec3 sampleLight = (phaseSky + AirAmbientF) * skyLightColor;
//         ApplyScatteringTransmission(cloudScatter, cloudAbsorb, farMax, sampleLight, AirDensityF, AirScatterColor, AirExtinctColor, 8);
//     }
// }

// vec4 TraceCloudVL(const in vec3 worldPos, const in vec3 localViewDir, const in float viewDist, const in float depthOpaque, const in int stepCount, const in int shadowStepCount) {
//     vec3 cloudNear, cloudFar;
//     GetCloudNearFar(worldPos, localViewDir, cloudNear, cloudFar);
    
//     float cloudDistNear = length(cloudNear);
//     float cloudDistFar = length(cloudFar);

//     if (cloudDistNear < viewDist || depthOpaque >= 0.9999)
//         cloudDistFar = min(cloudDistFar, min(viewDist, far));
//     else {
//         cloudDistNear = 0.0;
//         cloudDistFar = 0.0;
//     }

//     //float farMax = min(viewDist, far);

//     return _TraceCloudVL(worldPos, localViewDir, cloudDistNear, cloudDistFar, stepCount, shadowStepCount);
// }

float TraceCloudDensity(const in vec3 worldPos, const in vec3 localLightDir, const in int sampleCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
    float cloudDist = length(cloudFar) - length(cloudNear);
    float cloudDensity = 0.0;

    if (cloudDist > EPSILON) {
        float dither = GetCloudDither();
    
        float cloudStepLen = cloudDist / sampleCount;
        vec3 cloudStep = localLightDir * cloudStepLen;

        float cloudAlt = GetCloudAltitude();
        //vec3 sampleOffset = worldPos - vec3(0.0, cloudAlt, 0.0);

        for (uint stepI = 0; stepI < sampleCount; stepI++) {
            vec3 traceLocalPos = cloudNear + cloudStep * (stepI + dither);
            // vec3 traceWorldPos = worldPos + traceLocalPos;

            #if WORLD_CURVE_RADIUS > 0
                float traceAltitude = GetWorldAltitude(traceLocalPos);
                vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
                traceWorldPos.xz += worldPos.xz;
            #else
                vec3 traceWorldPos = traceLocalPos + worldPos;
                float traceAltitude = traceWorldPos.y;
            #endif

            float sampleF = SampleCloudOctaves(traceWorldPos, traceAltitude, CloudShadowOctaves);

            // float shadowY = traceWorldPos.y;
            // sampleF *= step(0.0, shadowY) * step(shadowY, CloudHeight);

            cloudDensity += sampleF;
        }
    }

    return cloudDensity / sampleCount;
}
