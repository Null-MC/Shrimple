const float cascadeTexSize = shadowMapSize * 0.5;
const float tile_dist_bias_factor = 0.012288;
const int pcf_sizes[4] = int[](4, 3, 2, 1);
const int pcf_max = 4;


float SampleDepth(const in vec2 shadowPos, const in vec2 offset) {
    return textureLod(shadowtex1, shadowPos + offset, 0).r;
}

vec2 GetPixelRadius(const in float blockRadius, const in int cascade) {
    return blockRadius * (cascadeTexSize / shadowProjectionSize[cascade]) * shadowPixelSize;
}

bool IsSampleWithinCascade(const in vec2 shadowPos, const in int cascade, const in float blockRadius) {
    vec2 padding = blockRadius / shadowProjectionSize[cascade];
    vec2 clipMin = shadowProjectionPos[cascade] + padding;
    vec2 clipMax = shadowProjectionPos[cascade] + 0.5 - padding;

    return all(greaterThan(shadowPos, clipMin)) && all(lessThan(shadowPos, clipMax));
}

int GetShadowCascade(const in vec3 shadowPos[4], const in float blockRadius) {
    if (IsSampleWithinCascade(shadowPos[0].xy, 0, blockRadius)) return 0;
    if (IsSampleWithinCascade(shadowPos[1].xy, 1, blockRadius)) return 1;
    if (IsSampleWithinCascade(shadowPos[2].xy, 2, blockRadius)) return 2;
    if (IsSampleWithinCascade(shadowPos[3].xy, 3, blockRadius)) return 3;
    return -1;
}

// returns: [0] when depth occluded, [1] otherwise
float CompareDepth(const in vec3 shadowPos, const in vec2 offset, const in float bias) {
    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        #ifdef RENDER_TRANSLUCENT
            return texture(shadowtex0HW, shadowPos + vec3(offset, -bias)).r;
        #else
            return texture(shadowtex1HW, shadowPos + vec3(offset, -bias)).r;
        #endif
    #else
        float texDepth = texture(shadowtex0, shadowPos.xy + offset).r;
        return step(shadowPos.z - bias, texDepth);
    #endif
}

#if SHADOW_FILTER != 0
    #ifdef SHADOW_COLORED
        vec3 GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);
            float angle = fract(dither) * TAU;
            float s = sin(angle), c = cos(angle);
            mat2 rotation = mat2(c, -s, s, c);

            vec3 shadowColor = vec3(0.0);
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;

                float depthOpaque = textureLod(shadowtex1, shadowPos.xy + pixelOffset, 0).r;

                vec4 sampleColor = vec4(1.0);
                if (shadowPos.z - bias > depthOpaque) sampleColor.rgb = vec3(0.0);
                else {
                    float depthTrans = textureLod(shadowtex0, shadowPos.xy + pixelOffset, 0).r;
                    if (shadowPos.z + EPSILON <= depthTrans) sampleColor.rgb = vec3(1.0);
                    else {
                        sampleColor = textureLod(shadowcolor0, shadowPos.xy + pixelOffset, 0);
                        sampleColor.rgb = RGBToLinear(sampleColor.rgb);
                        
                        float lum = luminance(sampleColor.rgb);
                        if (lum > 0.0) sampleColor.rgb /= lum;

                        sampleColor.rgb = mix(sampleColor.rgb, vec3(0.0), _pow2(sampleColor.a));
                    }
                }

                shadowColor += sampleColor.rgb;
            }

            return shadowColor * rcp(SHADOW_PCF_SAMPLES);
        }
    #else
        float GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);
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
#endif

