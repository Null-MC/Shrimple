vec4 BasicVertex() {
    vec4 pos = gl_Vertex;

    #if defined RENDER_TERRAIN || defined RENDER_WATER
        vOut.blockId = int(mc_Entity.x + 0.5);
    #endif

    #if defined RENDER_TERRAIN || defined RENDER_WATER
        #if defined WORLD_SKY_ENABLED && defined WORLD_WAVING_ENABLED
            ApplyWavingOffset(pos.xyz, vOut.blockId);
        #endif
    #endif

    vec4 viewPos = gl_ModelViewMatrix * pos;

    #if defined RENDER_WATER && defined WORLD_WATER_ENABLED && !defined WATER_TESSELLATION
        if (vOut.blockId == BLOCK_WATER) {
            // if (abs(vLocalNormal.y) > 0.999 && (gl_Vertex.y + at_midBlock.y/64.0) < 0.0) {
            //     gl_Position = vec4(-1.0);
            //     return;
            // }

            float distF = 1.0 - smoothstep(0.2, 2.8, length(viewPos.xyz));
            distF = 1.0 - _pow2(distF);

            #ifdef PHYSICS_OCEAN
                vOut.physics_localWaviness = texelFetch(physics_waviness, ivec2(pos.xz) - physics_textureOffset, 0).r;

                #ifdef WATER_DISPLACEMENT
                    pos.y += distF * physics_waveHeight(pos.xz, PHYSICS_ITERATIONS_OFFSET, vOut.physics_localWaviness, physics_gameTime);
                #endif

                vOut.physics_localPosition = pos.xyz;
            #elif WATER_WAVE_SIZE != WATER_WAVES_NONE && defined WATER_DISPLACEMENT
                vOut.localPos = (gbufferModelViewInverse * viewPos).xyz;
                pos.y += distF * water_waveHeight(vOut.localPos.xz + cameraPosition.xz, vOut.lmcoord.y);
            #endif

            viewPos = gl_ModelViewMatrix * pos;
        }
    #endif

    vOut.localPos = (gbufferModelViewInverse * viewPos).xyz;

    #if !(defined RENDER_BILLBOARD || defined RENDER_CLOUDS)
        vOut.localNormal = vec3(0.0);
    #endif

    #ifndef RENDER_DAMAGEDBLOCK
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        //vBlockLight = vec3(0.0);

        #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
            vec3 _vLocalNormal = mat3(gbufferModelViewInverse) * viewNormal;
        #else
            vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;
        #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vOut.shadowTile = -1;
            #endif

            #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && !defined RENDER_BILLBOARD
                vec3 skyLightDir = normalize(shadowLightPosition);
                float geoNoL = dot(skyLightDir, viewNormal);
            #else
                float geoNoL = 1.0;
            #endif

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
                    ApplyShadows(vOut.localPos, _vLocalNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
                #else
                    ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
                #endif
            #else
                #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
                    vOut.shadowPos = ApplyShadows(vOut.localPos, _vLocalNormal, geoNoL);
                #else
                    vOut.shadowPos = ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL);
                #endif
            #endif

            #if defined RENDER_CLOUD_SHADOWS_ENABLED && !defined RENDER_CLOUDS
                vOut.cloudPos = ApplyCloudShadows(vOut.localPos);
            #endif
        #endif

        // #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED && !defined RENDER_CLOUDS
        //     vec2 lmcoordFinal = vec2(lmcoord.x, 0.0);
        //     //float lightP = rcp(max(DynamicLightAmbientF, EPSILON));
        //     //lmcoordFinal.y = pow(lmcoordFinal.y, lightP);
        //     lmcoordFinal = saturate(lmcoordFinal) * (15.0/16.0) + (0.5/16.0);

        //     vec3 blockLightDefault = textureLod(TEX_LIGHTMAP, lmcoordFinal, 0).rgb;
        //     blockLightDefault = RGBToLinear(blockLightDefault);

        //     #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        //         #ifdef RENDER_ENTITIES
        //             vec4 lightColor = GetSceneEntityLightColor(entityId);
        //             vBlockLight += vec3(lightColor.a / 15.0);
        //         #elif defined RENDER_HAND
        //             // TODO: change ID depending on hand
        //             float lightRange = heldBlockLightValue;//GetSceneItemLightRange(heldItemId);
        //             vBlockLight += vec3(lightRange / 15.0);
        //         #elif defined RENDER_TERRAIN || defined RENDER_WATER
        //             float lightRange = GetSceneBlockEmission(vOut.blockId);
        //             vBlockLight += vec3(lightRange);
        //         #endif
        //     #else
        //         vBlockLight += blockLightDefault;
        //     #endif
        // #endif
    #endif

    //gl_Position = gl_ProjectionMatrix * viewPos;
    return viewPos;
}
