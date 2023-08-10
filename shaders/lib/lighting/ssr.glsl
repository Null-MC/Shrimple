#if SSR_QUALITY == 2
    const int SSR_MinLod = 0;
    const int SSR_MaxStepCount = 128;
    //const float SSR_StepScale = 1.0;
#elif SSR_QUALITY == 1
    const int SSR_MinLod = 1;
    const int SSR_MaxStepCount = 64;
    //const float SSR_StepScale = 2.0;
#else
    const int SSR_MinLod = 2;
    const int SSR_MaxStepCount = 32;
    //const float SSR_StepScale = 4.0;
#endif


float SampleDepthTiles(const in sampler2D depthtex, const in vec2 texcoord, const in int level) {
    const ivec2 tileOffsets[] = ivec2[](
        ivec2(0, 0),
        ivec2(0, 2),
        ivec2(2, 4),
        ivec2(6, 8));

    //ivec2 viewSize = ivec2(viewWidth, viewHeight);
    float depth = 1.0;

    if (level == 0) depth = texelFetch(depthtex, ivec2(texcoord * viewSize), 0).r;
    else {
        ivec2 tileSize = viewSize / int(exp2(level));

        ivec2 uv = ivec2(texcoord * tileSize);

        uv += tileSize * tileOffsets[level - 1];

        return texelFetch(texDepthNear, uv, 0).r;
        //return imageLoad(imgDepthNear, uv).r;
    }

    return depth;
}

// returns: xyz=clip-pos  w=attenuation
vec4 GetReflectionPosition(const in sampler2D depthtex, const in vec3 clipPos, const in vec3 clipRay) {
    float screenRayLength = length(clipRay);
    if (screenRayLength < EPSILON) return vec4(0.0);

    //vec2 viewSize = vec2(viewWidth, viewHeight);
    //vec2 ssrPixelSize = rcp(viewSize);

    vec3 screenRay = clipRay / screenRayLength;



    vec2 origin = clipPos.xy * viewSize;

    #ifdef SSR_HIZ
        vec3 direction = screenRay;

        vec2 stepDir = sign(direction.xy);
        vec2 stepSizes = rcp(abs(direction.xy));// * viewSize;
        vec2 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction.xy;
    #endif



    vec2 screenRayAbs = abs(screenRay.xy);
    if (screenRayAbs.y > screenRayAbs.x)
        screenRay *= pixelSize.y / abs(screenRay.y);
    else
        screenRay *= pixelSize.x / abs(screenRay.x);

    vec3 lastTracePos = clipPos + screenRay;
    vec3 lastVisPos = lastTracePos;

    float startDepthLinear = linearizeDepthFast(clipPos.z, near, far);
    //ivec2 iuv_start = ivec2(origin);

    //return vec4(lastVisPos, 1.0);


    #ifdef SSR_HIZ
        float closestDist = minOf(nextDist);
        vec2 currPos = origin + direction.xy * closestDist;

        bvec2 stepAxis = lessThanEqual(nextDist, vec2(closestDist));

        nextDist -= closestDist;
        nextDist += stepSizes * vec2(stepAxis);
    #endif



    const vec3 clipMin = vec3(0.0);
    vec3 clipMax = vec3(1.0) - vec3(pixelSize, EPSILON);

    int i;
    int level = SSR_MinLod;
    float alpha = 0.0;
    float texDepth;
    vec3 tracePos;
    for (i = 0; i < SSR_MaxStepCount && alpha < EPSILON; i++) {
        int l2 = int(exp2(level));
        tracePos = lastTracePos + screenRay*l2;



        #ifdef SSR_HIZ
            closestDist = minOf(nextDist);
            vec2 ddaStep = direction.xy * closestDist * l2;

            //float currLen2 = length2(currPos - origin);
            //if (currLen2 > traceRayLen2) currPos = endPos;
            
            //vec3 voxelPos = floor(0.5 * (currPos + rayStart));

            //if (ivec3(0.5 * (currPos + rayStart)) == ivec3(origin)) continue;

            stepAxis = lessThanEqual(nextDist, vec2(closestDist));

            nextDist -= closestDist;
            nextDist += stepSizes * vec2(stepAxis);
        #endif



        // vec3 t = clamp(tracePos, clipMin, clipMax);
        // if (t != tracePos) {
        //     if (level > SSR_MinLod) {
        //         level--;
        //         continue;
        //     }

        //     lastVisPos = t;
        //     alpha = 1.0;
        //     break;
        // }

        #ifdef SSR_HIZ
            texDepth = SampleDepthTiles(depthtex, currPos * pixelSize, level);
        #else
            float depthBias = -0.01 * (1.0 - clipPos.z);
            texDepth = SampleDepthTiles(depthtex, tracePos.xy, 0);
        #endif

        float traceDepthL = linearizeDepthFast(tracePos.z, near, far);
        float sampleDepthL = linearizeDepthFast(texDepth, near, far);

        bool ignoreIfCloserThanStartAndMovingAway = texDepth < clipPos.z && screenRay.z > 0.0;
        bool ignoreIfTraceNearer = traceDepthL < sampleDepthL + 0.001;
        //bool ignoreIfTraceNearer = traceDepthL < sampleDepthL + 0.1;
        bool ignoreIfTooThick = false;//traceDepthL > sampleDepthL + 1.0 && screenRay.z < 0.0;

        if (ignoreIfTraceNearer) lastVisPos = tracePos;

        if (ignoreIfCloserThanStartAndMovingAway || ignoreIfTraceNearer || ignoreIfTooThick) {
            lastTracePos = tracePos;

            //if (ignoreIfTraceNearer) lastVisPos = tracePos;

            #ifdef SSR_HIZ
                currPos += ddaStep;

                if (level < SSR_LOD_MAX) {
                    //vec2 halfPos = floor(currPos + 0.5) * 0.5;
                    //if (all(greaterThan(abs(fract(halfPos) - 0.5), vec2(0.49)))) level++;

                    level++;
                }
            #endif

            continue;
        }

        #ifdef SSR_HIZ
            if (level > SSR_MinLod) {
                level--;
                continue;
            }
        #endif

        //lastTracePos = tracePos;
        lastVisPos = tracePos;
        alpha = 1.0;
    }

    return vec4(tracePos, alpha);
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
