vec3 GetLightGlassTint(const in uint blockType) {
    vec3 stepTint = vec3(1.0);

    switch (blockType) {
        case BLOCKTYPE_DIAMOND:
            stepTint = vec3(0.427, 0.969, 0.910);
            break;
        case BLOCKTYPE_EMERALD:
            stepTint = vec3(0.153, 0.804, 0.349);
            break;
    }

    switch (blockType) {
        case BLOCKTYPE_AMETHYST:
            stepTint = vec3(0.707, 0.526, 0.944);
            break;
        case BLOCKTYPE_HONEY:
            stepTint = vec3(0.984, 0.733, 0.251);
            break;
        case BLOCKTYPE_SLIME:
            stepTint = vec3(0.408, 0.725, 0.329);
            break;
        case BLOCKTYPE_SNOW:
            stepTint = vec3(0.375, 0.546, 0.621);
            break;
        case BLOCKTYPE_STAINED_GLASS_BLACK:
            stepTint = vec3(0.1, 0.1, 0.1);
            break;
        case BLOCKTYPE_STAINED_GLASS_BLUE:
            stepTint = vec3(0.1, 0.1, 0.98);
            break;
        case BLOCKTYPE_STAINED_GLASS_BROWN:
            stepTint = vec3(0.566, 0.388, 0.148);
            break;
        case BLOCKTYPE_STAINED_GLASS_CYAN:
            stepTint = vec3(0.082, 0.533, 0.763);
            break;
        case BLOCKTYPE_STAINED_GLASS_GRAY:
            stepTint = vec3(0.4, 0.4, 0.4);
            break;
        case BLOCKTYPE_STAINED_GLASS_GREEN:
            stepTint = vec3(0.125, 0.808, 0.081);
            break;
        case BLOCKTYPE_STAINED_GLASS_LIGHT_BLUE:
            stepTint = vec3(0.320, 0.685, 0.955);
            break;
        case BLOCKTYPE_STAINED_GLASS_LIGHT_GRAY:
            stepTint = vec3(0.7, 0.7, 0.7);
            break;
        case BLOCKTYPE_STAINED_GLASS_LIME:
            stepTint = vec3(0.633, 0.924, 0.124);
            break;
        case BLOCKTYPE_STAINED_GLASS_MAGENTA:
            stepTint = vec3(0.698, 0.298, 0.847);
            break;
        case BLOCKTYPE_STAINED_GLASS_ORANGE:
            stepTint = vec3(0.919, 0.586, 0.185);
            break;
        case BLOCKTYPE_STAINED_GLASS_PINK:
            stepTint = vec3(0.949, 0.274, 0.497);
            break;
        case BLOCKTYPE_STAINED_GLASS_PURPLE:
            stepTint = vec3(0.578, 0.170, 0.904);
            break;
        case BLOCKTYPE_STAINED_GLASS_RED:
            stepTint = vec3(0.999, 0.188, 0.188);
            break;
        case BLOCKTYPE_STAINED_GLASS_WHITE:
            stepTint = vec3(0.96, 0.96, 0.96);
            break;
        case BLOCKTYPE_STAINED_GLASS_YELLOW:
            stepTint = vec3(0.965, 0.965, 0.123);
            break;
    }

    return RGBToLinear(stepTint);
}

vec3 TraceDDA_fast(vec3 origin, const in vec3 endPos, const in float range) {
    vec3 traceRay = endPos - origin;
    float traceRayLen = length(traceRay);
    if (traceRayLen < EPSILON) return vec3(1.0);

    vec3 direction = traceRay / traceRayLen;
    float STEP_COUNT = 16;//ceil(traceRayLen);

    vec3 stepSizes = 1.0 / abs(direction);
    vec3 stepDir = sign(direction);
    vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction;

    float traceRayLen2 = _pow2(traceRayLen);
    vec3 color = vec3(1.0);
    vec3 currPos = origin;
    bool hit = false;

    for (int i = 0; i < STEP_COUNT && !hit; i++) {
        vec3 rayStart = currPos;

        float closestDist = minOf(nextDist);
        currPos += direction * closestDist;
        if (dot(currPos - origin, traceRay) > traceRayLen2) break;

        vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));

        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;
        
        vec3 voxelPos = floor(0.5 * (currPos + rayStart));

        ivec3 gridCell, blockCell;
        if (GetSceneLightGridCell(voxelPos, gridCell, blockCell)) {
            uint gridIndex = GetSceneLightGridIndex(gridCell);
            uint blockType = GetSceneBlockMask(blockCell, gridIndex);

            if (blockType >= BLOCKTYPE_AMETHYST && blockType <= BLOCKTYPE_STAINED_GLASS_YELLOW) {
                vec3 glassTint = GetLightGlassTint(blockType);
                color *= exp(-2.0 * DynamicLightTintF * closestDist * (1.0 - glassTint));
            }
            else if (blockType != BLOCKTYPE_EMPTY) {
                //vec3 rayInv = rcp(currPos - rayStart);
                hit = true;//TraceHitTest(blockType, rayStart - voxelPos, rayInv);
                color = vec3(0.0);
            }
        }
    }

    return color;
}

