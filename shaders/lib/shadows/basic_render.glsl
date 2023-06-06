float SampleDepth(const in vec2 shadowPos, const in vec2 offset) {
    return texture(shadowtex1, shadowPos + offset).r;
}

// returns: [0] when depth occluded, [1] otherwise
float CompareDepth(const in vec3 shadowPos, const in vec2 offset, const in float bias) {
    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        return texture(shadowtex0HW, shadowPos + vec3(offset, -bias)).r;
    #else
        float texDepth = texture(shadowtex0, shadowPos.xy + offset).r;
        return step(shadowPos.z - bias, texDepth);
    #endif
}

#if SHADOW_FILTER != 0
    // PCF
    #ifdef SHADOW_COLORED
        vec3 GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
            #ifdef RENDER_FRAG
                float dither = InterleavedGradientNoise(gl_FragCoord.xy);
            #else
                float dither = 0.0;
            #endif

            float angle = fract(dither) * TAU;
            float s = sin(angle), c = cos(angle);
            mat2 rotation = mat2(c, -s, s, c);
            
            vec3 shadowColor = vec3(0.0);
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;

                vec4 sampleColor = vec4(1.0);

                float depthOpaque = textureLod(shadowtex1, shadowPos.xy + pixelOffset, 0).r;

                if (shadowPos.z - bias > depthOpaque) sampleColor.rgb = vec3(0.0);
                else {
                    float depthTrans = textureLod(shadowtex0, shadowPos.xy + pixelOffset, 0).r;
                    if (shadowPos.z - bias < depthTrans) sampleColor.rgb = vec3(1.0);
                    else {
                        sampleColor = textureLod(shadowcolor0, shadowPos.xy + pixelOffset, 0);
                        sampleColor.rgb = RGBToLinear(sampleColor.rgb);
                        
                        sampleColor.rgb = mix(sampleColor.rgb, vec3(0.0), _pow2(sampleColor.a));
                    }
                }

                shadowColor += sampleColor.rgb;
            }

            return shadowColor * rcp(SHADOW_PCF_SAMPLES);
        }
    #else
        float GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
            #ifdef RENDER_FRAG
                float dither = InterleavedGradientNoise(gl_FragCoord.xy);
            #else
                float dither = 0.0;
            #endif

            float angle = fract(dither) * TAU;
            float s = sin(angle), c = cos(angle);
            mat2 rotation = mat2(c, -s, s, c);

            float shadow = 0.0;
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                shadow += 1.0 - CompareDepth(shadowPos, pixelOffset, bias);
            }

            return shadow * rcp(SHADOW_PCF_SAMPLES);
        }
    #endif

    vec2 GetShadowPixelRadius(const in vec3 shadowPos, const in float blockRadius) {
        vec2 shadowProjectionSize = 2.0 / vec2(shadowProjectionEx[0].x, shadowProjectionEx[1].y);

        float distortFactor = getDistortFactor(shadowPos.xy * 2.0 - 1.0);
        float maxRes = shadowMapSize / SHADOW_DISTORT_FACTOR;

        vec2 pixelPerBlockScale = maxRes / shadowProjectionSize;
        return blockRadius * pixelPerBlockScale * shadowPixelSize * (1.0 - distortFactor);
    }
#endif

#if SHADOW_FILTER == 2
    // PCF + PCSS
    float FindBlockerDistance(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
        #ifdef RENDER_FRAG
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);
        #else
            float dither = 0.0;
        #endif

        float angle = fract(dither) * TAU;
        float s = sin(angle), c = cos(angle);
        mat2 rotation = mat2(c, -s, s, c);
        
        float blockers = 0.0;
        float avgBlockerDistance = 0.0;
        for (int i = 0; i < SHADOW_PCSS_SAMPLES; i++) {
            vec2 pixelOffset = (rotation * pcssDiskOffset[i]) * pixelRadius;

            #ifdef SHADOW_COLORED
                float texDepth = texture(shadowtex1, shadowPos.xy + pixelOffset).r;
            #else
                float texDepth = texture(shadowtex0, shadowPos.xy + pixelOffset).r;
            #endif

            float hitDist = max((shadowPos.z - bias) - texDepth, 0.0);

            avgBlockerDistance += hitDist * (2.0 * far);
            blockers += step(0.0, hitDist);
        }

        return blockers > 0 ? avgBlockerDistance / blockers : -1.0;
    }

    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in float bias) {
            vec2 minPixelRadius = GetShadowPixelRadius(shadowPos, ShadowMinPcfSize);
            vec2 maxPixelRadius = GetShadowPixelRadius(shadowPos, ShadowMaxPcfSize);
            float offsetBias = GetShadowOffsetBias() + bias;

            // blocker search
            float blockerDistance = FindBlockerDistance(shadowPos, maxPixelRadius, offsetBias);

            if (blockerDistance <= 0.0) {
                float depthTrans = textureLod(shadowtex0, shadowPos.xy, 0).r;
                if (shadowPos.z - offsetBias < depthTrans) return vec3(1.0);

                vec4 shadowColor = textureLod(shadowcolor0, shadowPos.xy, 0);
                shadowColor.rgb = RGBToLinear(shadowColor.rgb);

                shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), _pow2(shadowColor.a));
                
                return shadowColor.rgb;
            }

            vec2 pixelRadius = minPixelRadius + (maxPixelRadius - minPixelRadius) * min(blockerDistance * SHADOW_PENUMBRA_SCALE, 1.0);
            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in float bias) {
            vec2 minPixelRadius = GetShadowPixelRadius(shadowPos, ShadowMinPcfSize);
            vec2 maxPixelRadius = GetShadowPixelRadius(shadowPos, ShadowMaxPcfSize);
            float offsetBias = GetShadowOffsetBias() + bias;

            // blocker search
            float blockerDistance = FindBlockerDistance(shadowPos, maxPixelRadius, offsetBias);
            if (blockerDistance <= 0.0) return 1.0;

            vec2 pixelRadius = minPixelRadius + (maxPixelRadius - minPixelRadius) * min(blockerDistance * SHADOW_PENUMBRA_SCALE, 1.0);
            return 1.0 - GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #endif
#elif SHADOW_FILTER == 1
    // PCF
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in float bias) {
            vec2 pixelRadius = GetShadowPixelRadius(shadowPos, ShadowMaxPcfSize);
            float offsetBias = GetShadowOffsetBias() + bias;

            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in float bias) {
            vec2 pixelRadius = GetShadowPixelRadius(shadowPos, ShadowMaxPcfSize);
            float offsetBias = GetShadowOffsetBias() + bias;

            return 1.0 - GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #endif
#elif SHADOW_FILTER == 0
    // Unfiltered
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in float bias) {
            float offsetBias = GetShadowOffsetBias() + bias;

            float depthOpaque = texture(shadowtex1, shadowPos.xy).r;
            if (shadowPos.z - offsetBias > depthOpaque) return vec3(0.0);

            float depthTrans = texture(shadowtex0, shadowPos.xy).r;
            if (shadowPos.z - offsetBias < depthTrans) return vec3(1.0);

            vec4 shadowColor = texture(shadowcolor0, shadowPos.xy);
            shadowColor.rgb = RGBToLinear(shadowColor.rgb);

            shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), _pow2(shadowColor.a));
            
            return shadowColor.rgb;
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in float bias) {
            float offsetBias = GetShadowOffsetBias() + bias;
            return CompareDepth(shadowPos, vec2(0.0), offsetBias);
        }
    #endif
#endif
