float SampleDepthTiles(const in sampler2D depthtex, const in vec2 texcoord, const in int level) {
    ivec2 viewSize = ivec2(viewWidth, viewHeight);
    float depth = 1.0;

    if (level == 0) depth = texelFetch(depthtex, ivec2(texcoord * viewSize), 0).r;
    else {
        ivec2 tileSize = viewSize / int(exp2(level));

        ivec2 uv = ivec2(texcoord * tileSize);

        if (level == 4) {
            uv += ivec2(tileSize * ivec2(6, 8));
        }
        else if (level == 3) {
            uv += ivec2(tileSize * ivec2(2, 4));
        }
        else if (level == 2) {
            uv += ivec2(tileSize * ivec2(0, 2));
        }

        return texelFetch(texDepthNear, uv, 0).r;
        //return imageLoad(imgDepthNear, uv).r;
    }

    return depth;
}

// returns: xyz=clip-pos  w=attenuation
vec4 GetReflectionPosition(const in sampler2D depthtex, const in vec3 clipPos, const in vec3 clipRay) {
    float screenRayLength = length(clipRay);
    if (screenRayLength < EPSILON) return vec4(0.0);

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 ssrPixelSize = rcp(viewSize);

    vec3 screenRay = clipRay / screenRayLength;



    vec2 origin = clipPos.xy * viewSize;
    vec3 direction = screenRay;

    vec2 stepDir = sign(direction.xy);
    vec2 stepSizes = rcp(abs(direction.xy));// * viewSize;
    vec2 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction.xy;



    vec2 screenRayAbs = abs(screenRay.xy);
    if (screenRayAbs.y > screenRayAbs.x)
        screenRay *= ssrPixelSize.y / abs(screenRay.y);
    else
        screenRay *= ssrPixelSize.x / abs(screenRay.x);

    vec3 lastTracePos = clipPos + screenRay;
    vec3 lastVisPos = lastTracePos;

    float startDepthLinear = linearizeDepthFast(clipPos.z, near, far);
    ivec2 iuv_start = ivec2(clipPos.xy * viewSize);



    float closestDist = minOf(nextDist);
    vec2 currPos = origin + direction.xy * closestDist;

    bvec2 stepAxis = lessThanEqual(nextDist, vec2(closestDist));

    nextDist -= closestDist;
    nextDist += stepSizes * vec2(stepAxis);



    const vec3 clipMin = vec3(0.0);
    vec3 clipMax = vec3(1.0) - vec3(ssrPixelSize, EPSILON);

    const int minLod = 0;

    int i;
    int level = minLod;
    float alpha = 0.0;
    float texDepth;
    vec3 tracePos;
    for (i = 0; i < SSR_MAXSTEPS && alpha < EPSILON; i++) {
        int l2 = int(exp2(level));
        tracePos = lastTracePos + screenRay*l2;



        closestDist = minOf(nextDist);
        vec2 ddaStep = direction.xy * closestDist * l2;

        //float currLen2 = length2(currPos - origin);
        //if (currLen2 > traceRayLen2) currPos = endPos;
        
        //vec3 voxelPos = floor(0.5 * (currPos + rayStart));

        //if (ivec3(0.5 * (currPos + rayStart)) == ivec3(origin)) continue;

        stepAxis = lessThanEqual(nextDist, vec2(closestDist));

        nextDist -= closestDist;
        nextDist += stepSizes * vec2(stepAxis);



        vec3 t = clamp(tracePos, clipMin, clipMax);
        if (tracePos.z >= 1.0 && t != tracePos) {
            if (level > minLod) {
                level--;
                continue;
            }

            lastVisPos = t;
            alpha = 1.0;
            break;
        }

        //float depthBias = -0.01 * (1.0 - clipPos.z);
        //texDepth = SampleDepthTiles(depthtex, tracePos.xy, level);
        texDepth = SampleDepthTiles(depthtex, (currPos) / viewSize, level);

        float traceDepthL = linearizeDepthFast(tracePos.z, near, far);
        float sampleDepthL = linearizeDepthFast(texDepth, near, far);

        bool ignoreIfCloserThanStartAndMovingAway = texDepth < clipPos.z && screenRay.z > 0.0;
        bool ignoreIfTraceNearer = tracePos.z < texDepth + 0.0001;
        //bool ignoreIfTraceNearer = traceDepthL < sampleDepthL + 0.1;
        bool ignoreIfTooThick = traceDepthL > sampleDepthL + 1.0 && screenRay.z < 0.0;

        if (ignoreIfCloserThanStartAndMovingAway || ignoreIfTraceNearer || ignoreIfTooThick) {
            lastTracePos = tracePos;
            currPos += ddaStep;

            if (ignoreIfTraceNearer) lastVisPos = tracePos;

            if (level < SSR_LOD_MAX) {
                //vec2 halfPos = floor(currPos + 0.5) * 0.5;
                //if (all(greaterThan(abs(fract(halfPos) - 0.5), vec2(0.49)))) level++;

                level++;
            }

            continue;
        }

        if (level > minLod) {
            level--;
            continue;
        }

        //lastTracePos = tracePos;
        alpha = 1.0;
    }

    return vec4(lastVisPos, alpha);
}

// uv=tracePos.xy
vec3 GetRelectColor(const in vec2 uv, inout float alpha, const in float lod) {
    vec3 color = vec3(0.0);

    if (alpha > EPSILON) {
        vec2 alphaXY = saturate(12.0 * abs(vec2(0.5) - uv) - 5.0);
        alpha = maxOf(alphaXY);
        alpha = 1.0 - pow4(alpha);

        color = textureLod(BUFFER_FINAL, uv, lod).rgb;
    }

    return color;
}
