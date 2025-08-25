uint GetSceneLightType(const in uint blockId) {
    uint lightType = LIGHT_NONE;
    if (blockId < 1) return lightType;

    // 200
    switch (blockId) {
        case BLOCK_LIGHT_1:
        case BLOCK_REDSTONE_ILLUMINATOR_14:
            lightType = LIGHT_BLOCK_1;
            break;
        case BLOCK_LIGHT_2:
        case BLOCK_REDSTONE_ILLUMINATOR_13:
            lightType = LIGHT_BLOCK_2;
            break;
        case BLOCK_LIGHT_3:
        case BLOCK_REDSTONE_ILLUMINATOR_12:
            lightType = LIGHT_BLOCK_3;
            break;
        case BLOCK_LIGHT_4:
        case BLOCK_REDSTONE_ILLUMINATOR_11:
            lightType = LIGHT_BLOCK_4;
            break;
        case BLOCK_LIGHT_5:
        case BLOCK_REDSTONE_ILLUMINATOR_10:
            lightType = LIGHT_BLOCK_5;
            break;
        case BLOCK_LIGHT_6:
        case BLOCK_REDSTONE_ILLUMINATOR_9:
            lightType = LIGHT_BLOCK_6;
            break;
        case BLOCK_LIGHT_7:
        case BLOCK_REDSTONE_ILLUMINATOR_8:
            lightType = LIGHT_BLOCK_7;
            break;
        case BLOCK_LIGHT_8:
        case BLOCK_REDSTONE_ILLUMINATOR_7:
            lightType = LIGHT_BLOCK_8;
            break;
        case BLOCK_LIGHT_9:
        case BLOCK_REDSTONE_ILLUMINATOR_6:
            lightType = LIGHT_BLOCK_9;
            break;
        case BLOCK_LIGHT_10:
        case BLOCK_REDSTONE_ILLUMINATOR_5:
            lightType = LIGHT_BLOCK_10;
            break;
        case BLOCK_LIGHT_11:
        case BLOCK_REDSTONE_ILLUMINATOR_4:
            lightType = LIGHT_BLOCK_11;
            break;
        case BLOCK_LIGHT_12:
        case BLOCK_REDSTONE_ILLUMINATOR_3:
            lightType = LIGHT_BLOCK_12;
            break;
        case BLOCK_LIGHT_13:
        case BLOCK_REDSTONE_ILLUMINATOR_2:
            lightType = LIGHT_BLOCK_13;
            break;
        case BLOCK_LIGHT_14:
        case BLOCK_REDSTONE_ILLUMINATOR_1:
            lightType = LIGHT_BLOCK_14;
            break;
        case BLOCK_LIGHT_15:
        case BLOCK_REDSTONE_ILLUMINATOR_0:
            lightType = LIGHT_BLOCK_15;
            break;

        case BLOCK_AMETHYST:
            lightType = LIGHT_AMETHYST_BLOCK;
            break;
        case BLOCK_AMETHYST_BUD_LARGE:
            lightType = LIGHT_AMETHYST_BUD_LARGE;
            break;
        case BLOCK_AMETHYST_BUD_MEDIUM:
            lightType = LIGHT_AMETHYST_BUD_MEDIUM;
            break;
        case BLOCK_AMETHYST_CLUSTER:
            lightType = LIGHT_AMETHYST_CLUSTER;
            break;
        case BLOCK_BEACON:
            lightType = LIGHT_BEACON;
            break;
        case BLOCK_BLAST_FURNACE_LIT_N:
            lightType = LIGHT_BLAST_FURNACE_N;
            break;
        case BLOCK_BLAST_FURNACE_LIT_E:
            lightType = LIGHT_BLAST_FURNACE_E;
            break;
        case BLOCK_BLAST_FURNACE_LIT_S:
            lightType = LIGHT_BLAST_FURNACE_S;
            break;
        case BLOCK_BLAST_FURNACE_LIT_W:
            lightType = LIGHT_BLAST_FURNACE_W;
            break;
        case BLOCK_BREWING_STAND:
            lightType = LIGHT_BREWING_STAND;
            break;
        case BLOCK_COPPER_BULB_LIT:
            lightType = LIGHT_COPPER_BULB;
            break;
        case BLOCK_COPPER_BULB_EXPOSED_LIT:
            lightType = LIGHT_COPPER_BULB_EXPOSED;
            break;
        case BLOCK_COPPER_BULB_OXIDIZED_LIT:
            lightType = LIGHT_COPPER_BULB_OXIDIZED;
            break;
        case BLOCK_COPPER_BULB_WEATHERED_LIT:
            lightType = LIGHT_COPPER_BULB_WEATHERED;
            break;
        case BLOCK_CREAKING_HEART:
            lightType = LIGHT_CREAKING_HEART;
            break;
        case BLOCK_CRYING_OBSIDIAN:
            lightType = LIGHT_CRYING_OBSIDIAN;
            break;
        case BLOCK_END_ROD:
            lightType = LIGHT_END_ROD;
            break;
        case BLOCK_CAMPFIRE_LIT_N_S:
        case BLOCK_CAMPFIRE_LIT_W_E:
            lightType = LIGHT_CAMPFIRE;
            break;
        case BLOCK_EYEBLOSSOM_OPEN:
            lightType = LIGHT_EYEBLOSSOM;
            break;
        case BLOCK_FIRE:
            lightType = LIGHT_FIRE;
            break;
        case BLOCK_FROGLIGHT_OCHRE:
            lightType = LIGHT_FROGLIGHT_OCHRE;
            break;
        case BLOCK_FROGLIGHT_PEARLESCENT:
            lightType = LIGHT_FROGLIGHT_PEARLESCENT;
            break;
        case BLOCK_FROGLIGHT_VERDANT:
            lightType = LIGHT_FROGLIGHT_VERDANT;
            break;
        case BLOCK_FURNACE_LIT_N:
            lightType = LIGHT_FURNACE_N;
            break;
        case BLOCK_FURNACE_LIT_E:
            lightType = LIGHT_FURNACE_E;
            break;
        case BLOCK_FURNACE_LIT_S:
            lightType = LIGHT_FURNACE_S;
            break;
        case BLOCK_FURNACE_LIT_W:
            lightType = LIGHT_FURNACE_W;
            break;
        case BLOCK_GLOWSTONE:
            lightType = LIGHT_GLOWSTONE;
            break;
        case BLOCK_GLOW_LICHEN:
            lightType = LIGHT_GLOW_LICHEN;
            break;
        case BLOCK_JACK_O_LANTERN_N:
            lightType = LIGHT_JACK_O_LANTERN_N;
            break;
        case BLOCK_JACK_O_LANTERN_E:
            lightType = LIGHT_JACK_O_LANTERN_E;
            break;
        case BLOCK_JACK_O_LANTERN_S:
            lightType = LIGHT_JACK_O_LANTERN_S;
            break;
        case BLOCK_JACK_O_LANTERN_W:
            lightType = LIGHT_JACK_O_LANTERN_W;
            break;
        case BLOCK_LANTERN_CEIL:
        case BLOCK_LANTERN_FLOOR:
            lightType = LIGHT_LANTERN;
            break;
        case BLOCK_LIGHTING_ROD_POWERED:
            lightType = LIGHT_LIGHTING_ROD;
            break;
        case BLOCK_MAGMA:
            lightType = LIGHT_MAGMA;
            break;
        case BLOCK_REDSTONE_LAMP_LIT:
            lightType = LIGHT_REDSTONE_LAMP;
            break;
        case BLOCK_REDSTONE_ORE_LIT:
            lightType = LIGHT_REDSTONE_ORE;
            break;
        case BLOCK_REDSTONE_TORCH_FLOOR_LIT:
            lightType = LIGHT_REDSTONE_TORCH_FLOOR;
            break;
        case BLOCK_REDSTONE_TORCH_WALL_N_LIT:
            lightType = LIGHT_REDSTONE_TORCH_WALL_N;
            break;
        case BLOCK_REDSTONE_TORCH_WALL_E_LIT:
            lightType = LIGHT_REDSTONE_TORCH_WALL_E;
            break;
        case BLOCK_REDSTONE_TORCH_WALL_S_LIT:
            lightType = LIGHT_REDSTONE_TORCH_WALL_S;
            break;
        case BLOCK_REDSTONE_TORCH_WALL_W_LIT:
            lightType = LIGHT_REDSTONE_TORCH_WALL_W;
            break;
        case BLOCK_RESPAWN_ANCHOR_1:
            lightType = LIGHT_RESPAWN_ANCHOR_1;
            break;
        case BLOCK_RESPAWN_ANCHOR_2:
            lightType = LIGHT_RESPAWN_ANCHOR_2;
            break;
        case BLOCK_RESPAWN_ANCHOR_3:
            lightType = LIGHT_RESPAWN_ANCHOR_3;
            break;
        case BLOCK_RESPAWN_ANCHOR_4:
            lightType = LIGHT_RESPAWN_ANCHOR_4;
            break;
        case BLOCK_SCULK_CATALYST:
            lightType = LIGHT_SCULK_CATALYST;
            break;
        case BLOCK_SEA_LANTERN:
            lightType = LIGHT_SEA_LANTERN;
            break;
        case BLOCK_SHROOMLIGHT:
            lightType = LIGHT_SHROOMLIGHT;
            break;
        case BLOCK_SMOKER_LIT_N:
            lightType = LIGHT_SMOKER_N;
            break;
        case BLOCK_SMOKER_LIT_E:
            lightType = LIGHT_SMOKER_E;
            break;
        case BLOCK_SMOKER_LIT_S:
            lightType = LIGHT_SMOKER_S;
            break;
        case BLOCK_SMOKER_LIT_W:
            lightType = LIGHT_SMOKER_W;
            break;
        case BLOCK_SOUL_CAMPFIRE_LIT_N_S:
        case BLOCK_SOUL_CAMPFIRE_LIT_W_E:
            lightType = LIGHT_SOUL_CAMPFIRE;
            break;
        case BLOCK_SOUL_FIRE:
            lightType = LIGHT_SOUL_FIRE;
            break;
        case BLOCK_SOUL_LANTERN_CEIL:
        case BLOCK_SOUL_LANTERN_FLOOR:
            lightType = LIGHT_SOUL_LANTERN;
            break;
        case BLOCK_SOUL_TORCH_FLOOR:
            lightType = LIGHT_SOUL_TORCH_FLOOR;
            break;
        case BLOCK_SOUL_TORCH_WALL_N:
            lightType = LIGHT_SOUL_TORCH_WALL_N;
            break;
        case BLOCK_SOUL_TORCH_WALL_E:
            lightType = LIGHT_SOUL_TORCH_WALL_E;
            break;
        case BLOCK_SOUL_TORCH_WALL_S:
            lightType = LIGHT_SOUL_TORCH_WALL_S;
            break;
        case BLOCK_SOUL_TORCH_WALL_W:
            lightType = LIGHT_SOUL_TORCH_WALL_W;
            break;
        case BLOCK_TORCH_FLOOR:
            lightType = LIGHT_TORCH_FLOOR;
            break;
        case BLOCK_TORCH_WALL_N:
            lightType = LIGHT_TORCH_WALL_N;
            break;
        case BLOCK_TORCH_WALL_E:
            lightType = LIGHT_TORCH_WALL_E;
            break;
        case BLOCK_TORCH_WALL_S:
            lightType = LIGHT_TORCH_WALL_S;
            break;
        case BLOCK_TORCH_WALL_W:
            lightType = LIGHT_TORCH_WALL_W;
            break;
        case BLOCK_END_STONE_LAMP:
            lightType = LIGHT_END_STONE_LAMP;
            break;
        case BLOCK_EDGE_LIGHT:
            lightType = LIGHT_EDGE;
            break;
    }

    // 400
    switch (blockId) {
        case BLOCK_CANDLE_CAKE_LIT:
            lightType = LIGHT_CANDLE_CAKE;
            break;
        case BLOCK_CANDLE_HOLDER_LIT_1:
            lightType = LIGHT_CANDLES_1;
            break;
        case BLOCK_CANDLE_HOLDER_LIT_2:
            lightType = LIGHT_CANDLES_2;
            break;
        case BLOCK_CANDLE_HOLDER_LIT_3:
            lightType = LIGHT_CANDLES_3;
            break;
        case BLOCK_CANDLE_HOLDER_LIT_4:
            lightType = LIGHT_CANDLES_4;
            break;
        case BLOCK_CAULDRON_LAVA:
            lightType = LIGHT_LAVA_CAULDRON;
            break;
    }

    #ifdef LIGHTING_COLORED_CANDLES
        switch (blockId) {
            case BLOCK_BLACK_CANDLES_LIT_1:
                lightType = LIGHT_BLACK_CANDLES_1;
                break;
            case BLOCK_BLACK_CANDLES_LIT_2:
                lightType = LIGHT_BLACK_CANDLES_2;
                break;
            case BLOCK_BLACK_CANDLES_LIT_3:
                lightType = LIGHT_BLACK_CANDLES_3;
                break;
            case BLOCK_BLACK_CANDLES_LIT_4:
                lightType = LIGHT_BLACK_CANDLES_4;
                break;
            case BLOCK_BLUE_CANDLES_LIT_1:
                lightType = LIGHT_BLUE_CANDLES_1;
                break;
            case BLOCK_BLUE_CANDLES_LIT_2:
                lightType = LIGHT_BLUE_CANDLES_2;
                break;
            case BLOCK_BLUE_CANDLES_LIT_3:
                lightType = LIGHT_BLUE_CANDLES_3;
                break;
            case BLOCK_BLUE_CANDLES_LIT_4:
                lightType = LIGHT_BLUE_CANDLES_4;
                break;
            case BLOCK_BROWN_CANDLES_LIT_1:
                lightType = LIGHT_BROWN_CANDLES_1;
                break;
            case BLOCK_BROWN_CANDLES_LIT_2:
                lightType = LIGHT_BROWN_CANDLES_2;
                break;
            case BLOCK_BROWN_CANDLES_LIT_3:
                lightType = LIGHT_BROWN_CANDLES_3;
                break;
            case BLOCK_BROWN_CANDLES_LIT_4:
                lightType = LIGHT_BROWN_CANDLES_4;
                break;
            case BLOCK_CYAN_CANDLES_LIT_1:
                lightType = LIGHT_CYAN_CANDLES_1;
                break;
            case BLOCK_CYAN_CANDLES_LIT_2:
                lightType = LIGHT_CYAN_CANDLES_2;
                break;
            case BLOCK_CYAN_CANDLES_LIT_3:
                lightType = LIGHT_CYAN_CANDLES_3;
                break;
            case BLOCK_CYAN_CANDLES_LIT_4:
                lightType = LIGHT_CYAN_CANDLES_4;
                break;
            case BLOCK_GRAY_CANDLES_LIT_1:
                lightType = LIGHT_GRAY_CANDLES_1;
                break;
            case BLOCK_GRAY_CANDLES_LIT_2:
                lightType = LIGHT_GRAY_CANDLES_2;
                break;
            case BLOCK_GRAY_CANDLES_LIT_3:
                lightType = LIGHT_GRAY_CANDLES_3;
                break;
            case BLOCK_GRAY_CANDLES_LIT_4:
                lightType = LIGHT_GRAY_CANDLES_4;
                break;
            case BLOCK_GREEN_CANDLES_LIT_1:
                lightType = LIGHT_GREEN_CANDLES_1;
                break;
            case BLOCK_GREEN_CANDLES_LIT_2:
                lightType = LIGHT_GREEN_CANDLES_2;
                break;
            case BLOCK_GREEN_CANDLES_LIT_3:
                lightType = LIGHT_GREEN_CANDLES_3;
                break;
            case BLOCK_GREEN_CANDLES_LIT_4:
                lightType = LIGHT_GREEN_CANDLES_4;
                break;
            case BLOCK_LIGHT_BLUE_CANDLES_LIT_1:
                lightType = LIGHT_LIGHT_BLUE_CANDLES_1;
                break;
            case BLOCK_LIGHT_BLUE_CANDLES_LIT_2:
                lightType = LIGHT_LIGHT_BLUE_CANDLES_2;
                break;
            case BLOCK_LIGHT_BLUE_CANDLES_LIT_3:
                lightType = LIGHT_LIGHT_BLUE_CANDLES_3;
                break;
            case BLOCK_LIGHT_BLUE_CANDLES_LIT_4:
                lightType = LIGHT_LIGHT_BLUE_CANDLES_4;
                break;
            case BLOCK_LIGHT_GRAY_CANDLES_LIT_1:
                lightType = LIGHT_LIGHT_GRAY_CANDLES_1;
                break;
            case BLOCK_LIGHT_GRAY_CANDLES_LIT_2:
                lightType = LIGHT_LIGHT_GRAY_CANDLES_2;
                break;
            case BLOCK_LIGHT_GRAY_CANDLES_LIT_3:
                lightType = LIGHT_LIGHT_GRAY_CANDLES_3;
                break;
            case BLOCK_LIGHT_GRAY_CANDLES_LIT_4:
                lightType = LIGHT_LIGHT_GRAY_CANDLES_4;
                break;
            case BLOCK_LIME_CANDLES_LIT_1:
                lightType = LIGHT_LIME_CANDLES_1;
                break;
            case BLOCK_LIME_CANDLES_LIT_2:
                lightType = LIGHT_LIME_CANDLES_2;
                break;
            case BLOCK_LIME_CANDLES_LIT_3:
                lightType = LIGHT_LIME_CANDLES_3;
                break;
            case BLOCK_LIME_CANDLES_LIT_4:
                lightType = LIGHT_LIME_CANDLES_4;
                break;
            case BLOCK_MAGENTA_CANDLES_LIT_1:
                lightType = LIGHT_MAGENTA_CANDLES_1;
                break;
            case BLOCK_MAGENTA_CANDLES_LIT_2:
                lightType = LIGHT_MAGENTA_CANDLES_2;
                break;
            case BLOCK_MAGENTA_CANDLES_LIT_3:
                lightType = LIGHT_MAGENTA_CANDLES_3;
                break;
            case BLOCK_MAGENTA_CANDLES_LIT_4:
                lightType = LIGHT_MAGENTA_CANDLES_4;
                break;
            case BLOCK_ORANGE_CANDLES_LIT_1:
                lightType = LIGHT_ORANGE_CANDLES_1;
                break;
            case BLOCK_ORANGE_CANDLES_LIT_2:
                lightType = LIGHT_ORANGE_CANDLES_2;
                break;
            case BLOCK_ORANGE_CANDLES_LIT_3:
                lightType = LIGHT_ORANGE_CANDLES_3;
                break;
            case BLOCK_ORANGE_CANDLES_LIT_4:
                lightType = LIGHT_ORANGE_CANDLES_4;
                break;
            case BLOCK_PINK_CANDLES_LIT_1:
                lightType = LIGHT_PINK_CANDLES_1;
                break;
            case BLOCK_PINK_CANDLES_LIT_2:
                lightType = LIGHT_PINK_CANDLES_2;
                break;
            case BLOCK_PINK_CANDLES_LIT_3:
                lightType = LIGHT_PINK_CANDLES_3;
                break;
            case BLOCK_PINK_CANDLES_LIT_4:
                lightType = LIGHT_PINK_CANDLES_4;
                break;
            case BLOCK_PURPLE_CANDLES_LIT_1:
                lightType = LIGHT_PURPLE_CANDLES_1;
                break;
            case BLOCK_PURPLE_CANDLES_LIT_2:
                lightType = LIGHT_PURPLE_CANDLES_2;
                break;
            case BLOCK_PURPLE_CANDLES_LIT_3:
                lightType = LIGHT_PURPLE_CANDLES_3;
                break;
            case BLOCK_PURPLE_CANDLES_LIT_4:
                lightType = LIGHT_PURPLE_CANDLES_4;
                break;
            case BLOCK_RED_CANDLES_LIT_1:
                lightType = LIGHT_RED_CANDLES_1;
                break;
            case BLOCK_RED_CANDLES_LIT_2:
                lightType = LIGHT_RED_CANDLES_2;
                break;
            case BLOCK_RED_CANDLES_LIT_3:
                lightType = LIGHT_RED_CANDLES_3;
                break;
            case BLOCK_RED_CANDLES_LIT_4:
                lightType = LIGHT_RED_CANDLES_4;
                break;
            case BLOCK_WHITE_CANDLES_LIT_1:
                lightType = LIGHT_WHITE_CANDLES_1;
                break;
            case BLOCK_WHITE_CANDLES_LIT_2:
                lightType = LIGHT_WHITE_CANDLES_2;
                break;
            case BLOCK_WHITE_CANDLES_LIT_3:
                lightType = LIGHT_WHITE_CANDLES_3;
                break;
            case BLOCK_WHITE_CANDLES_LIT_4:
                lightType = LIGHT_WHITE_CANDLES_4;
                break;
            case BLOCK_YELLOW_CANDLES_LIT_1:
                lightType = LIGHT_YELLOW_CANDLES_1;
                break;
            case BLOCK_YELLOW_CANDLES_LIT_2:
                lightType = LIGHT_YELLOW_CANDLES_2;
                break;
            case BLOCK_YELLOW_CANDLES_LIT_3:
                lightType = LIGHT_YELLOW_CANDLES_3;
                break;
            case BLOCK_YELLOW_CANDLES_LIT_4:
                lightType = LIGHT_YELLOW_CANDLES_4;
                break;
            case BLOCK_PLAIN_CANDLES_LIT_1:
                lightType = LIGHT_CANDLES_1;
                break;
            case BLOCK_PLAIN_CANDLES_LIT_2:
                lightType = LIGHT_CANDLES_2;
                break;
            case BLOCK_PLAIN_CANDLES_LIT_3:
                lightType = LIGHT_CANDLES_3;
                break;
            case BLOCK_PLAIN_CANDLES_LIT_4:
                lightType = LIGHT_CANDLES_4;
                break;
        }
    #else
        switch (blockId) {
            case BLOCK_CANDLES_LIT_1:
                lightType = LIGHT_CANDLES_1;
                break;
            case BLOCK_CANDLES_LIT_2:
                lightType = LIGHT_CANDLES_2;
                break;
            case BLOCK_CANDLES_LIT_3:
                lightType = LIGHT_CANDLES_3;
                break;
            case BLOCK_CANDLES_LIT_4:
                lightType = LIGHT_CANDLES_4;
                break;
        }
    #endif

    switch (blockId) {
        case BLOCK_CREATE_XP:
            lightType = LIGHT_CREATE_XP;
            break;
        case BLOCK_ROSE_QUARTZ_LAMP_LIT:
            lightType = LIGHT_ROSE_QUARTZ_LAMP;
            break;
        case BLOCK_DECO_LAMP_BLUE_LIT:
            lightType = LIGHT_DECO_LAMP_BLUE;
            break;
        case BLOCK_DECO_LAMP_GREEN_LIT:
            lightType = LIGHT_DECO_LAMP_GREEN;
            break;
        case BLOCK_DECO_LAMP_RED_LIT:
            lightType = LIGHT_DECO_LAMP_RED;
            break;
        case BLOCK_DECO_LAMP_YELLOW_LIT:
            lightType = LIGHT_DECO_LAMP_YELLOW;
            break;
    }

    switch (blockId) {
        case BLOCK_STREET_LAMP_LIT:
            lightType = LIGHT_STREET_LAMP;
            break;
        case BLOCK_SOUL_STREET_LAMP_LIT:
            lightType = LIGHT_SOUL_STREET_LAMP;
            break;
        case BLOCK_LAMP_LIT_BLACK:
        case BLOCK_PAPER_LAMP_LIT_BLACK:
        case BLOCK_CEILING_LIGHT_LIT_BLACK:
            lightType = LIGHT_PAPER_LAMP_BLACK;
            break;
        case BLOCK_LAMP_LIT_BLUE:
        case BLOCK_PAPER_LAMP_LIT_BLUE:
        case BLOCK_CEILING_LIGHT_LIT_BLUE:
            lightType = LIGHT_PAPER_LAMP_BLUE;
            break;
        case BLOCK_LAMP_LIT_BROWN:
        case BLOCK_PAPER_LAMP_LIT_BROWN:
        case BLOCK_CEILING_LIGHT_LIT_BROWN:
            lightType = LIGHT_PAPER_LAMP_BROWN;
            break;
        case BLOCK_LAMP_LIT_CYAN:
        case BLOCK_PAPER_LAMP_LIT_CYAN:
        case BLOCK_CEILING_LIGHT_LIT_CYAN:
            lightType = LIGHT_PAPER_LAMP_CYAN;
            break;
        case BLOCK_LAMP_LIT_GRAY:
        case BLOCK_PAPER_LAMP_LIT_GRAY:
        case BLOCK_CEILING_LIGHT_LIT_GRAY:
            lightType = LIGHT_PAPER_LAMP_GRAY;
            break;
        case BLOCK_LAMP_LIT_GREEN:
        case BLOCK_PAPER_LAMP_LIT_GREEN:
        case BLOCK_CEILING_LIGHT_LIT_GREEN:
            lightType = LIGHT_PAPER_LAMP_GREEN;
            break;
        case BLOCK_LAMP_LIT_LIGHT_BLUE:
        case BLOCK_PAPER_LAMP_LIT_LIGHT_BLUE:
        case BLOCK_CEILING_LIGHT_LIT_LIGHT_BLUE:
            lightType = LIGHT_PAPER_LAMP_LIGHT_BLUE;
            break;
        case BLOCK_LAMP_LIT_LIGHT_GRAY:
        case BLOCK_PAPER_LAMP_LIT_LIGHT_GRAY:
        case BLOCK_CEILING_LIGHT_LIT_LIGHT_GRAY:
            lightType = LIGHT_PAPER_LAMP_LIGHT_GRAY;
            break;
        case BLOCK_LAMP_LIT_LIME:
        case BLOCK_PAPER_LAMP_LIT_LIME:
        case BLOCK_CEILING_LIGHT_LIT_LIME:
            lightType = LIGHT_PAPER_LAMP_LIME;
            break;
        case BLOCK_LAMP_LIT_MAGENTA:
        case BLOCK_PAPER_LAMP_LIT_MAGENTA:
        case BLOCK_CEILING_LIGHT_LIT_MAGENTA:
            lightType = LIGHT_PAPER_LAMP_MAGENTA;
            break;
        case BLOCK_LAMP_LIT_ORANGE:
        case BLOCK_PAPER_LAMP_LIT_ORANGE:
        case BLOCK_CEILING_LIGHT_LIT_ORANGE:
            lightType = LIGHT_PAPER_LAMP_ORANGE;
            break;
        case BLOCK_LAMP_LIT_PINK:
        case BLOCK_PAPER_LAMP_LIT_PINK:
        case BLOCK_CEILING_LIGHT_LIT_PINK:
            lightType = LIGHT_PAPER_LAMP_PINK;
            break;
        case BLOCK_LAMP_LIT_PURPLE:
        case BLOCK_PAPER_LAMP_LIT_PURPLE:
        case BLOCK_CEILING_LIGHT_LIT_PURPLE:
            lightType = LIGHT_PAPER_LAMP_PURPLE;
            break;
        case BLOCK_LAMP_LIT_RED:
        case BLOCK_PAPER_LAMP_LIT_RED:
        case BLOCK_CEILING_LIGHT_LIT_RED:
            lightType = LIGHT_PAPER_LAMP_RED;
            break;
        case BLOCK_LAMP_LIT_WHITE:
        case BLOCK_PAPER_LAMP_LIT_WHITE:
        case BLOCK_CEILING_LIGHT_LIT_WHITE:
            lightType = LIGHT_PAPER_LAMP_WHITE;
            break;
        case BLOCK_LAMP_LIT_YELLOW:
        case BLOCK_PAPER_LAMP_LIT_YELLOW:
        case BLOCK_CEILING_LIGHT_LIT_YELLOW:
            lightType = LIGHT_PAPER_LAMP_YELLOW;
            break;
    }

    switch (blockId) {
        case BLOCK_CREATE_BLAZE_BURNER_LOW:
            lightType = LIGHT_CREATE_BLAZE_BURNER_LOW;
            break;
        case BLOCK_CREATE_BLAZE_BURNER_MEDIUM:
            lightType = LIGHT_CREATE_BLAZE_BURNER_MEDIUM;
            break;
        case BLOCK_CREATE_BLAZE_BURNER_HIGH:
            lightType = LIGHT_CREATE_BLAZE_BURNER_HIGH;
            break;
    }

    #if DYN_LIGHT_GLOW_BERRIES != DYN_LIGHT_BLOCK_NONE
        if (blockId == BLOCK_CAVEVINE_BERRIES) lightType = LIGHT_CAVEVINE_BERRIES;
    #endif

    #if DYN_LIGHT_LAVA != DYN_LIGHT_BLOCK_NONE
        if (blockId == BLOCK_LAVA) lightType = LIGHT_LAVA;
    #endif

    #if DYN_LIGHT_PORTAL != DYN_LIGHT_BLOCK_NONE
        if (blockId == BLOCK_NETHER_PORTAL) lightType = LIGHT_NETHER_PORTAL;
    #endif

    #if DYN_LIGHT_SEA_PICKLE != DYN_LIGHT_BLOCK_NONE
        switch (blockId) {
            case BLOCK_SEA_PICKLE_WET_1:
                lightType = LIGHT_SEA_PICKLE_1;
                break;
            case BLOCK_SEA_PICKLE_WET_2:
                lightType = LIGHT_SEA_PICKLE_2;
                break;
            case BLOCK_SEA_PICKLE_WET_3:
                lightType = LIGHT_SEA_PICKLE_3;
                break;
            case BLOCK_SEA_PICKLE_WET_4:
                lightType = LIGHT_SEA_PICKLE_4;
                break;
        }
    #endif

    #if DYN_LIGHT_REDSTONE != DYN_LIGHT_BLOCK_NONE
        switch (blockId) {
            case BLOCK_COMPARATOR_LIT:
                lightType = LIGHT_COMPARATOR;
                break;
            case BLOCK_RAIL_POWERED:
                lightType = LIGHT_RAIL_POWERED;
                break;
            case BLOCK_REDSTONE_WIRE_1:
                lightType = LIGHT_REDSTONE_WIRE_1;
                break;
            case BLOCK_REDSTONE_WIRE_2:
                lightType = LIGHT_REDSTONE_WIRE_2;
                break;
            case BLOCK_REDSTONE_WIRE_3:
                lightType = LIGHT_REDSTONE_WIRE_3;
                break;
            case BLOCK_REDSTONE_WIRE_4:
                lightType = LIGHT_REDSTONE_WIRE_4;
                break;
            case BLOCK_REDSTONE_WIRE_5:
                lightType = LIGHT_REDSTONE_WIRE_5;
                break;
            case BLOCK_REDSTONE_WIRE_6:
                lightType = LIGHT_REDSTONE_WIRE_6;
                break;
            case BLOCK_REDSTONE_WIRE_7:
                lightType = LIGHT_REDSTONE_WIRE_7;
                break;
            case BLOCK_REDSTONE_WIRE_8:
                lightType = LIGHT_REDSTONE_WIRE_8;
                break;
            case BLOCK_REDSTONE_WIRE_9:
                lightType = LIGHT_REDSTONE_WIRE_9;
                break;
            case BLOCK_REDSTONE_WIRE_10:
                lightType = LIGHT_REDSTONE_WIRE_10;
                break;
            case BLOCK_REDSTONE_WIRE_11:
                lightType = LIGHT_REDSTONE_WIRE_11;
                break;
            case BLOCK_REDSTONE_WIRE_12:
                lightType = LIGHT_REDSTONE_WIRE_12;
                break;
            case BLOCK_REDSTONE_WIRE_13:
                lightType = LIGHT_REDSTONE_WIRE_13;
                break;
            case BLOCK_REDSTONE_WIRE_14:
                lightType = LIGHT_REDSTONE_WIRE_14;
                break;
            case BLOCK_REDSTONE_WIRE_15:
                lightType = LIGHT_REDSTONE_WIRE_15;
                break;
            case BLOCK_REPEATER_LIT:
                lightType = LIGHT_REPEATER;
                break;
        }

        // if (blockId == BLOCK_GANTRY_SHAFT_POWERED)
        //     lightType = LIGHT_REDSTONE_WIRE_8;
    #endif

    #ifdef DYN_LIGHT_OREBLOCKS
        switch (blockId) {
            case BLOCK_DIAMOND:
                lightType = LIGHT_DIAMOND_BLOCK;
                break;
            case BLOCK_EMERALD:
                lightType = LIGHT_EMERALD_BLOCK;
                break;
            case BLOCK_LAPIS:
                lightType = LIGHT_LAPIS_BLOCK;
                break;
            case BLOCK_REDSTONE:
                lightType = LIGHT_REDSTONE_BLOCK;
                break;
        }
    #endif

    return lightType;
}
