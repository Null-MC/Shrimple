#define BLUR_BLIND_DIST 12.0

const vec3 aberrationF = vec3(3.0, 2.0, 1.0) * (EFFECT_BLUR_ABERRATION_STRENGTH * 0.01);


mat2 GetBlurRotation() {
    #ifdef EFFECT_TAA_ENABLED
        float dither = InterleavedGradientNoiseTime();
    #else
        float dither = InterleavedGradientNoise();
    #endif

    float angle = dither * TAU;
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

float GetBlurSize(const in float fragDepthL, const in float focusDepthL) {
    float coc = rcp(focusDepthL) - rcp(fragDepthL);
    return saturate(abs(coc) * DepthOfFieldFocusScale);
}

#ifdef WORLD_WATER_ENABLED
    float GetWaterBlurDistF(const in float viewDist) {
        float waterDistF = min(viewDist / (32.0 * WaterDensityF), 1.0);
        return pow(waterDistF, 1.5);
    }
#endif

vec3 GetBlur(const in vec2 texcoord, const in float fragDepthL, const in float minDepth, const in float viewDist, const in bool isWater) {
    float _far = far;
    #ifdef DISTANT_HORIZONS
        _far = 0.5*dhFarPlane;
    #endif

    // if (isEyeInWater == 1) _far = 16.0;

    float distF = min(viewDist / _far, 1.0);
    float maxRadius = EFFECT_BLUR_MAX_RADIUS;

    // #if EFFECT_BLUR_TYPE == DIST_BLUR_DOF
    //     float centerDepthL = linearizeDepthFast(centerDepthSmooth, near, far);
    //     float centerSize = GetBlurSize(fragDepthL, centerDepthL);
    // #endif

    #if EFFECT_BLUR_WATER_RADIUS > 0 && defined WORLD_WATER_ENABLED
        if (isWater) {
            float waterDistF = GetWaterBlurDistF(viewDist);
            distF = max(distF, waterDistF);
            maxRadius = EFFECT_BLUR_WATER_RADIUS;
        }
    #endif

    // #if EFFECT_BLUR_TYPE == DIST_BLUR_DOF
    //     maxRadius = isWater ? WATER_BLUR_RADIUS : EFFECT_BLUR_MAX_RADIUS;
    //     //uint sampleCount = EFFECT_BLUR_SAMPLE_COUNT;
    // #else //if EFFECT_BLUR_TYPE == DIST_BLUR_FAR
    //     if (!isWater) maxRadius = EFFECT_BLUR_MAX_RADIUS;
    //     //uint sampleCount = uint(ceil(EFFECT_BLUR_SAMPLE_COUNT * distF));

    //     //maxRadius *= distF;
    // #endif

    #ifdef WORLD_SKY_ENABLED
        #if EFFECT_BLUR_RADIUS_WEATHER > 0
            if (!isWater) maxRadius = mix(maxRadius, max(maxRadius, EFFECT_BLUR_RADIUS_WEATHER), _pow2(skyRainStrength));
        #endif
    #elif defined WORLD_SMOKE
        if (!isWater) maxRadius = max(maxRadius, EFFECT_BLUR_RADIUS_WEATHER);
    #endif

    #if EFFECT_BLUR_RADIUS_BLIND > 0
        if (blindnessSmooth > EPSILON) {
            float blindDistF = min(viewDist / BLUR_BLIND_DIST, 1.0);
            distF = max(distF, blindDistF);

            maxRadius = mix(maxRadius, max(maxRadius, EFFECT_BLUR_RADIUS_BLIND), blindnessSmooth);
        }
    #endif

    float radius = maxRadius * distF;
    if (radius < EPSILON) return texelFetch(BUFFER_FINAL, ivec2(texcoord * viewSize), 0).rgb;

    vec3 color = vec3(0.0);
    float maxWeight = 0.0;
    vec2 pixelRadius = radius * pixelSize;
    float maxLod = 0.75 * log2(radius);

    #ifdef EFFECT_BLUR_ABERRATION_ENABLED
        vec2 aberrationOffset = pixelRadius * (texcoord * 2.0 - 1.0);

        vec2 screenCoordMin = vec2(0.5 * pixelSize);
        vec2 screenCoordMax = 1.0 - 3.0*screenCoordMin;
    #endif

    const float goldenAngle = PI * (3.0 - sqrt(5.0));
    const float PHI = (1.0 + sqrt(5.0)) / 2.0;

    mat2 rotation = GetBlurRotation();

    for (uint i = 0; i < EFFECT_BLUR_SAMPLE_COUNT; i++) {
        vec2 sampleCoord = texcoord;
        vec2 diskOffset = vec2(0.0);

        float r = sqrt((i + 0.5) / (EFFECT_BLUR_SAMPLE_COUNT - 0.5));
        float theta = i * goldenAngle + PHI;
        
        float sine = sin(theta);
        float cosine = cos(theta);
        
        diskOffset = rotation * (vec2(cosine, sine) * r);
        sampleCoord = saturate(sampleCoord + diskOffset * pixelRadius);

        ivec2 sampleUV = ivec2(sampleCoord * viewSize);

        #ifdef RENDER_TRANSLUCENT_BLUR_POST
            float sampleDepth = texelFetch(depthtex0, sampleUV, 0).r;
            //float sampleDepth = textureLod(depthSampler, sampleCoord, 0.0).r;
        #else
            float sampleDepth = texelFetch(depthtex1, sampleUV, 0).r;
        #endif

        float sampleDepthL = linearizeDepthFast(sampleDepth, near, farPlane);

        #ifdef DISTANT_HORIZONS
            #ifdef RENDER_TRANSLUCENT_BLUR_POST
                float dhDepth = texelFetch(dhDepthTex, sampleUV, 0).r;
            #else
                float dhDepth = texelFetch(dhDepthTex1, sampleUV, 0).r;
            #endif

            float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

            if (sampleDepth >= 1.0 || dhDepthL < sampleDepthL) {
                sampleDepth = dhDepth;
                sampleDepthL = dhDepthL;
            }
        #endif

        float sampleDistF = saturate((sampleDepthL - minDepth) / _far);
        // #if EFFECT_BLUR_TYPE == DIST_BLUR_DOF
        //     float sampleSize = GetBlurSize(sampleDepthL, centerDepthL);

        //     if (sampleDepthL > fragDepthL)
        //         sampleSize = clamp(sampleSize, 0.0, centerSize*2.0);


        //     sampleDistF = sampleSize;
        // #else //elif EFFECT_BLUR_TYPE == DIST_BLUR_FAR
        //     if (!isWater) {
        //         sampleDistF = saturate((sampleDepthL - minDepth) / far);
        //         //sampleDistF = pow(sampleDistF, EFFECT_BLUR_FAR_POW);
        //     }
        // #endif

        #if EFFECT_BLUR_WATER_RADIUS > 0 && defined WORLD_WATER_ENABLED
            if (isWater) {
                float sampleWaterDistF = GetWaterBlurDistF(max(sampleDepthL - minDepth, 0.0));
                sampleDistF = sampleWaterDistF;//max(sampleDistF, sampleWaterDistF);
            }
        #endif

        #if EFFECT_BLUR_RADIUS_BLIND > 0
            if (blindnessSmooth > EPSILON) {
                float blindDistF = min(viewDist / BLUR_BLIND_DIST, 1.0);
                sampleDistF = mix(sampleDistF, max(sampleDistF, blindDistF), blindnessSmooth);
            }
        #endif

        //#if EFFECT_BLUR_TYPE == DIST_BLUR_FAR
            sampleDistF = min(sampleDistF, distF);
        //#endif

        #ifdef EFFECT_BLUR_ABERRATION_ENABLED
            //vec2 sampleOffset = sampleCoord - texcoord;
            vec2 sampleCoordR = clamp(sampleCoord + aberrationOffset * aberrationF.r, screenCoordMin, screenCoordMax);
            vec2 sampleCoordG = clamp(sampleCoord + aberrationOffset * aberrationF.g, screenCoordMin, screenCoordMax);
            vec2 sampleCoordB = clamp(sampleCoord + aberrationOffset * aberrationF.b, screenCoordMin, screenCoordMax);

            vec3 sampleColor;
            #ifdef EFFECT_TAA_ENABLED
                sampleColor.r = texelFetch(BUFFER_FINAL, ivec2(sampleCoordR * viewSize), 0).r;
                sampleColor.g = texelFetch(BUFFER_FINAL, ivec2(sampleCoordG * viewSize), 0).g;
                sampleColor.b = texelFetch(BUFFER_FINAL, ivec2(sampleCoordB * viewSize), 0).b;
            #else
                float sampleLod = maxLod * max(sampleDistF - 0.1, 0.0);
                sampleColor.r = textureLod(BUFFER_FINAL, sampleCoordR, sampleLod).r;
                sampleColor.g = textureLod(BUFFER_FINAL, sampleCoordG, sampleLod).g;
                sampleColor.b = textureLod(BUFFER_FINAL, sampleCoordB, sampleLod).b;
            #endif
        #else
            #ifdef EFFECT_TAA_ENABLED
                vec3 sampleColor = texelFetch(BUFFER_FINAL, sampleUV, 0).rgb;
            #else
                float sampleLod = maxLod * max(sampleDistF - 0.1, 0.0);
                vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, sampleLod).rgb;
            #endif
        #endif

        float sampleWeight = exp(-3.0 * length2(diskOffset));

        sampleWeight *= step(minDepth, sampleDepth) * sampleDistF;

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
