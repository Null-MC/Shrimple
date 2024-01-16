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
    mat4 matSceneToShadow = matShadowProjection * (shadowModelViewEx * matModelViewProjectionInv);

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
