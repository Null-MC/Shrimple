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
    #if DYN_LIGHT_RT_SHADOWS > 0 && defined RENDER_FRAG
        #define TRACE_MODE TraceRay // [TraceDDA TraceRay]

        vec3 TraceDDA(vec3 origin, const in vec3 endPos) {
            vec3 traceRay = endPos - origin;
            float traceRayLen = length(traceRay);
            if (traceRayLen < EPSILON) return vec3(1.0);

            vec3 direction = traceRay / traceRayLen;
            float STEP_COUNT = 12;//ceil(traceRayLen);

            origin += direction * 0.001;
            traceRayLen -= 0.001;

            vec3 stepSizes = 1.0 / abs(direction);
            vec3 stepDir = sign(direction);
            vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(origin)) / direction;

            float traceRayLen2 = pow2(traceRayLen);
            vec3 voxelPos = floor(origin);
            vec3 currPos = origin;

            bool hit = false;
            for (int i = 0; i < STEP_COUNT && !hit; i++) {
                float closestDist = minOf(nextDist);
                currPos += direction * closestDist;

                if (dot(currPos - origin, traceRay) >= traceRayLen2) break;

                vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));

                voxelPos += stepAxis * stepDir;
                nextDist -= closestDist;
                nextDist += stepSizes * stepAxis;
                
                ivec3 gridCell, blockCell;
                if (GetSceneLightGridCell(currPos, gridCell, blockCell)) {
                    uint gridIndex = GetSceneLightGridIndex(gridCell);
                    uint blockType = GetSceneBlockMask(blockCell, gridIndex);

                    if (blockType != BLOCKTYPE_EMPTY) {
                        vec3 blockPos = fract(currPos);
                        hit = TraceHitTest(blockPos, blockType);
                    }
                }
            }

            return vec3(hit ? 0.0 : 1.0);
        }

        vec3 TraceRay(const in vec3 origin, const in vec3 endPos, const in float range) {
            vec3 traceRay = endPos - origin;
            float traceRayLen = length(traceRay);
            if (traceRayLen < EPSILON) return vec3(1.0);

            int stepCount = int(DYN_LIGHT_RT_SHADOWS * range);
            float dither = InterleavedGradientNoise(gl_FragCoord.xy);
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

                        color *= RGBToLinear(stepTint);
                    }
                    else if (blockType != BLOCKTYPE_EMPTY) {
                        vec3 blockPos = fract(gridPos);
                        hit = TraceHitTest(blockPos, blockType);
                        if (hit) color = vec3(0.0);
                    }

                    blockTypeLast = blockType;
                }

                //lastGridPos = gridPos;
            }

            return color;
        }
    #endif

    vec3 SampleDynamicLighting(const in vec3 localPos, const in vec3 localNormal, const in int blockId, const in float blockLight) {
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

            #if defined RENDER_TERRAIN || defined RENDER_WATER
                //vec2 lightNoiseSample = GetDynLightNoise(localPos);
                //vec3 accumDiffuse = GetSceneBlockLightColor(blockId, lightNoiseSample);
                vec3 accumDiffuse = vec3(GetSceneBlockLightLevel(blockId) / 16.0);
            #else
                vec3 accumDiffuse = vec3(0.0);
            #endif

            #if DYN_LIGHT_RT_SHADOWS > 0 && defined RENDER_FRAG
                vec3 traceOffset = vec3(0.0);//fract(cameraPosition);
            #endif

            for (int i = 0; i < lightCount; i++) {
                SceneLightData light = GetSceneLight(gridIndex, i);

                vec3 lightVec = light.position - lightFragPos;
                if (dot(lightVec, lightVec) >= pow2(light.range)) continue;

                vec3 lightTint = vec3(1.0);
                #if DYN_LIGHT_RT_SHADOWS > 0 && defined RENDER_FRAG
                    //vec3 traceOrigin = light.position;// + traceOffset;
                    vec3 traceOrigin = GetLightGridPosition(light.position);

                    //vec3 traceEnd = lightFragPos;// + traceOffset;
                    vec3 traceEnd = GetLightGridPosition(lightFragPos);

                    lightTint = TRACE_MODE(traceOrigin, traceEnd, light.range);
                #endif

                accumDiffuse += SampleLight(lightFragPos, localNormal, light.position, light.range) * light.color.rgb * lightTint;
            }

            accumDiffuse *= blockLight * DynamicLightBrightness;

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
#endif

#if HAND_LIGHT_MODE != HAND_LIGHT_NONE
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
                #if DYN_LIGHT_RT_SHADOWS > 0 && defined RENDER_FRAG
                    //vec3 traceOrigin = light.position;// + traceOffset;
                    vec3 traceOrigin = GetLightGridPosition(lightLocalPos);

                    //vec3 traceEnd = lightFragPos;// + traceOffset;
                    vec3 traceEnd = GetLightGridPosition(fragLocalPos);

                    lightColor *= TRACE_MODE(traceOrigin, traceEnd, heldBlockLightValue);
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
                #if DYN_LIGHT_RT_SHADOWS > 0 && defined RENDER_FRAG
                    //vec3 traceOrigin = light.position;// + traceOffset;
                    vec3 traceOrigin = GetLightGridPosition(lightLocalPos);

                    //vec3 traceEnd = lightFragPos;// + traceOffset;
                    vec3 traceEnd = GetLightGridPosition(fragLocalPos);

                    lightColor *= TRACE_MODE(traceOrigin, traceEnd, heldBlockLightValue2);
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

        #if DYN_LIGHT_MODE != DYN_LIGHT_PIXEL
            int vBlockId;
        #endif

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

        #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX || HAND_LIGHT_MODE == HAND_LIGHT_VERTEX
            vBlockLight = vec3(0.0);

            #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX //&& (defined RENDER_TERRAIN || defined RENDER_WATER)
                vBlockLight += SampleDynamicLighting(localPos, localNormal, vBlockId, lmcoord.x)
                    * saturate((lmcoord.x - (0.5/16.0)) * (16.0/15.0));
            #endif

            #if HAND_LIGHT_MODE == HAND_LIGHT_VERTEX
                vBlockLight += SampleHandLight(localPos, localNormal);
            #endif
        #endif

        #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || HAND_LIGHT_MODE == HAND_LIGHT_PIXEL
            vLocalPos = localPos;
            vLocalNormal = localNormal;
        #endif

        gl_Position = gl_ProjectionMatrix * viewPos;
    }
