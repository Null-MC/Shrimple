float TraceCloudShadow(const in vec3 worldPos, const in vec3 localLightDir, const in int stepCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
    
    float cloudDistNear = length(cloudNear);
    float cloudDistFar = length(cloudFar);
    float cloudDist = cloudDistFar - cloudDistNear;

    if (cloudDist < EPSILON) return 1.0;
    cloudDist = min(cloudDist, 128.0);

    float dither = GetCloudDither();
    float cloudAlt = GetCloudAltitude();
    vec2 cloudOffset = GetCloudOffset();
    //vec3 camOffset = GetCloudCameraOffset();

    float cloudStepLen = cloudDist / stepCount;
    vec3 cloudStep = localLightDir * cloudStepLen;

    float cloudAbsorb = 1.0;
    for (uint i = 0u; i < stepCount; i++) {
        // vec3 traceLocalPos = worldPos + cloudNear - cameraPosition;
        // traceLocalPos += cloudStep * (i + dither);

        #if WORLD_CURVE_RADIUS > 0
            vec3 traceLocalPos = worldPos + cloudNear - cameraPosition;
            traceLocalPos += cloudStep * (i + dither);

            float traceAltitude = GetWorldAltitude(traceLocalPos);
            vec3 traceWorldPos = GetWorldCurvedPosition(traceLocalPos);
            traceWorldPos.xz += cameraPosition.xz;
        #else
            vec3 traceWorldPos = worldPos + cloudNear;
            traceWorldPos += cloudStep * (i + dither);

            //vec3 traceWorldPos = traceLocalPos + cameraPosition;
            //float traceAltitude = traceWorldPos.y;
        #endif

        float sampleD = SampleClouds(traceWorldPos, cloudOffset) * CloudDensityF;

        float traceStepLen = cloudStepLen;
        // if (i == stepCount) traceStepLen *= (1.0 - dither);
        // else if (i == 0) traceStepLen *= dither;

        cloudAbsorb *= exp(traceStepLen * sampleD * -CloudAbsorbF);
        // cloudAbsorb *= 1.0 - sampleD;
    }

    // return cloudAbsorb * 0.74 + 0.26;
    return cloudAbsorb;
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

float TraceCloudDensity(const in vec3 worldPos, const in vec3 localLightDir, const in int sampleCount) {
    vec3 cloudNear, cloudFar;
    GetCloudNearFar(worldPos, localLightDir, cloudNear, cloudFar);
    float cloudDist = length(cloudFar) - length(cloudNear);
    float cloudDensity = 0.0;

    float sampleCountInv = rcp(sampleCount);

    if (cloudDist > EPSILON) {
        float dither = 0.0;//GetCloudDither();
    
        float cloudStepLen = cloudDist * sampleCountInv;
        vec3 cloudStep = localLightDir * cloudStepLen;

        float cloudAlt = GetCloudAltitude();
        vec2 cloudOffset = GetCloudOffset();
        //vec3 camOffset = GetCloudCameraOffset();
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

            cloudDensity += SampleClouds(traceWorldPos, cloudOffset);
        }
    }

    return cloudDensity * sampleCountInv;
}
