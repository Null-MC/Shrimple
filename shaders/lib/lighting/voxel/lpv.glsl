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

vec3 getCameraViewDir(const in mat4 matModelView) {
    return vec3(matModelView[0].z, matModelView[1].z, matModelView[2].z);
}

vec3 GetLpvCenter(const in vec3 viewPos, const in vec3 viewDir) {
    ivec3 offset = ivec3(floor(viewDir * SceneLPVSize * 0.4));
    return (SceneLPVCenter + offset) + fract(viewPos);
}

vec3 GetLPVPosition(const in vec3 position) {
    vec3 viewDir = getCameraViewDir(gbufferModelView);
    return position + GetLpvCenter(cameraPosition, viewDir);
}

ivec3 GetLPVImgCoord(const in vec3 lpvPos) {
	return ivec3(lpvPos);
}

vec3 GetLPVTexCoord(const in vec3 lpvPos) {
	return clamp(lpvPos, vec3(0.5), vec3(SceneLPVSize - 0.5)) / SceneLPVSize;
}

float GetLpvFade(const in vec3 lpvPos) {
    const vec3 lpvSizeInner = SceneLPVCenter - LPV_PADDING;

    vec3 viewDir = getCameraViewDir(gbufferModelView);
    vec3 lpvDist = abs(lpvPos - SceneLPVCenter);
    vec3 lpvDistF = max(lpvDist - lpvSizeInner, vec3(0.0));
    return saturate(1.0 - maxOf((lpvDistF / LPV_PADDING)));
}

// #if defined RENDER_VERTEX || defined RENDER_SHADOW || defined RENDER_COMPOSITE_LPV
    ivec3 GetLPVFrameOffset() {
        vec3 viewDir = getCameraViewDir(gbufferModelView);
        vec3 posNow = GetLpvCenter(cameraPosition, viewDir);

        //vec3 posLast = GetLPVPosition(previousCameraPosition - cameraPosition);
        vec3 viewDirPrev = getCameraViewDir(gbufferPreviousModelView);
        vec3 posPrev = GetLpvCenter(previousCameraPosition, viewDirPrev);

        //vec3 posLast = (SceneLPVCenter + offsetPrev) + fract(previousCameraPosition);
        vec3 posLast = posNow + (previousCameraPosition - cameraPosition) - (posPrev - posNow);

        return GetLPVImgCoord(posNow) - GetLPVImgCoord(posLast);
    }
// #endif
