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

    vLocalPos = (gbufferModelViewInverse * viewPos).xyz;

    #if !(defined RENDER_BILLBOARD || defined RENDER_CLOUDS)
        vLocalNormal = vec3(0.0);
    #endif

    #ifndef RENDER_DAMAGEDBLOCK
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vBlockLight = vec3(0.0);

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
