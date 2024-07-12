#define BLUR_BLIND_DIST 12.0

const float BlurAberrationStrengthF = EFFECT_BLUR_ABERRATION_STRENGTH * 0.01;
const vec3 aberrationF = vec3(3.0, 2.0, 1.0) * BlurAberrationStrengthF;


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
    const float WaterBlurDistF = 8.0;
    //const float WaterBlurPow = 1.5;

    float GetWaterBlurDistF(const in float viewDist) {
        // float waterDistF = smoothstep(0.0, WaterBlurDistF / WaterDensityF, viewDist);
        float waterDistF = min(viewDist / WaterBlurDistF * WaterDensityF, 1.0);
        //return pow(waterDistF, WaterBlurPow);
        return waterDistF;
    }

    #ifdef EFFECT_BLUR_ABERRATION_ENABLED
        vec3 GetWaterBlurDistF(const in vec3 viewDist) {
            // vec3 waterDistF = smoothstep(0.0, WaterBlurDistF / WaterDensityF, viewDist);
            vec3 waterDistF = min(viewDist / WaterBlurDistF * WaterDensityF, 1.0);
            //return pow(waterDistF, vec3(WaterBlurPow));
            return waterDistF;
        }
    #endif
#endif

#ifdef DISTANT_HORIZONS
    #ifdef EFFECT_BLUR_ABERRATION_ENABLED
        vec3 dhDepthTest(inout vec3 depth, inout vec3 depthL, const in vec3 dhDepth, const in vec3 dhDepthL) {
            //bvec3 result = false;

            vec3 isNotSky = 1.0 - step(1.0, depth);
            vec3 isNotDH = 1.0 - step(dhDepthL + EPSILON, depthL) * step(EPSILON, dhDepth);
            vec3 f = 1.0 - isNotSky * isNotDH;

            depth = mix(depth, dhDepth, f);
            depthL = mix(depthL, dhDepthL, f);

            // if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
            //     depth = dhDepth;
            //     depthL = dhDepthL;
            //     result = true;
            // }

            return f;
        }
    #else
        bool dhDepthTest(inout float depth, inout float depthL, const in float dhDepth, const in float dhDepthL) {
            bool result = false;

            if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
                depth = dhDepth;
                depthL = dhDepthL;
                result = true;
            }

            return result;
        }
    #endif
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
            // TODO: apply aberration here?
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
    #elif defined IS_WORLD_SMOKE_ENABLED
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
    vec2 pixelRadius = radius * pixelSize;
    float maxLod = 0.75 * log2(radius);

    #ifdef EFFECT_BLUR_ABERRATION_ENABLED
        vec3 maxWeight = vec3(0.0);

        vec2 aberrationOffset = pixelRadius * (texcoord * 2.0 - 1.0);

        vec2 centerF = 1.0 - 2.0 * abs(texcoord - 0.5);
        aberrationOffset *= saturate(centerF*10.0);
        //aberrationOffset *= sqrt(saturate(centerF*10.0));
    #else
        float maxWeight = 0.0;
    #endif

    vec2 screenCoordMin = vec2(0.5 * pixelSize);
    vec2 screenCoordMax = 1.0 - 3.0*screenCoordMin;

    const float goldenAngle = PI * (3.0 - sqrt(5.0));
    const float PHI = (1.0 + sqrt(5.0)) / 2.0;

    mat2 rotation = GetBlurRotation();

    for (uint i = 0; i < EFFECT_BLUR_SAMPLE_COUNT; i++) {
        float r = sqrt((i + 0.5) / (EFFECT_BLUR_SAMPLE_COUNT - 0.5));
        float theta = i * goldenAngle + PHI;
        
        float sine = sin(theta);
        float cosine = cos(theta);
        
        vec2 diskOffset = rotation * (vec2(cosine, sine) * r);
        vec2 sampleCoord = saturate(diskOffset * pixelRadius + texcoord);

        #ifdef EFFECT_BLUR_ABERRATION_ENABLED
            vec2 sampleCoordR = saturate(aberrationOffset * aberrationF.r + sampleCoord);
            ivec2 sampleUVR = ivec2(sampleCoordR * viewSize);

            vec2 sampleCoordG = saturate(aberrationOffset * aberrationF.g + sampleCoord);
            ivec2 sampleUVG = ivec2(sampleCoordG * viewSize);

            vec2 sampleCoordB = saturate(aberrationOffset * aberrationF.b + sampleCoord);
            ivec2 sampleUVB = ivec2(sampleCoordB * viewSize);

            #ifdef RENDER_TRANSLUCENT_BLUR_POST
                vec3 sampleDepth = vec3(
                    texelFetch(depthtex0, sampleUVR, 0).r,
                    texelFetch(depthtex0, sampleUVG, 0).r,
                    texelFetch(depthtex0, sampleUVB, 0).r);
            #else
                vec3 sampleDepth = vec3(
                    texelFetch(depthtex1, sampleUVR, 0).r,
                    texelFetch(depthtex1, sampleUVG, 0).r,
                    texelFetch(depthtex1, sampleUVB, 0).r);
            #endif

            vec3 sampleDepthL = linearizeDepthFast3(sampleDepth, near, farPlane);

            // vec3 sampleDepthL = vec3(
            //     linearizeDepthFast(sampleDepth, near, farPlane),
            //     linearizeDepthFast(sampleDepth, near, farPlane),
            //     linearizeDepthFast(sampleDepth, near, farPlane));
        #else
            ivec2 sampleUV = ivec2(sampleCoord * viewSize);

            #ifdef RENDER_TRANSLUCENT_BLUR_POST
                float sampleDepth = texelFetch(depthtex0, sampleUV, 0).r;
            #else
                float sampleDepth = texelFetch(depthtex1, sampleUV, 0).r;
            #endif

            float sampleDepthL = linearizeDepthFast(sampleDepth, near, farPlane);
        #endif

        #ifdef DISTANT_HORIZONS
            #ifdef EFFECT_BLUR_ABERRATION_ENABLED
                #ifdef RENDER_TRANSLUCENT_BLUR_POST
                    vec3 dhDepth = vec3(
                        texelFetch(dhDepthTex, sampleUVR, 0).r,
                        texelFetch(dhDepthTex, sampleUVG, 0).r,
                        texelFetch(dhDepthTex, sampleUVB, 0).r);
                #else
                    vec3 dhDepth = vec3(
                        texelFetch(dhDepthTex1, sampleUVR, 0).r,
                        texelFetch(dhDepthTex1, sampleUVG, 0).r,
                        texelFetch(dhDepthTex1, sampleUVB, 0).r);
                #endif

                vec3 dhDepthL = linearizeDepthFast3(dhDepth, dhNearPlane, dhFarPlane);

                dhDepthTest(sampleDepth, sampleDepthL, dhDepth, dhDepthL);

                // TODO: per-color
                // if (sampleDepth.r >= 1.0 || (dhDepthL.r < sampleDepthL.r && dhDepth > 0.0)) {
                //     sampleDepth.r = dhDepth.r;
                //     sampleDepthL.r = dhDepthL.r;
                // }

                // if (sampleDepth >= 1.0 || dhDepthL < sampleDepthL) {
                //     sampleDepth = dhDepth;
                //     sampleDepthL = dhDepthL;
                // }

                // if (sampleDepth >= 1.0 || dhDepthL < sampleDepthL) {
                //     sampleDepth = dhDepth;
                //     sampleDepthL = dhDepthL;
                // }
            #else
                #ifdef RENDER_TRANSLUCENT_BLUR_POST
                    float dhDepth = texelFetch(dhDepthTex, sampleUV, 0).r;
                #else
                    float dhDepth = texelFetch(dhDepthTex1, sampleUV, 0).r;
                #endif

                float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

                dhDepthTest(sampleDepth, sampleDepthL, dhDepth, dhDepthL);

                // if (sampleDepth >= 1.0 || dhDepthL < sampleDepthL) {
                //     sampleDepth = dhDepth;
                //     sampleDepthL = dhDepthL;
                // }
            #endif
        #endif

        #ifdef EFFECT_BLUR_ABERRATION_ENABLED
            vec3 sampleDepthDiff = max(sampleDepthL - minDepth, 0.0);
            vec3 sampleDistF = saturate(sampleDepthDiff / _far);
        #else
            float sampleDepthDiff = max(sampleDepthL - minDepth, 0.0);
            float sampleDistF = saturate(sampleDepthDiff / _far);
        #endif

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
                sampleDistF = GetWaterBlurDistF(sampleDepthDiff);
                // sampleDistF = sampleWaterDistF;//max(sampleDistF, sampleWaterDistF);
            }
        #endif

        #if EFFECT_BLUR_RADIUS_BLIND > 0
            if (blindnessSmooth > EPSILON) {
                #ifdef EFFECT_BLUR_ABERRATION_ENABLED
                    vec3 blindDistF = min(sampleDepthDiff / BLUR_BLIND_DIST, 1.0);
                #else
                    float blindDistF = min(sampleDepthDiff / BLUR_BLIND_DIST, 1.0);
                #endif

                sampleDistF = mix(sampleDistF, max(sampleDistF, blindDistF), blindnessSmooth);
            }
        #endif

        //#if EFFECT_BLUR_TYPE == DIST_BLUR_FAR
            sampleDistF = min(sampleDistF, distF);
        //#endif

        #ifdef EFFECT_BLUR_ABERRATION_ENABLED
            // sampleCoordR = clamp(sampleCoordR, screenCoordMin, screenCoordMax);
            // sampleCoordG = clamp(sampleCoordG, screenCoordMin, screenCoordMax);
            // sampleCoordB = clamp(sampleCoordB, screenCoordMin, screenCoordMax);

            vec3 sampleColor;
            #ifdef EFFECT_TAA_ENABLED
                sampleColor.r = texelFetch(BUFFER_FINAL, ivec2(sampleCoordR * viewSize), 0).r;
                sampleColor.g = texelFetch(BUFFER_FINAL, ivec2(sampleCoordG * viewSize), 0).g;
                sampleColor.b = texelFetch(BUFFER_FINAL, ivec2(sampleCoordB * viewSize), 0).b;
            #else
                vec3 sampleLod = maxLod * max(sampleDistF - 0.1, 0.0);
                sampleColor.r = textureLod(BUFFER_FINAL, sampleCoordR, sampleLod.r).r;
                sampleColor.g = textureLod(BUFFER_FINAL, sampleCoordG, sampleLod.g).g;
                sampleColor.b = textureLod(BUFFER_FINAL, sampleCoordB, sampleLod.b).b;
            #endif
        #else
            sampleCoord = clamp(sampleCoord, screenCoordMin, screenCoordMax);

            #ifdef EFFECT_TAA_ENABLED
                vec3 sampleColor = texelFetch(BUFFER_FINAL, sampleUV, 0).rgb;
            #else
                float sampleLod = maxLod * max(sampleDistF - 0.1, 0.0);
                vec3 sampleColor = textureLod(BUFFER_FINAL, sampleCoord, sampleLod).rgb;
            #endif
        #endif

        const float blurSigma = 0.5;
        #ifdef EFFECT_BLUR_ABERRATION_ENABLED
            vec3 sampleWeight = vec3(Gaussian(blurSigma, r));
        #else
            float sampleWeight = Gaussian(blurSigma, r);
        #endif

        sampleWeight *= step(minDepth, sampleDepthL);// * sampleDistF;

        color += sampleColor * sampleWeight;
        maxWeight += sampleWeight;
    }

    //#ifdef EFFECT_BLUR_ABERRATION_ENABLED
        vec3 colorDef = texelFetch(BUFFER_FINAL, ivec2(texcoord * viewSize), 0).rgb;
        color = mix(colorDef, color / max(maxWeight, 1.0), saturate(maxWeight));
    //#endif

    // if (maxWeight < 1.0) {
    //     color += texelFetch(BUFFER_FINAL, ivec2(texcoord * viewSize), 0).rgb * (1.0 - maxWeight);
    // }
    // else {
    //     color /= maxWeight;
    // }

    return color;
}
