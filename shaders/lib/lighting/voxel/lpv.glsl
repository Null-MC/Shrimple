const ivec3 SceneLPVSize = ivec3(LPV_SIZE_XZ, LPV_SIZE_Y, LPV_SIZE_XZ);
const ivec3 SceneLPVCenter = SceneLPVSize / 2;

vec3 GetLPVPosition(const in vec3 position) {
    vec3 cameraOffset = fract(cameraPosition);
    return position + SceneLPVCenter + cameraOffset;
}

ivec3 GetLPVImgCoord(const in vec3 lpvPos) {
	return ivec3(lpvPos);
}

vec3 GetLPVTexCoord(const in vec3 lpvPos) {
	return lpvPos / SceneLPVSize;
}

float GetLpvFade(const in vec3 lpvPos) {
    const vec3 lpvSizeInner = SceneLPVCenter - LPV_PADDING;

    vec3 lpvDist = abs(lpvPos - SceneLPVCenter - fract(cameraPosition));
    vec3 lpvDistF = max(lpvDist - lpvSizeInner, vec3(0.0));
    return 1.0 - maxOf((lpvDistF / LPV_PADDING));
}
