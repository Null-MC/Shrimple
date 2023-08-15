float GetBloomTilePos(const in int tile) {
    return 1.0 - rcp(exp2(tile));
}

float GetBloomTileSize(const in int tile) {
    float tileMin = GetBloomTilePos(tile);
    float tileMax = GetBloomTilePos(tile + 1);
    return tileMax - tileMin;
}

void GetBloomTileOuterBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    float tileF = float(tile);
    float fx = floor(tileF * 0.5) * 2.0;
    float fy = fract(tileF * 0.5) * 2.0;

    boundsMin.x = (2.0 / 3.0) * (1.0 - exp2(-fx) + fx * pixelSize.x) + fx * pixelSize.x;
    boundsMin.y = fy * (0.5 + 4.0 * pixelSize.y);

    float tileSize = GetBloomTileSize(tile);
    boundsMax = boundsMin + tileSize + 2.0 * pixelSize;
}

void GetBloomTileInnerBounds(const in int tile, out vec2 boundsMin, out vec2 boundsMax) {
    GetBloomTileOuterBounds(tile, boundsMin, boundsMax);

    vec2 center = 0.5 * (boundsMin + boundsMax);
    
    boundsMin = min(boundsMin + pixelSize, center);
    boundsMax = max(boundsMax - pixelSize, center);
}

#ifdef RENDER_VERTEX
    void UpdateTileVertexBounds(const in int tile) {
        vec2 halfPixelSize = 0.5*pixelSize;

        vec2 boundsMin, boundsMax;
        GetBloomTileOuterBounds(tile, boundsMin, boundsMax);

        vec2 screenPos = (gl_Position.xy * 0.5 + 0.5) - halfPixelSize;
        screenPos = screenPos * (boundsMax - boundsMin) + boundsMin;
        gl_Position.xy = (screenPos + halfPixelSize) * 2.0 - 1.0;
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
        vec2 boundsMin, boundsMax;
        vec2 outerBoundsMin, outerBoundsMax;
        GetBloomTileInnerBounds(tile, boundsMin, boundsMax);
        GetBloomTileOuterBounds(tile, outerBoundsMin, outerBoundsMax);

        vec2 tex = (gl_FragCoord.xy - 0.5) * pixelSize;
        tex = clamp(tex, boundsMin, boundsMax);
        tex = (tex - outerBoundsMin) / (boundsMax - boundsMin);

        vec2 srcBoundsMin, srcBoundsMax;
        vec2 srcOuterBoundsMin, srcOuterBoundsMax;
        GetBloomTileInnerBounds(tile-1, srcBoundsMin, srcBoundsMax);
        GetBloomTileOuterBounds(tile-1, srcOuterBoundsMin, srcOuterBoundsMax);

        vec2 srcTex = tex * (srcBoundsMax - srcBoundsMin) + srcOuterBoundsMin;

        srcTex -= 0.25 * pixelSize;

        vec3 color = BloomBoxSample(texSrc, srcTex, pixelSize);

        return max(color, vec3(0.0));
    }

    vec3 BloomTileUpsample(const in sampler2D texSrc, const in int tile) {
        vec2 boundsMin, boundsMax;
        vec2 outerBoundsMin, outerBoundsMax;
        GetBloomTileInnerBounds(tile, boundsMin, boundsMax);
        GetBloomTileOuterBounds(tile, outerBoundsMin, outerBoundsMax);

        vec2 tex = (gl_FragCoord.xy - 0.5) * pixelSize;
        tex = clamp(tex, boundsMin, boundsMax);
        tex = (tex - outerBoundsMin) / (boundsMax - boundsMin);

        vec2 srcBoundsMin, srcBoundsMax;
        GetBloomTileInnerBounds(tile+1, srcBoundsMin, srcBoundsMax);

        vec2 srcTex = tex * (srcBoundsMax - srcBoundsMin) + srcBoundsMin;

        srcTex -= 0.625*pixelSize;

        vec3 color1 = textureLod(texSrc, srcTex, 0).rgb;
        vec3 color2 = textureLodOffset(texSrc, srcTex, 0, ivec2(1,0)).rgb;
        vec3 color3 = textureLodOffset(texSrc, srcTex, 0, ivec2(0,1)).rgb;
        vec3 color4 = textureLodOffset(texSrc, srcTex, 0, ivec2(1,1)).rgb;

        vec3 color = 0.25 * (color1 + color2 + color3 + color4);

        return max(color, vec3(0.0));
    }
#endif
