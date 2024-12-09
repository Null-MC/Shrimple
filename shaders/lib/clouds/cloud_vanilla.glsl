// vec2 GetCloudOffset() {
//     vec2 cloudOffset = vec2(-cloudTime/12.0, 0.33);
//     cloudOffset = mod(cloudOffset, vec2(256.0));
//     cloudOffset = mod(cloudOffset + 256.0, vec2(256.0));

//     return cloudOffset;
// }

// vec3 GetCloudCameraOffset() {
//     const float irisCamWrap = 1024.0;

//     vec3 camOffset = (mod(cameraPosition.xyz, irisCamWrap) + min(sign(cameraPosition.xyz), 0.0) * irisCamWrap) - (mod(eyePosition.xyz, irisCamWrap) + min(sign(eyePosition.xyz), 0.0) * irisCamWrap);
//     camOffset.xz -= ivec2(greaterThan(abs(camOffset.xz), vec2(10.0))) * irisCamWrap; // eyePosition precission issues can cause this to be wrong, since the camera is usally not farther than 5 blocks, this should be fine
//     return camOffset;
// }

vec3 GetCloudTexcoord(in vec3 worldPos, const in vec2 cloudOffset) {
    // worldPos.xz += mod(eyePosition.xz, 3072.0); // 3072 is one full cloud pattern
    // worldPos.y += eyePosition.y;

    vec3 cloudTexcoord = worldPos;
    cloudTexcoord.y = (cloudTexcoord.y - cloudHeight) / 4.5;
    cloudTexcoord.xz = ((cloudTexcoord.xz + vec2(0.0, 4.0)) / 12.0 - cloudOffset) / 256.0;

    return mod(cloudTexcoord, 1.0);
}
