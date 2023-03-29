#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    // float G(const in float NoV, const in float k) {
    //     return rcp(NoV * (1.0 - k) + k);
    // }

    // float GGX(vec3 N, vec3 V, vec3 L, float roughness, float F0) {
    //     vec3 H = normalize(V + L);
    //     float NoL = saturate(dot(N, L));
    //     float NoV = saturate(dot(N, V));
    //     float NoH = saturate(dot(N, H));
    //     float LoH = saturate(dot(L, H));

    //     float alpha = pow2(roughness);
    //     float a2 = pow2(alpha);
    //     float k = alpha * 0.5;

    //     float denom = pow2(NoH) * (a2 - 1.0) + 1.0;
    //     float D = a2 / (PI * denom * denom);

    //     float F = F0 + (1.0 - F0) * pow(1.0 - LoH, 5.0);

    //     return NoL * D * F * G(NoL, k) * G(NoV, k);
    // }

    float GetLightNoL(const in vec3 localNormal, const in vec3 texNormal, const in vec3 lightDir, const in float sss) {
        float NoL = 1.0;

        #if DYN_LIGHT_DIRECTIONAL > 0 || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            if (dot(localNormal, localNormal) > EPSILON)
                NoL = dot(localNormal, lightDir);

            if (dot(texNormal, texNormal) > EPSILON) {
                float texNoL = dot(texNormal, lightDir);
                NoL = min(NoL, texNoL);
            }
        #endif

        #if MATERIAL_SSS != SSS_NONE
            NoL = mix(max(NoL, 0.0), abs(NoL), sss);
        #else
            NoL = max(NoL, 0.0);
        #endif

        #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
            NoL = mix(1.0, NoL, DynamicLightDirectionalF);
        #endif

        return NoL;
    }

    float SampleLight(const in vec3 lightVec, const in float lightNoLm, const in float lightRange) {
        float lightDist = length(lightVec);
        //vec3 lightDir = lightVec / max(lightDist, EPSILON);
        //lightDist = max(lightDist - 0.5, 0.0);

        float lightAtt = 1.0 - saturate(lightDist / lightRange);
        lightAtt = pow(lightAtt, 5.0);
                
        return lightNoLm * lightAtt;
    }

    vec3 SampleDynamicLighting(const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in float sss, const in vec3 blockLightDefault) {
        uint gridIndex;
        vec3 lightFragPos = localPos + 0.06 * localNormal;
        int lightCount = GetSceneLights(lightFragPos, gridIndex);

        if (gridIndex != -1u) {
            #if defined RENDER_TEXTURED || defined RENDER_PARTICLES
                bool hasGeoNormal = false;
            #else
                bool hasGeoNormal = true;
            #endif

            vec3 accumDiffuse = vec3(0.0);

            for (int i = 0; i < lightCount; i++) {
                SceneLightData light = GetSceneLight(gridIndex, i);

                vec3 lightPos = light.position;
                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                    #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0 && !defined RENDER_TRANSLUCENT
                        float size = ((light.data >> 8u) & 31u) / 31.0;
                        size *= 0.5 * DynamicLightPenumbraF;
                        ApplyLightPenumbraOffset(lightPos, size);
                    #endif

                    vec3 lightVec = lightFragPos - lightPos;
                    uint traceFace = 1u << GetLightMaskFace(lightVec);
                    if ((light.data & traceFace) == traceFace) continue;
                    if (dot(lightVec, lightVec) >= pow2(light.range)) continue;
                #else
                    vec3 lightVec = lightFragPos - lightPos;
                #endif

                vec3 lightColor = light.color;
                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                    if ((light.data & 1u) == 1u) {
                        vec3 traceOrigin = GetLightGridPosition(lightPos);
                        vec3 traceEnd = traceOrigin + 0.99*lightVec;

                        #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                            lightColor *= TraceRay(traceOrigin, traceEnd, light.range);
                        #else
                            lightColor *= TraceDDA(traceEnd, traceOrigin, light.range);
                        #endif
                    }
                #endif

                vec3 lightDir = normalize(-lightVec);
                float lightNoLm = GetLightNoL(localNormal, texNormal, lightDir, sss);

                if (lightNoLm > EPSILON)
                    accumDiffuse += SampleLight(lightVec, lightNoLm, light.range) * lightColor;
            }

            accumDiffuse *= DynamicLightBrightness;

            // #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
            //     accumDiffuse *= blockLight;
            // #endif

            #ifdef DYN_LIGHT_FALLBACK
                // TODO: shrink to shadow bounds
                vec3 offsetPos = localPos + LightGridCenter;
                //vec3 maxSize = SceneLightSize
                float fade = minOf(min(offsetPos, SceneLightSize - offsetPos)) / 8.0;
                accumDiffuse = mix(blockLightDefault, accumDiffuse, saturate(fade));
            #endif

            return accumDiffuse;
        }
        else {
            #ifdef DYN_LIGHT_FALLBACK
                return blockLightDefault;
            #else
                return vec3(0.0);
            #endif
        }
    }

    vec3 SampleHandLight(const in vec3 fragLocalPos, const in vec3 fragLocalNormal, const in vec3 texNormal, const in float sss) {
        vec2 noiseSample = GetDynLightNoise(vec3(0.0));
        vec3 result = vec3(0.0);

        //if (heldItemId == 115) return vec3(1.0);

        vec3 lightFragPos = fragLocalPos + 0.06 * fragLocalNormal;

        if (heldBlockLightValue > 0) {
            vec3 lightLocalPos = (gbufferModelViewInverse * vec4(HandLightOffsetR, 1.0)).xyz;
            if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;

            vec3 lightVec = lightLocalPos - lightFragPos;
            if (dot(lightVec, lightVec) < pow2(heldBlockLightValue)) {
                vec3 lightColor = GetSceneItemLightColor(heldItemId, noiseSample);

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                    vec3 traceOrigin = GetLightGridPosition(lightLocalPos);
                    vec3 traceEnd = traceOrigin - 0.99*lightVec;

                    #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0
                        float lightSize = GetSceneItemLightSize(heldItemId);
                        ApplyLightPenumbraOffset(traceOrigin, lightSize * 0.5);
                    #endif

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightColor *= TraceRay(traceOrigin, traceEnd, heldBlockLightValue);
                    #else
                        lightColor *= TraceDDA(traceEnd, traceOrigin, heldBlockLightValue);
                    #endif
                #endif

                vec3 lightDir = normalize(lightVec);
                float lightNoLm = GetLightNoL(fragLocalNormal, texNormal, lightDir, sss);

                if (lightNoLm > EPSILON)
                    result += SampleLight(lightVec, lightNoLm, heldBlockLightValue) * lightColor;
            }
        }

        if (heldBlockLightValue2 > 0) {
            vec3 lightLocalPos = (gbufferModelViewInverse * vec4(HandLightOffsetL, 1.0)).xyz;
            if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;

            vec3 lightVec = lightLocalPos - lightFragPos;
            if (dot(lightVec, lightVec) < pow2(heldBlockLightValue2)) {
                vec3 lightColor = GetSceneItemLightColor(heldItemId2, noiseSample);

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                    vec3 traceOrigin = GetLightGridPosition(lightLocalPos);
                    vec3 traceEnd = traceOrigin - 0.99*lightVec;

                    #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0
                        float lightSize = GetSceneItemLightSize(heldItemId);
                        ApplyLightPenumbraOffset(traceOrigin, lightSize * 0.5);
                    #endif

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightColor *= TraceRay(traceOrigin, traceEnd, heldBlockLightValue2);
                    #else
                        lightColor *= TraceDDA(traceEnd, traceOrigin, heldBlockLightValue2);
                    #endif
                #endif
                
                vec3 lightDir = normalize(lightVec);
                float lightNoLm = GetLightNoL(fragLocalNormal, texNormal, lightDir, sss);

                if (lightNoLm > EPSILON)
                    result += SampleLight(lightVec, lightNoLm, heldBlockLightValue2) * lightColor;
            }
        }

        return result * DynamicLightBrightness;
    }
