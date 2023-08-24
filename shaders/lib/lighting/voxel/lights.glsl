#if !(defined RENDER_SHADOW || defined RENDER_SHADOWCOMP_LIGHT_NEIGHBORS) && defined DYN_LIGHT_FLICKER && !defined RENDER_SETUP
    void ApplyLightFlicker(inout vec3 lightColor, const in uint lightType, const in vec2 noiseSample) {
        float flickerNoise = GetDynLightFlickerNoise(noiseSample);
        float blackbodyTemp = 0.0;

        bool isBigFireSource = (lightType >= LIGHT_TORCH_FLOOR && lightType <= LIGHT_TORCH_WALL_W)
            || lightType == LIGHT_FIRE || lightType == LIGHT_CAMPFIRE
            || lightType == LIGHT_LANTERN || lightType == LIGHT_STREET_LAMP;

        bool isSmallFireSource = lightType == LIGHT_CANDLES_1 || lightType == LIGHT_CANDLES_2
            || lightType == LIGHT_CANDLES_3 || lightType == LIGHT_CANDLES_4 || lightType == LIGHT_CANDLE_CAKE
            || (lightType >= LIGHT_JACK_O_LANTERN_N && lightType <= LIGHT_JACK_O_LANTERN_W);

        bool isSoulFireSource = (lightType >= LIGHT_SOUL_TORCH_FLOOR && lightType <= LIGHT_SOUL_TORCH_WALL_W)
            || lightType == LIGHT_SOUL_FIRE || lightType == LIGHT_SOUL_CAMPFIRE
            || lightType == LIGHT_SOUL_LANTERN || lightType == LIGHT_SOUL_STREET_LAMP;

        if (isBigFireSource) {
            const float tempFireMin = TEMP_FIRE - 0.5*TEMP_FIRE_RANGE;
            const float tempFireMax = tempFireMin + TEMP_FIRE_RANGE;
            blackbodyTemp = mix(tempFireMin, tempFireMax, flickerNoise);
        }

        if (isSoulFireSource) {
            blackbodyTemp = mix(TEMP_SOUL_FIRE_MIN, TEMP_SOUL_FIRE_MAX, 1.0 - flickerNoise);
        }

        if (isSmallFireSource) {
            blackbodyTemp = mix(TEMP_CANDLE_MIN, TEMP_CANDLE_MAX, flickerNoise);
        }

        vec3 blackbodyColor = vec3(1.0);
        if (blackbodyTemp > 0.0)
            blackbodyColor = blackbody(blackbodyTemp);

        float flickerBrightness = 0.6 + 0.4 * flickerNoise;

        if (isBigFireSource) {
            lightColor = flickerBrightness * blackbodyColor;
        }

        if (isSoulFireSource) {
            lightColor = flickerBrightness * saturate(1.0 - blackbodyColor);
        }

        if (isSmallFireSource) {
            lightColor = 0.4 * flickerBrightness * blackbodyColor;
        }
    }
