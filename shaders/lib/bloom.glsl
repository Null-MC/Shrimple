const float tilePadding = 2.0;

const float EffectBloomStrengthF = BLOOM_STRENGTH * 0.005;


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

void GetBloomTileOuterBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    boundsMin = GetBloomTileOuterPosition(tile);
    vec2 tileSize = GetBloomTileSize(tile);

    vec2 pixelSize = 1.0 / viewSize;
    boundsMax = boundsMin + tileSize + 2.0 * tilePadding * pixelSize;
}

void GetBloomTileInnerBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    GetBloomTileOuterBounds(tile, boundsMin, boundsMax);

    vec2 pixelSize = 1.0 / viewSize;

    boundsMin = boundsMin + tilePadding*pixelSize;
    boundsMax = boundsMax - tilePadding*pixelSize;
}

vec3 BloomSample(const in sampler2D texSrc, in vec2 texcoord, const in vec2 boundsMin, const in vec2 boundsMax) {
    texcoord = clamp(texcoord, boundsMin, boundsMax);
    return texture(texSrc, texcoord).rgb;
}

vec3 BloomTileUpsample(const in sampler2D texSrc, const in vec2 texcoord, const in int tile) {
    vec2 srcBoundsMin, srcBoundsMax;
    GetBloomTileInnerBounds(tile, srcBoundsMin, srcBoundsMax);

    vec2 pixelSize = 1.0 / viewSize;
//    srcBoundsMin -= 0.5 * pixelSize;
//    srcBoundsMax += 0.5 * pixelSize;

    vec2 tex = texcoord - 0.5 * pixelSize;
//    tex = fma(tex, (srcBoundsMax - srcBoundsMin), srcBoundsMin);
    tex = mix(srcBoundsMin, srcBoundsMax, tex);

    const float filterRadius = 0.0005; // [0.0004 0.0008]
    float x = filterRadius * (viewSize.y / viewSize.x);
    float y = filterRadius;

    vec3 a = BloomSample(texSrc, vec2(tex.x - x, tex.y + y), srcBoundsMin, srcBoundsMax);
    vec3 b = BloomSample(texSrc, vec2(tex.x,     tex.y + y), srcBoundsMin, srcBoundsMax);
    vec3 c = BloomSample(texSrc, vec2(tex.x + x, tex.y + y), srcBoundsMin, srcBoundsMax);

    vec3 d = BloomSample(texSrc, vec2(tex.x - x, tex.y), srcBoundsMin, srcBoundsMax);
    vec3 e = BloomSample(texSrc, vec2(tex.x,     tex.y), srcBoundsMin, srcBoundsMax);
    vec3 f = BloomSample(texSrc, vec2(tex.x + x, tex.y), srcBoundsMin, srcBoundsMax);

    vec3 g = BloomSample(texSrc, vec2(tex.x - x, tex.y - y), srcBoundsMin, srcBoundsMax);
    vec3 h = BloomSample(texSrc, vec2(tex.x,     tex.y - y), srcBoundsMin, srcBoundsMax);
    vec3 i = BloomSample(texSrc, vec2(tex.x + x, tex.y - y), srcBoundsMin, srcBoundsMax);

    vec3 upsample;
    upsample = e*4.0;
    upsample += (b+d+f+h)*2.0;
    upsample += (a+c+g+i);
    upsample *= 0.0625;

    return max(upsample, vec3(0.0));
}