#endif

#ifdef RENDER_VERTEX
    #if defined RENDER_TERRAIN || defined RENDER_WATER
        bool IsFoliageBlock(const in int blockId) {
            bool result = false;

            switch (blockId) {
                case BLOCK_LEAVES:
                
                case BLOCK_ALLIUM:
                case BLOCK_AZURE_BLUET:
                case BLOCK_BEETROOTS:
                case BLOCK_BLUE_ORCHID:
                case BLOCK_CARROTS:
                case BLOCK_CAVE_VINE:
                case BLOCK_CAVEVINE_BERRIES:
                case BLOCK_CORNFLOWER:
                case BLOCK_DANDELION:
                case BLOCK_FERN:
                case BLOCK_GRASS:
                case BLOCK_KELP:
                case BLOCK_LARGE_FERN_LOWER:
                case BLOCK_LARGE_FERN_UPPER:
                case BLOCK_LILAC_LOWER:
                case BLOCK_LILAC_UPPER:
                case BLOCK_LILY_OF_THE_VALLEY:
                case BLOCK_OXEYE_DAISY:
                case BLOCK_PEONY_LOWER:
                case BLOCK_PEONY_UPPER:
                case BLOCK_POPPY:
                case BLOCK_POTATOES:
                case BLOCK_ROSE_BUSH_LOWER:
                case BLOCK_ROSE_BUSH_UPPER:
                case BLOCK_SAPLING:
                case BLOCK_SEAGRASS:
                case BLOCK_SUGAR_CANE:
                case BLOCK_SUNFLOWER_LOWER:
                case BLOCK_SUNFLOWER_UPPER:
                case BLOCK_SWEET_BERRY_BUSH:
                case BLOCK_TALL_GRASS_LOWER:
                case BLOCK_TALL_GRASS_UPPER:
                case BLOCK_TULIP:
                case BLOCK_WHEAT:
                case BLOCK_WITHER_ROSE:
                    result = true;
                    break;
            }

            return result;
        }
    #endif

    void BasicVertex() {
        vec4 pos = gl_Vertex;

        #if defined RENDER_TERRAIN || defined RENDER_WATER
            vBlockId = int(mc_Entity.x + 0.5);

            #ifdef ENABLE_WAVING
                ApplyWavingOffset(pos.xyz, vBlockId);
            #endif
        #endif

        vec4 viewPos = gl_ModelViewMatrix * pos;

        vPos = viewPos.xyz;

        #ifdef RENDER_BILLBOARD
            vec3 vNormal;
            vec3 vLocalNormal;
        #endif

        vNormal = normalize(gl_NormalMatrix * gl_Normal);
        vLocalNormal = mat3(gbufferModelViewInverse) * vNormal;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && !defined RENDER_BILLBOARD
            vec3 lightDir = normalize(shadowLightPosition);
            geoNoL = dot(lightDir, vNormal);

            vLit = geoNoL;

            #if defined RENDER_TERRAIN && defined FOLIAGE_UP
                if (IsFoliageBlock(vBlockId))
                    vLit = dot(lightDir, gbufferModelView[1].xyz);
            #endif
        #else
            geoNoL = 1.0;
            vLit = 1.0;
        #endif

        vLocalPos = (gbufferModelViewInverse * viewPos).xyz;
        vBlockLight = vec3(0.0);

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                shadowTile = -1;
            #endif

            ApplyShadows(vLocalPos, vLocalNormal, geoNoL);
        #endif

        #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED && !defined RENDER_CLOUDS
            vec3 blockLightDefault = textureLod(lightmap, vec2(lmcoord.x, (0.5/16.0)), 0).rgb;
            blockLightDefault = RGBToLinear(blockLightDefault);

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_VERTEX && !defined RENDER_BILLBOARD
                #if defined RENDER_TERRAIN || defined RENDER_WATER
                    float sss = GetBlockSSS(vBlockId);
                #else
                    const float sss = 0.0;
                #endif

                vBlockLight += SampleDynamicLighting(vLocalPos, vLocalNormal, vec3(0.0), sss, blockLightDefault)
                    * saturate((lmcoord.x - (0.5/16.0)) * (16.0/15.0));

                vBlockLight += SampleHandLight(vLocalPos, vLocalNormal, vec3(0.0), sss);
            #endif

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
                #ifdef RENDER_ENTITIES
                    vec4 light = GetSceneEntityLightColor(entityId);
                    vBlockLight += vec3(light.a / 15.0);
                #elif defined RENDER_HAND
                    // TODO: change ID depending on hand
                    float lightRange = GetSceneItemLightRange(heldItemId);
                    vBlockLight += vec3(lightRange / 15.0);
                #elif defined RENDER_TERRAIN || defined RENDER_WATER
                    float lightRange = GetSceneBlockEmission(vBlockId);
                    vBlockLight += vec3(lightRange);
                #endif
            #else
                vBlockLight += blockLightDefault;
            #endif
        #endif

        gl_Position = gl_ProjectionMatrix * viewPos;
    }
