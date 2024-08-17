const float tile_dist[4] = float[](8, 20, 35, 75);

const float cascadeNormalBias[] = float[]
    (0.1, 0.2, 0.4, 0.8);

const float cascadeOffsetBias[] = float[]
    (0.1, 0.2, 0.4, 0.8);


// tile: 0-3
vec2 GetShadowTilePos(const in int tile) {
    if (tile < 0) return vec2(10.0);

    vec2 pos;
    pos.x = fract(tile / 2.0);
    pos.y = floor(float(tile) * 0.5) * 0.5;
    return pos;
}

float GetShadowRange() {
    float _far = far;
    #ifdef DISTANT_HORIZONS
        _far = 0.5 * dhFarPlane;
    #endif

    return _far * 3.0;
}

float GetShadowRange(const in int cascade) {
    return -2.0 / cascadeProjection[cascade][2][2];
}

float GetShadowNormalBias(const in int cascade, const in float geoNoL) {
    float bias = 0.0;

    #if SHADOW_FILTER == SHADOW_FILTER_PCF
        bias += 0.008 * SHADOW_PCF_SIZE_MAX;
    #endif

    bias += cascadeNormalBias[cascade];

    return bias * max(1.0 - geoNoL, 0.0) * Shadow_BiasScale;
}

float GetShadowOffsetBias(const in int cascade) {
    // float bias = 0.0;

    // #if SHADOW_FILTER == SHADOW_FILTER_PCF
    //     bias += 0.001 * rcp(far * 3.0) * SHADOW_PCF_SIZE_MAX;
    // #endif

    // float _far = far;
    // #ifdef DISTANT_HORIZONS
    //     _far = 0.5 * dhFarPlane;
    // #endif

    // float zNear = -_far;
    // float zFar = _far * 2.0;
    float shadowDepthRange = GetShadowRange(cascade);
    return cascadeOffsetBias[cascade] / shadowDepthRange * Shadow_BiasScale;

    // float blocksPerPixelScale = max(shadowProjectionSize[cascade].x, shadowProjectionSize[cascade].y) / cascadeTexSize;

    // float zRangeBias = 0.0000001;
    // float xySizeBias = blocksPerPixelScale * tile_dist_bias_factor;
    // return mix(xySizeBias, zRangeBias, geoNoL) * Shadow_BiasScale;
}

bool CascadeContainsPosition(const in vec3 shadowViewPos, const in int cascade, const in float padding) {
    return clamp(shadowViewPos.xy, cascadeViewMin[cascade] - padding, cascadeViewMax[cascade] + padding) == shadowViewPos.xy;

    // return all(greaterThan(shadowViewPos.xy, cascadeViewMin[cascade] - padding))
    //     && all(lessThan(shadowViewPos.xy, cascadeViewMax[cascade] + padding));
}

bool CascadeIntersectsPosition(const in vec3 shadowViewPos, const in int cascade) {
    return clamp(shadowViewPos.xy, cascadeViewMin[cascade] - 3.0, cascadeViewMax[cascade] + 3.0) == shadowViewPos.xy;

    // return all(greaterThan(shadowViewPos.xy + 3.0, cascadeViewMin[cascade]))
    //     && all(lessThan(shadowViewPos.xy - 3.0, cascadeViewMax[cascade]));
}

int GetShadowCascade(const in vec3 shadowViewPos, const in float padding) {
    if (CascadeContainsPosition(shadowViewPos, 0, padding)) return 0;
    if (CascadeContainsPosition(shadowViewPos, 1, padding)) return 1;
    if (CascadeContainsPosition(shadowViewPos, 2, padding)) return 2;
    if (CascadeContainsPosition(shadowViewPos, 3, padding)) return 3;
    return -1;
}
