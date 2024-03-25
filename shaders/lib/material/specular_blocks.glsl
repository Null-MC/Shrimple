float GetBlockRoughness(const in uint blockId) {
    float smoothness = 0.05;

    // 200
    switch (blockId) {
        case BLOCK_AMETHYST:
        case BLOCK_AMETHYST_CLUSTER:
        case BLOCK_AMETHYST_BUD_LARGE:
        case BLOCK_AMETHYST_BUD_SMALL:
            smoothness = 0.8;
            break;
        case BLOCK_CRYING_OBSIDIAN:
            smoothness = 0.75;
            break;
        case BLOCK_DIAMOND:
            smoothness = 0.85;
            break;
        case BLOCK_EMERALD:
        case BLOCK_LAPIS:
            smoothness = 0.70;
            break;
        case BLOCK_REDSTONE:
            smoothness = 0.80;
            break;
    }

    // 400
    switch (blockId) {
        case BLOCK_ANVIL_N_S:
        case BLOCK_ANVIL_W_E:
            smoothness = 0.65;
            break;
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

    // 500
    switch (blockId) {
        case BLOCK_HONEY:
            smoothness = 0.60;
            break;
        case BLOCK_SNOW:
            smoothness = 0.55;
            break;
    }

    // 700
    switch (blockId) {
        case BLOCK_CHAIN:
        case BLOCK_IRON_BARS:
            smoothness = 0.65;
            break;
        case BLOCK_ICE:
            smoothness = 0.75;
            break;
    }

    // 1000
    switch (blockId) {
        case BLOCK_BUDDING_AMETHYST:
            smoothness = 0.8;
            break;
        case BLOCK_CALCITE:
            smoothness = 0.4;
            break;
        case BLOCK_COAL:
            smoothness = 0.60;
            break;
        case BLOCK_CONCRETE:
            smoothness = 0.30;
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
        case BLOCK_GLAZED_TERRACOTTA:
            smoothness = 0.80;
            break;
        case BLOCK_GOLD:
            smoothness = 0.75;
            break;
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
            smoothness = 0.26;
            break;
        case BLOCK_OBSIDIAN:
            smoothness = 0.75;
            break;
        case BLOCK_BLUE_ICE:
        case BLOCK_PACKED_ICE:
            smoothness = 0.75;
            break;
        case BLOCK_POLISHED:
            smoothness = 0.60;
            break;
        case BLOCK_PURPUR:
            smoothness = 0.70;
            break;
        case BLOCK_QUARTZ:
            smoothness = 0.50;
            break;
        case BLOCK_RAW_COPPER:
        case BLOCK_RAW_GOLD:
        case BLOCK_RAW_IRON:
            smoothness = 0.5;
            break;
        case BLOCK_WOOL:
            smoothness = 0.0;
            break;
    }

    if (blockId >= BLOCK_STAINED_GLASS_BLACK && blockId <= BLOCK_TINTED_GLASS)
        smoothness = 0.90;

    return 1.0 - smoothness;
}

float GetBlockMetalF0(const in uint blockId) {
    float metal_f0 = 0.04;

    // 200
    switch (blockId) {
        case BLOCK_DIAMOND:
            metal_f0 = 0.17;
            break;
        case BLOCK_REDSTONE:
            metal_f0 = (231.5/255.0);
            break;
    }

    // 400
    switch (blockId) {
        case BLOCK_ANVIL_N_S:
        case BLOCK_ANVIL_W_E:
            metal_f0 = (230.5/255.0);
            break;
    }

    // 700
    switch (blockId) {
        case BLOCK_CHAIN:
        case BLOCK_IRON_BARS:
            metal_f0 = (230.5/255.0);
            break;
    }

    // 1000
    switch (blockId) {
        case BLOCK_BLUE_ICE:
        case BLOCK_PACKED_ICE:
            metal_f0 = 0.02;
            break;
        case BLOCK_COPPER:
        case BLOCK_COPPER_EXPOSED:
        case BLOCK_COPPER_WEATHERED:
        case BLOCK_RAW_COPPER:
            metal_f0 = (234.5/255.0);
            break;
        case BLOCK_GOLD:
        case BLOCK_RAW_GOLD:
            metal_f0 = (231.5/255.0);
            break;
        case BLOCK_IRON:
        case BLOCK_RAW_IRON:
            metal_f0 = (230.5/255.0);
            break;
    }

    return metal_f0;
}
