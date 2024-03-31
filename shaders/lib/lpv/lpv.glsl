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
const float LpvFrustumOffsetF = LPV_FRUSTUM_OFFSET * 0.01;

vec3 Lpv_RgbToHsv(const in vec3 lightColor, const in float lightRange) {
    vec3 lightValue = RgbToHsv(lightColor);
    lightValue.b = (lightRange * DynamicLightRangeF) / LPV_BLOCKLIGHT_SCALE;
    return lightValue;
}

vec3 GetLpvCenter(const in vec3 viewPos, const in vec3 viewDir) {
    ivec3 offset = ivec3(floor(viewDir * SceneLPVSize * LpvFrustumOffsetF));
    return (SceneLPVCenter + offset) + fract(viewPos);
}

vec3 GetLPVPosition(const in vec3 position) {
    vec3 viewDir = gbufferModelViewInverse[2].xyz;
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

    vec3 viewDir = gbufferModelViewInverse[2].xyz;
    vec3 lpvDist = abs(lpvPos - SceneLPVCenter);
    vec3 lpvDistF = max(lpvDist - lpvSizeInner, vec3(0.0));
    return saturate(1.0 - maxOf((lpvDistF / LPV_PADDING)));
}

// #if defined RENDER_VERTEX || defined RENDER_SHADOW || defined RENDER_COMPOSITE_LPV
    ivec3 GetLPVFrameOffset() {
        vec3 viewDir = gbufferModelViewInverse[2].xyz;
        vec3 posNow = GetLpvCenter(cameraPosition, viewDir);

        //vec3 posLast = GetLPVPosition(previousCameraPosition - cameraPosition);
        // vec3 viewDirPrev = getCameraViewDir(gbufferPreviousModelView);
        vec3 viewDirPrev = vec3(gbufferPreviousModelView[0].z, gbufferPreviousModelView[1].z, gbufferPreviousModelView[2].z);
        vec3 posPrev = GetLpvCenter(previousCameraPosition, viewDirPrev);

        //vec3 posLast = (SceneLPVCenter + offsetPrev) + fract(previousCameraPosition);
        vec3 posLast = posNow + (previousCameraPosition - cameraPosition) - (posPrev - posNow);

        return GetLPVImgCoord(posNow) - GetLPVImgCoord(posLast);
    }
// #endif
