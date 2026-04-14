vec3 GetFloodFillSamplePos(const in vec3 voxelPos, const in vec3 geoNormal, const in vec3 texNormal) {
    return texNormal * 0.75 - geoNormal * 0.25 + voxelPos;
}

vec3 GetFloodFillSamplePos(const in vec3 voxelPos, const in vec3 normal) {
    return normal * 0.50 + voxelPos;
}

vec4 _SampleFloodFill(const in vec3 lpvPos, const in int frame) {
    vec3 texcoord = lpvPos / VoxelBufferSize;

    vec4 lpvSample = (frame % 2) == 0
        ? texture(texFloodFillA, texcoord).rgba
        : texture(texFloodFillB, texcoord).rgba;

    lpvSample.rgb = RGBToLinear(lpvSample.rgb);
    return lpvSample;
}

vec3 SampleFloodFill(const in vec3 lpvPos) {
    vec3 lpvSample = _SampleFloodFill(lpvPos, frameCounter).rgb;
    return lpvSample * 6.0;
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
