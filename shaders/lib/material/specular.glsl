#ifdef RENDER_ENTITIES
    float GetItemRoughness(const in int itemId) {
        float smoothness = 1.0 - StaticBlockMap[itemId].materialRough;

        switch (itemId) {
            case ITEM_GOLD_ARMOR:
            case ITEM_GOLD_SWORD:
                smoothness = 0.75;
                break;
            case ITEM_IRON_ARMOR:
            case ITEM_IRON_SWORD:
                smoothness = 0.65;
                break;
        }

        return 1.0 - smoothness;
    }

    float GetItemMetalF0(const in int itemId) {
        float metal_f0 = StaticBlockMap[itemId].materialMetalF0;

        switch (itemId) {
            case ITEM_GOLD_ARMOR:
            case ITEM_GOLD_SWORD:
                metal_f0 = (231.5/255.0);
                break;
            case ITEM_IRON_ARMOR:
            case ITEM_IRON_SWORD:
                metal_f0 = (230.5/255.0);
                break;
        }

        return metal_f0;
    }
#endif

#if defined RENDER_FRAG && !(defined RENDER_CLOUDS || defined RENDER_WEATHER || defined RENDER_DEFERRED || defined RENDER_COMPOSITE) //&& (!defined RENDER_BILLBOARD || ((defined RENDER_PARTICLES || defined RENDER_TEXTURED) && defined MATERIAL_PARTICLES))
    void GetMaterialSpecular(const in int blockId, const in vec2 texcoord, const in mat2 dFdXY, out float roughness, out float metal_f0) {
        roughness = 1.0;
        metal_f0 = 0.04;

        #ifdef RENDER_ENTITIES
            if (entityId == ENTITY_PHYSICSMOD_SNOW) {
                roughness = 0.5;
                metal_f0 = 0.02;
                return;
            }
        #endif

        #if MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR
            vec2 specularMap = textureGrad(specular, texcoord, dFdXY[0], dFdXY[1]).rg;
            roughness = 1.0 - specularMap.r;
            metal_f0 = specularMap.g;
        #elif defined RENDER_ENTITIES
            switch (entityId) {
                case ENTITY_IRON_GOLEM:
                    roughness = 0.6;
                    metal_f0 = (230.5/255.0);
                    break;
            }

            #ifdef IS_IRIS
                if (currentRenderedItemId > 0) {
                    roughness = GetItemRoughness(currentRenderedItemId);
                    metal_f0 = GetItemMetalF0(currentRenderedItemId);
                }
            #endif
        // #elif defined RENDER_HAND
        //     roughness = GetItemRoughness(heldItemId);
        //     metal_f0 = GetItemMetalF0(heldItemId);
        #elif !defined RENDER_BILLBOARD
            StaticBlockData blockData = StaticBlockMap[blockId];
            roughness = blockData.materialRough;
            metal_f0 = blockData.materialMetalF0;
        #endif
    }
#endif
