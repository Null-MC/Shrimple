const vec2 LpvBlockSkyRange = vec2(LPV_BLOCKLIGHT_SCALE, LPV_SKYLIGHT_RANGE);


float GetLpvFade(const in vec3 lpvPos) {
    const vec3 lpvSizeInner = VoxelBufferCenter - LPV_PADDING;

    vec3 viewDir = gbufferModelViewInverse[2].xyz;
    vec3 lpvDist = abs(lpvPos - VoxelBufferCenter);
    vec3 lpvDistF = max(lpvDist - lpvSizeInner, vec3(0.0));
    return saturate(1.0 - maxOf((lpvDistF / LPV_PADDING)));
}

ivec3 GetVoxelFrameOffset() {
    vec3 viewDir = gbufferModelViewInverse[2].xyz;
    vec3 posNow = GetVoxelCenter(cameraPosition, viewDir);

    vec3 viewDirPrev = vec3(gbufferPreviousModelView[0].z, gbufferPreviousModelView[1].z, gbufferPreviousModelView[2].z);
    vec3 posPrev = GetVoxelCenter(previousCameraPosition, viewDirPrev);

    vec3 posLast = posNow + (previousCameraPosition - cameraPosition) - (posPrev - posNow);

    return ivec3(posNow) - ivec3(posLast);
}
