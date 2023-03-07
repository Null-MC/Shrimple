const ivec3 SceneLightGridSize = ivec3(LIGHT_SIZE_XZ, LIGHT_SIZE_Y, LIGHT_SIZE_XZ);
const ivec3 SceneLightSize = SceneLightGridSize * LIGHT_BIN_SIZE;
const ivec3 LightGridCenter = SceneLightSize / 2;

const int lightMaskBitCount = int(log2(LIGHT_BIN_SIZE));


vec3 GetLightGridPosition(const in vec3 position) {
    vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
    return position + LightGridCenter + cameraOffset;
}

ivec3 GetSceneLightGridCell(const in vec3 gridPos) {
    return ivec3(floor(gridPos / LIGHT_BIN_SIZE + 0.001));
}

bool GetSceneLightGridCell(const in vec3 gridPos, out ivec3 gridCell, out ivec3 blockCell) {
    gridCell = GetSceneLightGridCell(gridPos);
    if (any(lessThan(gridCell, ivec3(0.0))) || any(greaterThanEqual(gridCell, SceneLightGridSize))) return false;

    blockCell = ivec3(floor(gridPos - gridCell * LIGHT_BIN_SIZE));
    return true;
}

uint GetSceneLightGridIndex(const in ivec3 gridCell) {
    return gridCell.z * (LIGHT_SIZE_Y * LIGHT_SIZE_XZ) + gridCell.y * LIGHT_SIZE_XZ + gridCell.x;
}

ivec2 GetSceneLightUV(const in uint gridIndex, const in uint gridLightIndex) {
    uint y = uint(gridIndex / 4096) * LIGHT_BIN_MAX_COUNT;
    return ivec2(gridIndex % 4096, y + gridLightIndex);
}

#if DYN_LIGHT_RT_SHADOWS > 0
    uint GetSceneBlockMask(const in ivec3 blockCell, const in uint gridIndex) {
        uint maskIndex = (blockCell.z << (lightMaskBitCount * 2)) | (blockCell.y << lightMaskBitCount) | blockCell.x;
        maskIndex *= DYN_LIGHT_MASK_STRIDE;
        uint intIndex = maskIndex >> 5;

        uint bit = SceneLightMaps[gridIndex].Mask[intIndex] >> (maskIndex & 31);
        return (bit & 255);
    }
#endif

