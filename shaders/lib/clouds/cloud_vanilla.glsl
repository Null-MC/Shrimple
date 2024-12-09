vec3 GetCloudTexcoord(in vec3 worldPos, const in vec2 cloudOffset) {
    vec3 cloudTexcoord = worldPos;
    cloudTexcoord.y = (cloudTexcoord.y - cloudHeight) / 4.5;
    cloudTexcoord.xz = ((cloudTexcoord.xz + vec2(0.0, 4.0)) / 12.0 - cloudOffset) / 256.0;

    return mod(cloudTexcoord, 1.0);
}