#endif

#ifdef RENDER_FRAG
    #if (defined RENDER_GBUFFER && !defined SHADOW_BLUR) || defined RENDER_COMPOSITE
        float GetFogFactor(const in float dist, const in float start, const in float end, const in float density) {
            float distFactor = dist >= end ? 1.0 : smoothstep(start, end, dist);
            return saturate(pow(distFactor, density));
        }

        float GetVanillaFogFactor(const in vec3 localPos) {
            if (fogStart > far) return 0.0;

            vec3 fogPos = localPos;
            if (fogShape == 1)
                fogPos.y = 0.0;

            float viewDist = length(fogPos);

            return GetFogFactor(viewDist, fogStart, fogEnd, 1.0);
        }

        void ApplyFog(inout vec4 color, const in vec3 localPos) {
            float fogF = GetVanillaFogFactor(localPos);
            vec3 fogCol = RGBToLinear(fogColor);

            color.rgb = mix(color.rgb, fogCol, fogF);

            if (color.a > alphaTestRef)
                color.a = mix(color.a, 1.0, fogF);
        }
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

                return mix(shadowColor * max(vLit, 0.0), vec3(1.0), SHADOW_BRIGHTNESS);
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
        #ifdef TONEMAP_ENABLED
            vec3 tonemap_Tech(const in vec3 color) {
                const float c = rcp(TONEMAP_CONTRAST);
                vec3 a = color * min(vec3(1.0), 1.0 - exp(-c * color));
                a = mix(a, color, color * color);
                return a / (a + 0.6);
            }
        #endif

        vec4 GetFinalLighting(const in vec4 color, const in vec3 shadowColor, const in vec3 viewPos, const in vec2 lmcoord, const in float occlusion) {
            vec3 albedo = RGBToLinear(color.rgb);
            vec3 blockLight = vec3(0.0);

            #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX || HAND_LIGHT_MODE == HAND_LIGHT_VERTEX
                blockLight = vBlockLight;
            #endif

            #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX && defined IRIS_FEATURE_SSBO && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
                #if !defined SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                    if (gl_FragCoord.x < 0) return vec4(texelFetch(shadowcolor0, ivec2(0.0), 0).rgb, 1.0);
                #endif
            #elif DYN_LIGHT_MODE == DYN_LIGHT_PIXEL && defined IRIS_FEATURE_SSBO && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
                blockLight += SampleDynamicLighting(vLocalPos, vLocalNormal, vBlockId, lmcoord.x)
                    * saturate((lmcoord.x - (0.5/16.0)) * (16.0/15.0));

                #if !defined SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                    if (gl_FragCoord.x < 0) return vec4(texelFetch(shadowcolor0, ivec2(0.0), 0).rgb, 1.0);
                #endif
            #else
                #ifdef IRIS_FEATURE_CUSTOM_TEXTURE_NAME
                    vec3 blockLightDefault = textureLod(texLightMap, vec2(lmcoord.x, 1.0/32.0), 0).rgb;
                #elif defined RENDER_COMPOSITE //|| defined RENDER_CLOUDS
                    vec3 blockLightDefault = textureLod(colortex3, vec2(lmcoord.x, 1.0/32.0), 0).rgb;
                #else
                    vec3 blockLightDefault = textureLod(lightmap, vec2(lmcoord.x, 1.0/32.0), 0).rgb;
                #endif

                blockLight += RGBToLinear(blockLightDefault);
            #endif

            #if HAND_LIGHT_MODE == HAND_LIGHT_PIXEL
                blockLight += SampleHandLight(vLocalPos, vLocalNormal);
            #endif

            #ifdef IRIS_FEATURE_CUSTOM_TEXTURE_NAME
                vec3 skyLight = textureLod(texLightMap, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #elif defined RENDER_COMPOSITE //|| defined RENDER_CLOUDS
                vec3 skyLight = textureLod(colortex3, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #else
                vec3 skyLight = textureLod(lightmap, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #endif

            skyLight = RGBToLinear(skyLight);
            skyLight = skyLight * (1.0 - SHADOW_BRIGHTNESS) + (SHADOW_BRIGHTNESS);
            skyLight *= 1.0 - blindness;

            vec3 ambient = albedo.rgb * skyLight * occlusion;
            vec3 diffuse = albedo.rgb * (blockLight + skyLight * shadowColor * (1.0 - SHADOW_BRIGHTNESS));
            vec4 final = vec4(ambient + diffuse, color.a);

            ApplyFog(final, viewPos);

            #ifdef TONEMAP_ENABLED
                final.rgb = tonemap_Tech(final.rgb);
            #endif

            final.rgb = LinearToRGB(final.rgb);
            return final;
        }
    #endif
#endif
