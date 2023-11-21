#define CLOUD_STEPS 16
#define CLOUD_SHADOW_STEPS 4

const int CloudOctaves = 3;
const float CloudScatterF = mix(0.080, 0.015, rainStrength);
const float CloudAbsorbF = mix(0.12, 0.15, rainStrength);
const float CloudFar = 800.0;
const float CloudHeight = 64.0;
const float CloudSize = 8.0;



// float CloudNoise(const in vec3 worldPos) {
//     ivec3 pos = ivec3(worldPos);
//     vec3 f = worldPos - pos;
//     f = f*f*(3.0-2.0*f);

//     float x1_y1_z1 = hash13(pos + ivec3(0, 0, 0));
//     float x2_y1_z1 = hash13(pos + ivec3(1, 0, 0));
//     float x1_y2_z1 = hash13(pos + ivec3(0, 1, 0));
//     float x2_y2_z1 = hash13(pos + ivec3(1, 1, 0));
//     float x1_y1_z2 = hash13(pos + ivec3(0, 0, 1));
//     float x2_y1_z2 = hash13(pos + ivec3(1, 0, 1));
//     float x1_y2_z2 = hash13(pos + ivec3(0, 1, 1));
//     float x2_y2_z2 = hash13(pos + ivec3(1, 1, 1));

//     float x_y1_z1 = mix(x1_y1_z1, x2_y1_z1, f.x);
//     float x_y2_z1 = mix(x1_y2_z1, x2_y2_z1, f.x);
//     float x_y1_z2 = mix(x1_y1_z2, x2_y1_z2, f.x);
//     float x_y2_z2 = mix(x1_y2_z2, x2_y2_z2, f.x);

//     float xy_z1 = mix(x_y1_z1, x_y2_z1, f.y);
//     float xy_z2 = mix(x_y1_z2, x_y2_z2, f.y);

//     return mix(xy_z1, xy_z2, f.z);
// }

float SampleCloudOctaves(const in vec3 tracePos) {
    float sampleD = 0.0;

    for (int octave = 0; octave < CloudOctaves; octave++) {
        float scale = exp2(CloudOctaves + 2 - octave);

        //vec3 testPos = floor(tracePos / CloudSize) / scale;
        vec3 testPos = tracePos / CloudSize / scale;
        //float sampleF = CloudNoise(testPos * (octave+1));
        float sampleF = textureLod(texClouds, testPos.xzy / 4.0 * (octave+1), 0).r;
        sampleD += _pow2(sampleF) * rcp(exp2(octave));
    }

    return sampleD;
}

vec2 SampleClouds2(const in vec3 cameraPosition, const in vec3 localViewDir, const in float viewDist, const in float depthOpaque) {
    float cloudOffset = cloudHeight - cameraPosition.y;// + 0.33;
    vec3 cloudPosHigh = vec3(localViewDir.xz * ((cloudOffset + CloudHeight) / localViewDir.y), cloudOffset + CloudHeight).xzy;
    vec3 cloudPosLow = vec3(localViewDir.xz * ((cloudOffset) / localViewDir.y), cloudOffset).xzy;

    vec3 cloudNear = vec3(0.0);
    vec3 cloudFar = vec3(0.0);
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

        // cloudFar = localViewDir.y >= 0.0
        //     ? cloudPosHigh : cloudPosLow;
    }
    
    float cloudDistNear = length(cloudNear);
    float cloudDistFar = length(cloudFar);
    float cloudDist = 0.0;

    //float viewDist = ?;
    if (cloudDistNear < viewDist || depthOpaque >= 0.9999)
        cloudDist = min(cloudDistFar, min(viewDist, CloudFar)) - cloudDistNear;

    float cloudAbsorb = 1.0;
    float cloudScatter = 0.0;

    if (cloudDist > EPSILON) {
        float dither = InterleavedGradientNoise(gl_FragCoord.xy);
        float cloudStepLen = cloudDist / (CLOUD_STEPS + 1);
        vec3 cloudStep = localViewDir * cloudStepLen;

        vec3 sampleOffset = cameraPosition + vec3(worldTime / 100.0, -cloudHeight, worldTime / 20.0);

        float shadowStepLen = 8.0;
        vec3 shadowStep = localSkyLightDirection * shadowStepLen;

        for (uint stepI = CLOUD_STEPS-1; stepI >= 0; stepI--) {
            vec3 tracePos = cloudNear + cloudStep * (stepI + dither);

            float sampleD = SampleCloudOctaves(tracePos + sampleOffset);

            float sampleLit = 1.0;
            for (int shadowI = 0; shadowI < CLOUD_SHADOW_STEPS; shadowI++) {
                vec3 shadowTracePos = tracePos + shadowStep * (shadowI + dither);

                float shadowSampleD = SampleCloudOctaves(shadowTracePos + sampleOffset);

                float shadowY = shadowTracePos.y + sampleOffset.y;
                shadowSampleD *= step(0.0, shadowY) * step(shadowY, CloudHeight);

                sampleLit *= exp(shadowSampleD * CloudAbsorbF * -3.0);
            }

            //sampleLit = max(1.0 - sampleLit, 0.0);

            //sampleD = 1.0 - sampleD;
            //sampleD = _pow3(sampleD);
            sampleD = smoothstep(mix(0.4, 0.1, rainStrength), 1.0, sampleD);
            //sampleD = step(0.9, sampleD);

            float fogDist = GetVanillaFogDistance(tracePos);
            sampleD *= 1.0 - GetFogFactor(fogDist, 0.8 * CloudFar, CloudFar, 1.0);

            float stepAbsorb = exp(cloudStepLen * sampleD * -CloudAbsorbF);

            cloudScatter = cloudScatter * stepAbsorb + CloudScatterF * cloudStepLen * sampleD * sampleLit;
            cloudAbsorb *= stepAbsorb;
        }

        //final.rgb = final.rgb * cloudAbsorb + cloudScatter * WorldSkyLightColor;
    }

    return vec2(cloudAbsorb, cloudScatter);
}