//#define DEBUG_BLOOM_TILES

const float tilePadding = 2.0;

const float EffectBloomStrengthF = EFFECT_BLOOM_STRENGTH * 0.01;
const float EffectBloomBrightnessF = EFFECT_BLOOM_BRIGHT * 0.01;
const float Bloom_HandStrength = EFFECT_BLOOM_HAND_STRENGTH * 0.01;


float GetBloomTileScale(const in int tile) {
    return 1.0 - rcp(exp2(tile));
}

vec2 GetBloomTileSize(const in int tile) {
    float tileMin = GetBloomTileScale(tile);
    float tileMax = GetBloomTileScale(tile + 1);
    vec2 tileSize = vec2(tileMax - tileMin);

    tileSize = ceil(tileSize * viewSize) / viewSize;

    return tileSize;
}

void GetBloomTileOuterBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    float tileF = float(tile);
    float fx = floor(tileF * 0.5) * 2.0;
    float fy = fract(tileF * 0.5) * 2.0;

    boundsMin.x = (2.0 / 3.0) * (1.0 - exp2(-fx) + fx * pixelSize.x) + fx * pixelSize.x * (tilePadding + 1.0);
    boundsMin.y = fy * (0.5 + (2.0 * tilePadding + 2.0) * pixelSize.y);

    boundsMin = floor(boundsMin * viewSize) / viewSize;

    vec2 tileSize = GetBloomTileSize(tile);
    boundsMax = boundsMin + tileSize + 2.0 * tilePadding * pixelSize;
}

void GetBloomTileInnerBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    GetBloomTileOuterBounds(tile, boundsMin, boundsMax);
    
    boundsMin = boundsMin + tilePadding*pixelSize;
    boundsMax = boundsMax - tilePadding*pixelSize;

    // vec2 center = 0.5 * (boundsMin + boundsMax);
    
    // boundsMin = min(boundsMin + tilePadding*pixelSize, center);
    // boundsMax = max(boundsMax - tilePadding*pixelSize, center);
}

#ifdef RENDER_VERTEX
    void UpdateTileVertexBounds_Down(const in int tile) {
        vec2 boundsMin, boundsMax;
        GetBloomTileOuterBounds(tile, boundsMin, boundsMax);

        vec2 screenPos = step(0.5, texcoord);
        screenPos = screenPos * (boundsMax - boundsMin) + boundsMin;
        gl_Position.xy = screenPos * 2.0 - 1.0;
    }

    void UpdateTileVertexBounds_Up(const in int tile) {
        vec2 boundsMin, boundsMax;
        GetBloomTileInnerBounds(tile, boundsMin, boundsMax);

        vec2 screenPos = step(0.5, texcoord);
        screenPos = screenPos * (boundsMax - boundsMin) + boundsMin;
        gl_Position.xy = screenPos * 2.0 - 1.0;
    }
#endif

#ifdef RENDER_FRAG
    vec3 BloomBoxSample(const in sampler2D texColor, const in vec2 texcoord, const in vec2 pixelSize) {
        vec3 color = vec3(0.0);
        float totalWeight = 0.0;

        for (float iy = -1.5; iy <= 1.5; iy++) {
            for (float ix = -1.5; ix <= 1.5; ix++) {
                vec2 sampleOffset = vec2(ix, iy);
                //float sampleWeight = pow(1.0 - length(sampleOffset) * 0.25, 1.0);
                float sampleWeight = 1.0 - length(sampleOffset) * 0.25;

                vec3 sampleColor = textureLod(texColor, texcoord + sampleOffset * pixelSize, 0).rgb;
                color += sampleWeight * sampleColor;
                totalWeight += sampleWeight;
            }
        }

        return color / totalWeight;
    }

    vec3 BloomTileDownsample(const in sampler2D texSrc, const in int tile) {
        vec2 srcBoundsMin, srcBoundsMax;
        GetBloomTileInnerBounds(tile-1, srcBoundsMin, srcBoundsMax);

        vec2 tex = (texcoord - 0.5 * pixelSize) / (1.0 - pixelSize);
        tex *= (srcBoundsMax - srcBoundsMin) + (4.0 * tilePadding * pixelSize);
        tex += srcBoundsMin - (2.0 * tilePadding * pixelSize);

        #ifndef DEBUG_BLOOM_TILES
            tex = clamp(tex, srcBoundsMin, srcBoundsMax);
        #endif
        
        vec3 color = BloomBoxSample(texSrc, tex, pixelSize);

        #ifdef DEBUG_BLOOM_TILES
            color = vec3(0.0, 1.0, 0.0);
            if (clamp(tex, srcBoundsMin, srcBoundsMax) != tex) color = vec3(1.0, 0.0, 0.0);
        #endif

        return max(color, vec3(0.0));
    }

    vec3 BloomTileUpsample(const in sampler2D texSrc, const in int tile) {
        vec2 srcBoundsMin, srcBoundsMax;
        GetBloomTileInnerBounds(tile+1, srcBoundsMin, srcBoundsMax);

        vec2 tex = (texcoord - 0.5 * pixelSize) / (1.0 - pixelSize);
        tex = tex * (srcBoundsMax - srcBoundsMin) + srcBoundsMin;
        tex -= 0.5 * pixelSize;

        vec3 color1 = textureLod(texSrc, tex, 0).rgb;
        vec3 color2 = textureLodOffset(texSrc, tex, 0, ivec2(1,0)).rgb;
        vec3 color3 = textureLodOffset(texSrc, tex, 0, ivec2(0,1)).rgb;
        vec3 color4 = textureLodOffset(texSrc, tex, 0, ivec2(1,1)).rgb;

        vec3 color = 0.25 * (color1 + color2 + color3 + color4);

        return max(color, vec3(0.0));
    }

    void DitherBloom(inout vec3 color) {
        color += (InterleavedGradientNoise(gl_FragCoord.xy) - 0.25) / 32.0e3;
    }
#endif
