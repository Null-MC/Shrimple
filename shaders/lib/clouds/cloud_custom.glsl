const float CloudCoverMinF = 1.0 - SKY_CLOUD_COVER_MIN * 0.01;
const float CloudCoverMaxF = 1.0 - SKY_CLOUD_COVER_MAX * 0.01;

float GetCloudDither() {
    #ifndef RENDER_FRAG
        return 0.0;
    #elif defined EFFECT_TAA_ENABLED
        return InterleavedGradientNoiseTime();
    #else
        return InterleavedGradientNoise();
    #endif
}

float SampleClouds(const in vec3 worldPos, const in vec2 cloudOffset) {
    vec3 cloudPos = worldPos;
    cloudPos.y -= GetCloudAltitude();
    cloudPos /= CloudSize;

    vec3 texcoord = cloudPos.xzy - vec3(cloudOffset, 0.0);

    const ivec3 CloudTexSize = ivec3(256, 256, 16);
    ivec3 uv = ivec3(texcoord) % CloudTexSize;

    float cloudF = texelFetch(TEX_CLOUDS, uv, 0).r;

    cloudF *= step(mod(cloudPos.y, 4.0), 1.0);

    cloudF *= step(0.01, cloudPos.y);
    cloudF *= step(cloudPos.y, CloudHeight - 0.01);

    // float middle;
    // middle = step(1.0, cloudPos.y);
    // middle *= step(cloudPos.y, 7.0);
    // cloudF *= 1.0 - middle;

    // float threshold = skyRainStrength * 0.6 + 0.2;
    // float threshold = mix(CloudCoverMinF, CloudCoverMaxF, skyRainStrength);
    float threshold = 1.0 - mix(0.28, 0.52, pow(skyRainStrength, 0.75));
    // return step(threshold, cloudF);
    return smoothstep(threshold, threshold + 0.02, cloudF);
    // return step(threshold, cloudF);
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
        worldCenter.y = -World_CurveRadius;

        float radiusNear = World_CurveRadius + cloudAlt;
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
        float heightScaled = CloudSize * CloudHeight;
        vec3 cloudPosHigh = vec3(localViewDir.xz * ((cloudOffset + heightScaled) / localViewDir.y), cloudOffset + heightScaled).xzy;
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
