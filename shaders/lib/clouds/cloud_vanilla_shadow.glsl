// float SampleCloudShadow(const in vec3 localPos, const in vec3 localDir, const in vec2 cloudOffset, const in vec3 camOffset) {
// 	vec3 vertexWorldPos = localPos + camOffset;
//     vertexWorldPos.xz += mod(eyePosition.xz, 3072.0); // 3072 is one full cloud pattern
//     vertexWorldPos.y += eyePosition.y;

// 	float cloudHeightDifference = cloudHeight - vertexWorldPos.y;

//     float cloudF = SampleClouds(localPos, localDir, cloudOffset, camOffset, 0.0);
//     //cloudF = 1.0 - 0.5 * cloudF;

//     //float cloudShadow = (1.0 - Shadow_CloudBrightnessF) * min(cloudF, 1.0);

//     //return 1.0 - cloudShadow;
//     return 1.0 - cloudF;
// }

vec3 GetCloudShadowTexcoord(in vec3 worldPos, const in vec3 localDir, const in vec2 cloudOffset) {
    worldPos.xz += mod(eyePosition.xz, 3072.0); // 3072 is one full cloud pattern
    worldPos.y += eyePosition.y;

    float dist = (cloudHeight - worldPos.y) / localDir.y;
    worldPos.xz = localDir.xz * dist + worldPos.xz;

    vec2 cloudTexcoord;
    cloudTexcoord = worldPos.xz;
    cloudTexcoord = ((cloudTexcoord + vec2(0.0, 4.0)) / 12.0 - cloudOffset.xy) / 256.0;

    return vec3(cloudTexcoord, dist);
}

#ifndef RENDER_VERTEX
    float SampleCloudShadow(const in vec3 localPos, const in vec3 localDir, const in vec2 cloudOffset, const in vec3 camOffset, const in float blur) {
        const int maxLod = int(log2(256));

        vec3 vertexWorldPos = localPos + camOffset;
        vec3 cloudTexcoord = GetCloudShadowTexcoord(vertexWorldPos, localDir, cloudOffset);
        float cloudF = textureLod(TEX_CLOUDS_VANILLA, cloudTexcoord.xy, blur * maxLod).a;

        cloudF *= 1.0 - smoothstep(0.8*far, 3.0 * far, cloudTexcoord.z);

        cloudF *= step(0.0, localDir.y);

        return 1.0 - 0.7 * cloudF;
    }
#endif
