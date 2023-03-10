float SampleLight(const in vec3 fragLocalPos, const in vec3 fragLocalNormal, const in vec3 lightPos, const in float lightRange) {
    vec3 lightVec = lightPos - fragLocalPos;

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

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
        vec3 GetLightGlassTint(const in uint blockType) {
            vec3 stepTint = vec3(1.0);

            switch (blockType) {
                case BLOCKTYPE_STAINED_GLASS_BLACK:
                    stepTint = vec3(0.1, 0.1, 0.1);
                    break;
                case BLOCKTYPE_STAINED_GLASS_BLUE:
                    stepTint = vec3(0.1, 0.1, 0.98);
                    break;
                case BLOCKTYPE_STAINED_GLASS_BROWN:
                    stepTint = vec3(0.566, 0.388, 0.148);
                    break;
                case BLOCKTYPE_STAINED_GLASS_CYAN:
                    stepTint = vec3(0.082, 0.533, 0.763);
                    break;
                case BLOCKTYPE_STAINED_GLASS_GRAY:
                    stepTint = vec3(0.4, 0.4, 0.4);
                    break;
                case BLOCKTYPE_STAINED_GLASS_GREEN:
                    stepTint = vec3(0.125, 0.808, 0.081);
                    break;
                case BLOCKTYPE_STAINED_GLASS_LIGHT_BLUE:
                    stepTint = vec3(0.320, 0.685, 0.955);
                    break;
                case BLOCKTYPE_STAINED_GLASS_LIGHT_GRAY:
                    stepTint = vec3(0.7, 0.7, 0.7);
                    break;
                case BLOCKTYPE_STAINED_GLASS_LIME:
                    stepTint = vec3(0.633, 0.924, 0.124);
                    break;
                case BLOCKTYPE_STAINED_GLASS_MAGENTA:
                    stepTint = vec3(0.698, 0.298, 0.847);
                    break;
                case BLOCKTYPE_STAINED_GLASS_ORANGE:
                    stepTint = vec3(0.934, 0.518, 0.163);
                    break;
                case BLOCKTYPE_STAINED_GLASS_PINK:
                    stepTint = vec3(0.949, 0.274, 0.497);
                    break;
                case BLOCKTYPE_STAINED_GLASS_PURPLE:
                    stepTint = vec3(0.578, 0.170, 0.904);
                    break;
                case BLOCKTYPE_STAINED_GLASS_RED:
                    stepTint = vec3(0.98, 0.1, 0.1);
                    break;
                case BLOCKTYPE_STAINED_GLASS_WHITE:
                    stepTint = vec3(0.96, 0.96, 0.96);
                    break;
                case BLOCKTYPE_STAINED_GLASS_YELLOW:
                    stepTint = vec3(0.965, 0.965, 0.123);
                    break;
            }

            return RGBToLinear(stepTint);
        }

        vec3 TraceDDA(vec3 origin, const in vec3 endPos, const in float range) {
            vec3 traceRay = endPos - origin;
            float traceRayLen = length(traceRay);
            if (traceRayLen < EPSILON) return vec3(1.0);

            vec3 direction = traceRay / traceRayLen;
            float STEP_COUNT = 16;//ceil(traceRayLen);

            vec3 stepSizes = 1.0 / abs(direction);
            vec3 stepDir = sign(direction);
            vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction;

            float traceRayLen2 = pow2(traceRayLen);
            vec3 currPos = origin;

            uint blockTypeLast = BLOCKTYPE_EMPTY;
            vec3 color = vec3(1.0);
            bool hit = false;

            for (int i = 0; i < STEP_COUNT && !hit; i++) {
                vec3 rayStart = currPos;

                float closestDist = minOf(nextDist);
                currPos += direction * closestDist;
                if (dot(currPos - origin, traceRay) > traceRayLen2) break;

                vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));

                nextDist -= closestDist;
                nextDist += stepSizes * stepAxis;
                
                vec3 voxelPos = floor(0.5 * (currPos + rayStart));

                ivec3 gridCell, blockCell;
                if (GetSceneLightGridCell(voxelPos, gridCell, blockCell)) {
                    uint gridIndex = GetSceneLightGridIndex(gridCell);
                    uint blockType = GetSceneBlockMask(blockCell, gridIndex);

                    if (blockType >= BLOCKTYPE_STAINED_GLASS_BLACK && blockType <= BLOCKTYPE_STAINED_GLASS_YELLOW && blockType != blockTypeLast) {
                        color *= GetLightGlassTint(blockType);
                    }
                    else if (blockType != BLOCKTYPE_EMPTY) {
                        vec3 rayInv = rcp(currPos - rayStart);
                        hit = TraceHitTest(blockType, rayStart - voxelPos, rayInv);
                        if (hit) color = vec3(0.0);
                    }

                    blockTypeLast = blockType;
                }
            }

            return color;
        }

        vec3 TraceRay(const in vec3 origin, const in vec3 endPos, const in float range) {
            vec3 traceRay = endPos - origin;
            float traceRayLen = length(traceRay);
            if (traceRayLen < EPSILON) return vec3(1.0);

            int stepCount = int(0.5 * DYN_LIGHT_RAY_QUALITY * range);
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);// + frameCounter);
            vec3 stepSize = traceRay / stepCount;
            vec3 color = vec3(1.0);
            bool hit = false;
            
            //vec3 lastGridPos = origin;
            uint blockTypeLast;
            for (int i = 1; i < stepCount && !hit; i++) {
                vec3 gridPos = (i + dither) * stepSize + origin;
                
                ivec3 gridCell, blockCell;
                if (GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
                    uint gridIndex = GetSceneLightGridIndex(gridCell);
                    uint blockType = GetSceneBlockMask(blockCell, gridIndex);

                    if (blockType >= BLOCKTYPE_STAINED_GLASS_BLACK && blockType <= BLOCKTYPE_STAINED_GLASS_YELLOW && blockType != blockTypeLast) {
                        color *= GetLightGlassTint(blockType);
                    }
                    else if (blockType != BLOCKTYPE_EMPTY) {
                        vec3 blockPos = fract(gridPos);
                        hit = TraceHitTest(blockType, blockPos, vec3(0.0));
                        if (hit) color = vec3(0.0);
                    }

                    blockTypeLast = blockType;
                }

                //lastGridPos = gridPos;
            }

            return color;
        }
    #endif

    vec3 SampleDynamicLighting(const in vec3 localPos, const in vec3 localNormal, const in float blockLight) {
        uint gridIndex;
        vec3 lightFragPos = localPos + 0.01 * localNormal;
        int lightCount = GetSceneLights(lightFragPos, gridIndex);

        vec3 blockLightColor = vec3(1.0, 0.9, 0.8);

        if (gridIndex != -1u) {
            #ifdef RENDER_TEXTURED
                bool hasGeoNormal = false;
            #else
                bool hasGeoNormal = true;
            #endif

            vec3 accumDiffuse = vec3(0.0);

            for (int i = 0; i < lightCount; i++) {
                SceneLightData light = GetSceneLight(gridIndex, i);

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && DYN_LIGHT_TEMPORAL > 0 && defined RENDER_OPAQUE
                    vec3 p = floor(cameraPosition + light.position);
                    float alt = mod(p.x + p.y + p.z + frameCounter, DYN_LIGHT_TEMPORAL);
                    if (alt > 0.5) continue;
                #endif

                vec3 lightVec = light.position - lightFragPos;
                if (dot(lightVec, lightVec) >= pow2(light.range)) continue;

                vec3 lightTint = vec3(1.0);
                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                    vec3 traceOrigin = GetLightGridPosition(light.position);
                    vec3 traceEnd = GetLightGridPosition(lightFragPos);

                    #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0
                        vec3 offset = hash32(gl_FragCoord.xy + 0.001*frameCounter)*2.0 - 1.0;
                        traceOrigin += DynamicLightPenumbra * offset;
                    #endif

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightTint = TraceRay(traceOrigin, traceEnd, light.range);
                    #else
                        lightTint = TraceDDA(traceEnd, traceOrigin, light.range);
                    #endif
                #endif

                accumDiffuse += SampleLight(lightFragPos, localNormal, light.position, light.range) * light.color.rgb * lightTint;
            }

            accumDiffuse *= DynamicLightBrightness;

            #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
                accumDiffuse *= blockLight;
            #endif

            #ifdef DYN_LIGHT_FALLBACK
                // TODO: shrink to shadow bounds
                vec3 offsetPos = localPos + LightGridCenter;
                //vec3 maxSize = SceneLightSize
                float fade = minOf(min(offsetPos, SceneLightSize - offsetPos)) / 15.0;
                accumDiffuse = mix(pow(blockLight, 4.0) * blockLightColor, accumDiffuse, saturate(fade));
            #endif

            return accumDiffuse;
        }
        else {
            #ifdef DYN_LIGHT_FALLBACK
                return pow(blockLight, 4.0) * blockLightColor;
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
                    vec3 traceEnd = GetLightGridPosition(fragLocalPos);

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightColor *= TraceRay(traceOrigin, traceEnd, heldBlockLightValue);
                    #else
                        lightColor *= TraceDDA(traceOrigin, traceEnd, heldBlockLightValue);
                    #endif
                #endif

                result += SampleLight(fragLocalPos, fragLocalNormal, lightLocalPos, heldBlockLightValue) * lightColor;
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
                    vec3 traceEnd = GetLightGridPosition(fragLocalPos);

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                        lightColor *= TraceRay(traceOrigin, traceEnd, heldBlockLightValue2);
                    #else
                        lightColor *= TraceDDA(traceOrigin, traceEnd, heldBlockLightValue2);
                    #endif
                #endif

                result += SampleLight(fragLocalPos, fragLocalNormal, lightLocalPos, heldBlockLightValue2) * lightColor;
            }
        }

        return result;
    }
