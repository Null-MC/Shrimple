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
        vec3 GetShadowing_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float bias) {
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

                vec3 samplePos = shadowPos + vec3(pixelOffset, -bias);
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
                        if (lum > 0.0) {
                            float lum2 = sqrt(lum);
                            shadowColor.rgb *= lum2 / lum;
                        }
                        
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
                // vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                #ifdef IRIS_FEATURE_SSBO
                    vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
                #else
                    float r = sqrt((i + 0.5) / SHADOW_PCF_SAMPLES);
                    float theta = i * GoldenAngle + PHI;
                    
                    vec2 pcfDiskOffset = vec2(cos(theta), sin(theta)) * r;
                    vec2 pixelOffset = (rotation * pcfDiskOffset) * pixelRadius;
                #endif

                shadow += 1.0 - CompareDepth(shadowPos, pixelOffset, bias);
            }

            return 1.0 - shadow * rcp(SHADOW_PCF_SAMPLES);
        }
    #endif
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

#if SHADOW_FILTER == SHADOW_FILTER_PIXEL
    #ifdef SHADOW_COLORED
        vec3 _sample(const in vec3 localPos, const in float offsetBias) {
            vec3 shadowViewPos = mul3(shadowModelViewEx, localPos);
            vec3 shadowPos = mul3(shadowProjectionEx, shadowViewPos);

            shadowPos = distort(shadowPos) * 0.5 + 0.5;

            float depthOpaque = texture(shadowtex1, shadowPos.xy).r;
            if (shadowPos.z - offsetBias > depthOpaque) return vec3(0.0);

            float depthTrans = texture(shadowtex0, shadowPos.xy).r;
            // if (shadowPos.z - offsetBias < depthTrans || depthTrans >= depthOpaque || depthTrans >= 1.0 || depthOpaque >= 1.0) return vec3(1.0);
            if (shadowPos.z - offsetBias < depthTrans || depthTrans >= depthOpaque || depthTrans >= 1.0 || depthOpaque >= 1.0) return vec3(1.0);

            vec4 shadowColor = texture(shadowcolor0, shadowPos.xy);
            shadowColor.rgb = RGBToLinear(shadowColor.rgb);

            float lum = luminance(shadowColor.rgb);
            if (lum > 0.0) {
                float lum2 = sqrt(lum);
                shadowColor.rgb *= lum2 / lum;
            }

            shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), _pow2(shadowColor.a));

            return shadowColor.rgb;
        }

        vec3 GetShadowColor(const in vec3 localPos, const in vec3 localNormal, const in float offsetBias) {
            //float bias = GetShadowNormalBias(cascade, geoNoL);
            //vec3 offsetLocalPos = localNormal * bias + localPos;

            vec3 worldPos = localPos + cameraPosition;
            vec3 f = floor(fract(worldPos) * MATERIAL_RESOLUTION + EPSILON) + 0.5;
            vec3 localPosMin = floor(worldPos) - cameraPosition + f / MATERIAL_RESOLUTION;

            localPosMin += 0.5*localNormal * rcp(MATERIAL_RESOLUTION);

            vec3 localPosMax = localPosMin + rcp(MATERIAL_RESOLUTION);

            vec3 s1 = _sample(localPosMin, offsetBias);
            vec3 s2 = _sample(vec3(localPosMax.x, localPosMin.y, localPosMin.z), offsetBias);
            vec3 s3 = _sample(vec3(localPosMin.x, localPosMin.y, localPosMax.z), offsetBias);
            vec3 s4 = _sample(vec3(localPosMax.x, localPosMin.y, localPosMax.z), offsetBias);
            vec3 s5 = _sample(vec3(localPosMin.x, localPosMax.y, localPosMin.z), offsetBias);
            vec3 s6 = _sample(vec3(localPosMax.x, localPosMax.y, localPosMin.z), offsetBias);
            vec3 s7 = _sample(vec3(localPosMin.x, localPosMax.y, localPosMax.z), offsetBias);
            vec3 s8 = _sample(vec3(localPosMax.x, localPosMax.y, localPosMax.z), offsetBias);
            return (s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8) / 8.0;
        }
    #else
        float _sample(const in vec3 localPos, const in float offsetBias) {
            vec3 shadowViewPos = mul3(shadowModelViewEx, localPos);
            vec3 shadowPos = mul3(shadowProjectionEx, shadowViewPos);

            return CompareDepth(shadowPos, vec2(0.0), offsetBias);
        }

        float GetShadowFactor(const in vec3 localPos, const in vec3 localNormal, const in float offsetBias) {
            //float bias = GetShadowNormalBias(cascade, geoNoL);
            //vec3 offsetLocalPos = localNormal * bias + localPos;

            vec3 worldPos = localPos + cameraPosition;
            vec3 f = floor(fract(worldPos) * MATERIAL_RESOLUTION + EPSILON) + 0.5;
            vec3 localPosMin = floor(worldPos) - cameraPosition + f / MATERIAL_RESOLUTION;

            localPosMin += 0.5*localNormal * rcp(MATERIAL_RESOLUTION);

            vec3 localPosMax = localPosMin + rcp(MATERIAL_RESOLUTION);

            float s1 = _sample(localPosMin, offsetBias);
            float s2 = _sample(vec3(localPosMax.x, localPosMin.y, localPosMin.z), offsetBias);
            float s3 = _sample(vec3(localPosMin.x, localPosMin.y, localPosMax.z), offsetBias);
            float s4 = _sample(vec3(localPosMax.x, localPosMin.y, localPosMax.z), offsetBias);
            float s5 = _sample(vec3(localPosMin.x, localPosMax.y, localPosMin.z), offsetBias);
            float s6 = _sample(vec3(localPosMax.x, localPosMax.y, localPosMin.z), offsetBias);
            float s7 = _sample(vec3(localPosMin.x, localPosMax.y, localPosMax.z), offsetBias);
            float s8 = _sample(vec3(localPosMax.x, localPosMax.y, localPosMax.z), offsetBias);
            return (s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8) / 8.0;
        }
    #endif
