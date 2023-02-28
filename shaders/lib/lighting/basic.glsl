#ifdef RENDER_VERTEX
    void BasicVertex() {
        vec4 pos = gl_Vertex;

        #if defined RENDER_TERRAIN || defined RENDER_WATER
            int blockId = int(mc_Entity.x + 0.5);

            #ifdef ENABLE_WAVING
                if (blockId >= 10001 && blockId <= 10004)
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
                    if (blockId >= 10001 && blockId <= 10004)
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
            shadowViewPos += vNormal * viewDist * SHADOW_NORMAL_BIAS * max(1.0 - geoNoL, 0.0);

            vec3 shadowLocalPos = (gbufferModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;

            ApplyShadows(shadowLocalPos);
        #endif

        #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX && !defined RENDER_COMPOSITE
            vec3 localPos = (gbufferModelViewInverse * viewPos).xyz;
            vec3 localNormal = mat3(gbufferModelViewInverse) * vNormal;
            float blockLight = lmcoord.x;

            vec3 blockLightColor = vec3(1.0, 0.9, 0.8);

            uint gridIndex;
            vec3 lightFragPos = localPos + 0.01 * vNormal;
            int lightCount = GetSceneLights(lightFragPos, gridIndex);

            if (gridIndex != -1u) {
                bool hasGeoNormal = true;//any(greaterThan(abs(vNormal), EPSILON3));
                bool hasTexNormal = false;//any(greaterThan(abs(localNormal), EPSILON3));

                #if defined RENDER_TERRAIN || defined RENDER_WATER
                    vec3 accumDiffuse = GetSceneBlockLightColor(blockId);
                #else
                    vec3 accumDiffuse = vec3(0.0);
                #endif

                for (int i = 0; i < lightCount; i++) {
                    SceneLightData light = GetSceneLight(gridIndex, i);
                    vec3 lightVec = light.position - lightFragPos;
                    if (dot(lightVec, lightVec) >= pow2(light.range)) continue;

                    float lightDist = length(lightVec);
                    vec3 lightDir = lightVec / max(lightDist, EPSILON);
                    lightDist = max(lightDist - 0.5, 0.0);

                    float lightAtt = 1.0 - saturate(lightDist / light.range);
                    lightAtt = pow(lightAtt, 5.0);
                    
                    float lightNoLm = 1.0;
                    // if (hasTexNormal) {
                    //     lightNoLm = max(dot(localNormal, lightDir), 0.0);
                    // }

                    float sss = 0.0;
                    // if (material.scattering > EPSILON) {
                    //     float lightVoL = dot(localViewDir, lightDir);

                    //     sss = 3.0 * material.scattering * max(mix(
                    //         ComputeVolumetricScattering(lightVoL, -0.2),
                    //         ComputeVolumetricScattering(lightVoL, 0.6),
                    //         0.65), 0.0);
                    // }

                    // WARN: This breaks on PhysicsMod snow cause geoNormal isn't smooth
                    float sampleShadow = 1.0;
                    #ifdef LIGHT_COLOR_NORMAL_CHECK
                        //if (hasTexNormal && hasGeoNormal)
                        if (hasGeoNormal)
                            sampleShadow = step(-EPSILON, dot(localNormal, lightDir));
                    #endif
                    
                    float lightDiffuse = (1.0 - lightNoLm) * sss + lightNoLm * sampleShadow;

                    accumDiffuse += lightDiffuse * light.color.rgb * lightAtt;
                }

                accumDiffuse *= blockLight * DynamicLightBrightness;

                #ifdef LIGHT_FALLBACK
                    // TODO: shrink to shadow bounds
                    vec3 offsetPos = localPos + LightGridCenter;
                    //vec3 maxSize = SceneLightSize
                    float fade = minOf(min(offsetPos, SceneLightSize - offsetPos)) / 15.0;
                    accumDiffuse = mix(pow(blockLight, 4.0) * blockLightColor, accumDiffuse, saturate(fade));
                #endif

                vBlockLight = accumDiffuse;
                //vBlockLight = vec3(0.0, 1.0, 0.0);
            }
            else {
                #ifdef LIGHT_FALLBACK
                    vBlockLight = pow(blockLight, 4.0) * blockLightColor;
                #else
                    vBlockLight = vec3(0.0);
                #endif
            }
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
            vec4 color = texture(gtexture, texcoord);

            #if !defined RENDER_WATER && !defined RENDER_HAND_WATER
                if (color.a < alphaTestRef) {
                    discard;
                    return vec4(0.0);
                }
            #endif

            color.rgb *= glcolor.rgb;

            #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED && defined DEBUG_CASCADE_TINT && defined SHADOW_BLUR
                color.rgb = RGBToLinear(color.rgb);
                color.rgb *= 1.0 - LOD_TINT_FACTOR * (1.0 - GetShadowTileColor(shadowTile));
                color.rgb = LinearToRGB(color.rgb);
            #endif

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
        vec4 GetFinalLighting(const in vec4 color, const in vec3 shadowColor, const in vec3 localPos, const in vec2 lmcoord, const in float occlusion) {
            vec3 albedo = RGBToLinear(color.rgb);

            #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED && defined DEBUG_CASCADE_TINT && !defined RENDER_CLOUDS && !defined RENDER_COMPOSITE
                albedo *= 1.0 - LOD_TINT_FACTOR * (1.0 - GetShadowTileColor(shadowTile));
            #endif

            #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX && defined IRIS_FEATURE_SSBO && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
                vec3 blockLight = vBlockLight * saturate((lmcoord.x - (0.5/16.0)) * (16.0/15.0));

                #if !defined SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                    if (gl_FragCoord.x < 0) return vec4(texelFetch(shadowcolor0, ivec2(0.0), 0).rgb, 1.0);
                #endif
            #else
                #if defined IS_IRIS && defined IRIS_FEATURE_CUSTOM_TEXTURE_NAME
                    vec3 blockLight = textureLod(texLightMap, vec2(lmcoord.x, 1.0/32.0), 0).rgb;
                #elif defined RENDER_COMPOSITE //|| defined RENDER_CLOUDS
                    vec3 blockLight = textureLod(colortex3, vec2(lmcoord.x, 1.0/32.0), 0).rgb;
                #else
                    vec3 blockLight = textureLod(lightmap, vec2(lmcoord.x, 1.0/32.0), 0).rgb;
                #endif

                blockLight = RGBToLinear(blockLight);
            #endif

            #if defined IS_IRIS && defined IRIS_FEATURE_CUSTOM_TEXTURE_NAME
                vec3 skyLight = textureLod(texLightMap, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #elif defined RENDER_COMPOSITE //|| defined RENDER_CLOUDS
                vec3 skyLight = textureLod(colortex3, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #else
                vec3 skyLight = textureLod(lightmap, vec2(1.0/32.0, lmcoord.y), 0).rgb;
            #endif

            skyLight = RGBToLinear(skyLight);
            skyLight *= 1.0 - blindness;

            vec3 ambient = albedo.rgb * skyLight * occlusion * SHADOW_BRIGHTNESS;
            vec3 diffuse = albedo.rgb * (blockLight + skyLight * shadowColor * (1.0 - SHADOW_BRIGHTNESS));
            vec4 final = vec4(ambient + diffuse, color.a);

            ApplyFog(final, localPos);

            final.rgb = LinearToRGB(final.rgb);
            return final;
        }
    #endif
#endif