#endif

#ifdef RENDER_VERTEX
    void BasicVertex() {
        vec4 pos = gl_Vertex;

        #if defined RENDER_TERRAIN || defined RENDER_WATER
            #if !(DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED)
                int vBlockId;
            #endif

            vBlockId = int(mc_Entity.x + 0.5);

            #ifdef ENABLE_WAVING
                if (vBlockId >= 10001 && vBlockId <= 10004)
                    pos.xyz += GetWavingOffset();
            #endif
        #endif

        vec4 viewPos = gl_ModelViewMatrix * pos;

        vPos = viewPos.xyz;

        vNormal = normalize(gl_NormalMatrix * gl_Normal);

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            vec3 lightDir = normalize(shadowLightPosition);
            geoNoL = dot(lightDir, vNormal);

            #ifdef RENDER_TEXTURED
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

        vec3 localPos = (gbufferModelViewInverse * viewPos).xyz;
        vec3 localNormal = mat3(gbufferModelViewInverse) * vNormal;

        vBlockLight = vec3(0.0);

        #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
            vBlockLight += SampleDynamicLighting(localPos, localNormal, lmcoord.x)
                * saturate((lmcoord.x - (0.5/16.0)) * (16.0/15.0));

            vBlockLight += SampleHandLight(localPos, localNormal);
        #endif

        #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
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
        #endif

        #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            vLocalPos = localPos;
            vLocalNormal = localNormal;
        #endif

        gl_Position = gl_ProjectionMatrix * viewPos;
    }
