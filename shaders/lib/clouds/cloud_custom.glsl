#define CLOUD_STEPS 24
#define CLOUD_SHADOW_STEPS 8
#define CLOUD_REFLECT_STEPS 12
#define CLOUD_REFLECT_SHADOW_STEPS 4
//#define CLOUD_CUBED

const int CloudOctaves = 3;


float SampleCloudOctaves(in vec3 worldPos) {
    float sampleD = 0.0;

    float _str = pow(skyRainStrength, 0.333);

    for (int octave = 0; octave < CloudOctaves; octave++) {
        float scale = exp2(CloudOctaves + 2 - octave);

        vec3 testPos = worldPos / CloudSize;

        #ifdef CLOUD_CUBED
            testPos = floor(testPos);
        #endif

        testPos /= scale;

        float sampleF = textureLod(texClouds, testPos.xzy * 0.25 * (octave+1), 0).r;
        sampleD += pow(sampleF, 2.4 - 1.4 * _str) * rcp(exp2(octave));
    }

    const float sampleMax = rcp(1.0 - rcp(exp2(CloudOctaves)));
    sampleD *= sampleMax;

    float z = saturate(worldPos.y / CloudHeight);
    sampleD *= sqrt(z - z*z) * 2.0;

    float threshold = mix(0.44, 0.74, _str);
    sampleD = max(sampleD - threshold, 0.0) / threshold;

    return smootherstep(sampleD);
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

vec4 TraceCloudVL(const in vec3 worldPos, const in vec3 localViewDir, const in float viewDist, const in float depthOpaque, const in int stepCount, const in int shadowStepCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localViewDir, cloudNear, cloudFar);
    
    float cloudDistNear = length(cloudNear);
    float cloudDistFar = length(cloudFar);
    float cloudDist = 0.0;

    if (cloudDistNear < viewDist || depthOpaque >= 0.9999)
        cloudDist = min(cloudDistFar, min(viewDist, far)) - cloudDistNear;

    float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0 + 0.02;
    vec3 skyLightColor = WorldSkyLightColor * (1.0 - 0.9 * _pow2(skyRainStrength));

    float cloudAbsorb = 1.0;
    vec3 cloudScatter = vec3(0.0);

    vec3 _airAmbientF = vec3(0.0);
    float _airScatterF = 0.0, _airExtinctF = 0.0;
    #if SKY_VOL_FOG_TYPE == VOL_TYPE_FAST
        _airAmbientF = AirAmbientF * skyLightColor;
        _airScatterF = AirScatterF * eyeSkyLightF;
        _airExtinctF = AirExtinctF;
    #endif

    float VoL = dot(localSkyLightDirection, localViewDir);
    float phaseCloud = DHG(VoL, -0.19, 0.824, 0.09);
    //float phaseAir = DHG(VoL, -0.19, 0.824, 0.051);
    vec3 _cloudAmbient = CloudAmbientF * skyLightColor;

    float farMax = min(viewDist, far);

    if (cloudDist > EPSILON) {
        if (cloudDistNear > 0.0) {
            float stepLength = min(cloudDistNear, farMax);

            vec3 sampleLight = phaseAir * skyLightColor + _airAmbientF;
            vec4 scatterTransmit = ApplyScatteringTransmission(stepLength, sampleLight, _airScatterF, _airExtinctF);

            cloudScatter += scatterTransmit.rgb * cloudAbsorb;
            cloudAbsorb *= scatterTransmit.a;
        }

        float dither = InterleavedGradientNoise(gl_FragCoord.xy);
        float stepLength = cloudDist / (stepCount + 1);
        vec3 traceStep = localViewDir * stepLength;

        vec3 sampleOffset = worldPos + vec3(worldTime / 40.0, -cloudHeight, worldTime / 8.0);

        //float extinctionInv = rcp(CloudAbsorbF);
        // float VoL = dot(localSkyLightDirection, localViewDir);
        // float phase = DHG(VoL, -0.19, 0.824, 0.09);

        float shadowStepLen = 2.0;
        vec3 shadowStep = localSkyLightDirection * shadowStepLen;

        for (uint stepI = 0; stepI < stepCount; stepI++) {
            vec3 tracePos = cloudNear + traceStep * (stepI + dither);

            float sampleD = SampleCloudOctaves(tracePos + sampleOffset);

            float sampleLit = 1.0;
            for (int shadowI = 0; shadowI < shadowStepCount; shadowI++) {
                vec3 shadowTracePos = tracePos + shadowStep * (shadowI + dither);

                float shadowSampleD = SampleCloudOctaves(shadowTracePos + sampleOffset);

                float shadowY = shadowTracePos.y + sampleOffset.y;
                shadowSampleD *= step(0.0, shadowY) * step(shadowY, CloudHeight);

                sampleLit *= exp(shadowSampleD * CloudAbsorbF * -shadowStepLen);
            }

            //float fogDist = GetShapedFogDistance(tracePos);
            //sampleD *= 1.0 - GetFogFactor(fogDist, 0.65 * CloudFar, CloudFar, 1.0);

            float inRange = 1.0;//step(cloudDistNear + stepLength * (stepI + dither), far);

            vec3 stepAmbientF = mix(inRange * _airAmbientF, _cloudAmbient, sampleD);
            float stepScatterF = mix(inRange * _airScatterF, CloudScatterF, sampleD);
            float stepExtinctF = mix(inRange * _airExtinctF, CloudAbsorbF, sampleD);
            float stepPhase = mix(phaseAir, phaseCloud, sampleD);

            vec3 sampleLight = stepPhase * (sampleLit * skyLightColor) + stepAmbientF;
            vec4 scatterTransmit = ApplyScatteringTransmission(stepLength, sampleLight, stepScatterF, stepExtinctF);

            cloudScatter += scatterTransmit.rgb * cloudAbsorb;
            cloudAbsorb *= scatterTransmit.a;
        }

        if (farMax > cloudDistFar) {
            float stepLength = farMax - cloudDistFar;

            vec3 sampleLight = phaseAir * skyLightColor + _airAmbientF;
            vec4 scatterTransmit = ApplyScatteringTransmission(stepLength, sampleLight, _airScatterF, _airExtinctF);

            cloudScatter += scatterTransmit.rgb * cloudAbsorb;
            cloudAbsorb *= scatterTransmit.a;
        }
    }
    else {
        float stepLength = farMax;

        vec3 sampleLight = phaseAir * skyLightColor + _airAmbientF;
        vec4 scatterTransmit = ApplyScatteringTransmission(stepLength, sampleLight, _airScatterF, _airExtinctF);

        cloudScatter += scatterTransmit.rgb * cloudAbsorb;
        cloudAbsorb *= scatterTransmit.a;
    }

    return vec4(cloudScatter, cloudAbsorb);
}

