#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    void SampleDynamicLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in float roughL, const in float metal_f0, const in float sss, const in vec3 blockLightDefault) {
        uint gridIndex;
        vec3 lightFragPos = localPos + 0.06 * localNormal;
        uint lightCount = GetSceneLights(lightFragPos, gridIndex);

        if (gridIndex != DYN_LIGHT_GRID_MAX) {
            bool hasGeoNormal = !all(lessThan(abs(localNormal), EPSILON3));
            bool hasTexNormal = !all(lessThan(abs(texNormal), EPSILON3));

            #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                float f0 = GetMaterialF0(metal_f0);
                vec3 localViewDir = -normalize(localPos);

                float lightNoVm = 1.0;
                if (hasTexNormal) lightNoVm = max(dot(texNormal, localViewDir), EPSILON);
            #endif

            vec3 accumDiffuse = vec3(0.0);
            vec3 accumSpecular = vec3(0.0);

            for (uint i = 0u; i < lightCount; i++) {
                vec3 lightPos, lightColor, lightVec;
                float lightSize, lightRange, traceDist2;
                uvec4 lightData;

                //bool hasLight = false;
                //for (uint i2 = 0u; i2 < 16u; i2++) {
                    lightData = GetSceneLight(gridIndex, i);
                    ParseLightData(lightData, lightPos, lightSize, lightRange, lightColor);

                    float traceRange2 = lightRange + 0.5;
                    traceRange2 = _pow2(traceRange2);

                    lightVec = lightFragPos - lightPos;
                    traceDist2 = length2(lightVec);

                    if (traceDist2 >= traceRange2) {
                        //i++;
                        continue;
                    }

                    //hasLight = true;
                    //break;
                //}

                //if (!hasLight) continue;

                lightColor = RGBToLinear(lightColor);

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                    #if DYN_LIGHT_TRACE_MODE == DYN_LIGHT_TRACE_DDA && DYN_LIGHT_PENUMBRA > 0 && !defined RENDER_TRANSLUCENT
                        vec3 offset = GetLightPenumbraOffset() * lightSize * 0.5 * DynamicLightPenumbraF;
                        //lightColor *= max(1.0 - 2.0*dot(offset, offset), 0.0);
                        lightPos += offset;
                    #endif

                    lightVec = lightFragPos - lightPos;
                    uint traceFace = 1u << GetLightMaskFace(lightVec);
                    if ((lightData.z & traceFace) == traceFace) continue;

                    //float traceRange2 = lightRange + 1.0;
                    //traceRange2 = _pow2(traceRange2);

                    //float traceDist2 = length2(lightVec);

                    //if (traceDist2 >= traceRange2) continue;
                //#else
                //    vec3 lightVec = lightFragPos - lightPos;
                #endif

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined RENDER_FRAG
                    if ((lightData.z & 1u) == 1u) {
                        vec3 traceOrigin = GetLightGridPosition(lightPos);
                        vec3 traceEnd = traceOrigin + 0.99*lightVec;

                        #ifdef RENDER_ENTITIES
                            if (entityId != ENTITY_PLAYER) {
                        #endif

                            #if DYN_LIGHT_PLAYER_SHADOW != PLAYER_SHADOW_NONE
                                vec3 playerPos = vec3(0.0, -0.8, 0.0);

                                #ifdef IS_IRIS
                                    if (!firstPersonCamera) playerPos += eyePosition - cameraPosition;
                                #endif

                                playerPos = GetLightGridPosition(playerPos);

                                vec3 playerOffset = traceOrigin - playerPos;
                                if (length2(playerOffset) < traceDist2) {
                                    #if DYN_LIGHT_PLAYER_SHADOW == PLAYER_SHADOW_CYLINDER
                                        bool hit = CylinderRayTest(traceOrigin - playerPos, traceEnd - traceOrigin, 0.36, 1.0);
                                    #else
                                        vec3 boundsMin = vec3(-0.36, -1.0, -0.36);
                                        vec3 boundsMax = vec3( 0.36,  1.0,  0.36);

                                        #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                                            bool hit = BoxPointTest(boundsMin, boundsMax, rayStart - playerPos);
                                        #else
                                            vec3 rayInv = rcp(traceEnd - traceOrigin);
                                            bool hit = BoxRayTest(boundsMin, boundsMax, traceOrigin - playerPos, rayInv);
                                        #endif
                                    #endif
                                    
                                    if (hit) lightColor = vec3(0.0);
                                }
                            #endif

                        #ifdef RENDER_ENTITIES
                            }
                        #endif

                        #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                            lightColor *= TraceRay(traceOrigin, traceEnd, lightRange);
                        #else
                            lightColor *= TraceDDA(traceEnd, traceOrigin, lightRange);
                        #endif
                    }
                #endif

                vec3 lightDir = normalize(-lightVec);
                float geoNoL = 1.0;
                if (hasGeoNormal) geoNoL = dot(localNormal, lightDir);

                float diffuseNoLm = GetLightNoL(geoNoL, texNormal, lightDir, sss);

                if (diffuseNoLm > EPSILON) {
                    float lightAtt = GetLightAttenuation(lightVec, lightRange);

                    float F = 0.0;
                    #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                        vec3 lightH = normalize(lightDir + localViewDir);
                        float lightVoHm = max(dot(localViewDir, lightH), EPSILON);

                        float invCosTheta = 1.0 - lightVoHm;
                        F = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);
                    #endif

                    accumDiffuse += SampleLightDiffuse(diffuseNoLm, F) * lightAtt * lightColor;

                    #if MATERIAL_SPECULAR != SPECULAR_NONE && defined RENDER_FRAG
                        float lightNoLm = max(dot(texNormal, lightDir), 0.0);
                        float lightNoHm = max(dot(texNormal, lightH), EPSILON);
                        float invGeoNoL = saturate(geoNoL*40.0 + 1.0);

                        accumSpecular += invGeoNoL * SampleLightSpecular(lightNoVm, lightNoLm, lightNoHm, F, roughL) * lightAtt * lightColor;
                    #endif
                }
            }

            accumDiffuse *= DynamicLightBrightness;
            accumSpecular *= DynamicLightBrightness;

            #ifdef DYN_LIGHT_FALLBACK
                // TODO: shrink to shadow bounds
                vec3 offsetPos = localPos + LightGridCenter;
                float fade = minOf(min(offsetPos, SceneLightSize - offsetPos)) / 8.0;
                accumDiffuse = mix(blockLightDefault, accumDiffuse, saturate(fade));
                accumSpecular = mix(vec3(0.0), accumSpecular, saturate(fade));
            #endif

            blockDiffuse += accumDiffuse;
            blockSpecular += accumSpecular;
        }
        else {
            #ifdef DYN_LIGHT_FALLBACK
                blockDiffuse += blockLightDefault;
            #endif
        }
    }
