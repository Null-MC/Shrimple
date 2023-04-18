const float tile_dist[4] = float[](5, 12, 30, 80);


// tile: 0-3
vec2 GetShadowTilePos(const in int tile) {
    if (tile < 0) return vec2(10.0);

    vec2 pos;
    pos.x = fract(tile / 2.0);
    pos.y = floor(float(tile) * 0.5) * 0.5;
    return pos;
}

float GetShadowNormalBias(const in int cascade, const in float geoNoL) {
    float bias = 0.0;

    #if SHADOW_FILTER == SHADOW_FILTER_PCF
        bias += 0.0008 * SHADOW_PCF_SIZE;
    #endif

    switch (cascade) {
        case 0:
            bias += 0.06;
            break;
        case 1:
            bias += 0.10;
            break;
        case 2:
            bias += 0.20;
            break;
        case 3:
            bias += 0.30;
            break;
    }

    return bias * max(1.0 - geoNoL, 0.0) * SHADOW_BIAS_SCALE;
}

float GetShadowOffsetBias(const in int cascade) {
    float bias = 0.0;

    #if SHADOW_FILTER == SHADOW_FILTER_PCF
        bias += 0.01 * rcp(far * 3.0) * SHADOW_PCF_SIZE;
    #endif

    switch (cascade) {
        case 0:
            bias += 0.000018;
            break;
        case 1:
            bias += 0.000032;
            break;
        case 2:
            bias += 0.000128;
            break;
        case 3:
            bias += 0.000512;
            break;
    }

    return bias * SHADOW_BIAS_SCALE;

    // float blocksPerPixelScale = max(shadowProjectionSize[cascade].x, shadowProjectionSize[cascade].y) / cascadeTexSize;

    // float zRangeBias = 0.0000001;
    // float xySizeBias = blocksPerPixelScale * tile_dist_bias_factor;
    // return mix(xySizeBias, zRangeBias, geoNoL) * SHADOW_BIAS_SCALE;
}

#if !defined RENDER_FRAG
    // tile: 0-3
    float GetCascadeDistance(const in int tile) {
        #ifdef SHADOW_CSM_FITRANGE
            float maxDist = min(shadowDistance, far * SHADOW_CSM_FIT_FARSCALE);

            if (tile == 2) {
                return tile_dist[2] + max(maxDist - tile_dist[2], 0.0) * SHADOW_CSM_FITSCALE;
            }
            else if (tile == 3) {
                return maxDist;
            }
        #endif

        return tile_dist[tile];
    }

    void SetProjectionRange(inout mat4 matProj, const in float zNear, const in float zFar) {
        matProj[2][2] = -(zFar + zNear) / (zFar - zNear);
        matProj[3][2] = -(2.0 * zFar * zNear) / (zFar - zNear);
    }
    
    vec3 GetCascadePaddedFrustumClipBounds(const in mat4 matShadowProjection, const in float padding) {
        return 1.0 + padding * vec3(
            matShadowProjection[0].x,
            matShadowProjection[1].y,
           -matShadowProjection[2].z);
    }

    mat4 GetShadowTileProjectionMatrix(const in float cascadeSizes[4], const in int tile, out vec2 shadowViewMin, out vec2 shadowViewMax) {
        float tileSize = cascadeSizes[tile];
        float projectionSize = tileSize * 2.0 + 3.0;

        float zNear = -far;
        float zFar = far * 2.0;

        // TESTING: reduce the depth-range for the nearest cascade only
        //if (tile == 0) zNear = 0.0;

        mat4 matShadowProjection = BuildOrthoProjectionMatrix(projectionSize, projectionSize, zNear, zFar);

        // project scene view frustum slices to shadow-view space and compute min/max XY bounds
        float rangeNear = tile > 0 ? GetCascadeDistance(tile - 1) : near;

        rangeNear = max(rangeNear - 3.0, near);
        float rangeFar = tileSize + 3.0;

        mat4 matSceneProjectionRanged = gbufferProjection;
        SetProjectionRange(matSceneProjectionRanged, rangeNear, rangeFar);

        mat4 matModelViewProjectionInv = inverse(matSceneProjectionRanged * gbufferModelView);
        mat4 matSceneToShadow = matShadowProjection * (shadowModelView * matModelViewProjectionInv);

        vec3 clipMin, clipMax;
        GetFrustumMinMax(matSceneToShadow, clipMin, clipMax);

        clipMin = max(clipMin, vec3(-1.0));
        clipMax = min(clipMax, vec3( 1.0));

        float viewScale = 2.0 / projectionSize;
        shadowViewMin = clipMin.xy / viewScale;
        shadowViewMax = clipMax.xy / viewScale;

        // add block padding to clip min/max
        vec2 blockPadding = 3.0 * vec2(
            matShadowProjection[0][0],
            matShadowProjection[1][1]);

        clipMin.xy -= blockPadding;
        clipMax.xy += blockPadding;

        clipMin = max(clipMin, vec3(-1.0));
        clipMax = min(clipMax, vec3( 1.0));

        // offset & scale frustum clip bounds to fullsize
        vec2 center = (clipMin.xy + clipMax.xy) * 0.5;
        vec2 scale = 2.0 / (clipMax.xy - clipMin.xy);
        mat4 matProjScale = BuildScalingMatrix(vec3(scale, 1.0));
        mat4 matProjTranslate = BuildTranslationMatrix(vec3(-center, 0.0));
        return matProjScale * (matProjTranslate * matShadowProjection);
    }

    mat4 GetShadowTileProjectionMatrix(const in float cascadeSizes[4], const in int tile) {
        vec2 shadowViewMin, shadowViewMax;
        return GetShadowTileProjectionMatrix(cascadeSizes, tile, shadowViewMin, shadowViewMax);
    }
