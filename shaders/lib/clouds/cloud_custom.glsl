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
    float threshold = CloudCoverMin * (1.0 - 0.6*skyRainStrength);
    sampleD = max(sampleD - threshold, 0.0) / (1.0 - threshold);

    sampleD = smootherstep(sampleD);
    return pow5(sampleD);
}

float SampleCloudOctaves(in vec3 worldPos, const in int octaveCount) {
    return SampleCloudOctaves(worldPos, worldPos.y, octaveCount);
}

float raySphere(const in vec3 ro, const in vec3 rd, const in vec3 sph, const in float rad) {
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - _pow2(rad);
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

        float _near = 0.0, _far = 0.0;
        if (distFar > distNear && distNear > 0.0) {
            // under clouds
            _near = distNear;
            _far = distFar;
        }
        else if (distFar < distNear && distFar > 0.0) {
            // above clouds
            _near = distFar;
            _far = distNear;
        }
        else if (distFar > 0.0) {
            // in clouds
            _near = 0.0;
            _far = max(distNear, distFar);
        }

        cloudNear = localViewDir * _near;
        cloudFar = localViewDir * _far;
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

float TraceCloudDensity(const in vec3 worldPos, const in vec3 localLightDir, const in int sampleCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
    float cloudDist = length(cloudFar) - length(cloudNear);
    float cloudDensity = 0.0;

    float sampleCountInv = rcp(sampleCount);

    if (cloudDist > EPSILON) {
        float dither = GetCloudDither();
    
        float cloudStepLen = cloudDist * sampleCountInv;
        vec3 cloudStep = localLightDir * cloudStepLen;

        float cloudAlt = GetCloudAltitude();
        //vec3 sampleOffset = worldPos - vec3(0.0, cloudAlt, 0.0);

        for (float i = 0.0; i < sampleCount; i++) {
            vec3 traceLocalPos = cloudStep * (i + dither) + cloudNear;
            // vec3 traceWorldPos = worldPos + traceLocalPos;

            #if WORLD_CURVE_RADIUS > 0
                float traceAltitude = GetWorldAltitude(traceLocalPos);
                vec3 traceWorldPos = worldPos * vec3(1.0, 0.0, 1.0) + GetWorldCurvedPosition(traceLocalPos);
            #else
                vec3 traceWorldPos = traceLocalPos + worldPos;
                float traceAltitude = traceWorldPos.y;
            #endif

            cloudDensity += SampleCloudOctaves(traceWorldPos, traceAltitude, CloudShadowOctaves);
        }
    }

    return cloudDensity * sampleCountInv;
}

#ifdef RENDER_FRAG
    float TraceCloudShadow(const in vec3 worldPos, const in vec3 localLightDir, const in int stepCount) {
        vec3 cloudNear, cloudFar;
        GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
        
        float cloudDistNear = length(cloudNear);
        float cloudDistFar = length(cloudFar);
        float cloudDist = cloudDistFar - cloudDistNear;

        if (cloudDist < EPSILON) return 1.0;
        cloudDist = min(cloudDist, 512.0);

        float dither = GetCloudDither();
        float cloudAlt = GetCloudAltitude();
    
        float cloudStepLen = cloudDist / stepCount;
        vec3 cloudStep = localLightDir * cloudStepLen;

        float cloudAbsorb = 1.0;
        for (uint i = 0u; i < stepCount; i++) {
            vec3 traceLocalPos = worldPos + cloudNear - cameraPosition;
            traceLocalPos += cloudStep * (i + dither);

            #if WORLD_CURVE_RADIUS > 0
                float traceAltitude = GetWorldAltitude(traceLocalPos);
                vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
                traceWorldPos.xz += cameraPosition.xz;
            #else
                vec3 traceWorldPos = traceLocalPos + cameraPosition;
                float traceAltitude = traceWorldPos.y;
            #endif

            float sampleD = SampleCloudOctaves(traceWorldPos, traceAltitude, CloudShadowOctaves) * CloudDensityF;

            float traceStepLen = cloudStepLen;
            // if (i == stepCount-1) traceStepLen *= (1.0 - dither);
            // else if (i == 0) traceStepLen *= dither;

            cloudAbsorb *= exp(traceStepLen * sampleD * -CloudAbsorbF);
        }

        return cloudAbsorb * 0.74 + 0.26;
    }

    // float _TraceCloudShadow(in vec3 worldPos, const in float dither, const in int stepCount) {
    //     //float cloudAlt = GetCloudAltitude();
    //     // vec3 sampleOffset = worldPos - vec3(0.0, cloudAlt, 0.0);
    //     float sampleLit = 1.0;

    //     for (int i = 0; i < stepCount; i++) {
    //         float shadowStepLen = 0.5 * exp2(i);
    //         vec3 shadowStep = localSkyLightDirection * shadowStepLen;

    //         vec3 shadowSamplePos = worldPos + shadowStep * dither;
    //         worldPos += shadowStep;

    //         #if WORLD_CURVE_RADIUS > 0
    //             float traceAltitude = GetWorldAltitude(shadowSamplePos - cameraPosition);
    //             vec3 traceWorldPos = GetWorldCurvedPosition(shadowSamplePos - cameraPosition);
    //             traceWorldPos.xz += worldPos.xz;
    //         #else
    //             vec3 traceWorldPos = shadowSamplePos + worldPos;
    //             float traceAltitude = traceWorldPos.y;
    //         #endif

    //         float shadowSampleF = SampleCloudOctaves(traceWorldPos, traceAltitude, CloudShadowOctaves);
    //         float shadowSampleD = shadowSampleF * CloudDensityF;

    //         // float shadowY = shadowSamplePos.y + sampleOffset.y;
    //         // shadowSampleD *= step(0.0, shadowY) * step(shadowY, CloudHeight);

    //         float traceStepLen = shadowStepLen;
    //         if (i == stepCount-1) traceStepLen *= (1.0 - dither);
    //         else if (i == 0) traceStepLen *= dither;

    //         sampleLit *= exp(shadowSampleD * CloudAbsorbF * -traceStepLen);
    //     }

    //     return pow(sampleLit, 10.0);
    // }

    void _TraceClouds(inout vec3 scatterFinal, inout vec3 transmitFinal, const in vec3 worldPos, const in vec3 localViewDir, const in float distMin, const in float distMax, const in int stepCount, const in int shadowStepCount) {
        float dither = GetCloudDither();

        float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
        vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

        float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * WorldSkyBrightnessF * eyeBrightF;
        #else
            vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
            skyColorFinal = RGBToLinear(skyColorFinal) * eyeBrightF;
        #endif

        float VoL = dot(localSkyLightDirection, localViewDir);
        float phaseCloud = GetCloudPhase(VoL);

        #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
            float phaseSky = GetSkyPhase(VoL);
        #else
            const float phaseSky = phaseIso;
        #endif

        float cloudDist = distMax - distMin;
        float stepLength = cloudDist / (stepCount+1);
        vec3 traceStep = localViewDir * stepLength;
        vec3 traceStart = localViewDir * distMin;

        float cloudAlt = GetCloudAltitude();
        //vec3 cloudOffset = worldPos - vec3(0.0, cloudAlt, 0.0);

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

            float sampleCloudF = 0.0;
            //if (cloudPos.y > 0.0 && cloudPos.y < CloudHeight) {
                sampleCloudF = SampleCloudOctaves(traceWorldPos, traceAltitude, CloudTraceOctaves);
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

            vec3 sampleLight = stepPhase * sampleCloudShadow * skyLightColor + stepAmbientF * skyColorFinal;
            ApplyScatteringTransmission(scatterFinal, transmitFinal, traceStepLen, sampleLight * stepLength, stepDensity, stepScatterF, stepExtinctF);
        }
    }
#endif