#if SHADOW_FILTER == 2
    // PCF + PCSS
    float FindBlockerDistance(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
        float dither = InterleavedGradientNoise(gl_FragCoord.xy);
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

            avgBlockerDistance += hitDist * (far * 3.0);
            blockers += step(0.0, hitDist);
        }

        return blockers > 0.0 ? avgBlockerDistance / blockers : -1.0;
    }

    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in int cascade, const in float bias) {
            vec2 minPixelRadius = GetPixelRadius(ShadowMinPcfSize, cascade);
            vec2 maxPixelRadius = GetPixelRadius(ShadowMaxPcfSize, cascade);
            float offsetBias = GetShadowOffsetBias(cascade) + bias;

            // blocker search
            float blockerDistance = FindBlockerDistance(shadowPos, maxPixelRadius, offsetBias);

            if (blockerDistance <= 0.0) {
                //float depthOpaque = textureLod(shadowtex1, shadowPos.xy, 0).r;
                //if (shadowPos.z - offsetBias > depthOpaque) return vec3(0.0);

                float depthTrans = textureLod(shadowtex0, shadowPos.xy, 0).r;
                if (shadowPos.z - offsetBias < depthTrans) return vec3(1.0);

                vec4 shadowColor = textureLod(shadowcolor0, shadowPos.xy, 0);
                shadowColor.rgb = RGBToLinear(shadowColor.rgb);

                float lum = luminance(shadowColor.rgb);
                if (lum > 0.0) shadowColor.rgb /= lum;

                shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), _pow2(shadowColor.a));
                
                return shadowColor.rgb;
            }

            vec2 pixelRadius = minPixelRadius + (maxPixelRadius - minPixelRadius) * min(blockerDistance * SHADOW_PENUMBRA_SCALE, 1.0);
            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in int cascade, const in float bias) {
            vec2 minPixelRadius = GetPixelRadius(ShadowMinPcfSize, cascade);
            vec2 maxPixelRadius = GetPixelRadius(ShadowMaxPcfSize, cascade);
            float offsetBias = GetShadowOffsetBias(cascade) + bias;

            float blockerDistance = FindBlockerDistance(shadowPos, maxPixelRadius, offsetBias);
            if (blockerDistance <= 0.0) return 1.0;

            //bias *= 1.0 + 20.0 * blockerDistance;

            vec2 pixelRadius = minPixelRadius + (maxPixelRadius - minPixelRadius) * min(blockerDistance * SHADOW_PENUMBRA_SCALE, 1.0);
            float shadow = GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
            //return 1.0 - shadow;
            return 1.0 - _smoothstep(shadow);
        }
    #endif
#elif SHADOW_FILTER == 1
    // PCF
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in int cascade, const in float bias) {
            vec2 pixelRadius = GetPixelRadius(ShadowMaxPcfSize, cascade);
            float offsetBias = GetShadowOffsetBias(cascade) + bias;

            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in int cascade, const in float bias) {
            vec2 pixelRadius = GetPixelRadius(ShadowMaxPcfSize, cascade);
            float offsetBias = GetShadowOffsetBias(cascade) + bias;

            return 1.0 - GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #endif
#elif SHADOW_FILTER == 0
    // Unfiltered
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in int cascade, const in float bias) {
            float offsetBias = GetShadowOffsetBias(cascade) + bias;

            float depthOpaque = texture(shadowtex1, shadowPos.xy).r;
            if (shadowPos.z - offsetBias > depthOpaque) return vec3(0.0);

            float depthTrans = texture(shadowtex0, shadowPos.xy).r;
            if (shadowPos.z - offsetBias < depthTrans) return vec3(1.0);

            vec4 shadowColor = texture(shadowcolor0, shadowPos.xy);
            shadowColor.rgb = RGBToLinear(shadowColor.rgb);

            float lum = luminance(shadowColor.rgb);
            if (lum > 0.0) shadowColor.rgb /= lum;

            shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), _pow2(shadowColor.a));

            return shadowColor.rgb;
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in int cascade, const in float bias) {
            float offsetBias = GetShadowOffsetBias(cascade) + bias;
            return CompareDepth(shadowPos, vec2(0.0), offsetBias);
        }
    #endif
#endif
