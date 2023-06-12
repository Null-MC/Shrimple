const ivec3 VoxelGridSize = ivec3(LIGHT_SIZE_XZ, LIGHT_SIZE_Y, LIGHT_SIZE_XZ);
const ivec3 VoxelBlockSize = VoxelGridSize * LIGHT_BIN_SIZE;
const ivec3 VoxelBlockCenter = VoxelBlockSize / 2;


vec3 GetVoxelBlockPosition(const in vec3 position) {
    vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
    return position + VoxelBlockCenter + cameraOffset;
}

#if defined RENDER_GBUFFERS || defined RENDER_DEFERRED || defined RENDER_COMPOSITE || defined RENDER_BEGIN_LPV
    vec3 GetPreviousVoxelBlockPosition(const in vec3 position) {
        vec3 cameraOffset = fract(previousCameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
        return position + VoxelBlockCenter + cameraOffset;
    }
#endif

ivec3 GetVoxelGridCell(const in vec3 gridPos) {
    return ivec3(floor(gridPos / LIGHT_BIN_SIZE + EPSILON));
}

bool GetVoxelGridCell(const in vec3 gridPos, out ivec3 gridCell, out ivec3 blockCell) {
    gridCell = GetVoxelGridCell(gridPos);
    if (any(lessThan(gridCell, ivec3(0.0))) || any(greaterThanEqual(gridCell, VoxelGridSize))) return false;

    blockCell = ivec3(floor(gridPos - gridCell * LIGHT_BIN_SIZE));
    return true;
}

uint GetVoxelGridCellIndex(const in ivec3 gridCell) {
    return gridCell.z * (LIGHT_SIZE_Y * LIGHT_SIZE_XZ) + gridCell.y * LIGHT_SIZE_XZ + gridCell.x;
}

// #if defined RENDER_SHADOWCOMP && !defined RENDER_BEGIN_LPV
//     bool LightIntersectsBin(const in vec3 binPos, const in float binSize, const in vec3 lightPos, const in float lightRange) { 
//         vec3 pointDist = lightPos - clamp(lightPos, binPos - binSize, binPos + binSize);
//         return dot(pointDist, pointDist) < _pow2(lightRange);
//     }
// #endif