#endif

bool CascadeContainsPosition(const in vec3 shadowViewPos, const in int cascade, const in float padding) {
    return all(greaterThan(shadowViewPos.xy + padding, cascadeViewMin[cascade]))
        && all(lessThan(shadowViewPos.xy - padding, cascadeViewMax[cascade]));
}

bool CascadeIntersectsPosition(const in vec3 shadowViewPos, const in int cascade) {
    return all(greaterThan(shadowViewPos.xy + 3.0, cascadeViewMin[cascade]))
        && all(lessThan(shadowViewPos.xy - 3.0, cascadeViewMax[cascade]));
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
            const int max = 4;
        //#endif

        for (int i = 0; i < max; i++) {
            if (CascadeContainsPosition(blockPos, i, 1.5)) return i;
        }

        //#ifdef SHADOW_CSM_FITRANGE
        //    return 3;
        //#else
            return -1;
        //#endif
    }
#endif

#if defined RENDER_VERTEX && !defined RENDER_COMPOSITE
    void ApplyShadows(const in vec3 localPos, const in vec3 localNormal, const in float geoNoL) {
        for (int i = 0; i < 4; i++) {
            float bias = GetShadowNormalBias(i, geoNoL);
            vec3 offsetLocalPos = localPos + localNormal * bias;

            vec3 shadowViewPos = (shadowModelView * vec4(offsetLocalPos, 1.0)).xyz;

            // convert to shadow screen space
            shadowPos[i] = (cascadeProjection[i] * vec4(shadowViewPos, 1.0)).xyz;

            shadowPos[i] = shadowPos[i] * 0.5 + 0.5; // convert from -1 ~ +1 to 0 ~ 1
            shadowPos[i].xy = shadowPos[i].xy * 0.5 + shadowProjectionPos[i]; // scale and translate to quadrant
        }

        #if defined RENDER_HAND //|| defined RENDER_ENTITIES
            vec3 blockPos = vec3(0.0);
        #elif defined RENDER_TERRAIN || defined RENDER_WATER
            vec3 blockPos = floor(gl_Vertex.xyz + at_midBlock / 64.0 + fract(cameraPosition));
            blockPos = (gl_ModelViewMatrix * vec4(blockPos, 1.0)).xyz;
            blockPos = (shadowModelView * (gbufferModelViewInverse * vec4(blockPos, 1.0))).xyz;
        #else
            vec3 blockPos = gl_Vertex.xyz;
            blockPos = floor(blockPos + 0.5);
            blockPos = (shadowModelView * vec4(blockPos, 1.0)).xyz;
        #endif

        shadowTile = GetShadowTile(cascadeProjection, blockPos);
    }
#endif
