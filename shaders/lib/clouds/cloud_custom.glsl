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
    //float _str = pow(skyRainStrength, 0.333);
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
        // sampleD += pow(sampleF, 2.0 - 0.5*_str) * rcp(exp2(octave));
        sampleD += pow2(sampleF) * rcp(exp2(octave));
    }

    const float sampleMaxInv = rcp(1.0 - rcp(exp2(octaveCount)));
    sampleD = saturate(sampleD * sampleMaxInv * sampleDensity);

    float cloudAlt = GetCloudAltitude();
    float z = saturate((altitude - cloudAlt) / CloudHeight);
    sampleD *= sqrt(z - z*z) * 2.0;

    const float CloudCoverMinF = SKY_CLOUD_COVER_MIN * 0.01;
    const float CloudCoverMin = 1.0 - sqrt(CloudCoverMinF);

    // float threshold = mix(CloudCoverMin, 0.0, _str);
    float threshold = CloudCoverMin * (1.0 - 0.7*skyRainStrength);
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
