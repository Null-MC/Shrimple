const float minShadowPixelRadius = Shadow_MinPcfSize * shadowPixelSize;
const float cascadeTexSize = shadowMapSize * 0.5;
const float tile_dist_bias_factor = 0.012288;
const int pcf_sizes[4] = int[](4, 3, 2, 1);
const int pcf_max = 4;


float GetShadowDither() {
    #ifdef RENDER_FRAG
        #ifdef EFFECT_TAA_ENABLED
            return InterleavedGradientNoiseTime();
        #else
            return InterleavedGradientNoise();
        #endif
    #else
        return 0.0;
    #endif
}

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
        #ifdef RENDER_TRANSLUCENT
            float texDepth = texture(shadowtex0, shadowPos.xy + offset).r;
        #else
            float texDepth = texture(shadowtex1, shadowPos.xy + offset).r;
        #endif
        return step(shadowPos.z - bias, texDepth);
    #endif
}

#if SHADOW_FILTER != 0
    #ifdef SHADOW_COLORED
        vec3 GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
            float dither = GetShadowDither();
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
            float dither = GetShadowDither();
            float angle = fract(dither) * TAU;
            float s = sin(angle), c = cos(angle);
            mat2 rotation = mat2(c, -s, s, c);

            float shadow = 0.0;
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                shadow += 1.0 - CompareDepth(shadowPos, pixelOffset, bias);
            }

            return 1.0 - shadow * rcp(SHADOW_PCF_SAMPLES);
        }
    #endif
#endif

#if SHADOW_FILTER == 3
    // Pixelated
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 localPos, const in int cascade) {
            float offsetBias = GetShadowOffsetBias(cascade);

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
        float _sample(const in vec3 localPos, const in float offsetBias, const in int cascade) {
            vec3 shadowViewPos = mul3(shadowModelViewEx, localPos);

            // convert to shadow screen space
            vec3 shadowPos = mul3(cascadeProjection[cascade], shadowViewPos);

            shadowPos = shadowPos * 0.5 + 0.5;
            shadowPos.xy = shadowPos.xy * 0.5 + shadowProjectionPos[cascade];

            return CompareDepth(shadowPos, vec2(0.0), offsetBias);
        }

        float GetShadowFactor(const in vec3 localPos, const in vec3 localNormal, const in int cascade) {
            float offsetBias = GetShadowOffsetBias(cascade);

            //float bias = GetShadowNormalBias(cascade, geoNoL);
            //vec3 offsetLocalPos = localNormal * bias + localPos;

            vec3 worldPos = localPos + cameraPosition;
            vec3 f = floor(fract(worldPos) * SHADOW_PIXELATE + EPSILON) + 0.5;
            vec3 localPosMin = floor(worldPos) - cameraPosition + f / SHADOW_PIXELATE;

            localPosMin += 0.5*localNormal * rcp(SHADOW_PIXELATE);

            vec3 localPosMax = localPosMin + rcp(SHADOW_PIXELATE);

            float s1 = _sample(localPosMin, offsetBias, cascade);
            float s2 = _sample(vec3(localPosMax.x, localPosMin.y, localPosMin.z), offsetBias, cascade);
            float s3 = _sample(vec3(localPosMin.x, localPosMin.y, localPosMax.z), offsetBias, cascade);
            float s4 = _sample(vec3(localPosMax.x, localPosMin.y, localPosMax.z), offsetBias, cascade);
            float s5 = _sample(vec3(localPosMin.x, localPosMax.y, localPosMin.z), offsetBias, cascade);
            float s6 = _sample(vec3(localPosMax.x, localPosMax.y, localPosMin.z), offsetBias, cascade);
            float s7 = _sample(vec3(localPosMin.x, localPosMax.y, localPosMax.z), offsetBias, cascade);
            float s8 = _sample(vec3(localPosMax.x, localPosMax.y, localPosMax.z), offsetBias, cascade);
            return (s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8) / 8.0;
        }
    #endif
#elif SHADOW_FILTER == 2
    // PCF + PCSS
    float FindBlockerDistance(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
        float dither = GetShadowDither();
        float zRange = GetShadowRange();

        float angle = fract(dither) * TAU;
        float s = sin(angle), c = cos(angle);
        mat2 rotation = mat2(c, -s, s, c);

        float blockers = 0.0;
        float avgDist = 0.0;
        for (int i = 0; i < SHADOW_PCSS_SAMPLES; i++) {
            vec2 pixelOffset = (rotation * pcssDiskOffset[i]) * pixelRadius;

            #ifdef SHADOW_COLORED
                float texDepth = texture(shadowtex1, shadowPos.xy + pixelOffset).r;
            #else
                float texDepth = texture(shadowtex0, shadowPos.xy + pixelOffset).r;
            #endif

            float hitDist = max((shadowPos.z - bias) - texDepth, 0.0) * zRange;

            avgDist += hitDist;
            blockers++;// += step(0.0, hitDist);
        }

        // return blockers > 0.0 ? avgDist / blockers : -1.0;
        return avgDist / blockers;
    }

    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in int cascade) {
            float offsetBias = GetShadowOffsetBias(cascade);

            vec2 maxPixelRadius = GetPixelRadius(Shadow_MaxPcfSize, cascade);
            float blockerDistance = FindBlockerDistance(shadowPos, 0.5 * maxPixelRadius, offsetBias);

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

            float scale = saturate(blockerDistance / (SHADOW_PENUMBRA_SCALE * Shadow_MaxPcfSize));
            vec2 pixelRadius = minShadowPixelRadius + (maxPixelRadius - minShadowPixelRadius) * scale;
            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in int cascade) {
            vec2 maxPixelRadius = GetPixelRadius(Shadow_MaxPcfSize, cascade);
            float offsetBias = GetShadowOffsetBias(cascade);

            float blockerDistance = FindBlockerDistance(shadowPos, 0.5 * maxPixelRadius, offsetBias);
            if (blockerDistance <= 0.0) return 1.0;

            float scale = saturate(blockerDistance / (SHADOW_PENUMBRA_SCALE * Shadow_MaxPcfSize));
            vec2 pixelRadius = minShadowPixelRadius + (maxPixelRadius - minShadowPixelRadius) * scale;
            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #endif
#elif SHADOW_FILTER == 1
    // PCF
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in int cascade) {
            // vec2 pixelRadius = max(GetPixelRadius(Shadow_MaxPcfSize, cascade), minShadowPixelRadius);
            float offsetBias = GetShadowOffsetBias(cascade);

            return GetShadowing_PCF(shadowPos, vec2(minShadowPixelRadius), offsetBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in int cascade) {
            // vec2 pixelRadius = max(GetPixelRadius(Shadow_MaxPcfSize, cascade), minShadowPixelRadius);
            float offsetBias = GetShadowOffsetBias(cascade);

            return 1.0 - GetShadowing_PCF(shadowPos, vec2(minShadowPixelRadius), offsetBias);
        }
    #endif
#elif SHADOW_FILTER == 0
    // Unfiltered
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in int cascade) {
            float offsetBias = GetShadowOffsetBias(cascade);

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
        float GetShadowFactor(const in vec3 shadowPos, const in int cascade) {
            float offsetBias = GetShadowOffsetBias(cascade);
            return CompareDepth(shadowPos, vec2(0.0), offsetBias);
        }
    #endif
#endif
