//vec3 GetLpvSamplePos(const in vec3 voxelPos, const in vec3 geoNormal, const in vec3 texNormal, const in float offset) {
//    #if MATERIAL_NORMALS != 0
//        vec3 minPos = floor(voxelPos + offset * geoNormal);
//
//        vec3 offsetPos = voxelPos + offset * texNormal;
//
//        offsetPos = clamp(offsetPos, minPos, minPos + 1.0);
//
//        return offsetPos;
//    #else
//        // vec3 samplePos = voxelPos + 0.5 * geoNormal;
//        return voxelPos + offset * geoNormal;
//    #endif
//}

vec3 GetFloodFillSamplePos(const in vec3 voxelPos, const in vec3 geoNormal, const in vec3 texNormal) {
    return texNormal * 0.75 - geoNormal * 0.25 + voxelPos;
}

vec3 GetFloodFillSamplePos(const in vec3 voxelPos, const in vec3 normal) {
    return normal * 0.50 + voxelPos;
}

vec3 _SampleFloodFill(const in vec3 lpvPos, const in int frame) {
    vec3 texcoord = lpvPos / VoxelBufferSize;

    vec3 lpvSample = (frame % 2) == 0
        ? texture(texFloodFillA, texcoord).rgb
        : texture(texFloodFillB, texcoord).rgb;

//    vec3 lpvSample = (frame % 2) == 0
//        ? texelFetch(texFloodFillA, ivec3(floor(lpvPos)), 0).rgb
//        : texelFetch(texFloodFillB, ivec3(floor(lpvPos)), 0).rgb;

    return RGBToLinear(lpvSample);
}

vec3 SampleFloodFill(const in vec3 lpvPos) {
    vec3 lpvSample = _SampleFloodFill(lpvPos, frameCounter);
    return lpvSample;

//    vec3 hsv = RgbToHsv(lpvSample);
////    hsv.z = hsv.z * (LpvBlockRange/15.0);
//    hsv.z = hsv.z*hsv.z * 2.0;
//    vec3 rgb = HsvToRgb(hsv);
//
//    return rgb;
}

vec3 SampleFloodFill(const in vec3 lpvPos, const in float brightness) {
    vec3 lpvSample = _SampleFloodFill(lpvPos, frameCounter);

    vec3 hsv = RgbToHsv(lpvSample);
    hsv.z = brightness;
//    hsv.z = hsv.z*hsv.z*hsv.z * 3.0;

    vec3 rgb = HsvToRgb(hsv);

    return rgb;
}
