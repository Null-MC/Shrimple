const float tilePadding = 2.0;

const float EffectBloomStrengthF = 0.5 * BLOOM_STRENGTH * 0.01;


float GetBloomTileScale(const in int tile) {
    return 1.0 - 1.0 / exp2(tile);
}

vec2 GetBloomTileSize(const in int tile) {
    float tileMin = GetBloomTileScale(tile);
    float tileMax = GetBloomTileScale(tile + 1);
    vec2 tileSize = vec2(tileMax - tileMin);

    tileSize = ceil(tileSize * viewSize) / viewSize;

    return tileSize;
}

vec2 GetBloomTileOuterPosition(const in int tile) {
    float fx = floor(tile * 0.5) * 2.0;
    float fy = fract(tile * 0.5) * 2.0;

    vec2 pixelSize = 1.0 / viewSize;

    vec2 boundsMin;
    boundsMin.x = (2.0 / 3.0) * (1.0 - exp2(-fx) + fx * pixelSize.x) + fx * pixelSize.x * (tilePadding + 1.0);
    boundsMin.y = fy * (0.5 + (2.0 * tilePadding + 2.0) * pixelSize.y);

    return floor(boundsMin * viewSize) / viewSize;
}

vec2 GetBloomTileInnerPosition(const in int tile) {
    vec2 boundsMin = GetBloomTileOuterPosition(tile);

    vec2 pixelSize = 1.0 / viewSize;
    return boundsMin + tilePadding*pixelSize;
}

void GetBloomTileInnerBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    boundsMin = GetBloomTileOuterPosition(tile);
    vec2 tileSize = GetBloomTileSize(tile);

    vec2 pixelSize = 1.0 / viewSize;

    boundsMin += tilePadding*pixelSize;
    boundsMax = boundsMin + tileSize;
}
