float GetShadowBias(const in float geoNoL) {
    return 0.00004;
}

float SampleDepth(const in vec2 shadowPos, const in vec2 offset) {
    #if SHADOW_COLORS == 0
        //for normal shadows, only consider the closest thing to the sun,
        //regardless of whether or not it's opaque.
        return texture(shadowtex0, shadowPos + offset).r;
    #else
        //for invisible and colored shadows, first check the closest OPAQUE thing to the sun.
        return texture(shadowtex1, shadowPos + offset).r;
    #endif
}

// returns: [0] when depth occluded, [1] otherwise
float CompareDepth(const in vec3 shadowPos, const in vec2 offset, const in float bias) {
    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            return texture(shadowtex0HW, shadowPos + vec3(offset, -bias)).r;
        #else
            return texture(shadow, shadowPos + vec3(offset, -bias)).r;
        #endif
    #else
        #if SHADOW_COLORS == SHADOW_COLOR_IGNORED
            float texDepth = texture(shadowtex1, shadowPos.xy + offset).r;
        #else
            float texDepth = texture(shadowtex0, shadowPos.xy + offset).r;
        #endif

        return step(shadowPos.z - bias, texDepth);
    #endif
}


#if SHADOW_FILTER != 0
    // PCF
    #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
        vec3 GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
            #ifdef IRIS_FEATURE_SSBO
                float dither = InterleavedGradientNoise(gl_FragCoord.xy);
                float angle = fract(dither) * TAU;
                float s = sin(angle), c = cos(angle);
                mat2 rotation = mat2(c, -s, s, c);
            #else
                float startAngle = hash12(gl_FragCoord.xy) * (2.0 * PI);
                vec2 rotation = vec2(cos(startAngle), sin(startAngle));

                const float angleDiff = -(PI * 2.0) / SHADOW_PCF_SAMPLES;
                const vec2 angleStep = vec2(cos(angleDiff), sin(angleDiff));
                const mat2 rotationStep = mat2(angleStep, -angleStep.y, angleStep.x);
            #endif
            
            vec3 shadowColor = vec3(0.0);
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                #ifdef IRIS_FEATURE_SSBO
                    vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                #else
                    rotation *= rotationStep;
                    float noiseDist = hash13(vec3(gl_FragCoord.xy, i));
                    vec2 pixelOffset = rotation * noiseDist * pixelRadius;
                #endif

                vec4 sampleColor = vec4(1.0);

                float depthOpaque = textureLod(shadowtex1, shadowPos.xy + pixelOffset, 0).r;

                if (shadowPos.z - bias > depthOpaque) sampleColor.rgb = vec3(0.0);
                else {
                    float depthTrans = textureLod(shadowtex0, shadowPos.xy + pixelOffset, 0).r;
                    if (shadowPos.z - bias < depthTrans) sampleColor.rgb = vec3(1.0);
                    else {
                        sampleColor = textureLod(shadowcolor0, shadowPos.xy + pixelOffset, 0);
                        sampleColor.rgb = RGBToLinear(sampleColor.rgb);
                        
                        sampleColor.rgb = mix(sampleColor.rgb, vec3(0.0), pow2(sampleColor.a));
                    }
                }

                shadowColor += sampleColor.rgb;
            }

            return shadowColor * rcp(SHADOW_PCF_SAMPLES);
        }
    #else
        float GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
            #ifdef IRIS_FEATURE_SSBO
                float dither = InterleavedGradientNoise(gl_FragCoord.xy);
                float angle = fract(dither) * TAU;
                float s = sin(angle), c = cos(angle);
                mat2 rotation = mat2(c, -s, s, c);
            #else
                float startAngle = hash12(gl_FragCoord.xy) * (2.0 * PI);
                vec2 rotation = vec2(cos(startAngle), sin(startAngle));

                const float angleDiff = -(PI * 2.0) / SHADOW_PCF_SAMPLES;
                const vec2 angleStep = vec2(cos(angleDiff), sin(angleDiff));
                const mat2 rotationStep = mat2(angleStep, -angleStep.y, angleStep.x);
            #endif

            float shadow = 0.0;
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                #ifdef IRIS_FEATURE_SSBO
                    vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                #else
                    rotation *= rotationStep;
                    float noiseDist = hash13(vec3(gl_FragCoord.xy, i));
                    vec2 pixelOffset = rotation * noiseDist * pixelRadius;
                #endif

                shadow += 1.0 - CompareDepth(shadowPos, pixelOffset, bias);
            }

            return shadow * rcp(SHADOW_PCF_SAMPLES);
        }
    #endif

    vec2 GetShadowPixelRadius(const in float blockRadius) {
        vec2 shadowProjectionSize = 2.0 / vec2(shadowProjection[0].x, shadowProjection[1].y);

        #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED
            float distortFactor = getDistortFactor(shadowPos.xy * 2.0 - 1.0);
            float maxRes = shadowMapSize / SHADOW_DISTORT_FACTOR;

            vec2 pixelPerBlockScale = maxRes / shadowProjectionSize;
            return blockRadius * pixelPerBlockScale * shadowPixelSize * (1.0 - distortFactor);
        #else
            vec2 pixelPerBlockScale = shadowMapSize / shadowProjectionSize;
            return blockRadius * pixelPerBlockScale * shadowPixelSize;
        #endif
    }
