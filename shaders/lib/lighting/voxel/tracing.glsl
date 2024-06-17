#define DDA_MAX_STEP ((LIGHTING_RANGE/100.0) * 24)

const uint DDAStepCount = uint(DDA_MAX_STEP);


bool BoxRayTest(const in vec3 boxMin, const in vec3 boxMax, const in vec3 rayStart, const in vec3 rayInv) {
    vec3 t1 = (boxMin - rayStart) * rayInv;
    vec3 t2 = (boxMax - rayStart) * rayInv;

    vec3 tmin = min(t1, t2);
    vec3 tmax = max(t1, t2);

    float rmin = maxOf(tmin);
    float rmax = minOf(tmax);

    return !isinf(rmin) && min(rmax, 1.0) >= max(rmin, 0.0);
}

bool BoxPointTest(const in vec3 boxMin, const in vec3 boxMax, const in vec3 point) {
    return all(greaterThanEqual(point, boxMin)) && all(lessThanEqual(point, boxMax));
}

bool CylinderRayTest(const in vec3 rayOrigin, const in vec3 rayVec, const in float radius, const in float height) {
    float rayLen = length(rayVec);
    vec3 rayDir = rayVec / max(rayLen, EPSILON);

    float k2 = 1.0 - _pow2(rayDir.y);
    float k1 = dot(rayOrigin, rayDir) - rayOrigin.y*rayDir.y;
    float k0 = length2(rayOrigin) - _pow2(rayOrigin.y) - _pow2(radius);
    
    float h = k1*k1 - k2*k0;
    if (h < 0.0) return false;

    h = sqrt(h);
    float t = (-k1 - h) / k2;

    float y = rayOrigin.y + t*rayDir.y;
    if (y > -height && y < height) return t > 0.0 && t < rayLen;
    
    t = (((y < 0.0) ? -height : height) - rayOrigin.y) / rayDir.y;
    if (abs(k1 + k2*t) < h) return t > 0.0 && t < rayLen;

    return false;
}

bool TraceHitTest(const in uint blockId, const in vec3 rayStart, const in vec3 rayInv) {
    BlockCollisionData blockData = StaticBlockMap[blockId].Collisions;

    bool hit = false;
    for (uint i = 0u; i < BLOCK_MASK_PARTS; i++) {
        if (hit || i >= blockData.Count) break;

        vec3 boundsMin = unpackUnorm4x8(blockData.Bounds[i].x).xyz;
        vec3 boundsMax = unpackUnorm4x8(blockData.Bounds[i].y).xyz;

        hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
    }

    return hit;
}

