vec4 BasicVertex() {
    vec4 pos = gl_Vertex;

    #if defined RENDER_TERRAIN || defined RENDER_WATER
        vOut.blockId = int(mc_Entity.x + 0.5);
    #endif

    #if defined RENDER_TERRAIN || defined RENDER_WATER
        #if WORLD_WIND_STRENGTH > 0 //&& defined WORLD_SKY_ENABLED
            vec3 localPos = mul3(gl_ModelViewMatrix, pos.xyz);
            localPos = mul3(gbufferModelViewInverse, localPos);

            ApplyWavingOffset(pos.xyz, localPos, vOut.blockId);
        #endif
    #endif

    vec3 viewPos = mul3(gl_ModelViewMatrix, pos.xyz);

    #if defined WORLD_WATER_ENABLED && defined WATER_DISPLACEMENT && ((defined RENDER_WATER && !defined WATER_TESSELLATION_ENABLED) || defined RENDER_TERRAIN)
        bool applyWaterWaves = vOut.blockId == BLOCK_WATER;

        #ifdef WATER_WAVE_LILY
            applyWaterWaves = applyWaterWaves || vOut.blockId == BLOCK_LILY_PAD;
        #endif

        if (applyWaterWaves) {
            float viewDist = length(viewPos);
            float distF = 1.0 - smoothstep(0.2, 2.8, viewDist);
            distF = 1.0 - _pow2(distF);

            if (vOut.blockId == BLOCK_WATER) {
                // reduce wave strength lower surface is
                // prevent waving if connected to above water
                float vertexY = saturate(-at_midBlock.y/64.0 + 0.5);
                distF *= vertexY * step(vertexY, (15.5/16.0));
            }

            #ifdef DISTANT_HORIZONS
                float waterClipFar = dh_clipDistF*far;
                distF *= 1.0 - smoothstep(0.6*waterClipFar, waterClipFar, viewDist);
            #endif

            vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

            #ifdef PHYSICS_OCEAN
                vOut.physics_localWaviness = texelFetch(physics_waviness, ivec2(pos.xz) - physics_textureOffset, 0).r;

                #ifdef WATER_DISPLACEMENT
                    pos.y += distF * physics_waveHeight(pos.xz, PHYSICS_ITERATIONS_OFFSET, vOut.physics_localWaviness, physics_gameTime);
                #endif

                vOut.physics_localPosition = pos.xyz;
            #elif WATER_WAVE_SIZE > 0 && defined WATER_DISPLACEMENT
                // vOut.localPos = (gbufferModelViewInverse * viewPos).xyz;
                float time = GetAnimationFactor();

                #ifdef WATER_WAVE_LILY
                    if (vOut.blockId == BLOCK_LILY_PAD) {
                        vec3 originPos = vOut.localPos + at_midBlock/64.0;
                        vec3 waveOffset = GetWaveHeight(cameraPosition + originPos, vOut.lmcoord.y, time, WATER_WAVE_DETAIL_VERTEX);
                        pos.xz += distF * waveOffset.xz;
                        pos.y -= (1.0/16.0);
                    }
                #endif

                // vec2 _o;
                // float waveOffset = distF * water_waveHeight(vOut.localPos.xz + cameraPosition.xz + uvOffset, vOut.lmcoord.y, time, _o);
                vec3 waveOffset = GetWaveHeight(cameraPosition + vOut.localPos, vOut.lmcoord.y, time, WATER_WAVE_DETAIL_VERTEX);
                pos.y += distF * waveOffset.y;

                #if defined EFFECT_TAA_ENABLED && defined RENDER_TERRAIN
                    float timePrev = time - frameTime;
                    
                    #ifdef WATER_WAVE_LILY
                        if (vOut.blockId == BLOCK_LILY_PAD) {
                            vec3 originPos = vOut.localPos + at_midBlock/64.0;
                            // water_waveHeight(previousCameraPosition.xz + originPos.xz, vOut.lmcoord.y, timePrev, uvOffsetPrev);
                            //vec3 wavePosPrev = previousCameraPosition + vOut.localPos;
                            vec3 waveOffsetPrev = GetWaveHeight(previousCameraPosition + vOut.localPos, vOut.lmcoord.y, timePrev, WATER_WAVE_DETAIL_VERTEX);
                            //uvOffsetPrev *= 0.5;

                            vOut.velocity.xz += distF * (waveOffset.xz - waveOffsetPrev.xz);
                        }
                    #endif
                    
                    // float waveOffsetPrev = distF * water_waveHeight(vOut.localPos.xz + previousCameraPosition.xz + uvOffset, vOut.lmcoord.y, timePrev, _o);
                    vec3 waveOffsetPrev = GetWaveHeight(previousCameraPosition + vOut.localPos, vOut.lmcoord.y, timePrev, WATER_WAVE_DETAIL_VERTEX);
                    vOut.velocity.y += distF * (waveOffset.y - waveOffsetPrev.y);
                #endif
            #endif

            viewPos = mul3(gl_ModelViewMatrix, pos.xyz);
        }
    #endif

    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    #if WORLD_CURVE_RADIUS > 0
        float angleY = 1.0;

        #ifdef WORLD_CURVE_SHADOWS
            vOut.localPos = GetWorldCurvedPosition(vOut.localPos, angleY);
            viewPos = mul3(gbufferModelView, vOut.localPos);

            if (vOut.localPos.y + cameraPosition.y < -WORLD_CURVE_RADIUS) viewPos = vec3(666.666);
        #else
            vec3 localPos = GetWorldCurvedPosition(vOut.localPos, angleY);
            viewPos = mul3(gbufferModelView, localPos);
        #endif

//        if (angleY <= 0.0) viewPos = vec3(666.666);
    #endif

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

        #if defined RENDER_SHADOWS_ENABLED && (!defined DEFERRED_BUFFER_ENABLED || defined RENDER_WEATHER)
            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vOut.shadowTile = -1;
            #endif

            #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED && !defined RENDER_BILLBOARD
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

            // #if defined RENDER_CLOUD_SHADOWS_ENABLED && !defined RENDER_CLOUDS && SKY_CLOUD_TYPE == CLOUD_TYPE_VANILLA
            //     vOut.cloudPos = ApplyCloudShadows(vOut.localPos);
            // #endif
        #endif
    #endif

    return vec4(viewPos, 1.0);
}
