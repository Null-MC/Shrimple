#define BLUR_BLIND_DIST 12.0
#define BLUR_BLIND_RADIUS 128.0


mat2 GetBlurRotation() {
    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    float angle = dither * TAU;
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

float GetBlurSize(const in float fragDepthL, const in float focusDepthL) {
    float coc = rcp(focusDepthL) - rcp(fragDepthL);
    return saturate(abs(coc) * DepthOfFieldFocusScale);
}

#ifdef WORLD_WATER_ENABLED
    float GetWaterDistF(const in float viewDist) {
        float waterDistF = min(viewDist / waterDensitySmooth, 1.0);
        return pow(waterDistF, 1.5);
    }
#endif

vec3 GetBlur(const in sampler2D depthSampler, const in vec2 texcoord, const in float fragDepthL, const in float minDepth, const in float viewDist, const in bool isWater) {
    //vec2 viewSize = vec2(viewWidth, viewHeight);
    // vec2 pixelSize = rcp(viewSize);

    #if defined WATER_BLUR && DIST_BLUR_MODE == DIST_BLUR_NONE
        if (!isWater) return texelFetch(BUFFER_FINAL, ivec2(texcoord * viewSize), 0).rgb;
    #endif

    //float distScale = isWater ? WATER_BLUR_SCALE : far;
    //distScale = mix(distScale, DIST_BLUR_SCALE_BLIND, blindness);

    float distF = 0.0;
    #if DIST_BLUR_MODE == DIST_BLUR_DOF
        float centerDepthL = linearizeDepthFast(centerDepthSmooth, near, far);
        float centerSize = GetBlurSize(fragDepthL, centerDepthL);
    #elif DIST_BLUR_MODE == DIST_BLUR_FAR
        if (!isWater) {
            distF = min(viewDist / far, 1.0);
            distF = pow(distF, DIST_BLUR_FAR_POW);
        }
    #endif

    #if defined WATER_BLUR && defined WORLD_WATER_ENABLED
        if (isWater) {
            float waterDistF = GetWaterDistF(viewDist);
            distF = max(distF, waterDistF);
        }
    #endif

    const float goldenAngle = PI * (3.0 - sqrt(5.0));
    const float PHI = (1.0 + sqrt(5.0)) / 2.0;

    mat2 rotation = GetBlurRotation();

    #if DIST_BLUR_MODE == DIST_BLUR_DOF
        float radius = isWater ? WATER_BLUR_RADIUS : DIST_BLUR_RADIUS;
        //uint sampleCount = DIST_BLUR_SAMPLES;
    #else
        float radius = distF * (isWater ? WATER_BLUR_RADIUS : DIST_BLUR_RADIUS);
        //uint sampleCount = uint(ceil(DIST_BLUR_SAMPLES * distF));

        //radius *= distF;
    #endif

    if (blindness > 0.0) {
        float blindDistF = min(viewDist / BLUR_BLIND_DIST, 1.0);
        //blindDistF = pow(blindDistF, 1.5);
        distF = max(distF, blindDistF);

        radius = mix(radius, max(radius, BLUR_BLIND_RADIUS), blindness);
    }

    vec3 color = vec3(0.0);
    float maxWeight = 0.0;
    vec2 pixelRadius = radius * pixelSize;
    float maxLod = 0.75 * log2(radius);

    for (uint i = 0; i < DIST_BLUR_SAMPLES; i++) {
        vec2 sampleCoord = texcoord;
        vec2 diskOffset = vec2(0.0);

        //if (DIST_BLUR_SAMPLES > 1) {
            float r = sqrt((i + 0.5) / DIST_BLUR_SAMPLES);
            float theta = i * goldenAngle + PHI;
            
            float sine = sin(theta);
            float cosine = cos(theta);
            
            diskOffset = rotation * (vec2(cosine, sine) * r);
            sampleCoord = saturate(sampleCoord + diskOffset * pixelRadius);
        //}

        ivec2 sampleUV = ivec2(sampleCoord * viewSize);

        float sampleDepth = texelFetch(depthSampler, sampleUV, 0).r;
        //float sampleDepth = textureLod(depthSampler, sampleCoord, 0.0).r;
        float sampleDepthL = linearizeDepthFast(sampleDepth, near, far);

        float sampleDistF = 0.0;
        #if DIST_BLUR_MODE == DIST_BLUR_DOF
            float sampleSize = GetBlurSize(sampleDepthL, centerDepthL);

            if (sampleDepthL > fragDepthL)
                sampleSize = clamp(sampleSize, 0.0, centerSize*2.0);


            sampleDistF = sampleSize;
        #elif DIST_BLUR_MODE == DIST_BLUR_FAR
            if (!isWater) {
                sampleDistF = saturate((sampleDepthL - minDepth) / far);
                sampleDistF = pow(sampleDistF, DIST_BLUR_FAR_POW);
            }
        #endif

        #if defined WATER_BLUR && defined WORLD_WATER_ENABLED
            if (isWater) {
                float sampleWaterDistF = GetWaterDistF(max(sampleDepthL - minDepth, 0.0));
                sampleDistF = sampleWaterDistF;//max(sampleDistF, sampleWaterDistF);
            }
        #endif

        if (blindness > EPSILON) {
            float blindDistF = min(viewDist / BLUR_BLIND_DIST, 1.0);
            sampleDistF = mix(sampleDistF, max(sampleDistF, blindDistF), blindness);
        }

        #if DIST_BLUR_MODE == DIST_BLUR_FAR
            sampleDistF = min(sampleDistF, distF);
        #endif

        float sampleLod = maxLod * max(sampleDistF - 0.1, 0.0);

        //vec3 sampleColor = texelFetch(BUFFER_FINAL, sampleUV, 0).rgb;
        vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, sampleLod).rgb;
        float sampleWeight = exp(-3.0 * length2(diskOffset));

        sampleWeight *= step(minDepth, sampleDepth) * sampleDistF;

        //if (DIST_BLUR_SAMPLES > 1) {
            #ifdef RENDER_TRANSLUCENT_POST_BLUR
                float sampleWeatherDepth = texelFetch(BUFFER_WEATHER_DEPTH, sampleUV, 0).r;
                sampleDepth = min(sampleDepth, sampleWeatherDepth);
            #endif

            //if (sampleDepth >= minDepth) sampleWeight *= sampleDistF;
            sampleWeight *= step(minDepth, sampleDepth) * sampleDistF;
        //}

        color += sampleColor * sampleWeight;
        maxWeight += sampleWeight;
    }

    if (maxWeight < 1.0) {
        color += texelFetch(BUFFER_FINAL, ivec2(texcoord * viewSize), 0).rgb * (1.0 - maxWeight);
    }
    else {
        color /= maxWeight;
    }

    return color;
}
