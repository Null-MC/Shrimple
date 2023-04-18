float GetBlockRoughness(const in int blockId) {
    float smoothness = 0.1;

    switch (blockId) {
        case BLOCK_IRON_BARS:
            smoothness = 0.65;
            break;
    }

    switch (blockId) {
        case BLOCK_GOLD:
            smoothness = 0.75;
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
        case BLOCK_POLISHED:
            smoothness = 0.60;
            break;
        case BLOCK_QUARTZ:
            smoothness = 0.50;
            break;
        case BLOCK_REDSTONE:
            smoothness = 0.80;
            break;
    }

    return 1.0 - smoothness;
}

float GetBlockMetalF0(const in int blockId) {
    float metal_f0 = 0.04;

    switch (blockId) {
        case BLOCK_IRON_BARS:
            metal_f0 = (230.5/255.0);
            break;
    }

    switch (blockId) {
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

float GetMaterialF0(const in float metal_f0) {
    return metal_f0 > 0.5 ? 0.96 : 0.04;
}

void GetMaterialSpecular(const in vec2 texcoord, const in int blockId, out float roughness, out float metal_f0) {
    #if MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR
        vec2 specularMap = texture(specular, texcoord).rg;
        roughness = 1.0 - specularMap.r;
        metal_f0 = specularMap.g;
    #else
        roughness = GetBlockRoughness(blockId);
        metal_f0 = GetBlockMetalF0(blockId);
    #endif
}
