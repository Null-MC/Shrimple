const float tile_dist[4] = float[](5, 12, 30, 80);

const float cascadeNormalBias[] = float[]
    (0.06, 0.15, 0.30, 0.60);

const float cascadeOffsetBias[] = float[]
    (0.06, 0.20, 0.40, 0.80);


// tile: 0-3
vec2 GetShadowTilePos(const in int tile) {
    if (tile < 0) return vec2(10.0);

    vec2 pos;
    pos.x = fract(tile / 2.0);
    pos.y = floor(float(tile) * 0.5) * 0.5;
    return pos;
}

float GetShadowRange(const in int cascade) {
    return -2.0 / cascadeProjection[cascade][2][2];
}

float GetShadowNormalBias(const in int cascade, const in float geoNoL) {
    float bias = 0.0;

    #if SHADOW_FILTER == SHADOW_FILTER_PCF
        bias += 0.0008 * SHADOW_PCF_SIZE_MAX;
    #endif

    bias += cascadeNormalBias[cascade];

    return bias * max(1.0 - geoNoL, 0.0) * ShadowBiasScale;
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
    return cascadeOffsetBias[cascade] / shadowDepthRange * ShadowBiasScale;

    // float blocksPerPixelScale = max(shadowProjectionSize[cascade].x, shadowProjectionSize[cascade].y) / cascadeTexSize;

    // float zRangeBias = 0.0000001;
    // float xySizeBias = blocksPerPixelScale * tile_dist_bias_factor;
    // return mix(xySizeBias, zRangeBias, geoNoL) * ShadowBiasScale;
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

#if (defined RENDER_VERTEX || defined RENDER_GEOMETRY) && !defined RENDER_COMPOSITE
    // returns: tile [0-3] or -1 if excluded
    int GetShadowTile(const in mat4 matShadowProjections[4], const in vec3 blockPos) {
        //#ifdef SHADOW_CSM_FITRANGE
        //    const int max = 3;
        //#else
            // const int max = 4;
        //#endif

        for (int i = 0; i < 4; i++) {
            if (CascadeContainsPosition(blockPos, i, -3.0)) return i;
        }

        //#ifdef SHADOW_CSM_FITRANGE
        //    return 3;
        //#else
            return -1;
        //#endif
    }
#endif

#if (defined RENDER_VERTEX) && !defined RENDER_COMPOSITE
    void ApplyShadows(const in vec3 localPos, const in vec3 localNormal, const in float geoNoL, out vec3 shadowPos[4], out int shadowTile) {
        for (int i = 0; i < 4; i++) {
            float bias = GetShadowNormalBias(i, geoNoL);
            vec3 offsetLocalPos = localNormal * bias + localPos;

            vec3 shadowViewPos = mul3(shadowModelViewEx, offsetLocalPos);

            // convert to shadow screen space
            shadowPos[i] = mul3(cascadeProjection[i], shadowViewPos);

            shadowPos[i] = shadowPos[i] * 0.5 + 0.5;
            shadowPos[i].xy = shadowPos[i].xy * 0.5 + shadowProjectionPos[i];
        }

        #if defined RENDER_HAND //|| defined RENDER_ENTITIES
            vec3 blockPos = vec3(0.0);
        #elif defined RENDER_TERRAIN || defined RENDER_WATER
            vec3 blockPos = at_midBlock / 64.0 + localPos + 0.5;
            blockPos = floor(blockPos + fract(cameraPosition));
            // blockPos = (gl_ModelViewMatrix * vec4(blockPos, 1.0)).xyz;
            // blockPos = (shadowModelViewEx * (gbufferModelViewInverse * vec4(blockPos, 1.0))).xyz;
            blockPos = mul3(shadowModelViewEx, blockPos);
        #else
            vec3 blockPos = floor(localPos + fract(cameraPosition) + 0.5);
            blockPos = mul3(shadowModelViewEx, blockPos);
        #endif

        shadowTile = GetShadowTile(cascadeProjection, blockPos);
    }
#endif