#elif SHADOW_FILTER == SHADOW_FILTER_PCSS
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
        vec3 GetShadowColor(const in vec3 shadowPos, const in float offsetBias) {
            vec2 maxPixelRadius = GetShadowPixelRadius(shadowPos, Shadow_MaxPcfSize);
            float blockerDistance = FindBlockerDistance(shadowPos, 0.5 * maxPixelRadius, offsetBias);

            if (blockerDistance <= 0.0) {
                vec3 _shadowPos = distort(shadowPos) * 0.5 + 0.5;

                float depthOpaque = textureLod(shadowtex1, _shadowPos.xy, 0).r;
                float depthTrans = textureLod(shadowtex0, _shadowPos.xy, 0).r;
                if (depthTrans + EPSILON >= depthOpaque) return vec3(1.0);

                vec4 shadowColor = textureLod(shadowcolor0, _shadowPos.xy, 0);
                shadowColor.rgb = RGBToLinear(shadowColor.rgb);

                float lum = luminance(shadowColor.rgb);
                if (lum > 0.0) {
                    float lum2 = sqrt(lum);
                    shadowColor.rgb *= lum2 / lum;
                }

                shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), _pow2(shadowColor.a));
                
                return shadowColor.rgb;
            }

            float scale = saturate(blockerDistance / (SHADOW_PENUMBRA_SCALE * Shadow_MaxPcfSize));
            vec2 pixelRadius = minShadowPixelRadius + (maxPixelRadius - minShadowPixelRadius) * scale;
            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in float offsetBias) {
            vec2 maxPixelRadius = GetShadowPixelRadius(shadowPos, Shadow_MaxPcfSize);

            float blockerDistance = FindBlockerDistance(shadowPos, 0.5 * maxPixelRadius, offsetBias);
            if (blockerDistance <= 0.0) return 1.0;

            float scale = saturate(blockerDistance / (SHADOW_PENUMBRA_SCALE * Shadow_MaxPcfSize));
            vec2 pixelRadius = minShadowPixelRadius + (maxPixelRadius - minShadowPixelRadius) * scale;
            return GetShadowing_PCF(shadowPos, pixelRadius, offsetBias);
        }
    #endif
#elif SHADOW_FILTER == SHADOW_FILTER_PCF
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(const in vec3 shadowPos, const in float offsetBias) {
            // vec2 pixelRadius = max(GetShadowPixelRadius(shadowPos, Shadow_MaxPcfSize), minShadowPixelRadius);

            return GetShadowing_PCF(shadowPos, vec2(minShadowPixelRadius), offsetBias);
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in float offsetBias) {
            // vec2 pixelRadius = max(GetShadowPixelRadius(shadowPos, Shadow_MaxPcfSize), minShadowPixelRadius);

            return 1.0 - GetShadowing_PCF(shadowPos, vec2(minShadowPixelRadius), offsetBias);
        }
    #endif
#elif SHADOW_FILTER == SHADOW_FILTER_NONE
    #ifdef SHADOW_COLORED
        vec3 GetShadowColor(in vec3 shadowPos, const in float offsetBias) {
            shadowPos = distort(shadowPos) * 0.5 + 0.5;

            float depthOpaque = texture(shadowtex1, shadowPos.xy).r;
            if (shadowPos.z - offsetBias > depthOpaque) return vec3(0.0);

            float depthTrans = texture(shadowtex0, shadowPos.xy).r;
            // if (shadowPos.z - offsetBias < depthTrans || depthTrans >= depthOpaque || depthTrans >= 1.0 || depthOpaque >= 1.0) return vec3(1.0);
            if (shadowPos.z - offsetBias < depthTrans || depthTrans >= depthOpaque || depthTrans >= 1.0 || depthOpaque >= 1.0) return vec3(1.0);

            vec4 shadowColor = texture(shadowcolor0, shadowPos.xy);
            shadowColor.rgb = RGBToLinear(shadowColor.rgb);

            float lum = luminance(shadowColor.rgb);
            if (lum > 0.0) {
                float lum2 = sqrt(lum);
                shadowColor.rgb *= lum2 / lum;
            }

            shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), _pow2(shadowColor.a));
            
            return shadowColor.rgb;
        }
    #else
        float GetShadowFactor(const in vec3 shadowPos, const in float offsetBias) {
            return CompareDepth(shadowPos, vec2(0.0), offsetBias);
        }
    #endif
#endif
