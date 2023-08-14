const ivec2 DepthTileSizes[] = ivec2[](
    ivec2( 0,  2),
    ivec2( 2,  4),
    ivec2( 6,  8),
    ivec2(14, 16));


void GetDepthTileBounds(const in int index, out ivec2 tilePos, out ivec2 tileSize) {
    ivec2 viewSize = ivec2(viewWidth, viewHeight);
    tileSize = ivec2(viewSize / exp2(index + 1));

    tilePos = ivec2(0);
    if (index > 0) tilePos += tileSize * DepthTileSizes[index - 1];
}

ivec2 GetDepthTileCoord(const in vec2 texcoord, const in int index) {
    ivec2 tilePos, tileSize;
    GetDepthTileBounds(index, tilePos, tileSize);
    tilePos += ivec2(texcoord * tileSize);
    return tilePos;
}