#endif

#ifdef RENDER_FRAG
    #if (defined RENDER_GBUFFER && !defined SHADOW_BLUR) || defined RENDER_COMPOSITE
        // float GetFogFactor(const in float dist, const in float start, const in float end, const in float density) {
        //     float distFactor = dist >= end ? 1.0 : smoothstep(start, end, dist);
        //     return saturate(pow(distFactor, density));
        // }

        // float GetVanillaFogFactor(const in vec3 localPos) {
        //     if (fogStart > far) return 0.0;

        //     vec3 fogPos = localPos;
        //     if (fogShape == 1)
        //         fogPos.y = 0.0;

        //     float viewDist = length(fogPos);

        //     return GetFogFactor(viewDist, fogStart, fogEnd, 1.0);
        // }

        // void ApplyFog(inout vec4 color, const in vec3 localPos) {
        //     float fogF = GetVanillaFogFactor(localPos);
        //     color.rgb = mix(color.rgb, skyColor, fogF);

        //     if (color.a > alphaTestRef)
        //         color.a = mix(color.a, 1.0, fogF);
        // }
    #endif

    #if defined RENDER_GBUFFER && !defined RENDER_CLOUDS
        vec4 GetColor() {
            #if AF_SAMPLES > 1 && defined IRIS_ANISOTROPIC_FILTERING_ENABLED
                vec4 color = textureAnisotropic(gtexture, texcoord);
            #else
                vec4 color = texture(gtexture, texcoord);
            #endif

            #if !defined RENDER_WATER && !defined RENDER_HAND_WATER
                if (color.a < alphaTestRef) {
                    discard;
                    return vec4(0.0);
                }
            #endif

            color.rgb *= glcolor.rgb;

            return color;
        }

        #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
            vec3 GetFinalShadowColor() {
                vec3 shadowColor = vec3(1.0);

                #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                        int tile = GetShadowCascade(shadowPos, ShadowPCFSize);

                        if (tile >= 0)
                            shadowColor = GetShadowColor(shadowPos[tile], tile);
                    #else
                        shadowColor = GetShadowColor(shadowPos);
                    #endif
                #endif

                return mix(shadowColor * max(vLit, 0.0), vec3(1.0), ShadowBrightnessF);
            }
        #else
            float GetFinalShadowFactor() {
                float shadow = 1.0;

                #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                        int tile = GetShadowCascade(shadowPos, ShadowPCFSize);

                        if (tile >= 0)
                            shadow = GetShadowFactor(shadowPos[tile], tile);
                    #else
                        shadow = GetShadowFactor(shadowPos);
                    #endif
                #endif

                return shadow * max(vLit, 0.0);
            }
        #endif
    #endif

    #if (defined RENDER_GBUFFER && !defined SHADOW_BLUR) || defined RENDER_COMPOSITE
        vec3 GetFinalBlockLighting(const in float lmcoordX) {
            vec3 blockLight = vBlockLight;

            #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX && defined IRIS_FEATURE_SSBO && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
                #if !defined SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                    if (gl_FragCoord.x < 0) return texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
                #endif
            #elif defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED) && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
                vec3 lit = SampleDynamicLighting(vLocalPos, vLocalNormal, lmcoordX);

                #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
                    lit *= saturate((lmcoordX - (0.5/16.0)) * (16.0/15.0));
                #endif

                blockLight += lit;

                #if !defined SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                    if (gl_FragCoord.x < 0) return texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
                #endif
            #else
                #ifdef IRIS_FEATURE_CUSTOM_TEXTURE_NAME
                    vec3 blockLightDefault = textureLod(texLightMap, vec2(lmcoordX, 1.0/32.0), 0).rgb;
                #elif defined RENDER_COMPOSITE //|| defined RENDER_CLOUDS
                    vec3 blockLightDefault = textureLod(colortex3, vec2(lmcoordX, 1.0/32.0), 0).rgb;
                #else
                    vec3 blockLightDefault = textureLod(lightmap, vec2(lmcoordX, 1.0/32.0), 0).rgb;
                #endif

                blockLight += RGBToLinear(blockLightDefault);
            #endif

            return blockLight;
        }

        vec4 GetFinalLighting(const in vec4 color, const in vec3 blockLightColor, const in vec3 shadowColor, const in vec3 viewPos, const in vec2 lmcoord, const in float occlusion) {
            vec3 albedo = RGBToLinear(color.rgb);

            vec3 blockLight = blockLightColor;

            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && DYN_LIGHT_TEMPORAL > 0 && defined RENDER_OPAQUE
                vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;

                #if DYN_LIGHT_TEMPORAL > 2
                    float depthLinear = linearizeDepthFast(gl_FragCoord.z, near, far);

                    for (int i = 0; i < 4; i++) {
                        vec2 offset;
                        offset.x = mod(i, 2);
                        offset.y = floor(i / 2.0);

                        vec3 viewPosPrev = (gbufferLightModelView[i] * vec4(worldPos - lightCameraPosition[i], 1.0)).xyz;
                        vec3 clipPosPrev = unproject(gbufferLightProjection[i] * vec4(viewPosPrev, 1.0)) * 0.5 + 0.5;

                        if (all(greaterThan(clipPosPrev.xy, vec2(0.0))) && all(lessThan(clipPosPrev.xy, vec2(1.0)))) {
                            vec2 uv = (clipPosPrev.xy + offset) * 0.5;
                            vec4 lightSample = textureLod(BUFFER_BLOCKLIGHT_PREV, uv, 0);

                            float weight = abs(depthLinear - lightSample.a);
                            weight = saturate(1.0 - 0.5*weight);

                            blockLight += weight * lightSample.rgb;
                        }
                    }
                #else
                    vec3 viewPosPrev = (gbufferPreviousModelView * vec4(worldPos - previousCameraPosition, 1.0)).xyz;
                    vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));

                    ivec2 uv = ivec2((clipPosPrev.xy * 0.5 + 0.5) * vec2(viewWidth, viewHeight));
                    blockLight += texelFetch(BUFFER_BLOCKLIGHT_PREV, uv, 0).rgb;
                #endif
            #endif

            #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                blockLight += SampleHandLight(vLocalPos, vLocalNormal);
            #endif

            #ifdef IRIS_FEATURE_CUSTOM_TEXTURE_NAME
                vec3 skyLight = textureLod(texLightMap, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #elif defined RENDER_COMPOSITE //|| defined RENDER_CLOUDS
                vec3 skyLight = textureLod(colortex3, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #else
                vec3 skyLight = textureLod(lightmap, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #endif

            skyLight = RGBToLinear(skyLight) * WorldBrightnessF;
            //skyLight = skyLight * (1.0 - ShadowBrightnessF) + (ShadowBrightnessF);
            skyLight *= 1.0 - blindness;

            vec3 ambient = albedo.rgb * skyLight * occlusion * ShadowBrightnessF;
            vec3 diffuse = albedo.rgb * (blockLight + skyLight * shadowColor * (1.0 - ShadowBrightnessF));
            vec4 final = vec4(ambient + diffuse, color.a);

            vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
            ApplyFog(final, localPos);

            #ifdef TONEMAP_ENABLED
                final.rgb = tonemap_Tech(final.rgb);
            #endif

            final.rgb = LinearToRGB(final.rgb);
            return final;
        }
    #endif
#endif
