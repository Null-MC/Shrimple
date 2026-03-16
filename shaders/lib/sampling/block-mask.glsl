void GetBlockMask(const in uint blockId, out float mixWeight, out uint mixMask) {
    ivec2 blockMaskUV = ivec2(blockId % 256, blockId / 256);
    uint maskData = texelFetch(texBlockMask, blockMaskUV, 0).r;
    mixWeight = unpackUnorm4x8(maskData).r;
    mixMask = bitfieldExtract(maskData, 8, 8);
}
