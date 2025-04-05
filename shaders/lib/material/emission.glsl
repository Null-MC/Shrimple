float GetSceneLightEmission(const in uint lightType) {
    StaticLightData lightInfo = StaticLightMap[lightType];
    float range = unpackUnorm4x8(lightInfo.RangeSize).x * 255.0;
    return range / 15.0;
}

#ifndef RENDER_BILLBOARD
    float GetSceneBlockEmission(const in int blockId) {
        uint lightType = StaticBlockMap[blockId].lightType;
        return GetSceneLightEmission(lightType);
    }
#endif

#ifdef RENDER_FRAG
    float GetMaterialEmission(const in int id, const in vec2 texcoord, const in float mip) {
        float emission = 0.0;

        #if MATERIAL_EMISSION == EMISSION_OLDPBR
            emission = textureLod(specular, texcoord, mip).b;

            #if MATERIAL_EMISSION_POWER != 100
                emission = pow(emission, Material_EmissionPower);
            #endif
        #elif MATERIAL_EMISSION == EMISSION_LABPBR
            emission = textureLod(specular, texcoord, mip).a;
            emission = fract(emission);

            #if MATERIAL_EMISSION_POWER != 100
                emission = pow(emission, Material_EmissionPower);
            #endif
        #else //if LIGHTING_MODE != LIGHTING_MODE_NONE
            int materialId = id;
            //if (currentRenderedItemId > 0)
            //    materialId = currentRenderedItemId;

            #ifdef RENDER_HAND
                emission = GetSceneItemLightRange(id, 0.0) / 15.0;
            #elif defined RENDER_TERRAIN || defined RENDER_WATER
                emission = GetSceneBlockEmission(id);
            #elif defined RENDER_ENTITIES
                if (currentRenderedItemId > 0) {
                    uint lightId = GetItemLightId(currentRenderedItemId);
                    
                    if (lightId > 0) {
                        emission = GetSceneLightEmission(lightId);
                    }
                    else {
                        emission = GetSceneItemLightRange(currentRenderedItemId, 0.0) / 15.0;
                    }
                }
                else
                    emission = GetSceneEntityLightColor(id).a / 15.0;
            #endif

            emission = _pow3(emission);
        #endif

        return emission * Lighting_Brightness;
    }
#endif
