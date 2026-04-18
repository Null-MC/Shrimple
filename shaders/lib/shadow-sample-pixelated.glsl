vec3 GetShadowPosition(const in vec3 localPos) {
    vec3 viewPos = mul3(shadowModelView, localPos);
    vec3 ndcPos = mul3(shadowProjection, viewPos);

    distort(ndcPos.xy);
    return ndcPos * 0.5 + 0.5;
}

float SampleShadows(const in vec3 localPos, const in vec3 localGeoNormal) {
    vec3 snapLocalPos = localPos - 0.5 / LIGHTING_RESOLUTION;
    snapLocalPos += localGeoNormal/LIGHTING_RESOLUTION;

    float shadow = 0.0;

    for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
        int loop_seed = frameCounter*SHADOW_PCF_SAMPLES + i;
        vec3 sampleOffset = hash33(vec3(gl_FragCoord.xy, loop_seed));
        vec3 sampleLocalPos = snapLocalPos + sampleOffset/LIGHTING_RESOLUTION;
        vec3 shadowSamplePos = GetShadowPosition(sampleLocalPos);

        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            float shadow_sample = texture(TEX_SHADOW, shadowSamplePos).r;
        #else
            float shadowDepth = texture(TEX_SHADOW, shadowSamplePos.xy).r;
            float shadow_sample = step(shadowSamplePos.z, shadowDepth).r;
        #endif

        shadow += shadow_sample;
    }

    return max(shadow / float(SHADOW_PCF_SAMPLES), 0.0);
}

#ifdef SHADOW_COLORED
    vec3 SampleShadowColor(const in vec3 localPos, const in vec3 localGeoNormal) {
        vec3 snapLocalPos = localPos - 0.5 / LIGHTING_RESOLUTION;
        snapLocalPos += localGeoNormal/LIGHTING_RESOLUTION;

        vec3 origin = snapLocalPos + cameraPosition;

        vec3 shadow = vec3(0.0);

        for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
            int loop_seed = frameCounter*SHADOW_PCF_SAMPLES + i;
            vec3 sampleOffset = hash33(vec3(gl_FragCoord.xy, loop_seed));
            vec3 sampleLocalPos = snapLocalPos + sampleOffset/LIGHTING_RESOLUTION;
            vec3 shadowSamplePos = GetShadowPosition(sampleLocalPos);

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
    vec3 SampleShadowColor(const in vec3 localPos) {
        return vec3(SampleShadows(shadowPos));
    }
#endif