#endif

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
                lightColor = vec3(0.600, 0.439, 0.820);
                break;
            case LIGHT_BEACON:
                lightColor = vec3(1.0);
                break;
            case LIGHT_BLAST_FURNACE_N:
            case LIGHT_BLAST_FURNACE_E:
            case LIGHT_BLAST_FURNACE_S:
            case LIGHT_BLAST_FURNACE_W:
                lightColor = vec3(0.798, 0.519, 0.289);
                break;
            case LIGHT_BREWING_STAND:
                lightColor = vec3(0.636, 0.509, 0.179);
                break;
            case LIGHT_CANDLES_1:
            case LIGHT_CANDLES_2:
            case LIGHT_CANDLES_3:
            case LIGHT_CANDLES_4:
            case LIGHT_CANDLE_CAKE:
                lightColor = vec3(0.758, 0.553, 0.239);
                break;
            case LIGHT_CAVEVINE_BERRIES:
                lightColor = 0.4 * vec3(0.717, 0.541, 0.188);
                break;
            case LIGHT_CRYING_OBSIDIAN:
                lightColor = vec3(0.390, 0.065, 0.646);
                break;
            case LIGHT_END_ROD:
                lightColor = vec3(0.957, 0.929, 0.875);
                break;
            case LIGHT_END_STONE_LAMP:
                lightColor = vec3(0.465, 0.143, 0.416);
                break;
            case LIGHT_CAMPFIRE:
            case LIGHT_FIRE:
                lightColor = vec3(0.851, 0.616, 0.239);
                break;
            case LIGHT_FROGLIGHT_OCHRE:
                lightColor = vec3(0.768, 0.648, 0.108);
                break;
            case LIGHT_FROGLIGHT_PEARLESCENT:
                lightColor = vec3(0.737, 0.435, 0.658);
                break;
            case LIGHT_FROGLIGHT_VERDANT:
                lightColor = vec3(0.463, 0.763, 0.409);
                break;
            case LIGHT_FURNACE_N:
            case LIGHT_FURNACE_E:
            case LIGHT_FURNACE_S:
            case LIGHT_FURNACE_W:
                lightColor = vec3(0.798, 0.519, 0.289);
                break;
            case LIGHT_GLOWSTONE:
                lightColor = vec3(0.652, 0.583, 0.275);
                break;
            case LIGHT_GLOW_LICHEN:
                lightColor = vec3(0.092, 0.217, 0.126);
                break;
            case LIGHT_JACK_O_LANTERN_N:
            case LIGHT_JACK_O_LANTERN_E:
            case LIGHT_JACK_O_LANTERN_S:
            case LIGHT_JACK_O_LANTERN_W:
                lightColor = vec3(0.768, 0.701, 0.325);
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
                lightColor = vec3(0.804, 0.424, 0.149);
                break;
            case LIGHT_MAGMA:
                lightColor = vec3(0.747, 0.323, 0.110);
                break;
            case LIGHT_NETHER_PORTAL:
                lightColor = vec3(0.502, 0.165, 0.831);
                break;
            case LIGHT_REDSTONE_LAMP:
                lightColor = vec3(0.953, 0.796, 0.496);
                break;
            case LIGHT_REDSTONE_ORE:
            case LIGHT_REDSTONE_TORCH_FLOOR:
            case LIGHT_REDSTONE_TORCH_WALL_N:
            case LIGHT_REDSTONE_TORCH_WALL_E:
            case LIGHT_REDSTONE_TORCH_WALL_S:
            case LIGHT_REDSTONE_TORCH_WALL_W:
                lightColor = vec3(0.697, 0.130, 0.051);
                break;
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
                lightColor = vec3(0.697, 0.130, 0.051);
                break;
            case LIGHT_RESPAWN_ANCHOR_4:
            case LIGHT_RESPAWN_ANCHOR_3:
            case LIGHT_RESPAWN_ANCHOR_2:
            case LIGHT_RESPAWN_ANCHOR_1:
                lightColor = vec3(0.390, 0.065, 0.646);
                break;
            case LIGHT_SCULK_CATALYST:
                lightColor = vec3(0.181, 0.358, 0.369);
                break;
            case LIGHT_SEA_LANTERN:
                lightColor = vec3(0.570, 0.780, 0.800);
                break;
            case LIGHT_SEA_PICKLE_1:
            case LIGHT_SEA_PICKLE_2:
            case LIGHT_SEA_PICKLE_3:
            case LIGHT_SEA_PICKLE_4:
                lightColor = vec3(0.283, 0.394, 0.212);
                break;
            case LIGHT_SHROOMLIGHT:
                lightColor = vec3(0.848, 0.469, 0.205);
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
                lightColor = vec3(0.203, 0.725, 0.758);
                break;
            case LIGHT_TORCH_FLOOR:
            case LIGHT_TORCH_WALL_N:
            case LIGHT_TORCH_WALL_E:
            case LIGHT_TORCH_WALL_S:
            case LIGHT_TORCH_WALL_W:
                lightColor = vec3(0.899, 0.625, 0.253);
                break;
        }

        #ifdef DYN_LIGHT_OREBLOCKS
            switch (lightType) {
                case LIGHT_AMETHYST_BLOCK:
                    lightColor = vec3(0.600, 0.439, 0.820);
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
                    lightColor = vec3(0.980, 0.143, 0.026);
                    break;
            }
        #endif

        switch (lightType) {
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

        #ifdef MAGNIFICENT_COLORS
            if (lightType == LIGHT_SEA_LANTERN) lightColor = vec3(0.2, 0.8, 1.0) * .5;
            if (lightType == LIGHT_GLOWSTONE) lightColor = vec3(1.0, 0.7, 0.4);
            if (lightType == LIGHT_END_ROD) lightColor = vec3(0.7, 0.5, 0.9) * 1.1;
            if (lightType >= LIGHT_TORCH_FLOOR && lightType <= LIGHT_TORCH_WALL_W) lightColor = vec3(1.00, 0.60, 0.30);
            if (lightType >= LIGHT_REDSTONE_TORCH_FLOOR && lightType <= LIGHT_REDSTONE_TORCH_WALL_W) lightColor = vec3(1.00, 0.30, 0.10);
            if (lightType == LIGHT_FIRE) lightColor = vec3(1.00, 0.40, 0.20);
            if (lightType == LIGHT_CAMPFIRE || lightType == LIGHT_LANTERN || (lightType >= LIGHT_FURNACE_N && lightType <= LIGHT_FURNACE_W)) lightColor = vec3(1.00, 0.60, 0.30);
            if (lightType == LIGHT_SOUL_CAMPFIRE || lightType == LIGHT_SOUL_LANTERN || lightType == LIGHT_SOUL_FIRE || (lightType >= LIGHT_SOUL_TORCH_FLOOR && lightType <= LIGHT_SOUL_TORCH_WALL_W)) lightColor = vec3(0.1, 0.8, 1.0);
            if (lightType == LIGHT_LAVA) lightColor = vec3(1.0, 0.5, 0.2);
            if (lightType == LIGHT_REDSTONE_LAMP) lightColor = vec3(1.0, 0.6, 0.4);
            if (lightType == LIGHT_BEACON) lightColor = vec3(0.6, 0.7, 1.0);
            if (lightType == LIGHT_MAGMA) lightColor = vec3(1.0, 0.2, 0.1);
            if (lightType == LIGHT_SHROOMLIGHT) lightColor = vec3(0.8, 0.4, 0.0);
        #endif
        
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
            case LIGHT_CANDLES_1:
            case LIGHT_CANDLE_CAKE:
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
            case LIGHT_CAVEVINE_BERRIES:
                lightRange = 14.0;
                break;
            case LIGHT_COMPARATOR:
                lightRange = 7.0;
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

        return lightRange * DynamicLightRangeF;
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
            case LIGHT_END_ROD:
            case LIGHT_BLAST_FURNACE_N:
            case LIGHT_BLAST_FURNACE_E:
            case LIGHT_BLAST_FURNACE_S:
            case LIGHT_BLAST_FURNACE_W:
                size = (8.0/16.0);
                break;
            case LIGHT_AMETHYST_BUD_MEDIUM:
            case LIGHT_CANDLES_3:
            case LIGHT_LANTERN:
            case LIGHT_SOUL_LANTERN:
            case LIGHT_STREET_LAMP:
            case LIGHT_SOUL_STREET_LAMP:
                size = (6.0/16.0);
                break;
            case LIGHT_CANDLES_2:
                size = (4.0/16.0);
                break;
            case LIGHT_CANDLES_1:
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
                lightOffset = vec3(0.0, 0.0, -0.4) * DynamicLightPenumbraF;
                break;
            case LIGHT_JACK_O_LANTERN_E:
                lightOffset = vec3(0.4, 0.0, 0.0) * DynamicLightPenumbraF;
                break;
            case LIGHT_JACK_O_LANTERN_S:
                lightOffset = vec3(0.0, 0.0, 0.4) * DynamicLightPenumbraF;
                break;
            case LIGHT_JACK_O_LANTERN_W:
                lightOffset = vec3(-0.4, 0.0, 0.0) * DynamicLightPenumbraF;
                break;
            case LIGHT_LANTERN:
                lightOffset = vec3(0.0, -0.2, 0.0);
                break;
            case LIGHT_LAVA_CAULDRON:
                #if DYN_LIGHT_PENUMBRA > 0
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
#endif

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

    #ifdef RENDER_SHADOWCOMP
        uint BuildLightMask(const in uint lightType) {
            uint lightData = 0u;

            switch (lightType) {
                case LIGHT_BEACON:
                    lightData |= 1u << LIGHT_MASK_DOWN;
                    break;
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
        uvec4 BuildLightData(const in vec3 position, const in bool traced, const in uint mask, const in float size, const in float range, const in vec3 color) {
            uvec4 lightData;

            // position
            lightData.x  = float2half(floatBitsToUint(position.x));
            lightData.x |= float2half(floatBitsToUint(position.y)) << 16u;
            lightData.y  = float2half(floatBitsToUint(position.z));

            // size
            uint bitSize = uint(clamp(size * 255.0, 0.0, 255.0) + 0.5);
            lightData.y |= bitSize << 16u;

            // range
            uint bitRange = uint(clamp(range * 15.0, 0.0, 255.0) + 0.5);
            lightData.y |= bitRange << 24u;

            // traced
            lightData.z = traced ? 1u : 0u;

            // mask
            lightData.z |= mask;

            // color
            uvec3 bitColor = uvec3(saturate(color) * 255.0 + 0.5);
            lightData.z |= bitColor.r << 8u;
            lightData.z |= bitColor.g << 16u;
            lightData.z |= bitColor.b << 24u;

            return lightData;
        }
    #endif
//#endif

void ParseLightPosition(const in uvec4 data, out vec3 position) {
    position.x = uintBitsToFloat(half2float(data.x & uint(0xffff)));
    position.y = uintBitsToFloat(half2float(data.x >> 16u));
    position.z = uintBitsToFloat(half2float(data.y & uint(0xffff)));
}

void ParseLightSize(const in uvec4 data, out float size) {
    size = ((data.y >> 16u) & 255u) / 255.0;
}

void ParseLightRange(const in uvec4 data, out float range) {
    range = ((data.y >> 24u) & 255u) / 15.0;
}

void ParseLightColor(const in uvec4 data, out vec3 color) {
    color.r = ((data.z >>  8u) & 255u) / 255.0;
    color.g = ((data.z >> 16u) & 255u) / 255.0;
    color.b = ((data.z >> 24u) & 255u) / 255.0;
}

void ParseLightData(const in uvec4 data, out vec3 position, out float size, out float range, out vec3 color) {
    ParseLightPosition(data, position);
    ParseLightSize(data, size);
    ParseLightRange(data, range);
    ParseLightColor(data, color);
}
