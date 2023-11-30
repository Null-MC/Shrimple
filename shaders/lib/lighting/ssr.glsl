const int SSR_LodMin = 0;


//#if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
    float SampleDepthTiles(const in sampler2D depthtex, const in vec2 texcoord, const in int level) {
        float depth = 1.0;

        if (level == 0) depth = texelFetch(depthtex, ivec2(texcoord * viewSize), 0).r;
        else {
            vec2 uv = GetDepthTileCoord(viewSize, texcoord, level - 1);
            //vec2 nearViewSize = vec2(viewWidth * 0.5, viewHeight * 0.75);
            //return textureLod(texDepthNear, (uv + 1.0) / nearViewSize, 0).r;
            return texelFetch(texDepthNear, ivec2(uv), 0).r;
            //return imageLoad(imgDepthNear, uv).r;
        }

        return depth;
    }
//#endif

// returns: xyz=clip-pos  w=attenuation
vec4 GetReflectionPosition(const in sampler2D depthtex, const in vec3 clipPos, const in vec3 clipRay) {
    float screenRayLength = length(clipRay);
    if (screenRayLength < EPSILON) return vec4(0.0);

    //vec2 viewSize = vec2(viewWidth, viewHeight);
    //vec2 ssrPixelSize = rcp(viewSize);

    vec3 screenRay = clipRay / screenRayLength;

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    // #ifndef MATERIAL_REFLECT_HIZ
    //     dither += 2.0;
    // #endif


    #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
        vec2 origin = clipPos.xy * viewSize + screenRay.xy * dither;
        vec3 direction = screenRay;

        vec2 stepDir = sign(direction.xy);
        vec2 stepSizes = rcp(abs(direction.xy));// * viewSize;
        vec2 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction.xy;
    #endif

    vec2 screenRayAbs = abs(screenRay.xy);
    vec3 rayX = screenRay * (pixelSize.x / screenRayAbs.x);
    vec3 rayY = screenRay * (pixelSize.y / screenRayAbs.y);
    screenRay = mix(rayX, rayY, screenRayAbs.y);

    // if (screenRayAbs.y > screenRayAbs.x / aspectRatio)
    //     screenRay *= pixelSize.y / screenRayAbs.y;
    // else
    //     screenRay *= pixelSize.x / screenRayAbs.x;

    int level = 0;
    #ifndef MATERIAL_REFLECT_HIZ
        //screenRay *= 8.0;
        level = 3;//clamp(int(log2(maxOf(viewSize) / SSR_MAXSTEPS + 1.0)), 0, 5);
    #endif

    vec3 lastTracePos = clipPos + screenRay * (1.0 + dither);
    vec3 lastVisPos = lastTracePos;

    float startDepthLinear = linearizeDepthFast(clipPos.z, near, far);
    ivec2 iuv_start = ivec2(clipPos.xy * viewSize);


    #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
        float closestDist = minOf(nextDist);
        vec2 currPos = origin + direction.xy * closestDist;
        vec2 lastPos = currPos;

        bvec2 stepAxis = lessThanEqual(nextDist, vec2(closestDist));

        nextDist -= closestDist;
        nextDist += stepSizes * vec2(stepAxis);
    #endif


    const vec3 clipMin = vec3(0.0);
    vec3 clipMax = vec3(1.0) - vec3(pixelSize, EPSILON);

    int i;
    float alpha = 0.0;
    float texDepth;
    vec3 tracePos;
    for (i = 0; i < SSR_MAXSTEPS; i++) {
        int l2 = int(exp2(level));
        tracePos = lastTracePos + screenRay*l2;


        #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
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


        vec3 t = clamp(tracePos, clipMin, clipMax);
        if (tracePos.z > 0.999 && t != tracePos) {
            if (level > SSR_LodMin && i < SSR_MAXSTEPS - (level + 1)) {
                level--;
                continue;
            }

            lastVisPos = t;
            alpha = 1.0;
            break;
        }

        //float depthBias = -0.01 * (1.0 - clipPos.z);
        //texDepth = SampleDepthTiles(depthtex, tracePos.xy, level);
        #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
            //texDepth = SampleDepthTiles(depthtex, currPos / viewSize, level);
            texDepth = SampleDepthTiles(depthtex, 0.5*(lastPos + currPos) / viewSize, level);
        #else
            //texDepth = SampleDepthTiles(depthtex, tracePos.xy, 0);
            //texDepth = texelFetch(depthtex, ivec2(tracePos.xy * viewSize), 0).r;
            //texDepth = textureLod(depthtex, tracePos.xy, 4).r;

            texDepth = SampleDepthTiles(depthtex, tracePos.xy, level);
        #endif

        //float minTraceDepth = min(tracePos.z, lastTracePos.z);
        float traceDepthL = linearizeDepthFast(tracePos.z, near, far);
        float sampleDepthL = linearizeDepthFast(texDepth, near, far);

        bool isCloserThanStartAndMovingAway = clipPos.z > texDepth + 0.002 && screenRay.z > 0.0;
        bool isTraceNearerThanSample = tracePos.z < texDepth + 0.00002;// - 0.04 * exp2(level) + EPSILON;
        //bool isTraceNearerThanStart = traceDepthL < sampleDepthL + 0.1;
        bool isTooThickAndMovingNearer = false;//traceDepthL > sampleDepthL + 1.0 && screenRay.z < 0.0;

        // if (isTraceNearerThanSample && !isCloserThanStartAndMovingAway) {
        //     lastVisPos = tracePos;
        //     alpha = 1.0;
        // }

        if (isTraceNearerThanSample || isCloserThanStartAndMovingAway || isTooThickAndMovingNearer) {
            lastTracePos = tracePos;

            #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
                lastPos = currPos;
                currPos += ddaStep;
            #endif

            if (level < SSR_LOD_MAX) {
                //vec2 halfPos = floor(currPos + 0.5) * 0.5;
                //if (all(greaterThan(abs(fract(halfPos) - 0.5), vec2(0.49)))) level++;

                level++;
            }

            continue;
        }

        //#if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
            if (level > SSR_LodMin && i < SSR_MAXSTEPS - (level + 1)) {
               level--;
               continue;
            }
        //#endif

        //lastTracePos = tracePos;
        lastVisPos = tracePos;
        alpha = 1.0;
        break;
    }

    // if (i == SSR_MAXSTEPS) {
    //     lastVisPos = tracePos;
    //     alpha = 1.0;
    // }

    #ifdef SSR_DEBUG
        alpha *= level + 0.1;
    #endif

    return vec4(lastVisPos, alpha);
}

// uv=tracePos.xy
vec3 GetRelectColor(const in vec2 uv, inout float alpha, const in float lod) {
    vec3 color = vec3(0.0);

    if (alpha > EPSILON) {
        #ifdef SSR_DEBUG
            if (alpha < 0.5)
                color = vec3(1.0,0.0,0.0);
            else if (alpha < 1.5)
                color = vec3(1.0,1.0,0.0);
            else if (alpha < 2.5)
                color = vec3(0.0,1.0,0.0);
            else if (alpha < 3.5)
                color = vec3(0.0,1.0,1.0);
            else if (alpha < 4.5)
                color = vec3(0.0,0.0,1.0);
            else
                color = vec3(1.0,1.0,1.0);

            alpha = 1.0;
        #else
            vec2 alphaXY = saturate(12.0 * abs(vec2(0.5) - uv) - 5.0);
            alpha = maxOf(alphaXY);
            alpha = 1.0 - pow4(alpha);

            color = textureLod(BUFFER_FINAL, uv, lod).rgb;
        #endif
    }

    return color;
}
