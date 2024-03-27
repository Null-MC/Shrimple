// #if defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE == CLOUDS_VANILLA && !defined RENDER_CLOUDS
//     float SampleCloudShadow(const in vec3 skyLightDir, const in vec3 cloudShadowPos) {
//         #ifdef RENDER_FRAG
//             #ifdef EFFECT_TAA_ENABLED
//                 float dither = InterleavedGradientNoiseTime();
//             #else
//                 float dither = InterleavedGradientNoise();
//             #endif
//         #else
//             float dither = 0.0;
//         #endif

//         float angle = fract(dither) * TAU;
//         float s = sin(angle), c = cos(angle);
//         mat2 rotation = mat2(c, -s, s, c);

//         float cloudF = 0.0;
//         for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
//             vec2 offset = (rotation * pcfDiskOffset[i]) * rcp(1024.0 * SHADOW_CLOUD_RADIUS);

//             float cloudSample = textureLod(TEX_CLOUDS_VANILLA, cloudShadowPos.xy + offset, 0).a;
//             cloudF += cloudSample * step(0.0, cloudShadowPos.z);
//         }

//         cloudF *= rcp(SHADOW_PCF_SAMPLES);

//         float skyLightF = smoothstep(0.1, 0.3, skyLightDir.y);

//         return 1.0 - (1.0 - ShadowCloudBrightnessF) * min(cloudF, 1.0) * skyLightF;
//     }
// #endif

#ifdef RENDER_FRAG
    #ifdef SHADOW_COLORED
        vec3 GetFinalShadowColor(const in vec3 skyLightDir, const in float geoNoL, const in float sss) {
            vec3 shadow = vec3(1.0);
    #else
        float GetFinalShadowFactor(const in vec3 skyLightDir, const in float geoNoL, const in float sss) {
            float shadow = 1.0;
    #endif

        #ifdef RENDER_SHADOWS_ENABLED
            #ifdef EFFECT_TAA_ENABLED
                float dither = InterleavedGradientNoiseTime();
            #else
                float dither = InterleavedGradientNoise();
            #endif

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int cascadeIndex = GetShadowCascade(vIn.shadowPos, ShadowMaxPcfSize);
                float zRange = GetShadowRange(cascadeIndex);
            #else
                float zRange = GetShadowRange();
            #endif

            // float bias = sss * dither;

            vec2 sssOffset = hash22(vec2(dither, 0.0)) - 0.5;
            sssOffset *= sss * _pow2(dither) * MATERIAL_SSS_SCATTER;
            
            float bias = sss * _pow3(dither) * MATERIAL_SSS_MAXDIST / zRange;

            //sssOffset = (sssOffset);

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                // int cascadeIndex = GetShadowCascade(vIn.shadowPos, ShadowMaxPcfSize);

                if (cascadeIndex >= 0) {
                    vec3 _shadowPos = vIn.shadowPos[cascadeIndex];
                    _shadowPos.xy += rcp(shadowProjectionSize[cascadeIndex]) * sssOffset;

                    #ifdef SHADOW_COLORED
                        shadow = GetShadowColor(_shadowPos, cascadeIndex, bias);
                    #else
                        shadow = GetShadowFactor(_shadowPos, cascadeIndex, bias);
                    #endif
                }
            #else
                vec3 _shadowPos = vIn.shadowPos;
                _shadowPos.xy += rcp(shadowDistance) * sssOffset;

                float offsetBias = GetShadowOffsetBias(_shadowPos, geoNoL) + bias;

                #ifdef SHADOW_COLORED
                    shadow = GetShadowColor(_shadowPos, offsetBias);
                #else
                    shadow = GetShadowFactor(_shadowPos, offsetBias);
                #endif
            #endif
        #endif

        //shadow = 1.0 - (1.0 - shadow) * (1.0 - shadowFade);

        // #if defined RENDER_CLOUD_SHADOWS_ENABLED && !defined RENDER_CLOUDS
        //     // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        //     //     shadow *= TraceCloudShadow(cameraPosition + vLocalPos, skyLightDir, time, CLOUD_SHADOW_STEPS);
        //     #if SKY_CLOUD_TYPE == CLOUDS_VANILLA
        //         shadow *= SampleCloudShadow(skyLightDir, vIn.cloudPos);
        //     #endif
        // #endif

        return shadow;
    }
#endif