#endif

#ifdef RENDER_VERTEX
    void BasicVertex() {
        vec4 pos = gl_Vertex;

        #if defined RENDER_TERRAIN || defined RENDER_WATER
            vBlockId = int(mc_Entity.x + 0.5);

            #if defined WORLD_SKY_ENABLED && defined WORLD_WAVING_ENABLED
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
        #else
            geoNoL = 1.0;
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

                const float roughL = 0.2;
                const float metal_f0 = 0.04;

                vec3 blockDiffuse = vec3(0.0);
                vec3 blockSpecular = vec3(0.0);
                SampleDynamicLighting(blockDiffuse, blockSpecular, vLocalPos, vLocalNormal, vec3(0.0), roughL, metal_f0, sss, blockLightDefault);
                SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, vLocalNormal, vec3(0.0), roughL, metal_f0, sss);

                vBlockLight += blockDiffuse * saturate((lmcoord.x - (0.5/16.0)) * (16.0/15.0));
            #endif

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
                #ifdef RENDER_ENTITIES
                    vec4 lightColor = GetSceneEntityLightColor(entityId);
                    vBlockLight += vec3(lightColor.a / 15.0);
                #elif defined RENDER_HAND
                    // TODO: change ID depending on hand
                    float lightRange = heldBlockLightValue;//GetSceneItemLightRange(heldItemId);
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

    void GetFinalBlockLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in float lmcoordX, const in float roughL, const in float metal_f0, const in float sss) {
        #ifdef RENDER_GBUFFER
            vec3 blockLightDefault = textureLod(lightmap, vec2(lmcoordX, 0.5/16.0), 0).rgb;
        #else
            vec3 blockLightDefault = textureLod(TEX_LIGHTMAP, vec2(lmcoordX, 0.5/16.0), 0).rgb;
        #endif

        blockLightDefault = RGBToLinear(blockLightDefault);

        #if defined RENDER_WEATHER && !defined DYN_LIGHT_WEATHER
            blockDiffuse += blockLightDefault;
        #elif defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED || (DYN_LIGHT_MODE == DYN_LIGHT_VERTEX && (defined RENDER_WEATHER || defined RENDER_DEFERRED))) && !(defined RENDER_CLOUDS || defined RENDER_COMPOSITE)
            SampleDynamicLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, roughL, metal_f0, sss, blockLightDefault);
        #else
            blockDiffuse += blockLightDefault;
        #endif

        SampleHandLight(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, roughL, metal_f0, sss);

        #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && !(defined RENDER_CLOUDS || defined RENDER_DEFERRED)
            if (gl_FragCoord.x < 0) blockDiffuse = texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
        #endif
    }

    #ifdef WORLD_SKY_ENABLED
        void GetSkyLightingFinal(inout vec3 skyDiffuse, inout vec3 skySpecular, const in vec3 shadowColor, const in vec3 localViewDir, const in vec3 localNormal, const in vec3 texNormal, const in float lmcoordY, const in float roughL, const in float metal_f0, const in float sss) {
            #ifndef RENDER_CLOUDS
                #ifdef RENDER_GBUFFER
                    vec3 skyLight = textureLod(lightmap, vec2(0.5/16.0, lmcoordY), 0).rgb;
                #else
                    vec3 skyLight = textureLod(TEX_LIGHTMAP, vec2(0.5/16.0, lmcoordY), 0).rgb;
                #endif

                float worldBrightness = GetWorldBrightnessF();
                skyLight = RGBToLinear(skyLight) * worldBrightness;

                //skyLight = skyLight * (1.0 - ShadowBrightnessF) + (ShadowBrightnessF);

                skyLight *= 1.0 - blindness;
            #else
                const float skyLight = 1.0;
            #endif

            //skyLight *= 1.0 - 0.8*rainStrength;
            
            #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                vec3 localLightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
            #else
                vec3 celestialPos = normalize(sunPosition);
                if (worldTime > 12000 && worldTime < 24000) celestialPos = -celestialPos;
                vec3 localLightDir = mat3(gbufferModelViewInverse) * celestialPos;
            #endif

            float geoNoL = 1.0;
            if (!all(lessThan(abs(localNormal), EPSILON3)))
                geoNoL = dot(localNormal, localLightDir);

            #if (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE)
                float diffuseNoL = GetLightNoL(geoNoL, texNormal, localLightDir, sss);
            #else
                const float diffuseNoL = 1.0;
            #endif

            skyDiffuse += diffuseNoL * skyLight * shadowColor;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                // float geoNoL = 1.0;
                // if (any(greaterThan(localNormal, EPSILON3)))
                //     geoNoL = max(dot(localNormal, localLightDir), 0.0);

                //if (geoNoL > EPSILON) {
                    float f0 = GetMaterialF0(metal_f0);

                    //vec3 localViewDir = normalize(localPos);

                    vec3 skyH = normalize(localLightDir + localViewDir);
                    float skyVoHm = max(dot(localViewDir, skyH), 0.0);

                    float skyNoLm = 1.0, skyNoVm = 1.0, skyNoHm = 1.0;
                    if (any(greaterThan(texNormal, EPSILON3))) {
                        skyNoLm = max(dot(texNormal, localLightDir), 0.0);
                        skyNoVm = max(dot(texNormal, localViewDir), 0.0);
                        skyNoHm = max(dot(texNormal, skyH), 0.0);
                    }

                    float invCosTheta = 1.0 - skyVoHm;
                    float skyF = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);

                    skyLight *= 1.0 - 0.92*rainStrength;
                    
                    float invGeoNoL = saturate(geoNoL*40.0 + 1.0);
                    skySpecular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyF, roughL) * skyLight * shadowColor;
                //}
            #endif
        }
    #endif

    vec3 GetFinalLighting(const in vec3 albedo, const in vec3 localNormal, const in vec3 blockDiffuse, const in vec3 blockSpecular, const in vec3 skyDiffuse, const in vec3 skySpecular, const in vec2 lmcoord, const in float metal_f0, const in float occlusion) {
        vec2 lightCoord = saturate((lmcoord - (0.5/16.0)) / (15.0/16.0));
        vec3 albedoFinal = albedo;

        // // weather darkening
        // #if defined WORLD_SKY_ENABLED && (defined RENDER_TERRAIN || defined RENDER_WATER || defined RENDER_BLOCK)
        //     float surfaceWetness = max(15.0 * lightCoord.y - 14.0, 0.0);
        //     albedoFinal *= 0.0;//pow(albedoFinal, vec3(1.0 + 3.6*surfaceWetness));
        // #endif
        
        //float worldBrightness = GetWorldBrightnessF();

        //float shadowingF = 1.0 - (1.0 - 0.5 * rainStrength) * (1.0 - ShadowBrightnessF);

        //skyDiffuse += skyNoLm * skyLight * shadowColor;// * (1.0 - shadowingF);

        vec3 ambientLight = vec3(0.0);
        #if (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
            #ifdef AMBIENT_FANCY
                ambientLight = fogColor;

                float upF = localNormal.y;
                ambientLight = mix(ambientLight, skyColor, localNormal.y * 0.5 + 0.5);
                ambientLight *= 0.34 + 0.66 * min(localNormal.y + 1.0, 1.0);
            #else
                ambientLight = vec3(1.0);
            #endif

            vec2 lmFinal = lightCoord;//saturate((lmcoord - (0.5/16.0)) / (15.0/16.0));
            lmFinal.x *= 0.16;
            lmFinal = saturate(lmFinal * (15.0/16.0) + (0.5/16.0));

            #ifdef RENDER_GBUFFER
                vec3 lightmapColor = textureLod(lightmap, lmFinal, 0).rgb;
            #else
                vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmFinal, 0).rgb;
            #endif

            ambientLight *= RGBToLinear(lightmapColor);
            //ambientLight *= ShadowBrightnessF;

            vec3 diffuse = albedoFinal * mix(blockDiffuse + skyDiffuse, ambientLight * occlusion, ShadowBrightnessF);
        #else
            vec3 diffuse = albedoFinal * (blockDiffuse + skyDiffuse) * occlusion;
        #endif

        vec3 specular = blockSpecular + skySpecular;

        // #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
        //     diffuse *= occlusion;
        // #endif

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            if (metal_f0 >= 0.5) {
                diffuse *= METAL_BRIGHTNESS;
                specular *= albedo;
            }
        #endif

        return diffuse + specular;
    }
#endif
