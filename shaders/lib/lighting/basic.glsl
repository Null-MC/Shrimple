#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    float SampleLight(const in vec3 lightVec, const in vec3 fragLocalNormal, const in float lightRange) {
        float lightDist = length(lightVec);
        vec3 lightDir = lightVec / max(lightDist, EPSILON);
        lightDist = max(lightDist - 0.5, 0.0);

        float lightAtt = 1.0 - saturate(lightDist / lightRange);
        lightAtt = pow(lightAtt, 5.0);
        
        float lightNoLm = 1.0;

        // WARN: This breaks on PhysicsMod snow cause geoNormal isn't smooth
        #ifdef DYN_LIGHT_DIRECTIONAL
            if (dot(fragLocalNormal, fragLocalNormal) > EPSILON)
                lightNoLm = max(dot(fragLocalNormal, lightDir), 0.0);
        #endif
        
        return lightNoLm * lightAtt;
    }

    vec3 SampleDynamicLighting(const in vec3 localPos, const in vec3 localNormal, const in vec3 blockLightDefault) {
        uint gridIndex;
        vec3 lightFragPos = localPos + 0.06 * localNormal;
        int lightCount = GetSceneLights(lightFragPos, gridIndex);

        //vec3 blockLightColor = vec3(1.0, 0.9, 0.8);

        if (gridIndex != -1u) {
            #if defined RENDER_TEXTURED || defined RENDER_PARTICLES
                bool hasGeoNormal = false;
            #else
                bool hasGeoNormal = true;
            #endif

            vec3 accumDiffuse = vec3(0.0);

            for (int i = 0; i < lightCount; i++) {
                SceneLightData light = GetSceneLight(gridIndex, i);

                // #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && DYN_LIGHT_TEMPORAL > 0 && defined RENDER_OPAQUE
                //     vec3 p = floor(cameraPosition + light.position);
                //     float alt = mod(p.x + p.y + p.z + frameCounter, DYN_LIGHT_TEMPORAL);
                //     if (alt > 0.5) continue;
                // #endif

                vec3 lightVec = light.position - lightFragPos;
                if (dot(lightVec, lightVec) >= pow2(light.range)) continue;

                vec3 lightTint = vec3(1.0);
                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                    vec3 traceOrigin = GetLightGridPosition(light.position);
                    //vec3 traceEnd = GetLightGridPosition(lightFragPos);
                    vec3 traceEnd = traceOrigin - 0.99*lightVec;

                    #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0
                        ApplyLightPenumbraOffset(traceOrigin);
                    #endif

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightTint = TraceRay(traceOrigin, traceEnd, light.range);
                    #else
                        lightTint = TraceDDA(traceEnd, traceOrigin, light.range);
                    #endif
                #endif

                accumDiffuse += SampleLight(lightVec, localNormal, light.range) * light.color.rgb * lightTint;
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

    vec3 SampleHandLight(const in vec3 fragLocalPos, const in vec3 fragLocalNormal) {
        vec2 noiseSample = vec2(1.0); // TODO!
        vec3 result = vec3(0.0);

        //if (heldItemId == 115) return vec3(1.0);

        if (heldBlockLightValue > 0) {
            vec3 lightLocalPos = (gbufferModelViewInverse * vec4(0.3, -0.3, 0.2, 1.0)).xyz;
            if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;

            vec3 lightColor = GetSceneBlockLightColor(heldItemId, noiseSample);

            vec3 lightVec = lightLocalPos - fragLocalPos;
            if (dot(lightVec, lightVec) < pow2(heldBlockLightValue)) {
                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                    vec3 traceOrigin = GetLightGridPosition(lightLocalPos);
                    //vec3 traceEnd = GetLightGridPosition(fragLocalPos);
                    vec3 traceEnd = traceOrigin - lightVec;

                    #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0
                        ApplyLightPenumbraOffset(traceOrigin);
                    #endif

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightColor *= TraceRay(traceOrigin, traceEnd, heldBlockLightValue);
                    #else
                        lightColor *= TraceDDA(traceOrigin, traceEnd, heldBlockLightValue);
                    #endif
                #endif

                result += SampleLight(lightVec, fragLocalNormal, heldBlockLightValue) * lightColor;
            }
        }

        if (heldBlockLightValue2 > 0) {
            vec3 lightLocalPos = (gbufferModelViewInverse * vec4(-0.3, -0.3, 0.2, 1.0)).xyz;
            if (!firstPersonCamera) lightLocalPos += eyePosition - cameraPosition;

            vec3 lightColor = GetSceneBlockLightColor(heldItemId2, noiseSample);

            vec3 lightVec = lightLocalPos - fragLocalPos;
            if (dot(lightVec, lightVec) < pow2(heldBlockLightValue2)) {
                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                    vec3 traceOrigin = GetLightGridPosition(lightLocalPos);
                    //vec3 traceEnd = GetLightGridPosition(fragLocalPos);
                    vec3 traceEnd = traceOrigin - lightVec;

                    #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0
                        ApplyLightPenumbraOffset(traceOrigin);
                    #endif

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightColor *= TraceRay(traceOrigin, traceEnd, heldBlockLightValue2);
                    #else
                        lightColor *= TraceDDA(traceOrigin, traceEnd, heldBlockLightValue2);
                    #endif
                #endif

                result += SampleLight(lightVec, fragLocalNormal, heldBlockLightValue2) * lightColor;
            }
        }

        return result;
    }
#endif

#ifdef RENDER_VERTEX
    void BasicVertex() {
        vec4 pos = gl_Vertex;

        #if defined RENDER_TERRAIN || defined RENDER_WATER
            vBlockId = int(mc_Entity.x + 0.5);

            #ifdef ENABLE_WAVING
                if (vBlockId >= 10001 && vBlockId <= 10004)
                    pos.xyz += GetWavingOffset();
            #endif
        #endif

        vec4 viewPos = gl_ModelViewMatrix * pos;

        vPos = viewPos.xyz;

        vNormal = normalize(gl_NormalMatrix * gl_Normal);

        //#if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
            #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                vec3 lightDir = normalize(shadowLightPosition);
                geoNoL = dot(lightDir, vNormal);

                #if defined RENDER_TEXTURED || defined RENDER_PARTICLES
                    vLit = 1.0;
                #else
                    vLit = geoNoL;

                    #if defined RENDER_TERRAIN && defined FOLIAGE_UP
                        if (vBlockId >= 10001 && vBlockId <= 10004)
                            vLit = dot(lightDir, gbufferModelView[1].xyz);
                    #endif
                #endif
            #else
                geoNoL = 1.0;
                vLit = 1.0;
            #endif

            #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                    shadowTile = -1;
                #endif

                float viewDist = 1.0 + length(viewPos.xyz);

                vec3 shadowViewPos = viewPos.xyz;

                shadowViewPos += vNormal * viewDist * ShadowNormalBias * max(1.0 - geoNoL, 0.0);

                vec3 shadowLocalPos = (gbufferModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;

                ApplyShadows(shadowLocalPos);
            #endif
        //#endif

        vLocalPos = (gbufferModelViewInverse * viewPos).xyz;
        vLocalNormal = mat3(gbufferModelViewInverse) * vNormal;

        vBlockLight = vec3(0.0);

        #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            //lmcoord.x = (0.5/16.0);

            // #ifdef RENDER_ENTITIES
            //     vec4 light = GetSceneEntityLightColor(entityId);
            //     //vBlockLight += light.rgb * (light.a / 15.0);
            //     lmcoord.x = (light.a / 15.0) * (15.0/16.0) + (0.5/16.0);
            // #elif defined RENDER_TERRAIN || defined RENDER_WATER
            //     //vec3 lightColor = GetSceneBlockLightColor(vBlockId, vec2(1.0));
            //     float lightRange = GetSceneBlockLightLevel(vBlockId);
            //     lmcoord.x = (lightRange / 15.0) * (15.0/16.0) + (0.5/16.0);
            // #endif
        #else
            vec3 blockLightDefault = textureLod(lightmap, vec2(lmcoord.x, (0.5/16.0)), 0).rgb;
            blockLightDefault += RGBToLinear(blockLightDefault);

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
                vBlockLight += SampleDynamicLighting(vLocalPos, vLocalNormal, blockLightDefault)
                    * saturate((lmcoord.x - (0.5/16.0)) * (16.0/15.0));

                vBlockLight += SampleHandLight(vLocalPos, vLocalNormal);
            #endif

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
                #ifdef RENDER_ENTITIES
                    vec4 light = GetSceneEntityLightColor(entityId);
                    //vBlockLight += light.rgb * (light.a / 15.0);
                    vBlockLight += vec3(light.a / 15.0);
                #elif defined RENDER_TERRAIN || defined RENDER_WATER
                    vec3 lightColor = GetSceneBlockLightColor(vBlockId, vec2(1.0));
                    float lightRange = GetSceneBlockLightLevel(vBlockId);
                    //vBlockLight += lightColor * (lightRange / 15.0);
                    vBlockLight += vec3(lightRange / 15.0);
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
            #if AF_SAMPLES > 1 && defined IRIS_ANISOTROPIC_FILTERING_ENABLED
                vec4 color = textureAnisotropic(gtexture, texcoord);
            #else
                vec4 color = texture(gtexture, texcoord);
            #endif

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

    #if (defined RENDER_GBUFFER && !defined SHADOW_BLUR) || defined RENDER_DEFERRED || defined RENDER_COMPOSITE
        vec3 GetFinalBlockLighting(const in vec3 localPos, const in vec3 localNormal, const in float lmcoordX) {
            vec3 blockLight = vec3(0.0);//vBlockLight;

            #ifdef RENDER_GBUFFER
                vec3 blockLightDefault = textureLod(lightmap, vec2(lmcoordX, 1.0/32.0), 0).rgb;
            #else
                vec3 blockLightDefault = textureLod(TEX_LIGHTMAP, vec2(lmcoordX, 1.0/32.0), 0).rgb;
            #endif

            blockLightDefault = RGBToLinear(blockLightDefault);

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_VERTEX && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
                #if !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && DYN_LIGHT_MODE != DYN_LIGHT_NONE
                    if (gl_FragCoord.x < 0) return texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
                #endif
            #elif defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED) && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
                vec3 lit = SampleDynamicLighting(localPos, localNormal, blockLightDefault);

                #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
                    lit *= saturate((lmcoordX - (0.5/16.0)) * (16.0/15.0));
                #endif

                blockLight += lit;

                #if !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && DYN_LIGHT_MODE != DYN_LIGHT_NONE
                    if (gl_FragCoord.x < 0) return texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
                #endif
            #else
                blockLight += blockLightDefault;
            #endif

            return blockLight;
        }

        vec3 GetFinalLighting(const in vec3 albedo, const in vec3 blockLightColor, const in vec3 shadowColor, const in vec3 viewPos, const in vec2 lmcoord, const in float occlusion) {
            vec3 blockLight = blockLightColor;

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
                blockLight += SampleHandLight(vLocalPos, vLocalNormal);
            #endif

            #ifdef RENDER_GBUFFER
                vec3 skyLight = textureLod(lightmap, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #else
                vec3 skyLight = textureLod(TEX_LIGHTMAP, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #endif

            skyLight = RGBToLinear(skyLight) * WorldBrightnessF;
            //skyLight = skyLight * (1.0 - ShadowBrightnessF) + (ShadowBrightnessF);
            skyLight *= 1.0 - blindness;

            vec3 ambient = albedo * skyLight * occlusion * ShadowBrightnessF;
            vec3 diffuse = albedo * (blockLight + skyLight * shadowColor * (1.0 - ShadowBrightnessF));
            return ambient + diffuse;
        }
    #endif
#endif