vec3 TraceDDA(vec3 origin, const in vec3 endPos, const in float range, const in bool traceSelf) {
    vec3 traceRay = endPos - origin;
    float traceRayLen = length(traceRay);
    if (traceRayLen < EPSILON) return vec3(1.0);

    vec3 direction = traceRay / traceRayLen;

    vec3 stepDir = sign(direction);
    vec3 stepSizes = rcp(abs(direction));
    vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction;

    ivec3 gridCell, blockCell;

    float traceRayLen2 = _pow2(traceRayLen);
    vec3 color = vec3(1.0);
    vec3 currPos = origin;
    float currDist2 = 0.0;
    bool hit = false;

    #if LIGHTING_TINT_MODE == LIGHT_TINT_BASIC
        uint blockIdLast;
    #endif

    if (!traceSelf) {
        float closestDist = minOf(nextDist);
        currPos += direction * closestDist;

        vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));

        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;
    }

    for (int i = 0; i < DDAStepCount; i++) {
        if (hit || currDist2 >= traceRayLen2) break;

        vec3 rayStart = currPos;

        float closestDist = minOf(nextDist);
        currPos += direction * closestDist;

        float currLen2 = length2(currPos - origin);
        if (currLen2 > traceRayLen2) currPos = endPos;
        
        vec3 voxelPos = floor(0.5 * (currPos + rayStart));

        if (!traceSelf && ivec3(voxelPos) == ivec3(endPos)) i = 999;

        vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));

        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;

        if (GetVoxelGridCell(voxelPos, gridCell, blockCell)) {
            uint gridIndex = GetVoxelGridCellIndex(gridCell);
            uint blockId = GetVoxelBlockMask(blockCell, gridIndex);

            // #ifdef DYN_LIGHT_OCTREE
            //     if ((SceneBlockMaps[gridIndex].OctreeMask[0] & 1u) == 0u) continue;

            //     uvec3 nodeMin = uvec3(0);
            //     uvec3 nodeMax = uvec3(LIGHT_BIN_SIZE);
            //     uvec3 nodePos = uvec3(0);

            //     bool treeHit = true;
            //     uint nodeBitOffset = 1u;
            //     for (uint treeDepth = 0u; treeDepth < DYN_LIGHT_OCTREE_LEVELS && treeHit; treeDepth++) {
            //         uvec3 nodeCenter = (nodeMin + nodeMax) / 2u;
            //         uvec3 nodeChild = uvec3(step(nodeCenter, blockCell));

            //         uint childMask = (nodeChild.z << 2u) & (nodeChild.y << 1u) & nodeChild.x;

            //         uint nodeSize = uint(exp2(treeDepth));
            //         uint nodeMaskOffset = (nodePos.z * _pow2(nodeSize)) + (nodePos.y * nodeSize) + nodePos.x;

            //         uint nodeBitIndex = nodeBitOffset + 8u * nodeMaskOffset + childMask;
            //         uint nodeArrayIndex = nodeBitIndex / 32u;

            //         uint depthMask = SceneBlockMaps[gridIndex].OctreeMask[nodeArrayIndex];
            //         uint nodeMask = 1u << (nodeBitIndex - nodeArrayIndex);

            //         if ((depthMask & nodeMask) == 0u) {
            //             // TODO: skip
            //             // vec3 nodeMin = ;
            //             // vec3 nodeMax = ;
            //             // for (uint ix = 0u; ix < LIGHT_BIN_SIZE; ix++) {
            //             //     //
            //             // }
            //             treeHit = false;
            //             break;
            //         }

            //         nodeBitOffset += uint(pow(8u, treeDepth + 1u));

            //         uvec3 nodeHalfSize = (nodeMax - nodeMin) / 2u;
            //         nodeMin += nodeHalfSize * nodeChild;
            //         nodeMax -= nodeHalfSize * (1u - nodeChild);
            //         nodePos = (nodePos + nodeChild) * 2u;
            //     }

            //     if (!treeHit) continue;
            // #endif

            #if LIGHTING_TINT_MODE == LIGHT_TINT_ABSORB
                if (blockId >= BLOCK_HONEY && blockId <= BLOCK_TINTED_GLASS) {
                    vec3 glassTint = GetLightGlassTint(blockId);
                    color *= exp(-2.0 * Lighting_TintF * closestDist * (1.0 - glassTint));
                }
                else {
            #elif LIGHTING_TINT_MODE == LIGHT_TINT_BASIC
                if (blockId >= BLOCK_HONEY && blockId <= BLOCK_TINTED_GLASS && blockId != blockIdLast) {
                    vec3 glassTint = GetLightGlassTint(blockId) * Lighting_TintF;
                    glassTint += max(1.0 - Lighting_TintF, 0.0);
                    color *= glassTint;
                }
                else {
            #endif

                if (blockId != BLOCK_EMPTY) {
                    if (blockId == BLOCK_SOLID || IsTraceFullBlock(blockId)) hit = true;
                    else {
                        vec3 ray = currPos - rayStart;
                        vec3 rayInv = rcp(ray);

                        hit = TraceHitTest(blockId, rayStart - voxelPos, rayInv);
                    }
                }

            #if LIGHTING_TINT_MODE != LIGHT_TINT_NONE
                }
            #endif

            #if LIGHTING_TINT_MODE == LIGHT_TINT_BASIC
                blockIdLast = blockId;
            #endif
        }

        currDist2 = length2(currPos - origin);
    }

    if (hit) color = vec3(0.0);
    return color;
}

#ifndef RENDER_COMPUTE
    vec3 GetLightPenumbraOffset() {
        return hash32(gl_FragCoord.xy + 0.33 * frameCounter) - 0.5;
    }
#endif
