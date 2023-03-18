vec3 GetLightGlassTint(const in uint blockType) {
    vec3 stepTint = vec3(1.0);

    switch (blockType) {
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
            stepTint = vec3(0.934, 0.518, 0.163);
            break;
        case BLOCKTYPE_STAINED_GLASS_PINK:
            stepTint = vec3(0.949, 0.274, 0.497);
            break;
        case BLOCKTYPE_STAINED_GLASS_PURPLE:
            stepTint = vec3(0.578, 0.170, 0.904);
            break;
        case BLOCKTYPE_STAINED_GLASS_RED:
            stepTint = vec3(0.98, 0.1, 0.1);
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

vec3 TraceDDA(vec3 origin, const in vec3 endPos, const in float range) {
    vec3 traceRay = endPos - origin;
    float traceRayLen = length(traceRay);
    if (traceRayLen < EPSILON) return vec3(1.0);

    vec3 direction = traceRay / traceRayLen;
    float STEP_COUNT = 16;//ceil(traceRayLen);

    vec3 stepSizes = 1.0 / abs(direction);
    vec3 stepDir = sign(direction);
    vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction;

    float traceRayLen2 = pow2(traceRayLen);
    vec3 currPos = origin;

    uint blockTypeLast = BLOCKTYPE_EMPTY;
    vec3 color = vec3(1.0);
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

            if (blockType >= BLOCKTYPE_HONEY && blockType <= BLOCKTYPE_STAINED_GLASS_YELLOW) {
                vec3 glassTint = GetLightGlassTint(blockType);
                color *= exp(-2.0 * DynamicLightTintF * closestDist * (1.0 - glassTint));
            }
            else if (blockType != BLOCKTYPE_EMPTY) {
                vec3 rayInv = rcp(currPos - rayStart);
                hit = TraceHitTest(blockType, rayStart - voxelPos, rayInv);
                if (hit) color = vec3(0.0);
            }

            blockTypeLast = blockType;
        }
    }

    return color;
}

vec3 TraceRay(const in vec3 origin, const in vec3 endPos, const in float range) {
    vec3 traceRay = endPos - origin;
    float traceRayLen = length(traceRay);
    if (traceRayLen < EPSILON) return vec3(1.0);

    int stepCount = int(0.5 * DYN_LIGHT_RAY_QUALITY * range);
    float dither = InterleavedGradientNoise(gl_FragCoord.xy);// + frameCounter);
    vec3 stepSize = traceRay / stepCount;
    vec3 color = vec3(1.0);
    bool hit = false;
    
    //vec3 lastGridPos = origin;
    uint blockTypeLast;
    for (int i = 1; i < stepCount && !hit; i++) {
        vec3 gridPos = (i + dither) * stepSize + origin;
        
        ivec3 gridCell, blockCell;
        if (GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
            uint gridIndex = GetSceneLightGridIndex(gridCell);
            uint blockType = GetSceneBlockMask(blockCell, gridIndex);

            if (blockType >= BLOCKTYPE_STAINED_GLASS_BLACK && blockType <= BLOCKTYPE_STAINED_GLASS_YELLOW && blockType != blockTypeLast) {
                color *= GetLightGlassTint(blockType);
            }
            else if (blockType != BLOCKTYPE_EMPTY) {
                vec3 blockPos = fract(gridPos);
                hit = TraceHitTest(blockType, blockPos, vec3(0.0));
                if (hit) color = vec3(0.0);
            }

            blockTypeLast = blockType;
        }

        //lastGridPos = gridPos;
    }

    return color;
}

void ApplyLightPenumbraOffset(inout vec3 position) {
    float ign = InterleavedGradientNoise(gl_FragCoord.xy);
    vec4 noise = hash41(ign + 0.1 * frameCounter);
    vec3 offset = noise.xyz*2.0 - 1.0;
    offset *= pow(noise.w, (1.0/3.0)) / length(offset);

    position += DynamicLightPenumbra * offset;
}
