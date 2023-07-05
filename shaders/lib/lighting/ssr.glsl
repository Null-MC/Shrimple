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

        //return texelFetch(texDepthNear, uv, 0).r;
        return imageLoad(imgDepthNear, uv).r;
    }

    return depth;
}

// returns: xyz=clip-pos  w=attenuation
vec4 GetReflectionPosition(const in sampler2D depthtex, const in vec3 clipPos, const in vec3 clipRay) {
    // vec3 clipPos = unproject(gbufferProjection * vec4(viewPos, 1.0)) * 0.5 + 0.5;
    // vec3 reflectClipPos = unproject(gbufferProjection * vec4(viewPos + reflectDir, 1.0)) * 0.5 + 0.5;

    // vec3 screenRay = reflectClipPos - clipPos;
    float screenRayLength = length(clipRay);
    if (screenRayLength < EPSILON) return vec4(0.0);

    vec3 screenRay = clipRay / screenRayLength;
    vec3 screenRayDir = screenRay;

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 ssrPixelSize = rcp(viewSize);

    if (abs(screenRay.y) > abs(screenRay.x))
        screenRay *= ssrPixelSize.y / abs(screenRay.y);
    else
        screenRay *= ssrPixelSize.x / abs(screenRay.x);

    // #ifndef SSR_HIZ
    //     #if SSR_QUALITY == 2
    //         screenRay *= 3.0;
    //     #elif SSR_QUALITY == 1
    //         screenRay *= 2.0;
    //     #endif
    // #endif

    vec3 lastTracePos = clipPos + screenRay;
    //#if SSR_QUALITY != 0
    //    lastTracePos += screenRay * GetScreenBayerValue();
    //#endif

    float startDepthLinear = linearizeDepthFast(clipPos.z, near, far);
    ivec2 iuv_start = ivec2(clipPos.xy * viewSize);

    const vec3 clipMin = vec3(0.0);
    vec3 clipMax = vec3(1.0) - vec3(ssrPixelSize, EPSILON);

    const int maxLevel = 4;
    int level = 0;

    int i;
    float alpha = 0.0;
    float texDepth;
    vec3 tracePos;
    for (i = 0; i < SSR_MAXSTEPS && alpha < EPSILON; i++) {
        int l2 = int(exp2(level));
        tracePos = lastTracePos + screenRay*l2;

        if (tracePos.z >= 1.0 && clamp(tracePos, clipMin, clipMax) != tracePos) {
            if (level > 0) {
                level--;
                continue;
            }

            alpha = 1.0;
            break;
        }

        ivec2 iuv = ivec2(tracePos.xy * viewSize);
        // if (iuv == iuv_start) {
        //     //i += l2;
        //     lastTracePos = tracePos;
        //     level++;
        //     continue;
        // }

        float depthBias = -0.01 * (1.0 - clipPos.z);
        //if (level > 0) depthBias += screenRay.z * l2;

        //texDepth = texelFetch(depthtex, iuv, level).r;
        //texDepth = textureLod(depthtex, tracePos.xy, level).r;

        //vec4 depthSamples = vec4(1.0);
        //depthSamples.x = textureLod(depthtex, tracePos.xy, level).r;
        //texDepth = textureLod(depthtex, tracePos.xy, level).r;
        texDepth = SampleDepthTiles(depthtex, tracePos.xy, level);

        // if (level > 0) {
        //     depthSamples.y = texelFetchOffset(depthtex, iuv, level, ivec2(1, 0)).r;
        //     depthSamples.z = texelFetchOffset(depthtex, iuv, level, ivec2(0, 1)).r;
        //     depthSamples.w = texelFetchOffset(depthtex, iuv, level, ivec2(1, 1)).r;
        // }

        //texDepth = minOf(depthSamples);

        if (texDepth > tracePos.z + depthBias) {
            level = min(level + 1, maxLevel);

            //i += l2;
            lastTracePos = tracePos;
            continue;
        }

        //float texDepthLinear = linearizeDepthFast(texDepth, near, far);
        //float traceDepthLinear = linearizeDepthFast(tracePos.z, near, far);

        // ignore geometry closer than start pos when tracing away
        if (screenRay.z > 0.0 && texDepth < clipPos.z) {
            lastTracePos = tracePos;
            continue;
        }

        // float d = 0.999 * traceDepthLinear; //  1.0e10 * pow(saturate(startDepthLinear / far), 3.0);
        // if (traceDepthLinear > texDepthLinear + d) {
        //     lastTracePos = tracePos;
        //     //i += l2;
        //     continue;
        // }

        if (level > 0) {
            level--;
            continue;
        }

        alpha = 1.0;
    }

    return vec4(tracePos, alpha);
}

// uv=tracePos.xy
vec3 GetRelectColor(const in vec2 uv, inout float alpha, const in float lod) {
    vec3 color = vec3(0.0);

    if (alpha > EPSILON) {
        vec2 alphaXY = saturate(12.0 * abs(vec2(0.5) - uv) - 5.0);
        alpha = 1.0 - pow(maxOf(alphaXY), 4.0);

        color = textureLod(BUFFER_FINAL, uv, lod).rgb;
    }

    return color;
}
