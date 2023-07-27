#ifdef RENDER_VERTEX
    void BasicVertex() {
        vec4 pos = gl_Vertex;

        #if defined RENDER_TERRAIN || defined RENDER_WATER || defined RENDER_BLOCK
            vBlockId = int(mc_Entity.x + 0.5);
        #endif

        #if defined RENDER_TERRAIN || defined RENDER_WATER
            #if defined WORLD_SKY_ENABLED && defined WORLD_WAVING_ENABLED
                ApplyWavingOffset(pos.xyz, vBlockId);
            #endif
        #endif

        vec4 viewPos = gl_ModelViewMatrix * pos;

        vPos = viewPos.xyz;

        vLocalPos = (gbufferModelViewInverse * viewPos).xyz;

        #ifndef RENDER_DAMAGEDBLOCK
            vBlockLight = vec3(0.0);

            #ifdef RENDER_BILLBOARD
                vec3 vNormal;
                vec3 vLocalNormal;
            #endif

            vNormal = normalize(gl_NormalMatrix * gl_Normal);
            vLocalNormal = mat3(gbufferModelViewInverse) * vNormal;

            #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && !defined RENDER_BILLBOARD
                vec3 skyLightDir = normalize(shadowLightPosition);
                geoNoL = dot(skyLightDir, vNormal);
            #else
                geoNoL = 1.0;
            #endif

            #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                    shadowTile = -1;
                #endif

                ApplyShadows(vLocalPos, vLocalNormal, geoNoL);

                #ifdef RENDER_CLOUD_SHADOWS_ENABLED
                    ApplyCloudShadows(vLocalPos);
                #endif
            #endif

            #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED && !defined RENDER_CLOUDS
                vec2 lmcoordFinal = vec2(lmcoord.x, 0.0);
                //float lightP = rcp(max(DynamicLightAmbientF, EPSILON));
                //lmcoordFinal.y = pow(lmcoordFinal.y, lightP);
                lmcoordFinal = saturate(lmcoordFinal) * (15.0/16.0) + (0.5/16.0);

                vec3 blockLightDefault = textureLod(TEX_LIGHTMAP, lmcoordFinal, 0).rgb;
                blockLightDefault = RGBToLinear(blockLightDefault);

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
        #endif

        gl_Position = gl_ProjectionMatrix * viewPos;
    }
#endif

