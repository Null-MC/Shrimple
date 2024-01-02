#if defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE == CLOUDS_VANILLA
    float SampleCloudShadow(const in vec3 skyLightDir, const in vec3 cloudShadowPos) {
        #ifdef RENDER_FRAG
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);
        #else
            float dither = 0.0;
        #endif

        float angle = fract(dither) * TAU;
        float s = sin(angle), c = cos(angle);
        mat2 rotation = mat2(c, -s, s, c);

        float cloudF = 0.0;
        for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
            vec2 offset = (rotation * pcfDiskOffset[i]) * rcp(1024.0 * SHADOW_CLOUD_RADIUS);

            float cloudSample = textureLod(TEX_CLOUDS, cloudShadowPos.xy + offset, 0).a;
            cloudF += cloudSample * step(0.0, cloudShadowPos.z);
        }

        cloudF *= rcp(SHADOW_PCF_SAMPLES);

        float skyLightF = smoothstep(0.1, 0.3, skyLightDir.y);

        return 1.0 - (1.0 - ShadowCloudBrightnessF) * min(cloudF, 1.0) * skyLightF;
    }
#endif

#ifdef RENDER_FRAG
    #ifdef SHADOW_COLORED
        vec3 GetFinalShadowColor(const in vec3 skyLightDir, const in float shadowFade, const in float sss) {
            vec3 shadow = vec3(1.0);
    #else
        float GetFinalShadowFactor(const in vec3 skyLightDir, const in float shadowFade, const in float sss) {
            float shadow = 1.0;
    #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #ifdef EFFECT_TAA_ENABLED
                float dither = InterleavedGradientNoiseTime();
            #else
                float dither = InterleavedGradientNoise();
            #endif

            // float bias = sss * dither;

            vec2 sssOffset = hash22(vec2(dither, 0.0)) - 0.5;
            sssOffset *= sss * _pow2(dither) * MATERIAL_SSS_SCATTER;
            
            float bias = sss * _pow3(dither) * MATERIAL_SSS_MAXDIST / (3.0 * far);

            //sssOffset = (sssOffset);

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int tile = GetShadowCascade(vIn.shadowPos, ShadowMaxPcfSize);

                if (tile >= 0) {
                    vec3 _shadowPos = vIn.shadowPos[tile];
                    _shadowPos.xy += 0.002 * sssOffset;

                    #ifdef SHADOW_COLORED
                        shadow = GetShadowColor(_shadowPos, tile, bias);
                    #else
                        shadow = GetShadowFactor(_shadowPos, tile, bias);
                    #endif
                }
            #else
                vec3 _shadowPos = vIn.shadowPos;
                _shadowPos.xy += (shadowDistance / shadowMapResolution) * sssOffset;
                //_shadowPos.z -= bias;

                // _shadowPos = distort(_shadowPos) * 0.5 + 0.5;

                #ifdef SHADOW_COLORED
                    shadow = GetShadowColor(_shadowPos, bias);
                #else
                    shadow = GetShadowFactor(_shadowPos, bias);
                #endif
            #endif
        #endif

        shadow = 1.0 - (1.0 - shadow) * (1.0 - shadowFade);

        #if defined RENDER_CLOUD_SHADOWS_ENABLED && !defined RENDER_CLOUDS
            // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            //     shadow *= TraceCloudShadow(cameraPosition + vLocalPos, skyLightDir, CLOUD_SHADOW_STEPS);
            #if SKY_CLOUD_TYPE == CLOUDS_VANILLA
                shadow *= SampleCloudShadow(skyLightDir, vIn.cloudPos);
            #endif
        #endif

        return shadow;
    }
#endif
