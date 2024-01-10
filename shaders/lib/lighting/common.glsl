vec4 BasicVertex() {
    vec4 pos = gl_Vertex;

    #if defined RENDER_TERRAIN || defined RENDER_WATER
        vOut.blockId = int(mc_Entity.x + 0.5);
    #endif

    #if defined RENDER_TERRAIN || defined RENDER_WATER
        #if defined WORLD_SKY_ENABLED && defined WORLD_WAVING_ENABLED
            vec3 localPos = (gbufferModelViewInverse * (gl_ModelViewMatrix * pos)).xyz;

            ApplyWavingOffset(pos.xyz, localPos, vOut.blockId);
        #endif
    #endif

    vec4 viewPos = gl_ModelViewMatrix * pos;

    #if defined WORLD_WATER_ENABLED && ((defined RENDER_WATER && WATER_TESSELLATION_QUALITY == 0) || defined RENDER_TERRAIN)
        if (vOut.blockId == BLOCK_WATER || vOut.blockId == BLOCK_LILY_PAD) {
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
                float time = GetAnimationFactor();

                vec2 uvOffset = vec2(0.0);
                if (vOut.blockId == BLOCK_LILY_PAD) {
                    vec3 originPos = vOut.localPos + at_midBlock/64.0;
                    water_waveHeight(cameraPosition.xz + originPos.xz, vOut.lmcoord.y, time, uvOffset);
                    uvOffset *= 0.5;
                    pos.xz += uvOffset;
                }

                vec2 _o;
                float waveOffset = distF * water_waveHeight(vOut.localPos.xz + cameraPosition.xz + uvOffset, vOut.lmcoord.y, time, _o);
                pos.y += waveOffset;

                #if defined EFFECT_TAA_ENABLED && defined RENDER_TERRAIN
                    float timePrev = time - frameTime;
                    
                    vec2 uvOffsetPrev;
                    if (vOut.blockId == BLOCK_LILY_PAD) {
                        vec3 originPos = vOut.localPos + at_midBlock/64.0;
                        water_waveHeight(previousCameraPosition.xz + originPos.xz, vOut.lmcoord.y, timePrev, uvOffsetPrev);
                        uvOffsetPrev *= 0.5;

                        vOut.velocity.xz += uvOffset - uvOffsetPrev;
                    }
                    
                    float waveOffsetPrev = distF * water_waveHeight(vOut.localPos.xz + previousCameraPosition.xz + uvOffset, vOut.lmcoord.y, timePrev, _o);
                    vOut.velocity.y += waveOffset - waveOffsetPrev;
                #endif
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

        #if defined RENDER_BILLBOARD //|| defined RENDER_CLOUDS
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
    #endif

    return viewPos;
}
