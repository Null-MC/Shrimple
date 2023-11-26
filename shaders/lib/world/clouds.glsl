#define CLOUD_STEPS 24
#define CLOUD_SHADOW_STEPS 8
#define CLOUD_REFLECT_STEPS 12
#define CLOUD_REFLECT_SHADOW_STEPS 4
//#define CLOUD_CUBED

const int CloudOctaves = 3;
const float CloudAmbientF = 0.02;
const float CloudScatterF = mix(2.40, 1.20, rainStrength);
const float CloudAbsorbF  = mix(0.36, 0.96, rainStrength);
const float CloudFar = 800.0;//mix(800.0, far, rainStrength);
const float CloudHeight = 128.0;
const float CloudSize = 16.0;


float SampleCloudOctaves(in vec3 worldPos) {
    float sampleD = 0.0;

    for (int octave = 0; octave < CloudOctaves; octave++) {
        float scale = exp2(CloudOctaves + 2 - octave);

        vec3 testPos = worldPos / CloudSize;

        #ifdef CLOUD_CUBED
            testPos = floor(testPos);
        #endif

        testPos /= scale;

        float sampleF = textureLod(texClouds, testPos.xzy * 0.25 * (octave+1), 0).r;
        sampleD += pow(sampleF, 3.0 - 2.0 * rainStrength) * rcp(exp2(octave));
    }

    const float sampleMax = rcp(1.0 - rcp(exp2(CloudOctaves)));
    sampleD *= sampleMax;

    float z = saturate(worldPos.y / CloudHeight);
    sampleD *= sqrt(z - z*z) * 2.0;

    float threshold = mix(0.36, 0.74, rainStrength);
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
            cloudFar = localViewDir * CloudFar;
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
        cloudDist = min(cloudDistFar, min(viewDist, CloudFar)) - cloudDistNear;

    float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0 + 0.02;

    float cloudAbsorb = 1.0;
    vec3 cloudScatter = vec3(0.0);
    float _airScatterF = AirScatterF * eyeSkyLightF;

    float VoL = dot(localSkyLightDirection, localViewDir);
    float phaseCloud = DHG(VoL, -0.19, 0.824, 0.09);
    const float phaseAir = 0.25;

    float farMax = min(viewDist, far);

    if (cloudDist > EPSILON) {
        if (cloudDistNear > 0.0) {
            float stepLength = min(cloudDistNear, farMax);

            vec3 inScattering = _airScatterF * (phaseAir + AirAmbientF) * WorldSkyLightColor;
            float sampleTransmittance = exp(-AirExtinctF * stepLength);

            vec3 scatteringIntegral = inScattering - inScattering * sampleTransmittance;
            scatteringIntegral /= AirExtinctF;

            cloudScatter += scatteringIntegral * cloudAbsorb;
            cloudAbsorb *= sampleTransmittance;
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

            float fogDist = GetVanillaFogDistance(tracePos);
            sampleD *= 1.0 - GetFogFactor(fogDist, 0.65 * CloudFar, CloudFar, 1.0);

            float inRange = step(cloudDistNear + stepLength * (stepI + dither), far);

            float stepScatterF = mix(inRange * _airScatterF, CloudScatterF, sampleD);
            float stepExtinctF = mix(inRange * AirExtinctF, CloudAbsorbF, sampleD);
            float phase = mix(phaseAir, phaseCloud, sampleD);

            vec3 inScattering = stepScatterF * (sampleLit * phase + CloudAmbientF) * WorldSkyLightColor;
            float sampleTransmittance = exp(-stepExtinctF * stepLength);

            vec3 scatteringIntegral = inScattering - inScattering * sampleTransmittance;
            scatteringIntegral /= max(stepExtinctF, EPSILON);

            cloudScatter += scatteringIntegral * cloudAbsorb;
            cloudAbsorb *= sampleTransmittance;
        }

        if (farMax > cloudDistFar) {
            float stepLength = farMax - cloudDistFar;

            vec3 inScattering = _airScatterF * (phaseAir + AirAmbientF) * WorldSkyLightColor;
            float sampleTransmittance = exp(-AirExtinctF * stepLength);

            vec3 scatteringIntegral = inScattering - inScattering * sampleTransmittance;
            scatteringIntegral /= AirExtinctF;

            cloudScatter += scatteringIntegral * cloudAbsorb;
            cloudAbsorb *= sampleTransmittance;
        }
    }
    else {
        float stepLength = farMax;

        vec3 inScattering = _airScatterF * (phaseAir + AirAmbientF) * WorldSkyLightColor;
        float sampleTransmittance = exp(-AirExtinctF * stepLength);

        vec3 scatteringIntegral = inScattering - inScattering * sampleTransmittance;
        scatteringIntegral /= AirExtinctF;

        cloudScatter += scatteringIntegral * cloudAbsorb;
        cloudAbsorb *= sampleTransmittance;
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

            float fogDist = GetVanillaFogDistance(tracePos);
            sampleD *= 1.0 - GetFogFactor(fogDist, 0.65 * CloudFar, CloudFar, 1.0);

            float stepAbsorb = exp(cloudStepLen * sampleD * -CloudAbsorbF);

            cloudAbsorb *= stepAbsorb;
        }
    }

    return cloudAbsorb;
}
