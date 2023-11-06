#if LPV_SIZE == 3
    const ivec3 SceneLPVSize = ivec3(256);
#elif LPV_SIZE == 2
    const ivec3 SceneLPVSize = ivec3(128);
#elif LPV_SIZE == 1
    const ivec3 SceneLPVSize = ivec3(64);
#else
    const ivec3 SceneLPVSize = ivec3(0);
#endif

const ivec3 SceneLPVCenter = SceneLPVSize / 2;

vec3 GetLPVPosition(const in vec3 position) {
    vec3 cameraOffset = fract(cameraPosition);
    return position + SceneLPVCenter + cameraOffset;
}

ivec3 GetLPVImgCoord(const in vec3 lpvPos) {
	return ivec3(lpvPos);
}

vec3 GetLPVTexCoord(const in vec3 lpvPos) {
	return clamp(lpvPos, vec3(0.5), vec3(SceneLPVSize - 0.5)) / SceneLPVSize;
}

float GetLpvFade(const in vec3 lpvPos) {
    const vec3 lpvSizeInner = SceneLPVCenter - LPV_PADDING;

    vec3 lpvDist = abs(lpvPos - SceneLPVCenter - fract(cameraPosition));
    vec3 lpvDistF = max(lpvDist - lpvSizeInner, vec3(0.0));
    return 1.0;//saturate(1.0 - maxOf((lpvDistF / LPV_PADDING)));
}

ivec3 GetLPVFrameOffset() {
    vec3 posNow = GetLPVPosition(vec3(0.0));
    vec3 posLast = GetLPVPosition(previousCameraPosition - cameraPosition);
    return GetLPVImgCoord(posNow) - GetLPVImgCoord(posLast);
}
