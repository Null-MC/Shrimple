const ivec2 DepthTileSizes[] = ivec2[](
    ivec2( 0,  2),
    ivec2( 2,  4),
    ivec2( 6,  8),
    ivec2(14, 16));


void GetDepthTileBounds(const in vec2 viewSize, const in int index, out ivec2 tilePos, out ivec2 tileSize) {
    vec2 _size = viewSize / exp2(index + 1);

    tilePos = ivec2(0);
    if (index > 0) {
        tilePos += ivec2(ceil(_size * DepthTileSizes[index - 1]));
    }

    tileSize = ivec2(_size + 0.5);
}

vec2 GetDepthTileCoord(const in vec2 viewSize, const in vec2 texcoord, const in int index) {
    ivec2 tilePos, tileSize;
    GetDepthTileBounds(viewSize, index, tilePos, tileSize);
    return texcoord * tileSize + tilePos;
}
