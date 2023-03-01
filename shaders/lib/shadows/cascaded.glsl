const float tile_dist[4] = float[](5, 12, 30, 80);

const vec3 _shadowTileColors[4] = vec3[](
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0),
    vec3(1.0, 0.0, 1.0));


// tile: 0-3
vec2 GetShadowTilePos(const in int tile) {
    if (tile < 0) return vec2(10.0);

    vec2 pos;
    pos.x = fract(tile / 2.0);
    pos.y = floor(float(tile) * 0.5) * 0.5;
    return pos;
}

// tile: 0-3
vec3 GetShadowTileColor(const in int tile) {
    if (tile < 0) return vec3(1.0);
    return _shadowTileColors[tile];
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

    void GetFrustumMinMax(const in mat4 matProjection, out vec3 clipMin, out vec3 clipMax) {
        vec3 frustum[8] = vec3[](
            vec3(-1.0, -1.0, -1.0),
            vec3( 1.0, -1.0, -1.0),
            vec3(-1.0,  1.0, -1.0),
            vec3( 1.0,  1.0, -1.0),
            vec3(-1.0, -1.0,  1.0),
            vec3( 1.0, -1.0,  1.0),
            vec3(-1.0,  1.0,  1.0),
            vec3( 1.0,  1.0,  1.0));

        for (int i = 0; i < 8; i++) {
            vec3 shadowClipPos = unproject(matProjection * vec4(frustum[i], 1.0));

            if (i == 0) {
                clipMin = shadowClipPos;
                clipMax = shadowClipPos;
            }
            else {
                clipMin = min(clipMin, shadowClipPos);
                clipMax = max(clipMax, shadowClipPos);
            }
        }
    }
    
    vec3 GetCascadePaddedFrustumClipBounds(const in mat4 matShadowProjection, const in float padding) {
        return 1.0 + padding * vec3(
            matShadowProjection[0].x,
            matShadowProjection[1].y,
           -matShadowProjection[2].z);
    }

    #ifdef IRIS_FEATURE_SSBO
        bool CascadeContainsProjection(const in vec3 shadowViewPos, const in int cascade) {
            return all(greaterThan(shadowViewPos.xy, cascadeViewMin[cascade]))
                && all(lessThan(shadowViewPos.xy, cascadeViewMax[cascade]));
        }

        bool CascadeIntersectsProjection(const in vec3 shadowViewPos, const in int cascade) {
            return all(greaterThan(shadowViewPos.xy + 1.5, cascadeViewMin[cascade]))
                && all(lessThan(shadowViewPos.xy - 1.5, cascadeViewMax[cascade]));
        }
    #else
        bool CascadeContainsProjection(const in vec3 shadowViewPos, const in mat4 matShadowProjection) {
            vec3 clipPos = (matShadowProjection * vec4(shadowViewPos, 1.0)).xyz;
            vec3 paddedSize = GetCascadePaddedFrustumClipBounds(matShadowProjection, -1.5);
            return all(greaterThan(clipPos, -paddedSize)) && all(lessThan(clipPos, paddedSize));
        }

        bool CascadeIntersectsProjection(const in vec3 shadowViewPos, const in mat4 matShadowProjection) {
            vec3 clipPos = (matShadowProjection * vec4(shadowViewPos, 1.0)).xyz;
            vec3 paddedSize = GetCascadePaddedFrustumClipBounds(matShadowProjection, 1.5);
            return all(greaterThan(clipPos, -paddedSize)) && all(lessThan(clipPos, paddedSize));
        }
    #endif

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

#if (defined RENDER_VERTEX || defined RENDER_GEOMETRY) && !defined RENDER_COMPOSITE
    // returns: tile [0-3] or -1 if excluded
    int GetShadowTile(const in mat4 matShadowProjections[4], const in vec3 blockPos) {
        //#ifdef SHADOW_CSM_FITRANGE
        //    const int max = 3;
        //#else
            const int max = 4;
        //#endif

        for (int i = 0; i < max; i++) {
            #ifdef IRIS_FEATURE_SSBO
                if (CascadeContainsProjection(blockPos, i)) return i;
            #else
                if (CascadeContainsProjection(blockPos, matShadowProjections[i])) return i;
            #endif
        }

        //#ifdef SHADOW_CSM_FITRANGE
        //    return 3;
        //#else
            return -1;
        //#endif
    }
#endif

#if defined RENDER_VERTEX && !defined RENDER_COMPOSITE
    void ApplyShadows(const in vec3 localPos) {
        #ifndef RENDER_TEXTURED
            shadowTileColor = vec3(1.0);
        #endif

        #ifndef IRIS_FEATURE_SSBO
            cascadeSize[0] = GetCascadeDistance(0);
            cascadeSize[1] = GetCascadeDistance(1);
            cascadeSize[2] = GetCascadeDistance(2);
            cascadeSize[3] = GetCascadeDistance(3);

            mat4 cascadeProjection[4];
            cascadeProjection[0] = GetShadowTileProjectionMatrix(cascadeSize, 0);
            cascadeProjection[1] = GetShadowTileProjectionMatrix(cascadeSize, 1);
            cascadeProjection[2] = GetShadowTileProjectionMatrix(cascadeSize, 2);
            cascadeProjection[3] = GetShadowTileProjectionMatrix(cascadeSize, 3);
        #endif

        vec3 shadowViewPos = (shadowModelView * vec4(localPos, 1.0)).xyz;

        for (int i = 0; i < 4; i++) {
            #ifndef IRIS_FEATURE_SSBO
                shadowProjectionSize[i] = 2.0 / vec2(
                    cascadeProjection[i][0].x,
                    cascadeProjection[i][1].y);
            #endif
            
            // convert to shadow screen space
            shadowPos[i] = (cascadeProjection[i] * vec4(shadowViewPos, 1.0)).xyz;

            shadowPos[i] = shadowPos[i] * 0.5 + 0.5; // convert from -1 ~ +1 to 0 ~ 1

            #ifdef IRIS_FEATURE_SSBO
                shadowPos[i].xy = shadowPos[i].xy * 0.5 + shadowProjectionPos[i]; // scale and translate to quadrant
            #else
                vec2 shadowProjectionPos = GetShadowTilePos(i);
                shadowPos[i].xy = shadowPos[i].xy * 0.5 + shadowProjectionPos; // scale and translate to quadrant
            #endif
        }

        #if defined RENDER_ENTITIES || defined RENDER_HAND
            vec3 blockPos = vec3(0.0);
        #elif defined RENDER_TEXTURED
            vec3 blockPos = gl_Vertex.xyz;
            blockPos = floor(blockPos + 0.5);
            blockPos = (shadowModelView * vec4(blockPos, 1.0)).xyz;
        #else
            vec3 blockPos = floor(gl_Vertex.xyz + at_midBlock / 64.0 + fract(cameraPosition));
            blockPos = (gl_ModelViewMatrix * vec4(blockPos, 1.0)).xyz;
            blockPos = (shadowModelView * (gbufferModelViewInverse * vec4(blockPos, 1.0))).xyz;
        #endif

        shadowTile = GetShadowTile(cascadeProjection, blockPos);
    }
#endif
