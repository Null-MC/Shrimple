#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    bool IsTraceEmptyBlock(const in uint blockId) {
        bool result = true;



        return result;
    }

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

        if (blockId == BLOCK_ROSE_QUARTZ_LAMP_LIT) result = true;

        if (blockId >= 1000) result = true;

        return result;
    }

    bool IsDynLightSolidBlock(const in uint blockId) {
        bool result = false;
        if (blockId < 1 || blockId >= 1000) result = true;
        if (blockId >= 400 && blockId < 700) result = true;

        if (blockId >= BLOCK_BLAST_FURNACE_LIT_N && blockId <= BLOCK_BLAST_FURNACE_LIT_W) result = true;
        if (blockId >= BLOCK_CANDLES_LIT_1 && blockId <= BLOCK_CANDLE_CAKE_LIT) result = true;
        if (blockId >= BLOCK_FURNACE_LIT_N && blockId <= BLOCK_FURNACE_LIT_W) result = true;
        if (blockId >= BLOCK_JACK_O_LANTERN_N && blockId <= BLOCK_JACK_O_LANTERN_W) result = true;
        if (blockId >= BLOCK_SMOKER_LIT_N && blockId <= BLOCK_SMOKER_LIT_W) result = true;
        
        if (blockId == BLOCK_FROGLIGHT_OCHRE) result = true;
        if (blockId == BLOCK_FROGLIGHT_PEARLESCENT) result = true;
        if (blockId == BLOCK_FROGLIGHT_VERDANT) result = true;
        if (blockId == BLOCK_GLOWSTONE) result = true;
        if (blockId == BLOCK_LANTERN_CEIL || blockId == BLOCK_SOUL_LANTERN_CEIL) result = true;
        if (blockId == BLOCK_LANTERN_FLOOR || blockId == BLOCK_SOUL_LANTERN_FLOOR) result = true;
        //if (blockId == BLOCK_LAVA_CAULDRON) result = true;
        if (blockId == BLOCK_REDSTONE_LAMP_LIT) result = true;
        if (blockId == BLOCK_SCULK_CATALYST) result = true;
        if (blockId == BLOCK_SEA_LANTERN) result = true;
        if (blockId == BLOCK_SHROOMLIGHT) result = true;

        if (blockId == BLOCK_AMETHYST || blockId == BLOCK_DIAMOND || blockId == BLOCK_EMERALD || blockId == BLOCK_LAPIS || blockId == BLOCK_REDSTONE) result = true;

        return result;
    }
#endif
