#ifdef RENDER_SETUP_STATIC_LIGHT
    vec3 GetSceneLightColor(const in uint lightType) {
        vec3 lightColor = vec3(0.0);

        switch (lightType) {
            case LIGHT_BLOCK_1:
            case LIGHT_BLOCK_2:
            case LIGHT_BLOCK_3:
            case LIGHT_BLOCK_4:
            case LIGHT_BLOCK_5:
            case LIGHT_BLOCK_6:
            case LIGHT_BLOCK_7:
            case LIGHT_BLOCK_8:
            case LIGHT_BLOCK_9:
            case LIGHT_BLOCK_10:
            case LIGHT_BLOCK_11:
            case LIGHT_BLOCK_12:
            case LIGHT_BLOCK_13:
            case LIGHT_BLOCK_14:
            case LIGHT_BLOCK_15:
                lightColor = vec3(0.9);
                break;
            case LIGHT_AMETHYST_BUD_LARGE:
            case LIGHT_AMETHYST_BUD_MEDIUM:
            case LIGHT_AMETHYST_CLUSTER:
                lightColor = LIGHT_COLOR_AMETHYST;
                break;
            case LIGHT_BEACON:
                lightColor = LIGHT_COLOR_BEACON;
                break;
            case LIGHT_BLAST_FURNACE_N:
            case LIGHT_BLAST_FURNACE_E:
            case LIGHT_BLAST_FURNACE_S:
            case LIGHT_BLAST_FURNACE_W:
                lightColor = vec3(0.798, 0.519, 0.289);
                break;
            case LIGHT_BREWING_STAND:
                lightColor = LIGHT_COLOR_BREWING_STAND;
                break;
            case LIGHT_CANDLE_CAKE:
                lightColor = vec3(0.758, 0.553, 0.239);
                break;
            case LIGHT_CAVEVINE_BERRIES:
                lightColor = LIGHT_COLOR_CAVEVINE_BERRIES;
                break;
            case LIGHT_COPPER_BULB:
            case LIGHT_COPPER_BULB_EXPOSED:
            case LIGHT_COPPER_BULB_OXIDIZED:
            case LIGHT_COPPER_BULB_WEATHERED:
                lightColor = vec3(0.9, 0.8, 0.5);
                break;
            case LIGHT_CRYING_OBSIDIAN:
                lightColor = LIGHT_COLOR_CRYING_OBSIDIAN;
                break;
            case LIGHT_END_ROD:
                lightColor = LIGHT_COLOR_END_ROD;
                break;
            case LIGHT_END_STONE_LAMP:
                lightColor = vec3(0.465, 0.143, 0.416);
                break;
            case LIGHT_CAMPFIRE:
            case LIGHT_FIRE:
                lightColor = LIGHT_COLOR_FIRE;
                break;
            case LIGHT_FROGLIGHT_OCHRE:
                lightColor = LIGHT_COLOR_FROGLIGHT_OCHRE;
                break;
            case LIGHT_FROGLIGHT_PEARLESCENT:
                lightColor = LIGHT_COLOR_FROGLIGHT_PEARLESCENT;
                break;
            case LIGHT_FROGLIGHT_VERDANT:
                lightColor = LIGHT_COLOR_FROGLIGHT_VERDANT;
                break;
            case LIGHT_FURNACE_N:
            case LIGHT_FURNACE_E:
            case LIGHT_FURNACE_S:
            case LIGHT_FURNACE_W:
                lightColor = vec3(0.798, 0.519, 0.289);
                break;
            case LIGHT_GLOWSTONE:
            case LIGHT_GLOWSTONE_DUST:
                lightColor = LIGHT_COLOR_GLOWSTONE;
                break;
            case LIGHT_GLOW_LICHEN:
                lightColor = LIGHT_COLOR_GLOW_LICHEN;
                break;
            case LIGHT_JACK_O_LANTERN_N:
            case LIGHT_JACK_O_LANTERN_E:
            case LIGHT_JACK_O_LANTERN_S:
            case LIGHT_JACK_O_LANTERN_W:
                lightColor = LIGHT_COLOR_JACK_O_LANTERN;
                break;
            case LIGHT_LANTERN:
            case LIGHT_STREET_LAMP:
                lightColor = vec3(0.906, 0.737, 0.451);
                break;
            case LIGHT_LIGHTING_ROD:
                lightColor = vec3(0.870, 0.956, 0.975);
                break;
            case LIGHT_LAVA:
            case LIGHT_LAVA_CAULDRON:
                lightColor = LIGHT_COLOR_LAVA;
                break;
            case LIGHT_MAGMA:
                lightColor = LIGHT_COLOR_MAGMA;
                break;
            case LIGHT_NETHER_PORTAL:
                lightColor = LIGHT_COLOR_NETHER_PORTAL;
                break;
            case LIGHT_REDSTONE_LAMP:
                lightColor = LIGHT_COLOR_REDSTONE_LAMP;
                break;
            case LIGHT_REDSTONE_ORE:
            case LIGHT_REDSTONE_TORCH_FLOOR:
            case LIGHT_REDSTONE_TORCH_WALL_N:
            case LIGHT_REDSTONE_TORCH_WALL_E:
            case LIGHT_REDSTONE_TORCH_WALL_S:
            case LIGHT_REDSTONE_TORCH_WALL_W:
            case LIGHT_COMPARATOR:
            case LIGHT_REPEATER:
            case LIGHT_REDSTONE_WIRE_1:
            case LIGHT_REDSTONE_WIRE_2:
            case LIGHT_REDSTONE_WIRE_3:
            case LIGHT_REDSTONE_WIRE_4:
            case LIGHT_REDSTONE_WIRE_5:
            case LIGHT_REDSTONE_WIRE_6:
            case LIGHT_REDSTONE_WIRE_7:
            case LIGHT_REDSTONE_WIRE_8:
            case LIGHT_REDSTONE_WIRE_9:
            case LIGHT_REDSTONE_WIRE_10:
            case LIGHT_REDSTONE_WIRE_11:
            case LIGHT_REDSTONE_WIRE_12:
            case LIGHT_REDSTONE_WIRE_13:
            case LIGHT_REDSTONE_WIRE_14:
            case LIGHT_REDSTONE_WIRE_15:
            case LIGHT_RAIL_POWERED:
                lightColor = LIGHT_COLOR_REDSTONE_TORCH;
                break;
            case LIGHT_RESPAWN_ANCHOR_4:
            case LIGHT_RESPAWN_ANCHOR_3:
            case LIGHT_RESPAWN_ANCHOR_2:
            case LIGHT_RESPAWN_ANCHOR_1:
                lightColor = vec3(0.390, 0.065, 0.646);
                break;
            case LIGHT_SCULK_CATALYST:
                lightColor = LIGHT_COLOR_SCULK_CATALYST;
                break;
            case LIGHT_SEA_LANTERN:
                lightColor = LIGHT_COLOR_SEA_LANTERN;
                break;
            case LIGHT_SEA_PICKLE_1:
            case LIGHT_SEA_PICKLE_2:
            case LIGHT_SEA_PICKLE_3:
            case LIGHT_SEA_PICKLE_4:
                lightColor = LIGHT_COLOR_SEA_PICKLE;
                break;
            case LIGHT_SHROOMLIGHT:
                lightColor = LIGHT_COLOR_SHROOMLIGHT;
                break;
            case LIGHT_SMOKER_N:
            case LIGHT_SMOKER_E:
            case LIGHT_SMOKER_S:
            case LIGHT_SMOKER_W:
                lightColor = vec3(0.798, 0.519, 0.289);
                break;
            case LIGHT_SOUL_LANTERN:
            case LIGHT_SOUL_TORCH_FLOOR:
            case LIGHT_SOUL_TORCH_WALL_N:
            case LIGHT_SOUL_TORCH_WALL_E:
            case LIGHT_SOUL_TORCH_WALL_S:
            case LIGHT_SOUL_TORCH_WALL_W:
            case LIGHT_SOUL_CAMPFIRE:
            case LIGHT_SOUL_FIRE:
            case LIGHT_SOUL_STREET_LAMP:
                //lightColor = vec3(0.203, 0.725, 0.758);
                lightColor = vec3(0.097, 0.721, 0.899);
                break;
            case LIGHT_TORCH_FLOOR:
            case LIGHT_TORCH_WALL_N:
            case LIGHT_TORCH_WALL_E:
            case LIGHT_TORCH_WALL_S:
            case LIGHT_TORCH_WALL_W:
                //lightColor = vec3(0.899, 0.625, 0.253);
                lightColor = vec3(0.960, 0.570, 0.277);
                break;
        }

        #ifdef LIGHTING_COLORED_CANDLES
            switch (lightType) {
                case LIGHT_BLACK_CANDLES_1:
                case LIGHT_BLACK_CANDLES_2:
                case LIGHT_BLACK_CANDLES_3:
                case LIGHT_BLACK_CANDLES_4:
                    lightColor = vec3(0.200, 0.200, 0.200);
                    break;
                case LIGHT_BLUE_CANDLES_1:
                case LIGHT_BLUE_CANDLES_2:
                case LIGHT_BLUE_CANDLES_3:
                case LIGHT_BLUE_CANDLES_4:
                    lightColor = vec3(0.000, 0.259, 1.000);
                    break;
                case LIGHT_BROWN_CANDLES_1:
                case LIGHT_BROWN_CANDLES_2:
                case LIGHT_BROWN_CANDLES_3:
                case LIGHT_BROWN_CANDLES_4:
                    lightColor = vec3(0.459, 0.263, 0.149);
                    break;
                case LIGHT_CYAN_CANDLES_1:
                case LIGHT_CYAN_CANDLES_2:
                case LIGHT_CYAN_CANDLES_3:
                case LIGHT_CYAN_CANDLES_4:
                    lightColor = vec3(0.000, 0.839, 0.839);
                    break;
                case LIGHT_GRAY_CANDLES_1:
                case LIGHT_GRAY_CANDLES_2:
                case LIGHT_GRAY_CANDLES_3:
                case LIGHT_GRAY_CANDLES_4:
                    lightColor = vec3(0.329, 0.357, 0.388);
                    break;
                case LIGHT_GREEN_CANDLES_1:
                case LIGHT_GREEN_CANDLES_2:
                case LIGHT_GREEN_CANDLES_3:
                case LIGHT_GREEN_CANDLES_4:
                    lightColor = vec3(0.263, 0.451, 0.000);
                    break;
                case LIGHT_LIGHT_BLUE_CANDLES_1:
                case LIGHT_LIGHT_BLUE_CANDLES_2:
                case LIGHT_LIGHT_BLUE_CANDLES_3:
                case LIGHT_LIGHT_BLUE_CANDLES_4:
                    lightColor = vec3(0.153, 0.686, 1.000);
                    break;
                case LIGHT_LIGHT_GRAY_CANDLES_1:
                case LIGHT_LIGHT_GRAY_CANDLES_2:
                case LIGHT_LIGHT_GRAY_CANDLES_3:
                case LIGHT_LIGHT_GRAY_CANDLES_4:
                    lightColor = vec3(0.631, 0.627, 0.624);
                    break;
                case LIGHT_LIME_CANDLES_1:
                case LIGHT_LIME_CANDLES_2:
                case LIGHT_LIME_CANDLES_3:
                case LIGHT_LIME_CANDLES_4:
                    lightColor = vec3(0.439, 0.890, 0.000);
                    break;
                case LIGHT_MAGENTA_CANDLES_1:
                case LIGHT_MAGENTA_CANDLES_2:
                case LIGHT_MAGENTA_CANDLES_3:
                case LIGHT_MAGENTA_CANDLES_4:
                    lightColor = vec3(0.757, 0.098, 0.812);
                    break;
                case LIGHT_ORANGE_CANDLES_1:
                case LIGHT_ORANGE_CANDLES_2:
                case LIGHT_ORANGE_CANDLES_3:
                case LIGHT_ORANGE_CANDLES_4:
                    lightColor = vec3(1.000, 0.459, 0.000);
                    break;
                case LIGHT_PINK_CANDLES_1:
                case LIGHT_PINK_CANDLES_2:
                case LIGHT_PINK_CANDLES_3:
                case LIGHT_PINK_CANDLES_4:
                    lightColor = vec3(1.000, 0.553, 0.718);
                    break;
                case LIGHT_PURPLE_CANDLES_1:
                case LIGHT_PURPLE_CANDLES_2:
                case LIGHT_PURPLE_CANDLES_3:
                case LIGHT_PURPLE_CANDLES_4:
                    lightColor = vec3(0.569, 0.000, 1.000);
                    break;
                case LIGHT_RED_CANDLES_1:
                case LIGHT_RED_CANDLES_2:
                case LIGHT_RED_CANDLES_3:
                case LIGHT_RED_CANDLES_4:
                    lightColor = vec3(0.859, 0.000, 0.000);
                    break;
                case LIGHT_WHITE_CANDLES_1:
                case LIGHT_WHITE_CANDLES_2:
                case LIGHT_WHITE_CANDLES_3:
                case LIGHT_WHITE_CANDLES_4:
                    lightColor = vec3(1.000, 1.000, 1.000);
                    break;
                case LIGHT_YELLOW_CANDLES_1:
                case LIGHT_YELLOW_CANDLES_2:
                case LIGHT_YELLOW_CANDLES_3:
                case LIGHT_YELLOW_CANDLES_4:
                    lightColor = vec3(1.000, 0.878, 0.000);
                    break;
            }
        #else
            switch (lightType) {
                case LIGHT_CANDLES_1:
                case LIGHT_CANDLES_2:
                case LIGHT_CANDLES_3:
                case LIGHT_CANDLES_4:
                    lightColor = vec3(0.758, 0.553, 0.239);
                    break;
            }
        #endif

        #ifdef DYN_LIGHT_OREBLOCKS
            switch (lightType) {
                case LIGHT_AMETHYST_BLOCK:
                    lightColor = LIGHT_COLOR_AMETHYST;
                    break;
                case LIGHT_DIAMOND_BLOCK:
                    lightColor = vec3(0.489, 0.960, 0.912);
                    break;
                case LIGHT_EMERALD_BLOCK:
                    lightColor = vec3(0.235, 0.859, 0.435);
                    break;
                case LIGHT_LAPIS_BLOCK:
                    lightColor = vec3(0.180, 0.427, 0.813);
                    break;
                case LIGHT_REDSTONE_BLOCK:
                    lightColor = LIGHT_COLOR_REDSTONE_TORCH;
                    break;
            }
        #endif

        switch (lightType) {
            case LIGHT_CREATE_XP:
                lightColor = vec3(0.635, 0.89, 0.278);
                break;
            case LIGHT_ROSE_QUARTZ_LAMP:
                lightColor = vec3(0.898, 0.369, 0.459);
                break;
            case LIGHT_DECO_LAMP_BLUE:
                lightColor = vec3(0.176, 0.329, 0.608);
                break;
            case LIGHT_DECO_LAMP_GREEN:
                lightColor = vec3(0.197, 0.596, 0.048);
                break;
            case LIGHT_DECO_LAMP_RED:
                lightColor = vec3(0.682, 0.064, 0.064);
                break;
            case LIGHT_DECO_LAMP_YELLOW:
                lightColor = vec3(0.818, 0.727, 0.066);
                break;
        }

        switch (lightType) {
            case LIGHT_PAPER_LAMP_BLACK:
                lightColor = vec3(0.145, 0.145, 0.145);
                break;
            case LIGHT_PAPER_LAMP_BLUE:
                lightColor = vec3(0.176, 0.329, 0.608);
                break;
            case LIGHT_PAPER_LAMP_BROWN:
                lightColor = vec3(0.600, 0.337, 0.137);
                break;
            case LIGHT_PAPER_LAMP_CYAN:
                lightColor = vec3(0.212, 0.522, 0.522);
                break;
            case LIGHT_PAPER_LAMP_GRAY:
                lightColor = vec3(0.263, 0.263, 0.263);
                break;
            case LIGHT_PAPER_LAMP_GREEN:
                lightColor = vec3(0.306, 0.435, 0.145);
                break;
            case LIGHT_PAPER_LAMP_LIGHT_BLUE:
                lightColor = vec3(0.322, 0.624, 0.890);
                break;
            case LIGHT_PAPER_LAMP_LIGHT_GRAY:
                lightColor = vec3(0.525, 0.525, 0.525);
                break;
            case LIGHT_PAPER_LAMP_LIME:
                lightColor = vec3(0.545, 0.835, 0.192);
                break;
            case LIGHT_PAPER_LAMP_MAGENTA:
                lightColor = vec3(0.773, 0.255, 0.675);
                break;
            case LIGHT_PAPER_LAMP_ORANGE:
                lightColor = vec3(0.882, 0.588, 0.180);
                break;
            case LIGHT_PAPER_LAMP_PINK:
                lightColor = vec3(0.941, 0.490, 0.667);
                break;
            case LIGHT_PAPER_LAMP_PURPLE:
                lightColor = vec3(0.620, 0.306, 0.710);
                break;
            case LIGHT_PAPER_LAMP_RED:
                lightColor = vec3(0.784, 0.243, 0.243);
                break;
            case LIGHT_PAPER_LAMP_WHITE:
                lightColor = vec3(0.875, 0.875, 0.875);
                break;
            case LIGHT_PAPER_LAMP_YELLOW:
                lightColor = vec3(0.867, 0.835, 0.271);
                break;
        }

        // #ifdef MAGNIFICENT_COLORS
        //     if (lightType == LIGHT_SEA_LANTERN) lightColor = vec3(0.2, 0.8, 1.0) * .5;
        //     if (lightType == LIGHT_GLOWSTONE) lightColor = vec3(1.0, 0.7, 0.4);
        //     if (lightType == LIGHT_END_ROD) lightColor = vec3(0.7, 0.5, 0.9) * 1.1;
        //     if (lightType >= LIGHT_TORCH_FLOOR && lightType <= LIGHT_TORCH_WALL_W) lightColor = vec3(1.00, 0.60, 0.30);
        //     if (lightType >= LIGHT_REDSTONE_TORCH_FLOOR && lightType <= LIGHT_REDSTONE_TORCH_WALL_W) lightColor = vec3(1.00, 0.30, 0.10);
        //     if (lightType == LIGHT_FIRE) lightColor = vec3(1.00, 0.40, 0.20);
        //     if (lightType == LIGHT_CAMPFIRE || lightType == LIGHT_LANTERN || (lightType >= LIGHT_FURNACE_N && lightType <= LIGHT_FURNACE_W)) lightColor = vec3(1.00, 0.60, 0.30);
        //     if (lightType == LIGHT_SOUL_CAMPFIRE || lightType == LIGHT_SOUL_LANTERN || lightType == LIGHT_SOUL_FIRE || (lightType >= LIGHT_SOUL_TORCH_FLOOR && lightType <= LIGHT_SOUL_TORCH_WALL_W)) lightColor = vec3(0.1, 0.8, 1.0);
        //     if (lightType == LIGHT_LAVA) lightColor = vec3(1.0, 0.5, 0.2);
        //     if (lightType == LIGHT_REDSTONE_LAMP) lightColor = vec3(1.0, 0.6, 0.4);
        //     if (lightType == LIGHT_BEACON) lightColor = vec3(0.6, 0.7, 1.0);
        //     if (lightType == LIGHT_MAGMA) lightColor = vec3(1.0, 0.2, 0.1);
        //     if (lightType == LIGHT_SHROOMLIGHT) lightColor = vec3(0.8, 0.4, 0.0);
        // #endif
        
        return lightColor;
    }

    float GetSceneLightRange(const in uint lightType) {
        float lightRange = 0.0;

        switch (lightType) {
            case LIGHT_BLOCK_1:
                lightRange = 1.0;
                break;
            case LIGHT_BLOCK_2:
                lightRange = 2.0;
                break;
            case LIGHT_BLOCK_3:
                lightRange = 3.0;
                break;
            case LIGHT_BLOCK_4:
                lightRange = 4.0;
                break;
            case LIGHT_BLOCK_5:
                lightRange = 5.0;
                break;
            case LIGHT_BLOCK_6:
                lightRange = 6.0;
                break;
            case LIGHT_BLOCK_7:
                lightRange = 7.0;
                break;
            case LIGHT_BLOCK_8:
                lightRange = 8.0;
                break;
            case LIGHT_BLOCK_9:
                lightRange = 9.0;
                break;
            case LIGHT_BLOCK_10:
                lightRange = 10.0;
                break;
            case LIGHT_BLOCK_11:
                lightRange = 11.0;
                break;
            case LIGHT_BLOCK_12:
                lightRange = 12.0;
                break;
            case LIGHT_BLOCK_13:
                lightRange = 13.0;
                break;
            case LIGHT_BLOCK_14:
                lightRange = 14.0;
                break;
            case LIGHT_BLOCK_15:
                lightRange = 15.0;
                break;
            case LIGHT_AMETHYST_BUD_LARGE:
                lightRange = 4.0;
                break;
            case LIGHT_AMETHYST_BUD_MEDIUM:
                lightRange = 2.0;
                break;
            case LIGHT_AMETHYST_CLUSTER:
                lightRange = 5.0;
                break;
            case LIGHT_BEACON:
                lightRange = 15.0;
                break;
            case LIGHT_BLAST_FURNACE_N:
            case LIGHT_BLAST_FURNACE_E:
            case LIGHT_BLAST_FURNACE_S:
            case LIGHT_BLAST_FURNACE_W:
                lightRange = 6.0;
                break;
            case LIGHT_BREWING_STAND:
                lightRange = 2.0;
                break;
            case LIGHT_CANDLE_CAKE:
                lightRange = 3.0;
                break;
            case LIGHT_CAVEVINE_BERRIES:
                lightRange = 14.0;
                break;
            case LIGHT_COMPARATOR:
                lightRange = 7.0;
                break;
            case LIGHT_COPPER_BULB:
                lightRange = 15.0;
                break;
            case LIGHT_COPPER_BULB_EXPOSED:
                lightRange = 12.0;
                break;
            case LIGHT_COPPER_BULB_OXIDIZED:
                lightRange = 4.0;
                break;
            case LIGHT_COPPER_BULB_WEATHERED:
                lightRange = 8.0;
                break;
            case LIGHT_CRYING_OBSIDIAN:
                lightRange = 10.0;
                break;
            case LIGHT_END_ROD:
                lightRange = 14.0;
                break;
            case LIGHT_END_STONE_LAMP:
            case LIGHT_CAMPFIRE:
            case LIGHT_FIRE:
                lightRange = 15.0;
                break;
            case LIGHT_FROGLIGHT_OCHRE:
                lightRange = 15.0;
                break;
            case LIGHT_FROGLIGHT_PEARLESCENT:
                lightRange = 15.0;
                break;
            case LIGHT_FROGLIGHT_VERDANT:
                lightRange = 15.0;
                break;
            case LIGHT_FURNACE_N:
            case LIGHT_FURNACE_E:
            case LIGHT_FURNACE_S:
            case LIGHT_FURNACE_W:
                lightRange = 6.0;
                break;
            case LIGHT_GLOWSTONE:
                lightRange = 15.0;
                break;
            case LIGHT_GLOWSTONE_DUST:
                lightRange = 6.0;
                break;
            case LIGHT_GLOW_LICHEN:
                lightRange = 7.0;
                break;
            case LIGHT_JACK_O_LANTERN_N:
            case LIGHT_JACK_O_LANTERN_E:
            case LIGHT_JACK_O_LANTERN_S:
            case LIGHT_JACK_O_LANTERN_W:
                lightRange = 15.0;
                break;
            case LIGHT_LANTERN:
                lightRange = 12.0;
                break;
            case LIGHT_LAVA:
                lightRange = 15.0;
                break;
            case LIGHT_LAVA_CAULDRON:
                lightRange = 15.0;
                break;
            case LIGHT_LIGHTING_ROD:
                lightRange = 8.0;
                break;
            case LIGHT_MAGMA:
                lightRange = 3.0;
                break;
            case LIGHT_NETHER_PORTAL:
                lightRange = 11.0;
                break;
            case LIGHT_REDSTONE_LAMP:
                lightRange = 15.0;
                break;
            case LIGHT_REDSTONE_ORE:
                lightRange = 9;
                break;
            case LIGHT_REDSTONE_TORCH_FLOOR:
            case LIGHT_REDSTONE_TORCH_WALL_N:
            case LIGHT_REDSTONE_TORCH_WALL_E:
            case LIGHT_REDSTONE_TORCH_WALL_S:
            case LIGHT_REDSTONE_TORCH_WALL_W:
                lightRange = 7.0;
                break;
            case LIGHT_REDSTONE_WIRE_1:
                lightRange = 1.0;
                break;
            case LIGHT_REDSTONE_WIRE_2:
                lightRange = 1.5;
                break;
            case LIGHT_REDSTONE_WIRE_3:
                lightRange = 2.0;
                break;
            case LIGHT_REDSTONE_WIRE_4:
                lightRange = 2.5;
                break;
            case LIGHT_REDSTONE_WIRE_5:
                lightRange = 3.0;
                break;
            case LIGHT_REDSTONE_WIRE_6:
                lightRange = 3.5;
                break;
            case LIGHT_REDSTONE_WIRE_7:
                lightRange = 4.0;
                break;
            case LIGHT_REDSTONE_WIRE_8:
                lightRange = 4.5;
                break;
            case LIGHT_REDSTONE_WIRE_9:
                lightRange = 5.0;
                break;
            case LIGHT_REDSTONE_WIRE_10:
                lightRange = 5.5;
                break;
            case LIGHT_REDSTONE_WIRE_11:
                lightRange = 6.0;
                break;
            case LIGHT_REDSTONE_WIRE_12:
                lightRange = 6.5;
                break;
            case LIGHT_REDSTONE_WIRE_13:
                lightRange = 7.0;
                break;
            case LIGHT_REDSTONE_WIRE_14:
                lightRange = 7.5;
                break;
            case LIGHT_REDSTONE_WIRE_15:
                lightRange = 8.0;
                break;
            case LIGHT_REPEATER:
                lightRange = 7.0;
                break;
            case LIGHT_RESPAWN_ANCHOR_1:
                lightRange = 3.0;
                break;
            case LIGHT_RESPAWN_ANCHOR_2:
                lightRange = 7.0;
                break;
            case LIGHT_RESPAWN_ANCHOR_3:
                lightRange = 11.0;
                break;
            case LIGHT_RESPAWN_ANCHOR_4:
                lightRange = 15.0;
                break;
            case LIGHT_SCULK_CATALYST:
                lightRange = 6.0;
                break;
            case LIGHT_SEA_LANTERN:
                lightRange = 15.0;
                break;
            case LIGHT_SEA_PICKLE_1:
                lightRange = 6.0;
                break;
            case LIGHT_SEA_PICKLE_2:
                lightRange = 9.0;
                break;
            case LIGHT_SEA_PICKLE_3:
                lightRange = 12.0;
                break;
            case LIGHT_SEA_PICKLE_4:
                lightRange = 15.0;
                break;
            case LIGHT_SHROOMLIGHT:
                lightRange = 15.0;
                break;
            case LIGHT_SMOKER_N:
            case LIGHT_SMOKER_E:
            case LIGHT_SMOKER_S:
            case LIGHT_SMOKER_W:
                lightRange = 6.0;
                break;
            case LIGHT_SOUL_CAMPFIRE:
            case LIGHT_SOUL_FIRE:
            case LIGHT_SOUL_LANTERN:
                lightRange = 12.0;
                break;
            case LIGHT_SOUL_TORCH_FLOOR:
            case LIGHT_SOUL_TORCH_WALL_N:
            case LIGHT_SOUL_TORCH_WALL_E:
            case LIGHT_SOUL_TORCH_WALL_S:
            case LIGHT_SOUL_TORCH_WALL_W:
                lightRange = 10.0;
                break;
            case LIGHT_TORCH_FLOOR:
            case LIGHT_TORCH_WALL_N:
            case LIGHT_TORCH_WALL_E:
            case LIGHT_TORCH_WALL_S:
            case LIGHT_TORCH_WALL_W:
                lightRange = 12.0;
                break;
        }

        #ifdef LIGHTING_COLORED_CANDLES
            switch (lightType) {
                case LIGHT_CANDLES_1:
                case LIGHT_BLACK_CANDLES_1:
                case LIGHT_BLUE_CANDLES_1:
                case LIGHT_BROWN_CANDLES_1:
                case LIGHT_CYAN_CANDLES_1:
                case LIGHT_GRAY_CANDLES_1:
                case LIGHT_GREEN_CANDLES_1:
                case LIGHT_LIGHT_BLUE_CANDLES_1:
                case LIGHT_LIGHT_GRAY_CANDLES_1:
                case LIGHT_LIME_CANDLES_1:
                case LIGHT_MAGENTA_CANDLES_1:
                case LIGHT_ORANGE_CANDLES_1:
                case LIGHT_PINK_CANDLES_1:
                case LIGHT_PURPLE_CANDLES_1:
                case LIGHT_RED_CANDLES_1:
                case LIGHT_WHITE_CANDLES_1:
                case LIGHT_YELLOW_CANDLES_1:
                    lightRange = 3.0;
                    break;
                case LIGHT_CANDLES_2:
                case LIGHT_BLACK_CANDLES_2:
                case LIGHT_BLUE_CANDLES_2:
                case LIGHT_BROWN_CANDLES_2:
                case LIGHT_CYAN_CANDLES_2:
                case LIGHT_GRAY_CANDLES_2:
                case LIGHT_GREEN_CANDLES_2:
                case LIGHT_LIGHT_BLUE_CANDLES_2:
                case LIGHT_LIGHT_GRAY_CANDLES_2:
                case LIGHT_LIME_CANDLES_2:
                case LIGHT_MAGENTA_CANDLES_2:
                case LIGHT_ORANGE_CANDLES_2:
                case LIGHT_PINK_CANDLES_2:
                case LIGHT_PURPLE_CANDLES_2:
                case LIGHT_RED_CANDLES_2:
                case LIGHT_WHITE_CANDLES_2:
                case LIGHT_YELLOW_CANDLES_2:
                    lightRange = 6.0;
                    break;
                case LIGHT_CANDLES_3:
                case LIGHT_BLACK_CANDLES_3:
                case LIGHT_BLUE_CANDLES_3:
                case LIGHT_BROWN_CANDLES_3:
                case LIGHT_CYAN_CANDLES_3:
                case LIGHT_GRAY_CANDLES_3:
                case LIGHT_GREEN_CANDLES_3:
                case LIGHT_LIGHT_BLUE_CANDLES_3:
                case LIGHT_LIGHT_GRAY_CANDLES_3:
                case LIGHT_LIME_CANDLES_3:
                case LIGHT_MAGENTA_CANDLES_3:
                case LIGHT_ORANGE_CANDLES_3:
                case LIGHT_PINK_CANDLES_3:
                case LIGHT_PURPLE_CANDLES_3:
                case LIGHT_RED_CANDLES_3:
                case LIGHT_WHITE_CANDLES_3:
                case LIGHT_YELLOW_CANDLES_3:
                    lightRange = 9.0;
                    break;
                case LIGHT_CANDLES_4:
                case LIGHT_BLACK_CANDLES_4:
                case LIGHT_BLUE_CANDLES_4:
                case LIGHT_BROWN_CANDLES_4:
                case LIGHT_CYAN_CANDLES_4:
                case LIGHT_GRAY_CANDLES_4:
                case LIGHT_GREEN_CANDLES_4:
                case LIGHT_LIGHT_BLUE_CANDLES_4:
                case LIGHT_LIGHT_GRAY_CANDLES_4:
                case LIGHT_LIME_CANDLES_4:
                case LIGHT_MAGENTA_CANDLES_4:
                case LIGHT_ORANGE_CANDLES_4:
                case LIGHT_PINK_CANDLES_4:
                case LIGHT_PURPLE_CANDLES_4:
                case LIGHT_RED_CANDLES_4:
                case LIGHT_WHITE_CANDLES_4:
                case LIGHT_YELLOW_CANDLES_4:
                    lightRange = 12.0;
                    break;
            }
        #else
            switch (lightType) {
                case LIGHT_CANDLES_1:
                    lightRange = 3.0;
                    break;
                case LIGHT_CANDLES_2:
                    lightRange = 6.0;
                    break;
                case LIGHT_CANDLES_3:
                    lightRange = 9.0;
                    break;
                case LIGHT_CANDLES_4:
                    lightRange = 12.0;
                    break;
            }
        #endif

        #ifdef DYN_LIGHT_OREBLOCKS
            switch (lightType) {
                case LIGHT_AMETHYST_BLOCK:
                case LIGHT_DIAMOND_BLOCK:
                case LIGHT_EMERALD_BLOCK:
                case LIGHT_LAPIS_BLOCK:
                case LIGHT_REDSTONE_BLOCK:
                    lightRange = 12.0;
                    break;
            }
        #endif

        switch (lightType) {
            case LIGHT_CREATE_XP:
            case LIGHT_ROSE_QUARTZ_LAMP:
                lightRange = 15.0;
                break;
            case LIGHT_DECO_LAMP_BLUE:
            case LIGHT_DECO_LAMP_GREEN:
            case LIGHT_DECO_LAMP_RED:
            case LIGHT_DECO_LAMP_YELLOW:
                lightRange = 12.0;
                break;
        }

        switch (lightType) {
            case LIGHT_STREET_LAMP:
            case LIGHT_SOUL_STREET_LAMP:
                lightRange = 12.0;
                break;
            case LIGHT_PAPER_LAMP_BLACK:
            case LIGHT_PAPER_LAMP_BLUE:
            case LIGHT_PAPER_LAMP_BROWN:
            case LIGHT_PAPER_LAMP_CYAN:
            case LIGHT_PAPER_LAMP_GRAY:
            case LIGHT_PAPER_LAMP_GREEN:
            case LIGHT_PAPER_LAMP_LIGHT_BLUE:
            case LIGHT_PAPER_LAMP_LIGHT_GRAY:
            case LIGHT_PAPER_LAMP_LIME:
            case LIGHT_PAPER_LAMP_MAGENTA:
            case LIGHT_PAPER_LAMP_ORANGE:
            case LIGHT_PAPER_LAMP_PINK:
            case LIGHT_PAPER_LAMP_PURPLE:
            case LIGHT_PAPER_LAMP_RED:
            case LIGHT_PAPER_LAMP_WHITE:
            case LIGHT_PAPER_LAMP_YELLOW:
                lightRange = 14.0;
                break;
        }

        return lightRange * Lighting_RangeF;
    }

    float GetSceneLightLevel(const in uint lightType) {
        #if DYN_LIGHT_REDSTONE == DYN_LIGHT_BLOCK_NONE
            if (lightType == LIGHT_COMPARATOR
             || lightType == LIGHT_REPEATER
             || lightType == LIGHT_RAIL_POWERED) return 0.0;

            if (lightType >= LIGHT_REDSTONE_WIRE_1
             && lightType <= LIGHT_REDSTONE_WIRE_15) return 0.0;
        #endif
        
        #if DYN_LIGHT_LAVA == DYN_LIGHT_BLOCK_NONE
            if (lightType == LIGHT_LAVA) return 0.0;
        #endif

        return GetSceneLightRange(lightType);
    }

    float GetSceneLightSize(const in uint lightType) {
        float size = (1.0/16.0);

        switch (lightType) {
            case LIGHT_AMETHYST_BLOCK:
            case LIGHT_AMETHYST_CLUSTER:
            case LIGHT_CRYING_OBSIDIAN:
            case LIGHT_CREATE_XP:
            case LIGHT_FIRE:
            case LIGHT_FROGLIGHT_OCHRE:
            case LIGHT_FROGLIGHT_PEARLESCENT:
            case LIGHT_FROGLIGHT_VERDANT:
            case LIGHT_GLOWSTONE:
            case LIGHT_LAVA:
            case LIGHT_MAGMA:
            case LIGHT_NETHER_PORTAL:
            case LIGHT_SHROOMLIGHT:
            case LIGHT_SOUL_FIRE:
                size = (16.0/16.0);
                break;
            case LIGHT_COPPER_BULB:
            case LIGHT_COPPER_BULB_EXPOSED:
            case LIGHT_COPPER_BULB_OXIDIZED:
            case LIGHT_COPPER_BULB_WEATHERED:
            case LIGHT_LAVA_CAULDRON:
            case LIGHT_SEA_LANTERN:
            case LIGHT_REDSTONE_LAMP:
            case LIGHT_REDSTONE_ORE:
            case LIGHT_ROSE_QUARTZ_LAMP:
            case LIGHT_SMOKER_N:
            case LIGHT_SMOKER_E:
            case LIGHT_SMOKER_S:
            case LIGHT_SMOKER_W:
                size = (14.0/16.0);
                break;
            case LIGHT_AMETHYST_BUD_LARGE:
            case LIGHT_CAMPFIRE:
            case LIGHT_SOUL_CAMPFIRE:
            case LIGHT_FURNACE_N:
            case LIGHT_FURNACE_E:
            case LIGHT_FURNACE_S:
            case LIGHT_FURNACE_W:
            case LIGHT_PAPER_LAMP_BLACK:
            case LIGHT_PAPER_LAMP_BLUE:
            case LIGHT_PAPER_LAMP_BROWN:
            case LIGHT_PAPER_LAMP_CYAN:
            case LIGHT_PAPER_LAMP_GRAY:
            case LIGHT_PAPER_LAMP_GREEN:
            case LIGHT_PAPER_LAMP_LIGHT_BLUE:
            case LIGHT_PAPER_LAMP_LIGHT_GRAY:
            case LIGHT_PAPER_LAMP_LIME:
            case LIGHT_PAPER_LAMP_MAGENTA:
            case LIGHT_PAPER_LAMP_ORANGE:
            case LIGHT_PAPER_LAMP_PINK:
            case LIGHT_PAPER_LAMP_PURPLE:
            case LIGHT_PAPER_LAMP_RED:
            case LIGHT_PAPER_LAMP_WHITE:
            case LIGHT_PAPER_LAMP_YELLOW:
                size = (12.0/16.0);
                break;
            case LIGHT_BEACON:
            case LIGHT_JACK_O_LANTERN_N:
            case LIGHT_JACK_O_LANTERN_E:
            case LIGHT_JACK_O_LANTERN_S:
            case LIGHT_JACK_O_LANTERN_W:
            case LIGHT_RAIL_POWERED:
                size = (10.0/16.0);
                break;
            case LIGHT_CANDLES_4:
            case LIGHT_BLACK_CANDLES_4:
            case LIGHT_BLUE_CANDLES_4:
            case LIGHT_BROWN_CANDLES_4:
            case LIGHT_CYAN_CANDLES_4:
            case LIGHT_GRAY_CANDLES_4:
            case LIGHT_GREEN_CANDLES_4:
            case LIGHT_LIGHT_BLUE_CANDLES_4:
            case LIGHT_LIGHT_GRAY_CANDLES_4:
            case LIGHT_LIME_CANDLES_4:
            case LIGHT_MAGENTA_CANDLES_4:
            case LIGHT_ORANGE_CANDLES_4:
            case LIGHT_PINK_CANDLES_4:
            case LIGHT_PURPLE_CANDLES_4:
            case LIGHT_RED_CANDLES_4:
            case LIGHT_WHITE_CANDLES_4:
            case LIGHT_YELLOW_CANDLES_4:
            case LIGHT_END_ROD:
            case LIGHT_BLAST_FURNACE_N:
            case LIGHT_BLAST_FURNACE_E:
            case LIGHT_BLAST_FURNACE_S:
            case LIGHT_BLAST_FURNACE_W:
                size = (8.0/16.0);
                break;
            case LIGHT_AMETHYST_BUD_MEDIUM:
            case LIGHT_CANDLES_3:
            case LIGHT_BLACK_CANDLES_3:
            case LIGHT_BLUE_CANDLES_3:
            case LIGHT_BROWN_CANDLES_3:
            case LIGHT_CYAN_CANDLES_3:
            case LIGHT_GRAY_CANDLES_3:
            case LIGHT_GREEN_CANDLES_3:
            case LIGHT_LIGHT_BLUE_CANDLES_3:
            case LIGHT_LIGHT_GRAY_CANDLES_3:
            case LIGHT_LIME_CANDLES_3:
            case LIGHT_MAGENTA_CANDLES_3:
            case LIGHT_ORANGE_CANDLES_3:
            case LIGHT_PINK_CANDLES_3:
            case LIGHT_PURPLE_CANDLES_3:
            case LIGHT_RED_CANDLES_3:
            case LIGHT_WHITE_CANDLES_3:
            case LIGHT_YELLOW_CANDLES_3:
            case LIGHT_LANTERN:
            case LIGHT_SOUL_LANTERN:
            case LIGHT_STREET_LAMP:
            case LIGHT_SOUL_STREET_LAMP:
                size = (6.0/16.0);
                break;
            case LIGHT_CANDLES_2:
            case LIGHT_BLACK_CANDLES_2:
            case LIGHT_BLUE_CANDLES_2:
            case LIGHT_BROWN_CANDLES_2:
            case LIGHT_CYAN_CANDLES_2:
            case LIGHT_GRAY_CANDLES_2:
            case LIGHT_GREEN_CANDLES_2:
            case LIGHT_LIGHT_BLUE_CANDLES_2:
            case LIGHT_LIGHT_GRAY_CANDLES_2:
            case LIGHT_LIME_CANDLES_2:
            case LIGHT_MAGENTA_CANDLES_2:
            case LIGHT_ORANGE_CANDLES_2:
            case LIGHT_PINK_CANDLES_2:
            case LIGHT_PURPLE_CANDLES_2:
            case LIGHT_RED_CANDLES_2:
            case LIGHT_WHITE_CANDLES_2:
            case LIGHT_YELLOW_CANDLES_2:
                size = (4.0/16.0);
                break;
            case LIGHT_CANDLES_1:
            case LIGHT_BLACK_CANDLES_1:
            case LIGHT_BLUE_CANDLES_1:
            case LIGHT_BROWN_CANDLES_1:
            case LIGHT_CYAN_CANDLES_1:
            case LIGHT_GRAY_CANDLES_1:
            case LIGHT_GREEN_CANDLES_1:
            case LIGHT_LIGHT_BLUE_CANDLES_1:
            case LIGHT_LIGHT_GRAY_CANDLES_1:
            case LIGHT_LIME_CANDLES_1:
            case LIGHT_MAGENTA_CANDLES_1:
            case LIGHT_ORANGE_CANDLES_1:
            case LIGHT_PINK_CANDLES_1:
            case LIGHT_PURPLE_CANDLES_1:
            case LIGHT_RED_CANDLES_1:
            case LIGHT_WHITE_CANDLES_1:
            case LIGHT_YELLOW_CANDLES_1:
            case LIGHT_CANDLE_CAKE:
                size = (2.0/16.0);
                break;
        }

        if (
            (lightType >= LIGHT_SOUL_TORCH_FLOOR && lightType <= LIGHT_SOUL_TORCH_WALL_W) ||
            (lightType >= LIGHT_TORCH_FLOOR && lightType <= LIGHT_TORCH_WALL_W) ||
            (lightType >= LIGHT_REDSTONE_TORCH_FLOOR && lightType <= LIGHT_REDSTONE_TORCH_WALL_W)
        ) size = (2.0/16.0);

        return size;
    }

    vec3 GetSceneLightOffset(const in uint lightType) {
        vec3 lightOffset = vec3(0.0);

        switch (lightType) {
            case LIGHT_CAMPFIRE:
            case LIGHT_SOUL_CAMPFIRE:
                lightOffset = vec3(0.0, -0.1, 0.0);
                break;

            case LIGHT_BLAST_FURNACE_N:
            case LIGHT_BLAST_FURNACE_E:
            case LIGHT_BLAST_FURNACE_S:
            case LIGHT_BLAST_FURNACE_W:
                lightOffset = vec3(0.0, -0.4, 0.0);
                break;

            case LIGHT_CANDLE_CAKE:
                lightOffset = vec3(0.0, 0.4, 0.0);
                break;

            case LIGHT_FIRE:
                lightOffset = vec3(0.0, -0.3, 0.0);
                break;

            case LIGHT_FURNACE_N:
            case LIGHT_FURNACE_E:
            case LIGHT_FURNACE_S:
            case LIGHT_FURNACE_W:
                lightOffset = vec3(0.0, -0.2, 0.0);
                break;
            case LIGHT_JACK_O_LANTERN_N:
                lightOffset = vec3(0.0, 0.0, -0.4) * Lighting_PenumbraF;
                break;
            case LIGHT_JACK_O_LANTERN_E:
                lightOffset = vec3(0.4, 0.0, 0.0) * Lighting_PenumbraF;
                break;
            case LIGHT_JACK_O_LANTERN_S:
                lightOffset = vec3(0.0, 0.0, 0.4) * Lighting_PenumbraF;
                break;
            case LIGHT_JACK_O_LANTERN_W:
                lightOffset = vec3(-0.4, 0.0, 0.0) * Lighting_PenumbraF;
                break;
            case LIGHT_LANTERN:
                lightOffset = vec3(0.0, -0.2, 0.0);
                break;
            case LIGHT_LAVA_CAULDRON:
                #if LIGHTING_TRACE_PENUMBRA > 0
                    lightOffset = vec3(0.0, 0.4, 0.0);
                #else
                    lightOffset = vec3(0.0, 0.2, 0.0);
                #endif
                break;
            case LIGHT_RESPAWN_ANCHOR_1:
            case LIGHT_RESPAWN_ANCHOR_2:
            case LIGHT_RESPAWN_ANCHOR_3:
            case LIGHT_RESPAWN_ANCHOR_4:
                lightOffset = vec3(0.0, 0.4, 0.0);
                break;
            case LIGHT_SCULK_CATALYST:
                lightOffset = vec3(0.0, 0.4, 0.0);
                break;
            case LIGHT_SMOKER_N:
            case LIGHT_SMOKER_E:
            case LIGHT_SMOKER_S:
            case LIGHT_SMOKER_W:
                lightOffset = vec3(0.0, -0.3, 0.0);
                break;
            case LIGHT_SOUL_FIRE:
            case LIGHT_SOUL_LANTERN:
                lightOffset = vec3(0.0, -0.25, 0.0);
                break;
            case LIGHT_REDSTONE_TORCH_FLOOR:
            case LIGHT_SOUL_TORCH_FLOOR:
            case LIGHT_TORCH_FLOOR:
                lightOffset = modelPart(0, 1, 0);
                break;
            case LIGHT_REDSTONE_TORCH_WALL_N:
            case LIGHT_SOUL_TORCH_WALL_N:
            case LIGHT_TORCH_WALL_N:
                lightOffset = modelPart(0, 4.5, 4.5);
                break;
            case LIGHT_REDSTONE_TORCH_WALL_E:
            case LIGHT_SOUL_TORCH_WALL_E:
            case LIGHT_TORCH_WALL_E:
                lightOffset = modelPart(-4.5, 4.5, 0);
                break;
            case LIGHT_REDSTONE_TORCH_WALL_S:
            case LIGHT_SOUL_TORCH_WALL_S:
            case LIGHT_TORCH_WALL_S:
                lightOffset = modelPart(0, 4.5, -4.5);
                break;
            case LIGHT_REDSTONE_TORCH_WALL_W:
            case LIGHT_SOUL_TORCH_WALL_W:
            case LIGHT_TORCH_WALL_W:
                lightOffset = modelPart(4.5, 4.5, 0);
                break;
        }

        switch (lightType) {
            case LIGHT_STREET_LAMP:
            case LIGHT_SOUL_STREET_LAMP:
                lightOffset = modelPart(0, 3, 0);
                break;
        }

        return lightOffset;
    }

    bool GetLightTraced(const in uint lightType) {
        bool result = true;

        #if DYN_LIGHT_GLOW_BERRIES != DYN_LIGHT_BLOCK_TRACE
            if (lightType == LIGHT_CAVEVINE_BERRIES) result = false;
        #endif

        #if DYN_LIGHT_LAVA != DYN_LIGHT_BLOCK_TRACE
            if (lightType == LIGHT_LAVA) result = false;
        #endif

        #if DYN_LIGHT_PORTAL != DYN_LIGHT_BLOCK_TRACE
            if (lightType == LIGHT_NETHER_PORTAL) result = false;
        #endif

        #if DYN_LIGHT_REDSTONE != DYN_LIGHT_BLOCK_TRACE
            if (lightType >= LIGHT_REDSTONE_WIRE_1 && lightType <= LIGHT_REDSTONE_WIRE_15) result = false;
        #endif

        return result;
    }

    bool GetLightSelfTraced(const in uint lightType) {
        bool result = false;

        if (lightType == LIGHT_BEACON) result = true;
        if (lightType == LIGHT_CAMPFIRE) result = true;
        if (lightType == LIGHT_SOUL_CAMPFIRE) result = true;

        return result;
    }
