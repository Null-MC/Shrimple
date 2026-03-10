const float tilePadding = 2.0;

//const float Bloom_Power = 1.0;
const float EffectBloomStrengthF = BLOOM_STRENGTH * 0.01;
//const float EffectBloomBrightnessF = EFFECT_BLOOM_BRIGHT * 0.01;
//const float Bloom_HandStrength = EFFECT_BLOOM_HAND_STRENGTH * 0.01;


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

void GetBloomTileOuterBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    float fx = floor(tile * 0.5) * 2.0;
    float fy = fract(tile * 0.5) * 2.0;

    vec2 pixelSize = 1.0 / viewSize;

    boundsMin.x = (2.0 / 3.0) * (1.0 - exp2(-fx) + fx * pixelSize.x) + fx * pixelSize.x * (tilePadding + 1.0);
    boundsMin.y = fy * (0.5 + (2.0 * tilePadding + 2.0) * pixelSize.y);

    boundsMin = floor(boundsMin * viewSize) / viewSize;

    vec2 tileSize = GetBloomTileSize(tile);
    boundsMax = boundsMin + tileSize + 2.0 * tilePadding * pixelSize;
}

void GetBloomTileInnerBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    GetBloomTileOuterBounds(tile, boundsMin, boundsMax);

    vec2 pixelSize = 1.0 / viewSize;

    boundsMin = boundsMin + tilePadding*pixelSize;
    boundsMax = boundsMax - tilePadding*pixelSize;

    // vec2 center = 0.5 * (boundsMin + boundsMax);

    // boundsMin = min(boundsMin + tilePadding*pixelSize, center);
    // boundsMax = max(boundsMax - tilePadding*pixelSize, center);
}

#ifdef RENDER_VERTEX
    void UpdateTileVertexBounds(const in int tile) {
        vec2 boundsMin, boundsMax;
        GetBloomTileOuterBounds(tile, boundsMin, boundsMax);

        vec2 screenPos = step(0.5, texcoord);
        screenPos = fma(screenPos, (boundsMax - boundsMin), boundsMin);
        gl_Position.xy = fma(screenPos, vec2(2.0), vec2(-1.0));
    }

//    void UpdateTileVertexBounds_Up(const in int tile) {
//        vec2 boundsMin, boundsMax;
//        GetBloomTileInnerBounds(tile, boundsMin, boundsMax);
//
//        vec2 screenPos = step(0.5, texcoord);
//        screenPos = fma(screenPos, (boundsMax - boundsMin), boundsMin);
//        gl_Position.xy = fma(screenPos, vec2(2.0), vec2(-1.0));
//    }
#endif