float TraceCloudShadow(const in vec3 worldPos, const in vec3 localLightDir, const in int stepCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
    
    float cloudDistNear = min(length(cloudNear), far);
    float cloudDistFar = min(length(cloudFar), far);
    float cloudDist = cloudDistFar - cloudDistNear;
    float cloudAbsorb = 1.0;

    if (cloudDist > EPSILON) {
        float dither = InterleavedGradientNoise(gl_FragCoord.xy);
        float cloudStepLen = cloudDist / (stepCount + 1);
        vec3 cloudStep = localLightDir * cloudStepLen;

        vec3 sampleOffset = worldPos + vec3(worldTime / 40.0, -cloudHeight, worldTime / 8.0);

        for (uint stepI = 0; stepI < stepCount; stepI++) {
            vec3 tracePos = cloudNear + cloudStep * (stepI + dither);

            float sampleD = SampleCloudOctaves(tracePos + sampleOffset);

            float shadowY = tracePos.y + sampleOffset.y;
            sampleD *= step(0.0, shadowY) * step(shadowY, CloudHeight);

            float fogDist = GetShapedFogDistance(tracePos);
            sampleD *= 1.0 - GetFogFactor(fogDist, 0.65 * CloudFar, CloudFar, 1.0);

            float stepAbsorb = exp(cloudStepLen * sampleD * -CloudAbsorbF);

            cloudAbsorb *= stepAbsorb;
        }
    }

    return cloudAbsorb;
}
