const float minShadowPixelRadius = Shadow_MinPcfSize * shadowPixelSize;


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

float SampleDepth(const in vec2 shadowPos) {
    #ifdef RENDER_TRANSLUCENT
        return texture(shadowtex0, shadowPos).r;
    #else
        return texture(shadowtex1, shadowPos).r;
    #endif
}

// returns: [0] when depth occluded, [1] otherwise
float CompareDepth(in vec3 shadowPos, const in vec2 offset, const in float bias) {
    shadowPos = distort(shadowPos + vec3(offset, -bias));
    shadowPos = shadowPos * 0.5 + 0.5;

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        #ifdef RENDER_TRANSLUCENT
            return texture(shadowtex0HW, shadowPos).r;
        #else
            return texture(shadowtex1HW, shadowPos).r;
        #endif
    #else
        float texDepth = SampleDepth(shadowPos.xy);
        return step(shadowPos.z, texDepth);
    #endif
}

#if SHADOW_FILTER != 0
    // PCF
    #ifdef SHADOW_COLORED
        vec3 GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias, const in float sss) {
            float dither = GetShadowDither();

            float angle = fract(dither) * TAU;
            float s = sin(angle), c = cos(angle);
            mat2 rotation = mat2(c, -s, s, c);
            
            vec3 shadowColor = vec3(0.0);
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                #ifdef IRIS_FEATURE_SSBO
                    vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                #else
                    float r = sqrt((i + 0.5) / SHADOW_PCF_SAMPLES);
                    float theta = i * GoldenAngle + PHI;

                    vec2 pcfDiskOffset = vec2(cos(theta), sin(theta)) * r;
                    vec2 pixelOffset = (rotation * pcfDiskOffset) * pixelRadius;
                #endif

                vec4 sampleColor = vec4(1.0);

                float sampleBias = bias + sss * InterleavedGradientNoiseTime(i);

                vec3 samplePos = shadowPos + vec3(pixelOffset, -sampleBias);
                samplePos = distort(samplePos) * 0.5 + 0.5;

                float depthOpaque = textureLod(shadowtex1, samplePos.xy, 0).r;

                if (samplePos.z > depthOpaque) sampleColor.rgb = vec3(0.0);
                else {
                    float depthTrans = textureLod(shadowtex0, samplePos.xy, 0).r;
                    if (samplePos.z < depthTrans) sampleColor.rgb = vec3(1.0);
                    else {
                        sampleColor = textureLod(shadowcolor0, samplePos.xy, 0);
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
        float GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias, const in float sss) {
            float dither = GetShadowDither();

            float angle = fract(dither) * TAU;
            float s = sin(angle), c = cos(angle);
            mat2 rotation = mat2(c, -s, s, c);

            float shadow = 0.0;
            for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
                // vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                #ifdef IRIS_FEATURE_SSBO
                    vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                #else
                    float r = sqrt((i + 0.5) / SHADOW_PCF_SAMPLES);
                    float theta = i * GoldenAngle + PHI;
                    
                    vec2 pcfDiskOffset = vec2(cos(theta), sin(theta)) * r;
                    vec2 pixelOffset = (rotation * pcfDiskOffset) * pixelRadius;
                #endif

                float sampleBias = bias + sss * InterleavedGradientNoiseTime(i);

                shadow += 1.0 - CompareDepth(shadowPos, pixelOffset, sampleBias);
            }

            return 1.0 - shadow * rcp(SHADOW_PCF_SAMPLES);
        }
    #endif

    vec2 GetShadowPixelRadius(const in vec3 shadowPos, const in float blockRadius) {
        // #ifndef IRIS_FEATURE_SSBO
        //     mat4 shadowProjectionEx = shadowProjection;//BuildShadowProjectionMatrix();
        //     shadowProjectionEx[2][2] = -2.0 / (3.0 * far);
        //     shadowProjectionEx[3][2] = 0.0;
        // #endif

        vec2 shadowProjectionSize = 2.0 / vec2(shadowProjectionEx[0].x, shadowProjectionEx[1].y);

        //float distortFactor = getDistortFactor(shadowPos.xy * 2.0 - 1.0);
        //float maxRes = shadowMapSize / Shadow_DistortF;

        vec2 pixelPerBlockScale = shadowMapSize / shadowProjectionSize;
        return 2.0 * blockRadius * pixelPerBlockScale * shadowPixelSize;// * (1.0 - distortFactor);
    }
#endif

#if SHADOW_FILTER == 2
    // PCF + PCSS
    float FindBlockerDistance(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
        float dither = GetShadowDither();

        float angle = fract(dither) * TAU;
        float s = sin(angle), c = cos(angle);
        mat2 rotation = mat2(c, -s, s, c);
        
        float blockers = 0.0;
        float avgDist = 0.0;
        for (int i = 0; i < SHADOW_PCSS_SAMPLES; i++) {
            // vec2 pixelOffset = (rotation * pcssDiskOffset[i]) * pixelRadius;
            #ifdef IRIS_FEATURE_SSBO
                vec2 pixelOffset = (rotation * pcssDiskOffset[i]) * pixelRadius;
            #else
                float r = sqrt((i + 0.5) / SHADOW_PCSS_SAMPLES);
                float theta = i * GoldenAngle + PHI;
                
                vec2 pcssDiskOffset = vec2(cos(theta), sin(theta)) * r;
                vec2 pixelOffset = (rotation * pcssDiskOffset) * pixelRadius;
            #endif

            vec3 _shadowPos = shadowPos;
            _shadowPos.xy += pixelOffset;
            _shadowPos = distort(_shadowPos) * 0.5 + 0.5;

            float texDepth = SampleDepth(_shadowPos.xy);
            float hitDist = max(_shadowPos.z - texDepth, 0.0);

            avgDist += hitDist;
            blockers++;// += step(0.0, hitDist);
        }

        float zRange = GetShadowRange();
        return (avgDist / blockers) * zRange;

        // float hitDist = max((_shadowPos.z - bias) - texDepth, 0.0);

        // return blockers > 0 ? avgBlockerDistance / blockers : -1.0;
    }

    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in float offsetBias, const in float sssBias) {
            vec2 maxPixelRadius = GetShadowPixelRadius(shadowPos, Shadow_MaxPcfSize);
            float blockerDistance = FindBlockerDistance(shadowPos, 0.5 * maxPixelRadius, offsetBias);

            if (blockerDistance <= 0.0) {
                vec3 _shadowPos = distort(shadowPos) * 0.5 + 0.5;

                float depthTrans = textureLod(shadowtex0, _shadowPos.xy, 0).r;
                if (_shadowPos.z - offsetBias < depthTrans) return vec3(1.0);

                vec4 shadowColor = textureLod(shadowcolor0, _shadowPos.xy, 0);
                shadowColor.rgb = RGBToLinear(shadowColor.rgb);

                float lum = luminance(shadowColor.rgb);
                if (lum > 0.0) shadowColor.rgb /= lum;

                shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), _pow2(shadowColor.a));
                
                return shadowColor.rgb;
            }

            float scale = saturate(blockerDistance / (SHADOW_PENUMBRA_SCALE * Shadow_MaxPcfSize));
            vec2 pixelRadius = minShadowPixelRadius + (maxPixelRadius - minShadowPixelRadius) * scale;
            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias, sssBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in float offsetBias, const in float sssBias) {
            vec2 maxPixelRadius = GetShadowPixelRadius(shadowPos, Shadow_MaxPcfSize);

            float blockerDistance = FindBlockerDistance(shadowPos, 0.5 * maxPixelRadius, offsetBias);
            if (blockerDistance <= 0.0) return 1.0;

            float scale = saturate(blockerDistance / (SHADOW_PENUMBRA_SCALE * Shadow_MaxPcfSize));
            vec2 pixelRadius = minShadowPixelRadius + (maxPixelRadius - minShadowPixelRadius) * scale;
            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias, sssBias);
        }
    #endif
#elif SHADOW_FILTER == 1
    // PCF
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in float offsetBias, const in float sssBias) {
            vec2 pixelRadius = max(GetShadowPixelRadius(shadowPos, Shadow_MaxPcfSize), minShadowPixelRadius);

            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias, sssBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in float offsetBias, const in float sssBias) {
            vec2 pixelRadius = max(GetShadowPixelRadius(shadowPos, Shadow_MaxPcfSize), minShadowPixelRadius);

            return 1.0 - GetShadowing_PCF(shadowPos, pixelRadius, offsetBias, sssBias);
        }
    #endif
#elif SHADOW_FILTER == 0
    // Unfiltered
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(in vec3 shadowPos, const in float offsetBias, const in float sssBias) {
            shadowPos = distort(shadowPos) * 0.5 + 0.5;

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
        float GetShadowFactor(const in vec3 shadowPos, const in float offsetBias, const in float sssBias) {
            return CompareDepth(shadowPos, vec2(0.0), offsetBias);
        }
    #endif
#endif
