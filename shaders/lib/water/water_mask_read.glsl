bool GetWaterMask(const in ivec2 uv) {
    ivec2 tilePos = uv / 8;
    ivec2 size = ivec2(ceil(viewSize / 8.0));
    int tileIndex = tilePos.y*size.x + tilePos.x;

    // ivec2 localPos = uv - tilePos*8;
    ivec2 localPos = uv % 8;
    int localIndex = localPos.y*8 + localPos.x;

    uint mask = 1u << (localIndex % 32);
    int shift = localIndex >= 32 ? 1 : 0;

    uint data = WaterMask[tileIndex*2 + shift];

    return (data & mask) == mask;
}
