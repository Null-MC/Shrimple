const int LightMaskBitCount = int(log2(LIGHT_BIN_SIZE));


#ifdef RENDER_SHADOWCOMP
    uint GetVoxelLightMask(const in ivec3 blockCell, const in uint gridIndex) {
        uint maskIndex = (blockCell.z << (LightMaskBitCount * 2)) | (blockCell.y << LightMaskBitCount) | blockCell.x;
        maskIndex *= DYN_LIGHT_MASK_STRIDE;

        uint intIndex = gridIndex * (LIGHT_BIN_SIZE3 * DYN_LIGHT_MASK_STRIDE / 32) + (maskIndex >> 5);

        ivec2 texcoord = ivec2(intIndex % DYN_LIGHT_IMG_SIZE, int(intIndex / DYN_LIGHT_IMG_SIZE));
        uint bit = imageLoad(imgLocalLightMask, texcoord).r >> (maskIndex & 31);
        return (bit & 0xFF);
    }
#endif

uint GetLightMaskFace(const in vec3 normal) {
    vec3 normalAbs = abs(normal);

    if (normalAbs.y > normalAbs.x && normalAbs.y > normalAbs.z)
        return normal.y > 0 ? LIGHT_MASK_UP : LIGHT_MASK_DOWN;
    
    if (normalAbs.x > normalAbs.z)
        return normal.x > 0 ? LIGHT_MASK_EAST : LIGHT_MASK_WEST;

    return normal.z > 0 ? LIGHT_MASK_SOUTH : LIGHT_MASK_NORTH;
}

#if defined RENDER_GEOMETRY || defined RENDER_VERTEX
    bool SetVoxelLightMask(const in ivec3 blockCell, const in uint gridIndex, const in uint lightType) {
        uint maskIndex = (blockCell.z << (LightMaskBitCount * 2)) | (blockCell.y << LightMaskBitCount) | blockCell.x;
        maskIndex *= DYN_LIGHT_MASK_STRIDE;

        uint intIndex = gridIndex * (LIGHT_BIN_SIZE3 * DYN_LIGHT_MASK_STRIDE / 32) + (maskIndex >> 5);
        uint bit = lightType << (maskIndex & 31u);

        ivec2 texcoord = ivec2(intIndex % DYN_LIGHT_IMG_SIZE, int(intIndex / DYN_LIGHT_IMG_SIZE));
        uint was = imageAtomicOr(imgLocalLightMask, texcoord, bit);
        return (was & bit) == 0u;
    }
#elif defined RENDER_SHADOWCOMP && !defined RENDER_BEGIN_LPV
    bool LightIntersectsBin(const in vec3 binPos, const in float binSize, const in vec3 lightPos, const in float lightRange) { 
        vec3 pointDist = lightPos - clamp(lightPos, binPos, binPos + binSize);
        return length(pointDist) < lightRange;
    }
#endif

#if LIGHTING_MODE == LIGHTING_MODE_TRACED && !(defined RENDER_BEGIN || defined RENDER_GEOMETRY || defined RENDER_VERTEX)
    uint GetVoxelLights(const in vec3 position, out uint gridIndex) {
        ivec3 gridCell, blockCell;
        vec3 gridPos = GetVoxelLightPosition(position);
        if (!GetVoxelGridCell(gridPos, gridCell, blockCell)) {
            gridIndex = DYN_LIGHT_GRID_MAX;
            return 0u;
        }

        gridIndex = GetVoxelGridCellIndex(gridCell);
        //return min(SceneLightMaps[gridIndex].LightCount + SceneLightMaps[gridIndex].LightNeighborCount, LIGHT_BIN_MAX_COUNT);
        return SceneLightMaps[gridIndex].LightCount + SceneLightMaps[gridIndex].LightNeighborCount;
    }

    uvec4 GetVoxelLight(const in uint gridIndex, const in uint binLightIndex) {
        uint lightGlobalIndex = SceneLightMaps[gridIndex].GlobalLights[binLightIndex];
        return SceneLights[lightGlobalIndex];
    }
#endif
