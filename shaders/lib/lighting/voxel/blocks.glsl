bool IsTraceFullBlock(const in uint blockId) {
    bool result = false;

    if (blockId == BLOCK_AMETHYST) result = true;

    if (blockId >= BLOCK_BLAST_FURNACE_LIT_N && blockId <= BLOCK_BLAST_FURNACE_LIT_W) result = true;

    if (blockId == BLOCK_CRYING_OBSIDIAN) result = true;
    if (blockId == BLOCK_DIAMOND) result = true;
    if (blockId == BLOCK_EMERALD) result = true;

    if (blockId >= BLOCK_FROGLIGHT_OCHRE && blockId <= BLOCK_FROGLIGHT_VERDANT) result = true;

    if (blockId >= BLOCK_FURNACE_LIT_N && blockId <= BLOCK_FURNACE_LIT_W) result = true;

    if (blockId == BLOCK_GLOWSTONE) result = true;
    if (blockId == BLOCK_LAPIS) result = true;

    if (blockId >= BLOCK_JACK_O_LANTERN_N && blockId <= BLOCK_JACK_O_LANTERN_W) result = true;

    if (blockId == BLOCK_MAGMA) result = true;
    if (blockId == BLOCK_REDSTONE) result = true;
    if (blockId == BLOCK_REDSTONE_LAMP_LIT) result = true;
    if (blockId == BLOCK_SEA_LANTERN) result = true;
    if (blockId == BLOCK_SHROOMLIGHT) result = true;

    if (blockId >= BLOCK_SMOKER_LIT_N && blockId <= BLOCK_SMOKER_LIT_W) result = true;

    if (blockId == BLOCK_CREATE_XP) result = true;
    if (blockId == BLOCK_ROSE_QUARTZ_LAMP_LIT) result = true;

    if (blockId >= 1000) result = true;

    return result;
}

bool IsTraceEmptyBlock(const in uint blockId) {
    bool result = false;

    if (blockId < 200) result = true;

    return result;
}

bool IsTraceOpenBlock(const in uint blockId) {
    bool result = blockId < 200;

    if (blockId >= 700 && blockId < 1000) result = true;

    if (blockId >= BLOCK_BUTTON_FLOOR_N_S && blockId <= BLOCK_BUTTON_WALL_W) result = true;

    if (blockId == BLOCK_CARPET) result = true;

    if (blockId >= BLOCK_FENCE_POST && blockId <= BLOCK_FENCE_GATE_CLOSED_W_E) result = true;

    if (blockId >= BLOCK_LEVER_FLOOR_N_S && blockId <= BLOCK_LEVER_WALL_W) result = true;

    if (blockId >= BLOCK_LIGHTNING_ROD_N && blockId <= BLOCK_LIGHTNING_ROD_DOWN) result = true;

    if (blockId == BLOCK_PRESSURE_PLATE || blockId == BLOCK_PRESSURE_PLATE_DOWN) result = true;

    if (blockId >= BLOCK_HONEY && blockId <= BLOCK_STAINED_GLASS_YELLOW) result = true;

    if (blockId >= BLOCK_SNOW_LAYERS_1 && blockId <= BLOCK_SNOW_LAYERS_3) result = true;

    if (blockId >= BLOCK_TRIPWIRE_HOOK_N && blockId <= BLOCK_TRIPWIRE_HOOK_W) result = true;

    if (blockId >= BLOCK_TORCH_FLOOR && blockId <= BLOCK_TORCH_WALL_W) result = true;

    if (blockId >= BLOCK_REDSTONE_TORCH_FLOOR_LIT && blockId <= BLOCK_REDSTONE_TORCH_WALL_W_LIT) result = true;

    if (blockId >= BLOCK_SOUL_TORCH_FLOOR && blockId <= BLOCK_SOUL_TORCH_WALL_W) result = true;

    if (blockId >= BLOCK_SIGN_WALL_N && blockId <= BLOCK_SIGN_WALL_W) result = true;

    return result;
}
