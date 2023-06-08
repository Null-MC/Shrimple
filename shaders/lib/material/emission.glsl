#ifdef IRIS_FEATURE_SSBO
    float GetSceneBlockEmission(const in int blockId) {
        uint lightType = GetSceneLightType(blockId);
        //float range = GetSceneLightRange(lightType);

        StaticLightData lightInfo = StaticLightMap[lightType];
        float range = unpackUnorm4x8(lightInfo.RangeSize).x * 255.0;

        //if (blockId == BLOCK_LAVA) range *= 2.0;
        //if (blockId == BLOCK_CAVEVINE_BERRIES) range = 0.0;

        return range / 15.0;
    }
#endif

#ifdef RENDER_FRAG
    float GetMaterialEmission(const in int id, const in vec2 texcoord, const in mat2 dFdXY) {
        float emission = 0.0;

        #if MATERIAL_EMISSION == EMISSION_OLDPBR
            emission = textureGrad(specular, texcoord, dFdXY[0], dFdXY[1]).b;
        #elif MATERIAL_EMISSION == EMISSION_LABPBR
            emission = textureGrad(specular, texcoord, dFdXY[0], dFdXY[1]).a;
            if (emission > (254.5/255.0)) emission = 0.0;
        #elif DYN_LIGHT_MODE != DYN_LIGHT_NONE
            int materialId = id;
            //if (currentRenderedItemId > 0)
            //    materialId = currentRenderedItemId;

            #ifdef RENDER_HAND
                emission = GetSceneItemLightRange(id, 0.0) / 15.0;
            #elif defined RENDER_TERRAIN || defined RENDER_WATER
                emission = GetSceneBlockEmission(id);
            #elif defined RENDER_ENTITIES
                if (currentRenderedItemId > 0) {
                    int blockId = GetItemBlockId(currentRenderedItemId);
                    
                    if (blockId > 0) {
                        emission = GetSceneBlockEmission(blockId);
                    }
                    else {
                        emission = GetSceneItemLightRange(currentRenderedItemId, 0.0) / 15.0;
                    }
                }
                else
                    emission = GetSceneEntityLightColor(id).a / 15.0;
            #endif
        #endif

        return emission;
    }
#endif