#ifdef RENDER_FRAGMENT
    vec3 BloomSample(const in sampler2D texSrc, in vec2 texcoord, const in vec2 boundsMin, const in vec2 boundsMax) {
        texcoord = clamp(texcoord, boundsMin, boundsMax);
        return texture(texSrc, texcoord).rgb;
    }

    vec3 BloomBoxSample(const in sampler2D texColor, const in vec2 texcoord, const in vec2 boundsMin, const in vec2 boundsMax) {
//        vec3 a = textureOffset(texColor, texcoord, ivec2(-2, +2)).rgb;
//        vec3 b = textureOffset(texColor, texcoord, ivec2( 0, +2)).rgb;
//        vec3 c = textureOffset(texColor, texcoord, ivec2(+2, +2)).rgb;
//
//        vec3 d = textureOffset(texColor, texcoord, ivec2(-2, 0)).rgb;
//        vec3 e = textureOffset(texColor, texcoord, ivec2( 0, 0)).rgb;
//        vec3 f = textureOffset(texColor, texcoord, ivec2(+2, 0)).rgb;
//
//        vec3 g = textureOffset(texColor, texcoord, ivec2(-2, -2)).rgb;
//        vec3 h = textureOffset(texColor, texcoord, ivec2( 0, -2)).rgb;
//        vec3 i = textureOffset(texColor, texcoord, ivec2(+2, -2)).rgb;
//
//        vec3 j = textureOffset(texColor, texcoord, ivec2(-1, +1)).rgb;
//        vec3 k = textureOffset(texColor, texcoord, ivec2(+1, +1)).rgb;
//        vec3 l = textureOffset(texColor, texcoord, ivec2(-1, -1)).rgb;
//        vec3 m = textureOffset(texColor, texcoord, ivec2(+1, -1)).rgb;

        vec2 px = 1.0 / viewSize;

        vec3 a = BloomSample(texColor, fma(vec2(-2, +2), px, texcoord), boundsMin, boundsMax);
        vec3 b = BloomSample(texColor, fma(vec2( 0, +2), px, texcoord), boundsMin, boundsMax);
        vec3 c = BloomSample(texColor, fma(vec2(+2, +2), px, texcoord), boundsMin, boundsMax);

        vec3 d = BloomSample(texColor, fma(vec2(-2,  0), px, texcoord), boundsMin, boundsMax);
        vec3 e = BloomSample(texColor, fma(vec2( 0,  0), px, texcoord), boundsMin, boundsMax);
        vec3 f = BloomSample(texColor, fma(vec2(+2,  0), px, texcoord), boundsMin, boundsMax);

        vec3 g = BloomSample(texColor, fma(vec2(-2, -2), px, texcoord), boundsMin, boundsMax);
        vec3 h = BloomSample(texColor, fma(vec2( 0, -2), px, texcoord), boundsMin, boundsMax);
        vec3 i = BloomSample(texColor, fma(vec2(+2, -2), px, texcoord), boundsMin, boundsMax);

        vec3 j = BloomSample(texColor, fma(vec2(-1, +1), px, texcoord), boundsMin, boundsMax);
        vec3 k = BloomSample(texColor, fma(vec2(+1, +1), px, texcoord), boundsMin, boundsMax);
        vec3 l = BloomSample(texColor, fma(vec2(-1, -1), px, texcoord), boundsMin, boundsMax);
        vec3 m = BloomSample(texColor, fma(vec2(+1, -1), px, texcoord), boundsMin, boundsMax);

        vec3 downsample;
        downsample = e*0.125;
        downsample += (a+c+g+i)*0.03125;
        downsample += (b+d+f+h)*0.0625;
        downsample += (j+k+l+m)*0.125;
        return downsample;
    }

    vec3 BloomTileDownsample(const in sampler2D texSrc, const in int tile) {
        vec2 srcBoundsMin, srcBoundsMax;
        GetBloomTileInnerBounds(tile-1, srcBoundsMin, srcBoundsMax);

        vec2 pixelSize = 1.0 / viewSize;
        srcBoundsMin -= pixelSize;
        srcBoundsMax += pixelSize;

        vec2 tex = (texcoord - 0.5 * pixelSize);// / (1.0 - pixelSize);
        tex *= (srcBoundsMax - srcBoundsMin) + (4.0 * tilePadding * pixelSize);
        tex += srcBoundsMin - (2.0 * tilePadding * pixelSize);

//        #ifndef DEBUG_BLOOM_TILES
//            tex = clamp(tex, srcBoundsMin, srcBoundsMax);
//        #endif

        vec3 color = BloomBoxSample(texSrc, tex, srcBoundsMin, srcBoundsMax);

//        #ifdef DEBUG_BLOOM_TILES
//            color = vec3(0.0, 1.0, 0.0);
//            if (clamp(tex, srcBoundsMin, srcBoundsMax) != tex) color = vec3(1.0, 0.0, 0.0);
//        #endif

        return max(color, vec3(0.0));
    }

    vec3 BloomTileUpsample(const in sampler2D texSrc, const in int tile) {
        vec2 srcBoundsMin, srcBoundsMax;
        GetBloomTileInnerBounds(tile+1, srcBoundsMin, srcBoundsMax);

        vec2 pixelSize = 1.0 / viewSize;
        srcBoundsMin -= 0.5 * pixelSize;
        srcBoundsMax += 0.5 * pixelSize;

        vec2 tex = texcoord - 0.5 * pixelSize;
        tex = fma(tex, (srcBoundsMax - srcBoundsMin), srcBoundsMin);

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

//    void DitherBloom(inout vec3 color) {
//        color += (InterleavedGradientNoise(gl_FragCoord.xy) - 0.25) / 32.0e3;
//    }
#endif