#ifdef RENDER_FRAG
    #if !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
        #if LPV_SIZE > 0
            vec3 GetLpvAmbient(const in vec3 voxelPos, const in vec3 lpvPos) {
                //if (saturate(lpvTexcoord) == lpvTexcoord) {

                vec3 lpvLight = SampleLpvVoxel(voxelPos, lpvPos);
                //lpvLight = sqrt(lpvLight / LpvRangeF);

                //lpvLight /= LpvBlockLightF;

                // float lum = luminance(lpvLight);
                // lpvLight /= lum + 3.0;

                lpvLight = sqrt(lpvLight / LpvBlockLightF);

                //lpvLight /= lpvLight + 1.0;

                //lpvLight *= rcp(256.0);
                //lpvLight /= 64.0 + luminance(lpvLight);
                //lpvLight /= 8.0 + luminance(lpvLight);
                //lpvLight /= LpvRangeF;

                // #if LPV_LIGHTMAP_MIX > 0
                //     ambientLight *= 1.0 - (1.0 - LpvLightmapMixF)*lpvFade;
                // #endif
                
                //lpvLight *= 0.3*LPV_BRIGHT_BLOCK;
                lpvLight *= sqrt(LPV_BRIGHT_BLOCK);
                //lpvLight *= LPV_BRIGHT_BLOCK;
                return lpvLight;
            }
        #endif

        vec3 GetAmbientLighting(const in vec3 localPos, const in vec3 localNormal) {
            vec3 ambientLight = vec3(0.0);

            #if LPV_SIZE > 0
                vec3 surfacePos = localPos;
                surfacePos += 0.501 * localNormal;// * (1.0 - sss);

                vec3 lpvPos = GetLPVPosition(surfacePos);

                //vec3 lpvTexcoord = GetLPVTexCoord(lpvPos);

                float lpvFade = GetLpvFade(lpvPos);
                lpvFade = smoothstep(0.0, 1.0, lpvFade);
            #endif

            // TODO: add lightmap mix

            #if LPV_SIZE > 0
                //lmFinal.x *= 1.0 - lpvFade;

                vec3 voxelPos = GetVoxelBlockPosition(surfacePos);

                vec3 lpvLight = GetLpvAmbient(voxelPos, lpvPos);
                
                ambientLight += lpvLight * lpvFade;
            #endif

            return ambientLight * DynamicLightAmbientF;
        }
    #endif

    //#if defined RENDER_GBUFFER || defined RENDER_DEFERRED_RT_LIGHT || defined RENDER_COMPOSITE_RT_LIGHT
        void GetFinalBlockLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float sss) {
            //#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
                vec2 lmBlock = vec2(lmcoord.x, 0.0);
            //#else
            //    vec2 lmBlock = lmcoord;
            //#endif

            //lmBlock = (vec4(lmBlock, 0.0, 1.0) * TEXTURE_MATRIX_2).xy;
            lmBlock = saturate(lmBlock) * (15.0/16.0) + (0.5/16.0);
            vec3 blockLightDefault = textureLod(TEX_LIGHTMAP, lmBlock, 0).rgb;

            blockLightDefault = RGBToLinear(blockLightDefault);

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && !(defined RENDER_CLOUDS || defined RENDER_WEATHER || defined DYN_LIGHT_WEATHER)
                SampleDynamicLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, roughL, metal_f0, sss, blockLightDefault);
            #endif

            #if LPV_SIZE > 0 && DYN_LIGHT_MODE == DYN_LIGHT_LPV
                vec3 lpvPos = GetLPVPosition(localPos + 0.52 * localNormal);
                vec3 lpvTexcoord = GetLPVTexCoord(lpvPos);

                float lpvFade = GetLpvFade(lpvPos);
                lpvFade = smoothstep(0.0, 1.0, lpvFade);

                if (saturate(lpvTexcoord) == lpvTexcoord) {
                    vec3 lpvLight = (frameCounter % 2) == 0
                        ? textureLod(texLPV_1, lpvTexcoord, 0).rgb
                        : textureLod(texLPV_2, lpvTexcoord, 0).rgb;

                    //lpvLight = sqrt(lpvLight) / LpvRangeF;
                    //lpvLight /= 1.0 + luminance(lpvLight);
                    //lpvLight /= LpvRangeF;
                    lpvLight /= lpvLight + 1.0;
                    blockDiffuse += mix(blockLightDefault, lpvLight, lpvFade);
                }
                else blockDiffuse += blockLightDefault;
            #endif

            //#if DYN_LIGHT_MODE == DYN_LIGHT_NONE
            //    blockDiffuse += blockLightDefault;
            //#endif

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && !(defined RENDER_CLOUDS || defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
                if (gl_FragCoord.x < 0) blockDiffuse = texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
            #endif
        }
    //#endif

    #if defined WORLD_SKY_ENABLED && !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
        void GetSkyLightingFinal(inout vec3 skyDiffuse, inout vec3 skySpecular, const in vec3 shadowPos, const in vec3 shadowColor, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {
            vec3 localViewDir = -normalize(localPos);

            #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
                vec2 lmSky = vec2(0.0, lmcoord.y);
            #else
                vec2 lmSky = lmcoord;
                //lmSky.y
            #endif

            // #ifndef RENDER_CLOUDS
            //     //lmSky.y = pow(lmSky.y, lightP);

            //     //lmSky = (vec4(lmSky, 0.0, 1.0) * TEXTURE_MATRIX_2).xy;
            //     lmSky = saturate(lmSky) * (15.0/16.0) + (0.5/16.0);

            //     vec3 skyLightColor = textureLod(TEX_LIGHTMAP, lmSky, 0).rgb;

            //     skyLightColor = RGBToLinear(skyLightColor);

            //     //skyLightColor = skyLightColor * (1.0 - ShadowBrightnessF) + (ShadowBrightnessF);

            //     //skyLightColor *= 1.0 - blindness;
            // #else
                vec3 skyLightColor = vec3(1.0);
            //#endif

            #if !defined LIGHT_LEAK_FIX && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
                float shadow = maxOf(abs(shadowPos * 2.0 - 1.0));
                shadow = 1.0 - smoothstep(0.5, 0.8, shadow);

                skyLightColor = mix(skyLightColor, vec3(1.0), shadow);
            #endif

            #ifndef IRIS_FEATURE_SSBO
                vec3 WorldSkyLightColor = GetSkyLightColor();
            #endif

            skyLightColor *= CalculateSkyLightWeatherColor(WorldSkyLightColor);// * WorldSkyBrightnessF;
            //skyLightColor *= 1.0 - 0.7 * rainStrength;
            
            #ifndef IRIS_FEATURE_SSBO
                #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                    vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
                #else
                    vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
                    if (worldTime > 12000 && worldTime < 24000)
                        localSkyLightDirection = -localSkyLightDirection;
                #endif
            #endif

            float geoNoL = 1.0;
            if (!all(lessThan(abs(localNormal), EPSILON3)))
                geoNoL = dot(localNormal, localSkyLightDirection);

            //#if (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE)
                float diffuseNoL = GetLightNoL(geoNoL, texNormal, localSkyLightDirection, sss);
            //#else
            //    const float diffuseNoL = 1.0;
            //#endif

            vec3 H = normalize(-localSkyLightDirection + -localViewDir);
            float diffuseNoVm = max(dot(texNormal, localViewDir), 0.0);
            float diffuseLoHm = max(dot(localSkyLightDirection, H), 0.0);
            float D = SampleLightDiffuse(diffuseNoVm, diffuseNoL, diffuseLoHm, roughL);
            //vec3 accumDiffuse = skyLightColor * D * mix(shadowColor, vec3(1.0), ShadowBrightnessF);// * roughL;
            vec3 accumDiffuse = skyLightColor * D * shadowColor;


            //vec2 lmcoordFinal = (vec4(lmcoord, 0.0, 1.0) * TEXTURE_MATRIX_2).xy;
            vec2 lmcoordFinal = lmcoord;
            //float lightP = rcp(max(DynamicLightAmbientF, EPSILON));
            //lmcoordFinal.y = pow(lmcoordFinal.y, lightP);
            lmcoordFinal = saturate(lmcoordFinal) * (15.0/16.0) + (0.5/16.0);

            vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmcoordFinal, 0).rgb;

            vec3 ambientLight = RGBToLinear(lightmapColor);

            #if LPV_SIZE > 0
                vec3 surfacePos = localPos;
                surfacePos += 0.501 * localNormal;// * (1.0 - sss);

                vec3 lpvPos = GetLPVPosition(surfacePos);

                float lpvFade = GetLpvFade(lpvPos);
                lpvFade = smoothstep(0.0, 1.0, lpvFade);

                //lmFinal.x *= 1.0 - lpvFade;

                vec3 voxelPos = GetVoxelBlockPosition(surfacePos);

                vec3 lpvLight = GetLpvAmbient(voxelPos, lpvPos);

                #if DYN_LIGHT_MODE != DYN_LIGHT_LPV
                    lpvFade *= 1.0 - LpvLightmapMixF;
                #endif

                #if DYN_LIGHT_MODE == DYN_LIGHT_LPV || (DYN_LIGHT_MODE == DYN_LIGHT_TRACED && LPV_LIGHTMAP_MIX != 100)
                    ambientLight *= 1.0 - lpvFade;
                    lpvLight *= 1.0 - LpvLightmapMixF;
                #endif
                
                ambientLight += lpvLight * lpvFade;
            #endif

            #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
                //ambientLight += WorldMinLightF;
                ambientLight *= DynamicLightAmbientF * (1.0 + 2.0*rainStrength);

                ambientLight *= occlusion;
            #endif

            accumDiffuse += ambientLight;// * roughL;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                if (metal_f0 >= 0.5) {
                    accumDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                }
            #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE && !defined RENDER_CLOUDS
                // float geoNoL = 1.0;
                // if (any(greaterThan(localNormal, EPSILON3)))
                //     geoNoL = max(dot(localNormal, localSkyLightDirection), 0.0);

                //if (geoNoL > EPSILON) {
                    vec3 f0 = GetMaterialF0(metal_f0);

                    vec3 localSkyLightDir = localSkyLightDirection;
                    //#if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
                        const float skyLightSize = 480.0;

                        vec3 r = reflect(-localViewDir, texNormal);
                        vec3 L = localSkyLightDir * 10000.0;
                        vec3 centerToRay = dot(L, r) * r - L;
                        vec3 closestPoint = L + centerToRay * saturate(skyLightSize / length(centerToRay));
                        localSkyLightDir = normalize(closestPoint);
                    //#endif

                    vec3 skyH = normalize(localSkyLightDir + localViewDir);
                    float skyVoHm = max(dot(localViewDir, skyH), 0.0);

                    float skyNoLm = 1.0, skyNoVm = 1.0, skyNoHm = 1.0;
                    if (!all(lessThan(abs(texNormal), EPSILON3))) {
                        skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);
                        skyNoVm = max(dot(texNormal, localViewDir), 0.0);
                        skyNoHm = max(dot(texNormal, skyH), 0.0);
                    }

                    //float invCosTheta = 1.0 - skyVoHm;
                    //float skyF = f0 + (max(1.0 - roughL, f0) - f0) * pow5(invCosTheta);
                    vec3 skyF = F_schlickRough(skyVoHm, f0, roughL);

                    skyLightColor *= 1.0 - 0.92*rainStrength;

                    //#if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
                    //    skyLightColor *= invPI;
                    //#endif

                    float invGeoNoL = saturate(geoNoL*40.0);
                    skySpecular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyF, roughL) * skyLightColor * shadowColor;
                //}

                #if MATERIAL_REFLECTIONS != REFLECT_NONE
                    vec3 viewPos = (gbufferModelView * vec4(localPos, 1.0)).xyz;
                    vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

                    vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);

                    #ifndef RENDER_OPAQUE_FINAL
                        skySpecular += ApplyReflections(viewPos, texViewNormal, lmcoord.y, sqrt(roughL)) * skyReflectF;
                    #endif

                    accumDiffuse *= 1.0 - skyReflectF;
                #endif
            #endif

            #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
               accumDiffuse *= occlusion;
            #endif

            skyDiffuse += accumDiffuse;
        }
    #endif

    #if !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
        vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, const in vec3 specular, const in float occlusion) {
            #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
                //occlusion = 0.5 + 0.5 * occlusion;
            #endif

            // #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
            //     diffuse *= blackbody(TEMP_FIRE);
            // #endif

            // TODO: handle specular occlusion
            return albedo * (WorldMinLightF * occlusion + diffuse) + specular * _pow3(occlusion);
        }
    #endif
#endif
