float GetBlockRoughness(const in int blockId) {
    float smoothness = 0.1;

    switch (blockId) {
        case BLOCK_CHAIN:
        case BLOCK_IRON_BARS:
            smoothness = 0.65;
            break;
    }

    switch (blockId) {
        case BLOCK_ANVIL_N_S:
        case BLOCK_ANVIL_W_E:
            smoothness = 0.65;
            break;
    }

    switch (blockId) {
        case BLOCK_AMETHYST:
        case BLOCK_AMETHYST_CLUSTER:
        case BLOCK_AMETHYST_BUD_LARGE:
        case BLOCK_AMETHYST_BUD_SMALL:
            smoothness = 0.8;
            break;
        case BLOCK_COAL:
            smoothness = 0.60;
            break;
        case BLOCK_COPPER:
            smoothness = 0.70;
            break;
        case BLOCK_COPPER_EXPOSED:
            smoothness = 0.60;
            break;
        case BLOCK_COPPER_WEATHERED:
            smoothness = 0.40;
            break;
        case BLOCK_DIAMOND:
            smoothness = 0.85;
            break;
        case BLOCK_EMERALD:
        case BLOCK_LAPIS:
            smoothness = 0.70;
            break;
        case BLOCK_GOLD:
            smoothness = 0.75;
            break;
        case BLOCK_HONEY:
        case BLOCK_HONEYCOMB:
            smoothness = 0.60;
            break;
        case BLOCK_IRON:
            smoothness = 0.65;
            break;
        case BLOCK_MUD:
            smoothness = 0.40;
            break;
        case BLOCK_NETHERRACK:
            smoothness = 0.36;
            break;
        case BLOCK_ICE:
        case BLOCK_BLUE_ICE:
        case BLOCK_PACKED_ICE:
            smoothness = 0.75;
            break;
        case BLOCK_POLISHED:
            smoothness = 0.60;
            break;
        case BLOCK_PURPUR:
        case BLOCK_QUARTZ:
            smoothness = 0.50;
            break;
        case BLOCK_REDSTONE:
            smoothness = 0.80;
            break;
        case BLOCK_SNOW:
        case BLOCK_SNOW_LAYERS_1:
        case BLOCK_SNOW_LAYERS_2:
        case BLOCK_SNOW_LAYERS_3:
        case BLOCK_SNOW_LAYERS_4:
        case BLOCK_SNOW_LAYERS_5:
        case BLOCK_SNOW_LAYERS_6:
        case BLOCK_SNOW_LAYERS_7:
            smoothness = 0.55;
            break;
    }

    if (blockId >= BLOCK_STAINED_GLASS_BLACK && blockId <= BLOCK_STAINED_GLASS_YELLOW)
        smoothness = 0.90;

    return 1.0 - smoothness;
}

float GetItemRoughness(const in int itemId) {
    float smoothness = GetBlockRoughness(itemId);

    switch (itemId) {
        case ITEM_GOLD_ARMOR:
            smoothness = 0.75;
            break;
        case ITEM_IRON_ARMOR:
            smoothness = 0.65;
            break;
    }

    return 1.0 - smoothness;
}

float GetBlockMetalF0(const in int blockId) {
    float metal_f0 = 0.04;

    switch (blockId) {
        case BLOCK_CHAIN:
        case BLOCK_IRON_BARS:
            metal_f0 = (230.5/255.0);
            break;
        case BLOCK_BLUE_ICE:
        case BLOCK_PACKED_ICE:
            metal_f0 = 0.02;
            break;
    }

    switch (blockId) {
        case BLOCK_ANVIL_N_S:
        case BLOCK_ANVIL_W_E:
            metal_f0 = (230.5/255.0);
            break;
    }

    switch (blockId) {
        case BLOCK_DIAMOND:
            metal_f0 = 0.17;
            break;
        case BLOCK_COPPER:
        case BLOCK_COPPER_EXPOSED:
        case BLOCK_COPPER_WEATHERED:
            metal_f0 = (234.5/255.0);
            break;
        case BLOCK_GOLD:
        case BLOCK_REDSTONE:
            metal_f0 = (231.5/255.0);
            break;
        case BLOCK_IRON:
            metal_f0 = (230.5/255.0);
            break;
    }

    return metal_f0;
}

float GetItemMetalF0(const in int itemId) {
    float metal_f0 = GetBlockMetalF0(itemId);

    switch (itemId) {
        case ITEM_GOLD_ARMOR:
            metal_f0 = (231.5/255.0);
            break;
        case ITEM_IRON_ARMOR:
            metal_f0 = (230.5/255.0);
            break;
    }

    return metal_f0;
}

float GetMaterialF0(const in float metal_f0) {
    return metal_f0 > 0.5 ? 0.96 : 0.04;
}

#if defined RENDER_FRAG && !(defined RENDER_CLOUDS || defined RENDER_WEATHER || defined RENDER_TEXTURED)
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

            if (currentRenderedItemId > 0) {
                roughness = GetItemRoughness(currentRenderedItemId);
                metal_f0 = GetItemMetalF0(currentRenderedItemId);
            }
        #else
            roughness = GetBlockRoughness(blockId);
            metal_f0 = GetBlockMetalF0(blockId);
        #endif
    }
#endif
