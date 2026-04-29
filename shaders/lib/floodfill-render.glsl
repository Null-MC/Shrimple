vec3 GetFloodFillSamplePos(const in vec3 voxelPos, const in vec3 geoNormal, const in vec3 texNormal) {
    return texNormal * 0.75 - geoNormal * 0.25 + voxelPos;
}

vec3 GetFloodFillSamplePos(const in vec3 voxelPos, const in vec3 normal) {
    return normal * 0.50 + voxelPos;
}

vec4 _SampleFloodFill(const in vec3 lpvPos, const in int frame) {
    vec3 texcoord = lpvPos / VoxelBufferSize;
    texcoord.z *= 0.5;
    if (frame % 2 == 1) texcoord.z += 0.5;

    vec4 lpvSample = texture(texFloodFill, texcoord).rgba;
    lpvSample.rgb = RGBToLinear(lpvSample.rgb);
    return lpvSample;
}

vec3 SampleFloodFill(const in vec3 lpvPos) {
    vec3 lpvSample = _SampleFloodFill(lpvPos, frameCounter).rgb;
    return lpvSample * 24.0;
}

vec3 SampleFloodFill(const in vec3 lpvPos, const in float brightness) {
    vec3 lpvSample = _SampleFloodFill(lpvPos, frameCounter).rgb;

    float lum_now = luminance(lpvSample);
    if (lum_now < EPSILON) return lpvSample;
    return lpvSample * (brightness / lum_now);
}

float SampleFloodFill_SkyExposure(const in vec3 lpvPos) {
    return 1.0 - _SampleFloodFill(lpvPos, frameCounter).a;
}