vec3 TraceDDA(vec3 origin, const in vec3 endPos, const in float range) {
    vec3 traceRay = endPos - origin;
    float traceRayLen = length(traceRay);
    if (traceRayLen < EPSILON) return vec3(1.0);

    vec3 direction = traceRay / traceRayLen;
    float STEP_COUNT = 16;//ceil(traceRayLen);

    vec3 stepSizes = 1.0 / abs(direction);
    vec3 stepDir = sign(direction);
    vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction;

    float traceRayLen2 = _pow2(traceRayLen);
    vec3 color = vec3(1.0);
    vec3 currPos = origin;
    bool hit = false;

    #ifdef DYN_LIGHT_PLAYER_SHADOW
        // TODO: entity tracing
        vec3 playerPos = vec3(0.0);
        if (!firstPersonCamera) playerPos += eyePosition - cameraPosition;
        playerPos = GetLightGridPosition(playerPos);
    #endif

    #if DYN_LIGHT_TINT_MODE == LIGHT_TINT_BASIC
        uint blockTypeLast;
    #endif

    for (int i = 0; i < STEP_COUNT && !hit; i++) {
        vec3 rayStart = currPos;

        float closestDist = minOf(nextDist);
        currPos += direction * closestDist;
        if (length2(currPos - origin) > traceRayLen2) break;

        vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));

        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;
        
        vec3 voxelPos = floor(0.5 * (currPos + rayStart));

        ivec3 gridCell, blockCell;
        if (GetSceneLightGridCell(voxelPos, gridCell, blockCell)) {
            uint gridIndex = GetSceneLightGridIndex(gridCell);
            uint blockType = GetSceneBlockMask(blockCell, gridIndex);

            #if DYN_LIGHT_TINT_MODE == LIGHT_TINT_ABSORB
                if (blockType >= BLOCKTYPE_AMETHYST && blockType <= BLOCKTYPE_STAINED_GLASS_YELLOW) {
                    vec3 glassTint = GetLightGlassTint(blockType);
                    color *= exp(-2.0 * DynamicLightTintF * closestDist * (1.0 - glassTint));
                }
                else {
            #elif DYN_LIGHT_TINT_MODE == LIGHT_TINT_BASIC
                if (blockType >= BLOCKTYPE_AMETHYST && blockType <= BLOCKTYPE_STAINED_GLASS_YELLOW && blockType != blockTypeLast) {
                    vec3 glassTint = GetLightGlassTint(blockType) * DynamicLightTintF;
                    glassTint += max(1.0 - DynamicLightTintF, 0.0);
                    color *= glassTint;
                }
                else {
            #endif

                if (blockType != BLOCKTYPE_EMPTY) {
                    vec3 rayInv = rcp(currPos - rayStart);
                    hit = TraceHitTest(blockType, rayStart - voxelPos, rayInv);
                    //if (hit) color = vec3(0.0);
                }

            #if DYN_LIGHT_TINT_MODE != LIGHT_TINT_NONE
                }
            #endif

            #if DYN_LIGHT_TINT_MODE == LIGHT_TINT_BASIC
                blockTypeLast = blockType;
            #endif
        }

        #ifdef DYN_LIGHT_PLAYER_SHADOW
            vec3 playerOffset = voxelPos - playerPos;
            if (!hit && dot(playerOffset, playerOffset) < _pow2(2.0)) {
                vec3 boundsMin = vec3(-0.3, -2.0, -0.3);
                vec3 boundsMax = vec3( 0.3,  0.0,  0.3);

                #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                    hit = BoxPointTest(boundsMin, boundsMax, rayStart - playerPos);
                #else
                    vec3 rayInv = rcp(currPos - rayStart);
                    hit = BoxRayTest(boundsMin, boundsMax, rayStart - playerPos, rayInv);
                #endif
            }
        #endif
    }

    if (hit) color = vec3(0.0);
    return color;
}

vec3 TraceRay(const in vec3 origin, const in vec3 endPos, const in float range) {
    vec3 traceRay = endPos - origin;
    float traceRayLen = length(traceRay);
    if (traceRayLen < EPSILON) return vec3(1.0);

    int stepCount = int(0.5 * DYN_LIGHT_RAY_QUALITY * range);
    float dither = InterleavedGradientNoise(gl_FragCoord.xy);
    vec3 stepSize = traceRay / stepCount;
    vec3 color = vec3(1.0);
    bool hit = false;
    
    uint blockTypeLast;
    for (int i = 1; i < stepCount && !hit; i++) {
        vec3 gridPos = (i + dither) * stepSize + origin;
        
        ivec3 gridCell, blockCell;
        if (GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
            uint gridIndex = GetSceneLightGridIndex(gridCell);
            uint blockType = GetSceneBlockMask(blockCell, gridIndex);

            if (blockType >= BLOCKTYPE_AMETHYST && blockType <= BLOCKTYPE_STAINED_GLASS_YELLOW && blockType != blockTypeLast) {
                color *= GetLightGlassTint(blockType);
            }
            else if (blockType != BLOCKTYPE_EMPTY) {
                vec3 blockPos = fract(gridPos);
                hit = TraceHitTest(blockType, blockPos, vec3(0.0));
                if (hit) color = vec3(0.0);
            }

            blockTypeLast = blockType;
        }
    }

    return color;
}

vec3 GetLightPenumbraOffset() {
    float ign = InterleavedGradientNoise(gl_FragCoord.xy);
    vec4 noise = hash41(ign + 0.1 * frameCounter);
    vec3 offset = normalize(noise.xyz*2.0 - 1.0);
    return offset * pow(noise.w, (1.0/3.0));
}
