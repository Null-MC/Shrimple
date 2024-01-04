#if defined RENDER_BEGIN_LPV || !(defined RENDER_BEGIN || defined RENDER_GEOMETRY || defined RENDER_VERTEX)
    uint GetVoxelBlockMask(const in ivec3 blockCell, const in uint gridIndex) {
        uint maskIndex = blockCell.z * _pow2(LIGHT_BIN_SIZE) + blockCell.y * LIGHT_BIN_SIZE + blockCell.x;
        uint intIndex = gridIndex * LIGHT_BIN_SIZE3 + maskIndex;

        ivec2 texcoord = ivec2(intIndex % DYN_LIGHT_BLOCK_IMG_SIZE, int(intIndex / DYN_LIGHT_BLOCK_IMG_SIZE));
        return imageLoad(imgLocalBlockMask, texcoord).r;
    }
#endif

#if defined RENDER_GEOMETRY || defined RENDER_VERTEX
    void SetVoxelBlockMask(const in ivec3 blockCell, const in uint gridIndex, const in uint blockId) {
        uint maskIndex = blockCell.z * _pow2(LIGHT_BIN_SIZE) + blockCell.y * LIGHT_BIN_SIZE + blockCell.x;
        uint intIndex = gridIndex * LIGHT_BIN_SIZE3 + maskIndex;

        ivec2 texcoord = ivec2(intIndex % DYN_LIGHT_BLOCK_IMG_SIZE, int(intIndex / DYN_LIGHT_BLOCK_IMG_SIZE));
        imageStore(imgLocalBlockMask, texcoord, uvec4(blockId));
    }
#endif
