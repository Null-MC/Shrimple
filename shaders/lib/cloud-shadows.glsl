vec2 GetCloudOffset() {
    vec2 cloudOffset = vec2(cloudTime/12.0, 0.33);

    cloudOffset = mod(cloudOffset, vec2(256.0));
//    cloudOffset = mod(cloudOffset + 256.0, vec2(256.0));

    return cloudOffset;
}

vec3 GetCloudCameraOffset() {
    const float irisCamWrap = 1024.0;

    vec3 camOffset = (mod(cameraPosition, irisCamWrap) + min(sign(cameraPosition), 0.0) * irisCamWrap) - (mod(eyePosition, irisCamWrap) + min(sign(eyePosition), 0.0) * irisCamWrap);
    camOffset.xz -= ivec2(greaterThan(abs(camOffset.xz), vec2(10.0))) * irisCamWrap; // eyePosition precission issues can cause this to be wrong, since the camera is usally not farther than 5 blocks, this should be fine
    return camOffset;
}

vec3 GetCloudShadowTexcoord(const in vec3 localPos, const in vec3 localDir, const in vec2 cloudOffset) {
    vec3 worldPos = localPos + cameraPosition;// + GetCloudCameraOffset();

    float dist = (cloudHeight - worldPos.y) / localDir.y;
    worldPos.xz += localDir.xz * dist;

    worldPos -= cameraPosition;

    worldPos.xz += mod(eyePosition.xz, 3072.0); // 3072 is one full cloud pattern
    worldPos.y += eyePosition.y;

    vec2 texcoord = ((worldPos.xz + vec2(0.0, 3.96)) / 12.0 + cloudOffset) / 256.0;

    return vec3(texcoord, dist);
}

float SampleCloudShadow(const in vec3 localPos, const in vec3 localLightDir) {
    vec2 cloudOffset = GetCloudOffset();
    vec3 cloudTexcoord = GetCloudShadowTexcoord(localPos, localLightDir, cloudOffset);
    float cloudShadow = texture(texCloudShadow, fract(cloudTexcoord.xy)).r;
    cloudShadow = _pow2(cloudShadow);

    // TODO: fade away
    float upF = smoothstep(0.06, 0.16, localLightDir.y);
    cloudShadow = mix(1.0, cloudShadow, upF);

    return cloudShadow * 0.7 + 0.3;
}
