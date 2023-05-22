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
