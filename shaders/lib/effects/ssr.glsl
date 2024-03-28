const int SSR_LodMin = 1;


float SampleDepthTiles(const in sampler2D depthtex, const in vec2 texcoord, const in int level) {
    vec2 uv = GetDepthTileCoord(viewSize, texcoord, level - 1);
    return texelFetch(texDepthNear, ivec2(uv), 0).r;
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

    vec2 screenRayAbs = abs(screenRay.xy);
    vec2 pixelRay = pixelSize / screenRayAbs.xy;
    vec3 rayX = screenRay * pixelRay.x;
    vec3 rayY = screenRay * pixelRay.y;
    screenRay = mix(rayX, rayY, screenRayAbs.y);

    vec3 lastTracePos = screenRay * (1.0 + dither) + clipPos;
    vec3 lastVisPos = lastTracePos;

    const vec3 clipMin = vec3(0.0);

    float alpha = 0.0;
    int level = SSR_LodMin;
    float texDepth;
    vec3 tracePos;

    for (int i = 0; i < SSR_MAXSTEPS; i++) {
        float stepScale = exp2(level);
        tracePos = screenRay*stepScale + lastTracePos;

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

        float sampleDepthL = SampleDepthTiles(depthtex, tracePos.xy, level) * _far;
        float traceDepthL = linearizeDepth(tracePos.z, near, _far);

        const float bias = 0.002;//0.1 * sampleDepthL;
        //bool isCloserThanStartAndMovingAway = false;//startDepthLinear > sampleDepthL + bias && screenRay.z > 0.0;
        //bool isTraceNearerThanSample = traceDepthL < sampleDepthL + bias;// - 0.04 * exp2(level) + EPSILON;
        //bool isTraceNearerThanStart = traceDepthL < sampleDepthL + 0.1;
        //bool isTooThickAndMovingNearer = false;//traceDepthL > sampleDepthL + 1.0 && screenRay.z < 0.0;

        // if (isTraceNearerThanSample || isCloserThanStartAndMovingAway || isTooThickAndMovingNearer) {
        if (traceDepthL < sampleDepthL + bias) {
            lastTracePos = tracePos;

            if (level < SSR_LOD_MAX) level++;

            continue;
        }

        if (level > SSR_LodMin && i < SSR_MAXSTEPS - (level + 1)) {
        // if (level > SSR_LodMin) {
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
