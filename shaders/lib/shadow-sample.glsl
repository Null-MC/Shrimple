const float ShadowPixelRadius = 1.8 / shadowMapResolution;


float GetShadowDither() {
    vec2 seed = gl_FragCoord.xy;

    #ifdef TAA_ENABLED
        seed += vec2(71.83, 83.71) * (frameCounter % 16);
    #endif

    return InterleavedGradientNoise(seed);
}

mat2 GetRandomShadowRotation() {
    float dither = GetShadowDither();
    float angle = fract(dither) * (PI * 2.0);
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

vec2 GetShadowSampleOffset(const in mat2 rotation, const in int i) {
    float r = sqrt((i + 0.5) / SHADOW_PCF_SAMPLES);
    float theta = i * GoldenAngle + PHI;

    vec2 pcfDiskOffset = vec2(cos(theta), sin(theta)) * r;
    return (rotation * pcfDiskOffset) * ShadowPixelRadius;
}

#ifdef SHADOW_COLORED
    vec3 SampleShadows(const in vec3 shadowPos) {
        #if SHADOW_PCF_SAMPLES > 1
            mat2 rotation = GetRandomShadowRotation();
        #endif

        vec3 shadow = vec3(0.0);

        for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
            vec3 shadowSamplePos = shadowPos;
            #if SHADOW_PCF_SAMPLES > 1
                shadowSamplePos.xy += GetShadowSampleOffset(rotation, i);
            #endif

            #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
                float shadowF = texture(TEX_SHADOW, shadowSamplePos).r;
                float shadowColorF = texture(TEX_SHADOW_COLOR, shadowSamplePos).r;
            #else
                float shadowDepth = texture(TEX_SHADOW, shadowSamplePos.xy).r;
                float shadowF = step(shadowSamplePos.z, shadowDepth).r;
            #endif

            vec4 shadowColor = texture(shadowcolor0, shadowSamplePos.xy);
            shadowColor.rgb = RGBToLinear(shadowColor.rgb) * (1.0 - _pow2(shadowColor.a));
            shadowColor.rgb = mix(shadowColor.rgb, vec3(1.0), shadowColorF);

            shadow += shadowF * shadowColor.rgb;
        }

        return max(shadow / float(SHADOW_PCF_SAMPLES), 0.0);
    }
#else
    vec3 SampleShadows(const in vec3 shadowPos) {
        #if SHADOW_PCF_SAMPLES > 1
            mat2 rotation = GetRandomShadowRotation();
        #endif

        float shadow = 0.0;

        for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
            vec3 shadowSamplePos = shadowPos;
            #if SHADOW_PCF_SAMPLES > 1
                shadowSamplePos.xy += GetShadowSampleOffset(rotation, i);
            #endif

            #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
                float shadow_sample = texture(TEX_SHADOW, shadowSamplePos).r;
            #else
                float shadowDepth = texture(TEX_SHADOW, shadowSamplePos.xy).r;
                float shadow_sample = step(shadowSamplePos.z, shadowDepth).r;
            #endif

            shadow += shadow_sample;
        }

        return vec3(max(shadow / float(SHADOW_PCF_SAMPLES), 0.0));
    }
#endif
