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
