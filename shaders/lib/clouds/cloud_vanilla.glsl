vec2 GetCloudOffset() {
    vec2 cloudOffset = vec2(-cloudTime/12.0, 0.33);
    cloudOffset = mod(cloudOffset, vec2(256.0));
    cloudOffset = mod(cloudOffset + 256.0, vec2(256.0));

    return cloudOffset;
}

vec3 GetCloudCameraOffset() {
    const float irisCamWrap = 1024.0;

    vec3 camOffset = (mod(cameraPosition.xyz, irisCamWrap) + min(sign(cameraPosition.xyz), 0.0) * irisCamWrap) - (mod(eyePosition.xyz, irisCamWrap) + min(sign(eyePosition.xyz), 0.0) * irisCamWrap);
    camOffset.xz -= ivec2(greaterThan(abs(camOffset.xz), vec2(10.0))) * irisCamWrap; // eyePosition precission issues can cause this to be wrong, since the camera is usally not farther than 5 blocks, this should be fine
    return camOffset;
}

// vec3 GetCloudShadowPosition(in vec3 worldPos, const in vec3 localDir, const in vec2 cloudOffset) {
//     worldPos.xz += mod(eyePosition.xz, 3072.0); // 3072 is one full cloud pattern
//     worldPos.y += eyePosition.y;

//     float cloudHeightDifference = cloudHeight - worldPos.y;

//     vec3 cloudTexPos;
//     cloudTexPos.xy = worldPos.xz + localDir.xz / localDir.y * cloudHeightDifference;
//     cloudTexPos.xy = ((cloudTexPos.xy + vec2(0.0, 4.0)) / 12.0 - cloudOffset.xy) / 256.0;
//     cloudTexPos.z = cloudHeightDifference;
//     return cloudTexPos;
// }

// #ifndef RENDER_VERTEX
//     float SampleClouds(const in vec3 localPos, const in vec3 localDir, const in vec2 cloudOffset, const in vec3 camOffset, const in float roughness) {
//         const int maxLod = int(log2(256));

//         vec3 vertexWorldPos = localPos + camOffset;
//         vec3 cloudTexPos = GetCloudShadowPosition(vertexWorldPos, localDir, cloudOffset);
//         return textureLod(TEX_CLOUDS_VANILLA, cloudTexPos.xy, roughness * maxLod).a;
//     }
// #endif