#endif

#ifdef RENDER_FRAG
    #if defined RENDER_GBUFFER && !defined RENDER_CLOUDS
        vec4 GetColor() {
            vec4 color = texture(gtexture, texcoord);

            #ifndef RENDER_TRANSLUCENT
                if (color.a < alphaTestRef) {
                    discard;
                    return vec4(0.0);
                }
            #endif

            color.rgb *= glcolor.rgb;

            return color;
        }
    #endif

    //#if defined RENDER_GBUFFER || defined RENDER_DEFERRED || defined RENDER_COMPOSITE
        vec3 GetFinalBlockLighting(const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in float lmcoordX, const in float emission, const in float sss) {
            vec3 blockLight = vec3(emission);//vBlockLight;

            #ifdef RENDER_GBUFFER
                vec3 blockLightDefault = textureLod(lightmap, vec2(lmcoordX, 1.0/32.0), 0).rgb;
            #else
                vec3 blockLightDefault = textureLod(TEX_LIGHTMAP, vec2(lmcoordX, 1.0/32.0), 0).rgb;
            #endif

            blockLightDefault = RGBToLinear(blockLightDefault);

            #if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED || (DYN_LIGHT_MODE == DYN_LIGHT_VERTEX && (defined RENDER_WEATHER || defined RENDER_DEFERRED))) && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
                blockLight += SampleDynamicLighting(localPos, localNormal, texNormal, sss, blockLightDefault);

                blockLight += SampleHandLight(localPos, localNormal, texNormal, sss);

                // #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
                //     lit *= saturate((lmcoordX - (0.5/16.0)) * (16.0/15.0));
                // #endif

                //blockLight += lit;
            #else
                blockLight += blockLightDefault;
            #endif

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && !(defined RENDER_CLOUDS || defined RENDER_DEFERRED)
                if (gl_FragCoord.x < 0) return texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
            #endif

            return blockLight;
        }

        vec3 GetFinalLighting(in vec3 albedo, const in vec3 blockLight, const in vec3 shadowColor, const in vec2 lmcoord, const in float occlusion) {
            // weather darkening
            

            #ifndef RENDER_CLOUDS
                #ifdef RENDER_GBUFFER
                    vec3 skyLight = textureLod(lightmap, vec2(1.0/32.0, lmcoord.y), 0).rgb;
                #else
                    vec3 skyLight = textureLod(TEX_LIGHTMAP, vec2(1.0/32.0, lmcoord.y), 0).rgb;
                #endif

                skyLight = RGBToLinear(skyLight) * GetWorldBrightnessF();

                //skyLight = skyLight * (1.0 - ShadowBrightnessF) + (ShadowBrightnessF);

                skyLight *= 1.0 - blindness;
            #else
                const float skyLight = 1.0;
            #endif

            vec3 ambientLight = skyLight;
            #if DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined RENDER_DEFERRED
                vec2 lmFinal = saturate((lmcoord - (0.5/16.0)) / (15.0/16.0));
                lmFinal.x *= 0.16;
                lmFinal = saturate(lmFinal * (15.0/16.0) + (0.5/16.0));

                ambientLight = textureLod(TEX_LIGHTMAP, lmFinal, 0).rgb;
                ambientLight = RGBToLinear(ambientLight);
            #endif

            float shadowingF = 1.0;
            #ifdef WORLD_SKY_ENABLED
                float shadowingF = 1.0 - (1.0 - 0.5 * rainStrength) * (1.0 - ShadowBrightnessF);
            #endif

            vec3 ambient = albedo * ambientLight * occlusion * shadowingF;
            vec3 diffuse = albedo * (blockLight + skyLight * shadowColor * (1.0 - shadowingF));
            return ambient + diffuse;
        }
    //#endif
#endif
