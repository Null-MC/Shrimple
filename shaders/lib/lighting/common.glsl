void BasicVertex() {
    vec4 pos = gl_Vertex;

    #if defined RENDER_TERRAIN || defined RENDER_WATER
        vBlockId = int(mc_Entity.x + 0.5);
    #endif

    #if defined RENDER_TERRAIN || defined RENDER_WATER
        #if defined WORLD_SKY_ENABLED && defined WORLD_WAVING_ENABLED
            ApplyWavingOffset(pos.xyz, vBlockId);
        #endif
    #endif

    vec4 viewPos = gl_ModelViewMatrix * pos;

    #if defined RENDER_WATER && defined WORLD_WATER_ENABLED
        if (vBlockId == BLOCK_WATER) {
            // if (abs(vLocalNormal.y) > 0.999 && (gl_Vertex.y + at_midBlock.y/64.0) < 0.0) {
            //     gl_Position = vec4(-1.0);
            //     return;
            // }

            float distF = saturate((length(viewPos) - 1.0) * 0.5);
            distF = smoothstep(0.0, 1.0, distF);

            #ifdef PHYSICS_OCEAN
                physics_localWaviness = texelFetch(physics_waviness, ivec2(pos.xz) - physics_textureOffset, 0).r;

                #ifdef WATER_DISPLACEMENT
                    pos.y += distF * physics_waveHeight(pos.xz, PHYSICS_ITERATIONS_OFFSET, physics_localWaviness, physics_gameTime);
                #endif

                physics_localPosition = pos.xyz;
            #elif WORLD_WATER_WAVES != WATER_WAVES_NONE && defined WATER_DISPLACEMENT
                vLocalPos = (gbufferModelViewInverse * viewPos).xyz;
                pos.y += distF * water_waveHeight(vLocalPos.xz + cameraPosition.xz, lmcoord.y);
            #endif

            viewPos = gl_ModelViewMatrix * pos;
        }
    #endif

    vLocalPos = (gbufferModelViewInverse * viewPos).xyz;

    #if !(defined RENDER_BILLBOARD || defined RENDER_CLOUDS)
        vLocalNormal = vec3(0.0);
    #endif

    #ifndef RENDER_DAMAGEDBLOCK
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        //vBlockLight = vec3(0.0);

        #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
            vec3 _vLocalNormal = mat3(gbufferModelViewInverse) * viewNormal;
        #else
            vLocalNormal = mat3(gbufferModelViewInverse) * viewNormal;
        #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                shadowTile = -1;
            #endif

            #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && !defined RENDER_BILLBOARD
                vec3 skyLightDir = normalize(shadowLightPosition);
                float geoNoL = dot(skyLightDir, viewNormal);
            #else
                float geoNoL = 1.0;
            #endif

            #if defined RENDER_BILLBOARD || defined RENDER_CLOUDS
                ApplyShadows(vLocalPos, _vLocalNormal, geoNoL);
            #else
                ApplyShadows(vLocalPos, vLocalNormal, geoNoL);
            #endif

            #if defined RENDER_CLOUD_SHADOWS_ENABLED && !defined RENDER_CLOUDS
                ApplyCloudShadows(vLocalPos);
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
        //             float lightRange = GetSceneBlockEmission(vBlockId);
        //             vBlockLight += vec3(lightRange);
        //         #endif
        //     #else
        //         vBlockLight += blockLightDefault;
        //     #endif
        // #endif
    #endif

    gl_Position = gl_ProjectionMatrix * viewPos;
}