#endif

#if SHADOW_FILTER == 2
    // PCF + PCSS
    float FindBlockerDistance(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
        #ifdef IRIS_FEATURE_SSBO
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);
            float angle = fract(dither) * TAU;
            float s = sin(angle), c = cos(angle);
            mat2 rotation = mat2(c, -s, s, c);
        #else
            float startAngle = hash12(gl_FragCoord.xy) * (2.0 * PI);
            vec2 rotation = vec2(cos(startAngle), sin(startAngle));

            const float angleDiff = -(PI * 2.0) / SHADOW_PCSS_SAMPLES;
            const vec2 angleStep = vec2(cos(angleDiff), sin(angleDiff));
            const mat2 rotationStep = mat2(angleStep, -angleStep.y, angleStep.x);
        #endif
        
        float blockers = 0.0;
        float avgBlockerDistance = 0.0;
        for (int i = 0; i < SHADOW_PCSS_SAMPLES; i++) {
            #ifdef IRIS_FEATURE_SSBO
                vec2 pixelOffset = (rotation * pcssDiskOffset[i]) * pixelRadius;
            #else
                rotation *= rotationStep;
                float noiseDist = hash13(vec3(gl_FragCoord.xy, i + 100.0));
                vec2 pixelOffset = rotation * noiseDist * pixelRadius;
            #endif

            #if SHADOW_COLORS == SHADOW_COLOR_IGNORED
                float texDepth = texture(shadowtex1, shadowPos.xy + pixelOffset).r;
            #else
                float texDepth = texture(shadowtex0, shadowPos.xy + pixelOffset).r;
            #endif

            float hitDist = max((shadowPos.z - bias) - texDepth, 0.0);

            avgBlockerDistance += hitDist * 256.0;
            blockers += step(0.0, hitDist);
        }

        return blockers > 0 ? avgBlockerDistance / blockers : -1.0;
    }

    #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
        vec3 GetShadowColor(const in vec3 shadowPos) {
            vec2 pixelRadius = GetShadowPixelRadius(ShadowPCFSize);
            float bias = GetShadowBias(geoNoL);

            // blocker search
            float blockerDistance = FindBlockerDistance(shadowPos, pixelRadius, bias);

            if (blockerDistance <= 0.0) {
                float depthTrans = textureLod(shadowtex0, shadowPos.xy, 0).r;
                if (shadowPos.z - bias < depthTrans) return vec3(1.0);

                vec4 shadowColor = textureLod(shadowcolor0, shadowPos.xy, 0);
                shadowColor.rgb = RGBToLinear(shadowColor.rgb);

                shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), pow2(shadowColor.a));
                
                return shadowColor.rgb;
            }

            pixelRadius *= min(blockerDistance * SHADOW_PENUMBRA_SCALE, 1.0);
            return GetShadowing_PCF(shadowPos, pixelRadius, bias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos) {
            vec2 pixelRadius = GetShadowPixelRadius(ShadowPCFSize);
            float bias = GetShadowBias(geoNoL);

            // blocker search
            float blockerDistance = FindBlockerDistance(shadowPos, pixelRadius, bias);
            if (blockerDistance <= 0.0) return 1.0;

            pixelRadius *= min(blockerDistance * SHADOW_PENUMBRA_SCALE, 1.0);
            return 1.0 - GetShadowing_PCF(shadowPos, pixelRadius, bias);
        }
    #endif
#elif SHADOW_FILTER == 1
    // PCF
    #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
        vec3 GetShadowColor(const in vec3 shadowPos) {
            vec2 pixelRadius = GetShadowPixelRadius(ShadowPCFSize);
            float bias = GetShadowBias(geoNoL);

            return GetShadowing_PCF(shadowPos, pixelRadius, bias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos) {
            vec2 pixelRadius = GetShadowPixelRadius(ShadowPCFSize);
            float bias = GetShadowBias(geoNoL);

            return 1.0 - GetShadowing_PCF(shadowPos, pixelRadius, bias);
        }
    #endif
#elif SHADOW_FILTER == 0
    // Unfiltered
    #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
        vec3 GetShadowColor(const in vec3 shadowPos) {
            float bias = GetShadowBias(geoNoL);

            float depthOpaque = texture(shadowtex1, shadowPos.xy).r;
            if (shadowPos.z - bias > depthOpaque) return vec3(0.0);

            float depthTrans = texture(shadowtex0, shadowPos.xy).r;
            if (shadowPos.z - bias < depthTrans) return vec3(1.0);

            vec4 shadowColor = texture(shadowcolor0, shadowPos.xy);
            shadowColor.rgb = RGBToLinear(shadowColor.rgb);

            shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), pow2(shadowColor.a));
            
            return shadowColor.rgb;
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos) {
            float bias = GetShadowBias(geoNoL);
            return CompareDepth(shadowPos, vec2(0.0), bias);
        }
    #endif
#endif