#if defined RENDER_SHADOW
    bool LightIntersectsBin(const in vec3 binPos, const in float binSize, const in vec3 lightPos, const in float lightRange) { 
        vec3 pointDist = lightPos - clamp(lightPos, binPos - binSize, binPos + binSize);
        return dot(pointDist, pointDist) < pow2(lightRange);
    }

    bool TrySetSceneLightMask(const in ivec3 blockCell, const in uint gridIndex) {
        uint maskIndex = (blockCell.z << (lightMaskBitCount * 2)) | (blockCell.y << lightMaskBitCount) | blockCell.x;

        #if DYN_LIGHT_RT_SHADOWS > 0
            maskIndex *= DYN_LIGHT_MASK_STRIDE;
        #endif

        uint intIndex = maskIndex >> 5;

        #if DYN_LIGHT_RT_SHADOWS > 0
            uint bit = 255 << (maskIndex & 31);
        #else
            uint bit = 1 << (maskIndex & 31);
        #endif

        uint status = atomicOr(SceneLightMaps[gridIndex].Mask[intIndex], bit);

        return (status & bit) == 0;
    }

    #if DYN_LIGHT_RT_SHADOWS > 0
        void SetSceneBlockMask(const in ivec3 blockCell, const in uint gridIndex, const in uint blockType) {
            uint maskIndex = (blockCell.z << (lightMaskBitCount * 2)) | (blockCell.y << lightMaskBitCount) | blockCell.x;
            maskIndex *= DYN_LIGHT_MASK_STRIDE;

            uint intIndex = maskIndex >> 5;
            uint bit = blockType << (maskIndex & 31);

            atomicOr(SceneLightMaps[gridIndex].Mask[intIndex], bit);
        }
    #endif

    void AddSceneLight(const in vec3 position, const in float range, const in vec4 color) {
        ivec3 gridCell, blockCell;
        vec3 gridPos = GetLightGridPosition(position);
        if (!GetSceneLightGridCell(gridPos, gridCell, blockCell)) return;
        uint gridIndex = GetSceneLightGridIndex(gridCell);

        if (!TrySetSceneLightMask(blockCell, gridIndex)) return;

        uint gridLightIndex = atomicAdd(SceneLightMaps[gridIndex].LightCount, 1u);
        if (gridLightIndex >= LIGHT_BIN_MAX_COUNT) return;

        uint lightIndex = atomicAdd(SceneLightCount, 1u);
        if (lightIndex >= LIGHT_MAX_COUNT) return;

        SceneLights[lightIndex] = SceneLightData(position, range, color);
        ivec2 uv = GetSceneLightUV(gridIndex, gridLightIndex);
        imageStore(imgSceneLights, uv, uvec4(lightIndex));

        #ifdef LIGHT_COLOR_NEIGHBORS
            float neighborRange = max(range - 1.5, 0.0);

            vec3 neighborGridPosMin = GetLightGridPosition(position - neighborRange);
            ivec3 neighborGridCellMin = GetSceneLightGridCell(neighborGridPosMin);

            vec3 neighborGridPosMax = GetLightGridPosition(position + neighborRange);
            ivec3 neighborGridCellMax = GetSceneLightGridCell(neighborGridPosMax);

            vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;

            ivec3 neighborGridCell;
            for (neighborGridCell.z = neighborGridCellMin.z; neighborGridCell.z <= neighborGridCellMax.z; neighborGridCell.z++) {
                for (neighborGridCell.y = neighborGridCellMin.y; neighborGridCell.y <= neighborGridCellMax.y; neighborGridCell.y++) {
                    for (neighborGridCell.x = neighborGridCellMin.x; neighborGridCell.x <= neighborGridCellMax.x; neighborGridCell.x++) {
                        if (neighborGridCell == gridCell || any(lessThan(neighborGridCell, ivec3(0.0))) || any(greaterThanEqual(neighborGridCell, SceneLightGridSize))) continue;

                        vec3 binPos = (neighborGridCell + 0.5) * LIGHT_BIN_SIZE + 0.5 - LightGridCenter - cameraOffset;
                        if (!LightIntersectsBin(binPos, LIGHT_BIN_SIZE, position, neighborRange)) continue;

                        uint neighborGridIndex = GetSceneLightGridIndex(neighborGridCell);
                        uint neighborLightIndex = atomicAdd(SceneLightMaps[neighborGridIndex].LightCount, 1u);
                        if (neighborLightIndex < LIGHT_BIN_MAX_COUNT) {
                            ivec2 neighborUV = GetSceneLightUV(neighborGridIndex, neighborLightIndex);
                            imageStore(imgSceneLights, neighborUV, uvec4(lightIndex));
                        }
                    }
                }
            }
        #endif
    }
#elif !defined RENDER_BEGIN
    int GetSceneLights(const in vec3 position, out uint gridIndex) {
        ivec3 gridCell, blockCell;
        vec3 gridPos = GetLightGridPosition(position);
        if (!GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
            gridIndex = -1u;
            return 0;
        }

        gridIndex = GetSceneLightGridIndex(gridCell);
        return min(int(SceneLightMaps[gridIndex].LightCount), LIGHT_BIN_MAX_COUNT);
    }

    SceneLightData GetSceneLight(const in uint gridIndex, const in int binLightIndex) {
        ivec2 uv = GetSceneLightUV(gridIndex, binLightIndex);
        uint globalLightIndex = imageLoad(imgSceneLights, uv).r;
        return SceneLights[globalLightIndex];
    }
#endif
