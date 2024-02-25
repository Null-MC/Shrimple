const int SSR_LodMin = 0;


float SampleDepthTiles(const in sampler2D depthtex, const in vec2 texcoord, const in int level) {
    if (level == 0) {
        ivec2 uv = ivec2(texcoord * viewSize);
        float depth = texelFetch(depthtex, uv, 0).r;

        float depthL = linearizeDepthFast(depth, near, farPlane);

        #ifdef DISTANT_HORIZONS
            float dhDepth = texelFetch(dhDepthTex, uv, 0).r;
            float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

            if (dhDepthL < depthL || depth >= 1.0) {
                depth = dhDepth;
                depthL = dhDepthL;
            }
        #endif

        return depthL;
    }
    else {
        vec2 uv = GetDepthTileCoord(viewSize, texcoord, level - 1);

        float _far = farPlane;
        #ifdef DISTANT_HORIZONS
            _far = dhFarPlane;
        #endif

        return texelFetch(texDepthNear, ivec2(uv), 0).r * _far;
    }
}

// returns: xyz=clip-pos  w=attenuation
vec4 GetReflectionPosition(const in sampler2D depthtex, const in vec3 clipPos, const in vec3 clipRay) {
    float screenRayLength = length(clipRay.xy);
    if (screenRayLength < EPSILON) return vec4(clipPos, 0.0);

    vec3 screenRay = clipRay / screenRayLength;

    #ifdef EFFECT_TAA_ENABLED
        float dither = InterleavedGradientNoiseTime();
    #else
        float dither = InterleavedGradientNoise();
    #endif

    #ifdef DISTANT_HORIZONS
        float _far = dhFarPlane;
    #else
        float _far = farPlane;
    #endif

    float startDepthLinear = linearizeDepth(clipPos.z, near, _far);

    // #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
    //     vec2 origin = clipPos.xy * viewSize + screenRay.xy * dither;
    //     vec3 direction = screenRay;

    //     vec2 stepDir = sign(direction.xy);
    //     vec2 stepSizes = rcp(abs(direction.xy));// * viewSize;
    //     vec2 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction.xy;
    // #endif

    vec2 screenRayAbs = abs(screenRay.xy);
    vec3 rayX = screenRay * (pixelSize.x / screenRayAbs.x);
    vec3 rayY = screenRay * (pixelSize.y / screenRayAbs.y);
    screenRay = mix(rayX, rayY, screenRayAbs.y);

    int level = 0;
    // #ifndef MATERIAL_REFLECT_HIZ
    //     //screenRay *= 8.0;
    //     level = 0;//clamp(int(log2(maxOf(viewSize) / SSR_MAXSTEPS + 1.0)), 0, 5);
    // #endif

    vec3 lastTracePos = clipPos + screenRay * (1.0 + dither);
    vec3 lastVisPos = lastTracePos;


    // #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
    //     float closestDist = minOf(nextDist);
    //     vec2 currPos = origin + direction.xy * closestDist;
    //     vec2 lastPos = currPos;

    //     bvec2 stepAxis = lessThanEqual(nextDist, vec2(closestDist));

    //     nextDist -= closestDist;
    //     nextDist += stepSizes * vec2(stepAxis);
    // #endif


    const vec3 clipMin = vec3(0.0);

    int i;
    float alpha = 0.0;
    float texDepth;
    vec3 tracePos;
    for (i = 0; i < SSR_MAXSTEPS; i++) {
        float stepScale = exp2(level);
        tracePos = screenRay*stepScale + lastTracePos;


        // #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
        //     closestDist = minOf(nextDist);
        //     vec2 ddaStep = direction.xy * closestDist * stepScale;

        //     stepAxis = lessThanEqual(nextDist, vec2(closestDist));

        //     nextDist -= closestDist;
        //     nextDist += stepSizes * vec2(stepAxis);
        // #endif


        vec3 clipMax = vec3(1.0) - vec3(pixelSize * stepScale, 0.0);

        vec3 t = clamp(tracePos, clipMin, clipMax);
        if (t != tracePos) {
            if (level > SSR_LodMin && i < SSR_MAXSTEPS - (level + 1)) {
                level--;
                continue;
            }

            lastVisPos = t;
            if (tracePos.z >= 1.0 && t.xy == tracePos.xy) alpha = 1.0;
            break;
        }

        #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
            //texDepth = SampleDepthTiles(depthtex, currPos / viewSize, level);
            float sampleDepthL = SampleDepthTiles(depthtex, 0.5*(lastPos + currPos) / viewSize, level);
        #else
            float sampleDepthL = SampleDepthTiles(depthtex, tracePos.xy, level);
        #endif

        float traceDepthL = linearizeDepth(tracePos.z, near, _far);

        float bias = 0.002;//0.1 * sampleDepthL;
        bool isCloserThanStartAndMovingAway = false;//startDepthLinear > sampleDepthL + bias && screenRay.z > 0.0;
        bool isTraceNearerThanSample = traceDepthL < sampleDepthL + bias;// - 0.04 * exp2(level) + EPSILON;
        //bool isTraceNearerThanStart = traceDepthL < sampleDepthL + 0.1;
        bool isTooThickAndMovingNearer = false;//traceDepthL > sampleDepthL + 1.0 && screenRay.z < 0.0;

        if (isTraceNearerThanSample || isCloserThanStartAndMovingAway || isTooThickAndMovingNearer) {
            lastTracePos = tracePos;

            // #if defined MATERIAL_REFLECT_HIZ && SSR_LOD_MAX > 0
            //     lastPos = currPos;
            //     currPos += ddaStep;
            // #endif

            if (level < SSR_LOD_MAX) level++;

            continue;
        }

        if (level > SSR_LodMin && i < SSR_MAXSTEPS - (level + 1)) {
           level--;
           continue;
        }

        lastVisPos = tracePos;
        alpha = 1.0;
        break;
    }

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
