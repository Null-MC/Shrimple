#ifdef SHADOW_CLOUD_ENABLED
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

            float cloudSample = textureLod(shadowcolor1, cloudShadowPos.xy + offset, 0).a;
            cloudF += cloudSample * step(0.0, cloudShadowPos.z);
        }

        cloudF *= rcp(SHADOW_PCF_SAMPLES);

        float skyLightF = smoothstep(0.1, 0.3, skyLightDir.y);

        return 1.0 - (1.0 - ShadowCloudBrightnessF) * min(cloudF, 1.0) * skyLightF;
    }
#endif

#ifdef RENDER_FRAG
    #ifdef SHADOW_COLORED
        vec3 GetFinalShadowColor(const in vec3 skyLightDir, const in float sss) {
            vec3 shadowColor = vec3(1.0);

            #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                float dither = InterleavedGradientNoise(gl_FragCoord.xy);

                float bias = dither * sss;

                #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                    int tile = GetShadowCascade(shadowPos, ShadowMaxPcfSize);

                    if (tile >= 0) {
                        bias *= MATERIAL_SSS_MAXDIST / (3.0 * far);
                        shadowColor = GetShadowColor(shadowPos[tile], tile, bias);
                    }
                #else
                    bias *= MATERIAL_SSS_MAXDIST / (2.0 * far);
                    shadowColor = GetShadowColor(shadowPos, bias);
                #endif
            #endif

            #ifdef SHADOW_CLOUD_ENABLED
                shadowColor *= SampleCloudShadow(skyLightDir, cloudPos);
            #endif

            return shadowColor;
        }
    #else
        float GetFinalShadowFactor(const in vec3 skyLightDir, const in float sss) {
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);

            float bias = dither * sss;
            float shadow = 1.0;

            #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                    int tile = GetShadowCascade(shadowPos, ShadowMaxPcfSize);

                    if (tile >= 0) {
                        bias *= MATERIAL_SSS_MAXDIST / (3.0 * far);
                        shadow = GetShadowFactor(shadowPos[tile], tile, bias);
                    }
                #else
                    bias *= MATERIAL_SSS_MAXDIST / (2.0 * far);
                    shadow = GetShadowFactor(shadowPos, bias);
                #endif
            #endif

            #ifdef SHADOW_CLOUD_ENABLED
                shadow *= SampleCloudShadow(skyLightDir, cloudPos);
            #endif

            return shadow;
        }
    #endif
#endif
