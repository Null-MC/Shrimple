float GetSceneBlockEmission(const in int blockId) {
    uint lightType = GetSceneLightType(blockId);
    float range = GetSceneLightRange(lightType);

    if (blockId == BLOCK_LAVA) range *= 2.0;
    if (blockId == BLOCK_CAVEVINE_BERRIES) range = 0.0;

    return range / 15.0;
}

#ifdef RENDER_FRAG
    float GetMaterialEmission(const in int blockId, const in vec2 texcoord) {
        float emission = 0.0;

        #if MATERIAL_EMISSION == EMISSION_OLDPBR
            emission = texture(specular, texcoord).b;
        #elif MATERIAL_EMISSION == EMISSION_LABPBR
            emission = texture(specular, texcoord).a;
            if (emission > (254.5/255.0)) emission = 0.0;
        #elif DYN_LIGHT_MODE != DYN_LIGHT_NONE
            #if defined RENDER_TERRAIN || defined RENDER_WATER
                emission = GetSceneBlockEmission(blockId);
            #elif defined RENDER_ENTITIES
                emission = GetSceneEntityLightColor(entityId).a / 15.0;
            #endif
        #endif

        return emission;
    }
#endif