#endif

    #ifdef RENDER_SHADOWCOMP
        uint BuildLightMask(const in uint lightType) {
            uint lightData = 0u;

            switch (lightType) {
                // case LIGHT_BEACON:
                //     lightData |= 1u << LIGHT_MASK_DOWN;
                //     break;
                case LIGHT_JACK_O_LANTERN_N:
                case LIGHT_FURNACE_N:
                case LIGHT_BLAST_FURNACE_N:
                case LIGHT_SMOKER_N:
                    lightData |= 1u << LIGHT_MASK_UP;
                    lightData |= 1u << LIGHT_MASK_DOWN;
                    lightData |= 1u << LIGHT_MASK_SOUTH;
                    lightData |= 1u << LIGHT_MASK_WEST;
                    lightData |= 1u << LIGHT_MASK_EAST;
                    break;
                case LIGHT_JACK_O_LANTERN_E:
                case LIGHT_FURNACE_E:
                case LIGHT_BLAST_FURNACE_E:
                case LIGHT_SMOKER_E:
                    lightData |= 1u << LIGHT_MASK_UP;
                    lightData |= 1u << LIGHT_MASK_DOWN;
                    lightData |= 1u << LIGHT_MASK_NORTH;
                    lightData |= 1u << LIGHT_MASK_SOUTH;
                    lightData |= 1u << LIGHT_MASK_WEST;
                    break;
                case LIGHT_JACK_O_LANTERN_S:
                case LIGHT_FURNACE_S:
                case LIGHT_BLAST_FURNACE_S:
                case LIGHT_SMOKER_S:
                    lightData |= 1u << LIGHT_MASK_UP;
                    lightData |= 1u << LIGHT_MASK_DOWN;
                    lightData |= 1u << LIGHT_MASK_NORTH;
                    lightData |= 1u << LIGHT_MASK_WEST;
                    lightData |= 1u << LIGHT_MASK_EAST;
                    break;
                case LIGHT_JACK_O_LANTERN_W:
                case LIGHT_FURNACE_W:
                case LIGHT_BLAST_FURNACE_W:
                case LIGHT_SMOKER_W:
                    lightData |= 1u << LIGHT_MASK_UP;
                    lightData |= 1u << LIGHT_MASK_DOWN;
                    lightData |= 1u << LIGHT_MASK_NORTH;
                    lightData |= 1u << LIGHT_MASK_SOUTH;
                    lightData |= 1u << LIGHT_MASK_EAST;
                    break;
                case LIGHT_LAVA_CAULDRON:
                    lightData |= 1u << LIGHT_MASK_DOWN;
                    lightData |= 1u << LIGHT_MASK_NORTH;
                    lightData |= 1u << LIGHT_MASK_SOUTH;
                    lightData |= 1u << LIGHT_MASK_WEST;
                    lightData |= 1u << LIGHT_MASK_EAST;
                    break;
            }

            return lightData;
        }

        // BuildLightMask
        uvec4 BuildLightData(const in vec3 position, const in bool traced, const in bool selfTrace, const in uint mask, const in float size, const in float range, const in vec3 color) {
            uvec4 lightData;

            // position
            const uvec3 pos_offsets = uvec3(0u, 16u, 0u);
            uvec3 pos_packed = float2half(floatBitsToUint(position)) << pos_offsets;
            lightData.x  = pos_packed.x | pos_packed.y;
            lightData.y  = pos_packed.z;

            // size
            uint bitSize = uint(clamp(size * 255.0, 0.0, 255.0) + 0.5);
            lightData.y |= bitSize << 16u;

            // range
            uint bitRange = uint(clamp(range * 4.0, 0.0, 255.0) + 0.5);
            lightData.y |= bitRange << 24u;

            // traced
            lightData.z = traced ? 1u : 0u;
            lightData.z |= (selfTrace ? 1u : 0u) << 1u;

            // mask
            lightData.z |= mask;

            // color
            const uvec3 color_offsets = uvec3(8u, 16u, 24u);
            uvec3 color_packed = uvec3(saturate(color) * 255.0 + 0.5) << color_offsets;
            lightData.z |= color_packed.r | color_packed.g | color_packed.b;

            return lightData;
        }
    #endif
//#endif
