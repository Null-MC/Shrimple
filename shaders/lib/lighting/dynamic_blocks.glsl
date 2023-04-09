#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    bool IsDynLightSolidBlock(const in int blockId) {
        if (blockId < 1 || blockId >= 1000) return true;
        return blockId >= 300 && blockId < 600;
    }
#endif

uint GetSceneLightType(const in int blockId) {
    uint lightType = LIGHT_NONE;
    if (blockId < 1) return lightType;

    switch (blockId) {
        case BLOCK_LIGHT_1:
            lightType = LIGHT_BLOCK_1;
            break;
        case BLOCK_LIGHT_2:
            lightType = LIGHT_BLOCK_2;
            break;
        case BLOCK_LIGHT_3:
            lightType = LIGHT_BLOCK_3;
            break;
        case BLOCK_LIGHT_4:
            lightType = LIGHT_BLOCK_4;
            break;
        case BLOCK_LIGHT_5:
            lightType = LIGHT_BLOCK_5;
            break;
        case BLOCK_LIGHT_6:
            lightType = LIGHT_BLOCK_6;
            break;
        case BLOCK_LIGHT_7:
            lightType = LIGHT_BLOCK_7;
            break;
        case BLOCK_LIGHT_8:
            lightType = LIGHT_BLOCK_8;
            break;
        case BLOCK_LIGHT_9:
            lightType = LIGHT_BLOCK_9;
            break;
        case BLOCK_LIGHT_10:
            lightType = LIGHT_BLOCK_10;
            break;
        case BLOCK_LIGHT_11:
            lightType = LIGHT_BLOCK_11;
            break;
        case BLOCK_LIGHT_12:
            lightType = LIGHT_BLOCK_12;
            break;
        case BLOCK_LIGHT_13:
            lightType = LIGHT_BLOCK_13;
            break;
        case BLOCK_LIGHT_14:
            lightType = LIGHT_BLOCK_14;
            break;
        case BLOCK_LIGHT_15:
            lightType = LIGHT_BLOCK_15;
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
        case BLOCK_CAVEVINE_BERRIES:
            lightType = LIGHT_CAVEVINE_BERRIES;
            break;
        case BLOCK_COMPARATOR_LIT:
            lightType = LIGHT_COMPARATOR;
            break;
        case BLOCK_CRYING_OBSIDIAN:
            lightType = LIGHT_CRYING_OBSIDIAN;
            break;
        case BLOCK_END_ROD:
            lightType = LIGHT_END_ROD;
            break;
        case BLOCK_CAMPFIRE_LIT:
            lightType = LIGHT_CAMPFIRE;
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
        case BLOCK_LANTERN:
            lightType = LIGHT_LANTERN;
            break;
        case BLOCK_LIGHTING_ROD_POWERED:
            lightType = LIGHT_LIGHTING_ROD;
            break;
        case BLOCK_LAVA:
            lightType = LIGHT_LAVA;
            break;
        case BLOCK_LAVA_CAULDRON:
            lightType = LIGHT_LAVA_CAULDRON;
            break;
        case BLOCK_MAGMA:
            lightType = LIGHT_MAGMA;
            break;
        case BLOCK_NETHER_PORTAL:
            lightType = LIGHT_NETHER_PORTAL;
            break;
        case BLOCK_RAIL_POWERED:
            lightType = LIGHT_RAIL_POWERED;
            break;
        case BLOCK_REDSTONE_LAMP_LIT:
            lightType = LIGHT_REDSTONE_LAMP;
            break;
        case BLOCK_REDSTONE_TORCH_LIT:
            lightType = LIGHT_REDSTONE_TORCH;
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
        case BLOCK_SOUL_CAMPFIRE_LIT:
            lightType = LIGHT_SOUL_CAMPFIRE;
            break;
        case BLOCK_SOUL_FIRE:
            lightType = LIGHT_SOUL_FIRE;
            break;
        case BLOCK_SOUL_LANTERN:
            lightType = LIGHT_SOUL_LANTERN;
            break;
        case BLOCK_SOUL_TORCH:
            lightType = LIGHT_SOUL_TORCH;
            break;
        case BLOCK_TORCH:
            lightType = LIGHT_TORCH;
            break;
    }

    return lightType;
}

#if defined RENDER_SHADOW && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    uint GetBlockType(const in int blockId) {
        uint blockType = BLOCKTYPE_SOLID;
        if (blockId < 1) return blockType;

        switch (blockId) {
            case BLOCK_ANVIL_N_S:
                blockType = BLOCKTYPE_ANVIL_N_S;
                break;
            case BLOCK_ANVIL_W_E:
                blockType = BLOCKTYPE_ANVIL_W_E;
                break;

            case BLOCK_BELL_FLOOR_N_S:
            case BLOCK_BELL_WALL_N:
            case BLOCK_BELL_WALL_S:
            case BLOCK_BELL_WALL_N_S:
            case BLOCK_BELL_CEILING:
                blockType = BLOCKTYPE_BELL_FLOOR_N_S;
                break;
            case BLOCK_BELL_FLOOR_W_E:
            case BLOCK_BELL_WALL_W:
            case BLOCK_BELL_WALL_E:
            case BLOCK_BELL_WALL_W_E:
                blockType = BLOCKTYPE_BELL_FLOOR_W_E;
                break;

            case BLOCK_CACTUS:
                blockType = BLOCKTYPE_CACTUS;
                break;

            case BLOCK_CAKE:
                blockType = BLOCKTYPE_CAKE;
                break;

            case BLOCK_CAMPFIRE_N_S:
                blockType = BLOCKTYPE_CAMPFIRE_N_S;
                break;
            case BLOCK_CAMPFIRE_W_E:
                blockType = BLOCKTYPE_CAMPFIRE_W_E;
                break;

            case BLOCK_CANDLE_CAKE:
                blockType = BLOCKTYPE_CANDLE_CAKE;
                break;

            case BLOCK_CARPET:
                blockType = BLOCKTYPE_CARPET;
                break;

            case BLOCK_COMPARATOR:
                blockType = BLOCKTYPE_LAYERS_2;
                break;

            case BLOCK_DAYLIGHT_DETECTOR:
                blockType = BLOCKTYPE_LAYERS_6;
                break;

            case BLOCK_ENCHANTING_TABLE:
                blockType = BLOCKTYPE_LAYERS_12;
                break;
            case BLOCK_END_PORTAL_FRAME:
                blockType = BLOCKTYPE_END_PORTAL_FRAME;
                break;
            case BLOCK_FLOWER_POT:
            case BLOCK_POTTED_PLANT:
                blockType = BLOCKTYPE_FLOWER_POT;
                break;
            case BLOCK_GRINDSTONE_FLOOR_N_S:
                blockType = BLOCKTYPE_GRINDSTONE_FLOOR_N_S;
                break;
            case BLOCK_GRINDSTONE_FLOOR_W_E:
                blockType = BLOCKTYPE_GRINDSTONE_FLOOR_W_E;
                break;
            case BLOCK_GRINDSTONE_WALL_N_S:
                blockType = BLOCKTYPE_GRINDSTONE_WALL_N_S;
                break;
            case BLOCK_GRINDSTONE_WALL_W_E:
                blockType = BLOCKTYPE_GRINDSTONE_WALL_W_E;
                break;
            case BLOCK_HOPPER_DOWN:
                blockType = BLOCKTYPE_HOPPER_DOWN;
                break;
            case BLOCK_HOPPER_N:
                blockType = BLOCKTYPE_HOPPER_N;
                break;
            case BLOCK_HOPPER_E:
                blockType = BLOCKTYPE_HOPPER_E;
                break;
            case BLOCK_HOPPER_S:
                blockType = BLOCKTYPE_HOPPER_S;
                break;
            case BLOCK_HOPPER_W:
                blockType = BLOCKTYPE_HOPPER_W;
                break;
            case BLOCK_LECTERN:
                blockType = BLOCKTYPE_LECTERN;
                break;
            case BLOCK_LIGHTNING_ROD_N:
                blockType = BLOCKTYPE_LIGHTNING_ROD_N;
                break;
            case BLOCK_LIGHTNING_ROD_E:
                blockType = BLOCKTYPE_LIGHTNING_ROD_E;
                break;
            case BLOCK_LIGHTNING_ROD_S:
                blockType = BLOCKTYPE_LIGHTNING_ROD_S;
                break;
            case BLOCK_LIGHTNING_ROD_W:
                blockType = BLOCKTYPE_LIGHTNING_ROD_W;
                break;
            case BLOCK_LIGHTNING_ROD_UP:
                blockType = BLOCKTYPE_LIGHTNING_ROD_UP;
                break;
            case BLOCK_LIGHTNING_ROD_DOWN:
                blockType = BLOCKTYPE_LIGHTNING_ROD_DOWN;
                break;
            case BLOCK_PATHWAY:
                blockType = BLOCKTYPE_PATHWAY;
                break;
            case BLOCK_PISTON_EXTENDED_N:
                blockType = BLOCKTYPE_PISTON_EXTENDED_N;
                break;
            case BLOCK_PISTON_EXTENDED_E:
                blockType = BLOCKTYPE_PISTON_EXTENDED_E;
                break;
            case BLOCK_PISTON_EXTENDED_S:
                blockType = BLOCKTYPE_PISTON_EXTENDED_S;
                break;
            case BLOCK_PISTON_EXTENDED_W:
                blockType = BLOCKTYPE_PISTON_EXTENDED_W;
                break;
            case BLOCK_PISTON_EXTENDED_UP:
                blockType = BLOCKTYPE_PISTON_EXTENDED_UP;
                break;
            case BLOCK_PISTON_EXTENDED_DOWN:
                blockType = BLOCKTYPE_PISTON_EXTENDED_DOWN;
                break;
            case BLOCK_PISTON_HEAD_N:
                blockType = BLOCKTYPE_PISTON_HEAD_N;
                break;
            case BLOCK_PISTON_HEAD_E:
                blockType = BLOCKTYPE_PISTON_HEAD_E;
                break;
            case BLOCK_PISTON_HEAD_S:
                blockType = BLOCKTYPE_PISTON_HEAD_S;
                break;
            case BLOCK_PISTON_HEAD_W:
                blockType = BLOCKTYPE_PISTON_HEAD_W;
                break;
            case BLOCK_PISTON_HEAD_UP:
                blockType = BLOCKTYPE_PISTON_HEAD_UP;
                break;
            case BLOCK_PISTON_HEAD_DOWN:
                blockType = BLOCKTYPE_PISTON_HEAD_DOWN;
                break;
            case BLOCK_PRESSURE_PLATE:
                blockType = BLOCKTYPE_PRESSURE_PLATE;
                break;
            case BLOCK_REPEATER:
                blockType = BLOCKTYPE_LAYERS_2;
                break;
            case BLOCK_STONECUTTER:
                blockType = BLOCKTYPE_STONECUTTER;
                break;

            case BLOCK_SNOW_LAYERS_1:
                blockType = BLOCKTYPE_LAYERS_2;
                break;
            case BLOCK_SNOW_LAYERS_2:
                blockType = BLOCKTYPE_LAYERS_4;
                break;
            case BLOCK_SNOW_LAYERS_3:
                blockType = BLOCKTYPE_LAYERS_6;
                break;
            case BLOCK_SNOW_LAYERS_4:
                blockType = BLOCKTYPE_LAYERS_8;
                break;
            case BLOCK_SNOW_LAYERS_5:
                blockType = BLOCKTYPE_LAYERS_10;
                break;
            case BLOCK_SNOW_LAYERS_6:
                blockType = BLOCKTYPE_LAYERS_12;
                break;
            case BLOCK_SNOW_LAYERS_7:
                blockType = BLOCKTYPE_LAYERS_14;
                break;
        }
                
        switch (blockId) {
            case BLOCK_BUTTON_FLOOR_N_S:
                blockType = BLOCKTYPE_BUTTON_FLOOR_N_S;
                break;
            case BLOCK_BUTTON_FLOOR_W_E:
                blockType = BLOCKTYPE_BUTTON_FLOOR_W_E;
                break;
            case BLOCK_BUTTON_CEILING_N_S:
                blockType = BLOCKTYPE_BUTTON_CEILING_N_S;
                break;
            case BLOCK_BUTTON_CEILING_W_E:
                blockType = BLOCKTYPE_BUTTON_CEILING_W_E;
                break;
            case BLOCK_BUTTON_WALL_N:
                blockType = BLOCKTYPE_BUTTON_WALL_N;
                break;
            case BLOCK_BUTTON_WALL_E:
                blockType = BLOCKTYPE_BUTTON_WALL_E;
                break;
            case BLOCK_BUTTON_WALL_S:
                blockType = BLOCKTYPE_BUTTON_WALL_S;
                break;
            case BLOCK_BUTTON_WALL_W:
                blockType = BLOCKTYPE_BUTTON_WALL_W;
                break;
                
            case BLOCK_CHORUS_DOWN:
                blockType = BLOCKTYPE_CHORUS_DOWN;
                break;
            case BLOCK_CHORUS_UP_DOWN:
                blockType = BLOCKTYPE_CHORUS_UP_DOWN;
                break;
            case BLOCK_CHORUS_OTHER:
                blockType = BLOCKTYPE_CHORUS_OTHER;
                break;

            case BLOCK_DOOR_N:
                blockType = BLOCKTYPE_DOOR_N;
                break;
            case BLOCK_DOOR_E:
                blockType = BLOCKTYPE_DOOR_E;
                break;
            case BLOCK_DOOR_S:
                blockType = BLOCKTYPE_DOOR_S;
                break;
            case BLOCK_DOOR_W:
                blockType = BLOCKTYPE_DOOR_W;
                break;

            case BLOCK_LEVER_FLOOR_N_S:
                blockType = BLOCKTYPE_LEVER_FLOOR_N_S;
                break;
            case BLOCK_LEVER_FLOOR_W_E:
                blockType = BLOCKTYPE_LEVER_FLOOR_W_E;
                break;
            case BLOCK_LEVER_CEILING_N_S:
                blockType = BLOCKTYPE_LEVER_CEILING_N_S;
                break;
            case BLOCK_LEVER_CEILING_W_E:
                blockType = BLOCKTYPE_LEVER_CEILING_W_E;
                break;
            case BLOCK_LEVER_WALL_N:
                blockType = BLOCKTYPE_LEVER_WALL_N;
                break;
            case BLOCK_LEVER_WALL_E:
                blockType = BLOCKTYPE_LEVER_WALL_E;
                break;
            case BLOCK_LEVER_WALL_S:
                blockType = BLOCKTYPE_LEVER_WALL_S;
                break;
            case BLOCK_LEVER_WALL_W:
                blockType = BLOCKTYPE_LEVER_WALL_W;
                break;

            case BLOCK_TRAPDOOR_BOTTOM:
                blockType = BLOCKTYPE_TRAPDOOR_BOTTOM;
                break;
            case BLOCK_TRAPDOOR_TOP:
                blockType = BLOCKTYPE_TRAPDOOR_TOP;
                break;
            case BLOCK_TRAPDOOR_N:
                blockType = BLOCKTYPE_TRAPDOOR_N;
                break;
            case BLOCK_TRAPDOOR_E:
                blockType = BLOCKTYPE_TRAPDOOR_E;
                break;
            case BLOCK_TRAPDOOR_S:
                blockType = BLOCKTYPE_TRAPDOOR_S;
                break;
            case BLOCK_TRAPDOOR_W:
                blockType = BLOCKTYPE_TRAPDOOR_W;
                break;

            case BLOCK_TRIPWIRE_HOOK_N:
                blockType = BLOCKTYPE_TRIPWIRE_HOOK_N;
                break;
            case BLOCK_TRIPWIRE_HOOK_E:
                blockType = BLOCKTYPE_TRIPWIRE_HOOK_E;
                break;
            case BLOCK_TRIPWIRE_HOOK_S:
                blockType = BLOCKTYPE_TRIPWIRE_HOOK_S;
                break;
            case BLOCK_TRIPWIRE_HOOK_W:
                blockType = BLOCKTYPE_TRIPWIRE_HOOK_W;
                break;

            case BLOCK_SLABS_BOTTOM:
            case BLOCK_SCULK_SENSOR:
            case BLOCK_SCULK_SHRIEKER:
                blockType = BLOCKTYPE_LAYERS_8;
                break;
            case BLOCK_SLABS_TOP:
                blockType = BLOCKTYPE_SLAB_TOP;
                break;

            case BLOCK_STAIRS_BOTTOM_N:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_N;
                break;
            case BLOCK_STAIRS_BOTTOM_E:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_E;
                break;
            case BLOCK_STAIRS_BOTTOM_S:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_S;
                break;
            case BLOCK_STAIRS_BOTTOM_W:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_W;
                break;
            case BLOCK_STAIRS_BOTTOM_INNER_N_W:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_INNER_N_W;
                break;
            case BLOCK_STAIRS_BOTTOM_INNER_N_E:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_INNER_N_E;
                break;
            case BLOCK_STAIRS_BOTTOM_INNER_S_W:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_INNER_S_W;
                break;
            case BLOCK_STAIRS_BOTTOM_INNER_S_E:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_INNER_S_E;
                break;
            case BLOCK_STAIRS_BOTTOM_OUTER_N_W:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_OUTER_N_W;
                break;
            case BLOCK_STAIRS_BOTTOM_OUTER_N_E:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_OUTER_N_E;
                break;
            case BLOCK_STAIRS_BOTTOM_OUTER_S_W:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_OUTER_S_W;
                break;
            case BLOCK_STAIRS_BOTTOM_OUTER_S_E:
                blockType = BLOCKTYPE_STAIRS_BOTTOM_OUTER_S_E;
                break;
            case BLOCK_STAIRS_TOP_N:
                blockType = BLOCKTYPE_STAIRS_TOP_N;
                break;
            case BLOCK_STAIRS_TOP_E:
                blockType = BLOCKTYPE_STAIRS_TOP_E;
                break;
            case BLOCK_STAIRS_TOP_S:
                blockType = BLOCKTYPE_STAIRS_TOP_S;
                break;
            case BLOCK_STAIRS_TOP_W:
                blockType = BLOCKTYPE_STAIRS_TOP_W;
                break;
            case BLOCK_STAIRS_TOP_INNER_N_W:
                blockType = BLOCKTYPE_STAIRS_TOP_INNER_N_W;
                break;
            case BLOCK_STAIRS_TOP_INNER_N_E:
                blockType = BLOCKTYPE_STAIRS_TOP_INNER_N_E;
                break;
            case BLOCK_STAIRS_TOP_INNER_S_W:
                blockType = BLOCKTYPE_STAIRS_TOP_INNER_S_W;
                break;
            case BLOCK_STAIRS_TOP_INNER_S_E:
                blockType = BLOCKTYPE_STAIRS_TOP_INNER_S_E;
                break;
            case BLOCK_STAIRS_TOP_OUTER_N_W:
                blockType = BLOCKTYPE_STAIRS_TOP_OUTER_N_W;
                break;
            case BLOCK_STAIRS_TOP_OUTER_N_E:
                blockType = BLOCKTYPE_STAIRS_TOP_OUTER_N_E;
                break;
            case BLOCK_STAIRS_TOP_OUTER_S_W:
                blockType = BLOCKTYPE_STAIRS_TOP_OUTER_S_W;
                break;
            case BLOCK_STAIRS_TOP_OUTER_S_E:
                blockType = BLOCKTYPE_STAIRS_TOP_OUTER_S_E;
                break;
        }

        switch (blockId) {
            case BLOCK_FENCE_POST:
                blockType = BLOCKTYPE_FENCE_POST;
                break;
            case BLOCK_FENCE_N:
                blockType = BLOCKTYPE_FENCE_N;
                break;
            case BLOCK_FENCE_E:
                blockType = BLOCKTYPE_FENCE_E;
                break;
            case BLOCK_FENCE_S:
                blockType = BLOCKTYPE_FENCE_S;
                break;
            case BLOCK_FENCE_W:
                blockType = BLOCKTYPE_FENCE_W;
                break;
            case BLOCK_FENCE_N_S:
                blockType = BLOCKTYPE_FENCE_N_S;
                break;
            case BLOCK_FENCE_W_E:
                blockType = BLOCKTYPE_FENCE_W_E;
                break;
            case BLOCK_FENCE_N_W:
                blockType = BLOCKTYPE_FENCE_N_W;
                break;
            case BLOCK_FENCE_N_E:
                blockType = BLOCKTYPE_FENCE_N_E;
                break;
            case BLOCK_FENCE_S_W:
                blockType = BLOCKTYPE_FENCE_S_W;
                break;
            case BLOCK_FENCE_S_E:
                blockType = BLOCKTYPE_FENCE_S_E;
                break;
            case BLOCK_FENCE_W_N_E:
                blockType = BLOCKTYPE_FENCE_W_N_E;
                break;
            case BLOCK_FENCE_W_S_E:
                blockType = BLOCKTYPE_FENCE_W_S_E;
                break;
            case BLOCK_FENCE_N_W_S:
                blockType = BLOCKTYPE_FENCE_N_W_S;
                break;
            case BLOCK_FENCE_N_E_S:
                blockType = BLOCKTYPE_FENCE_N_E_S;
                break;
            case BLOCK_FENCE_ALL:
                blockType = BLOCKTYPE_FENCE_ALL;
                break;

            case BLOCK_FENCE_GATE_CLOSED_N_S:
                blockType = BLOCKTYPE_FENCE_GATE_CLOSED_N_S;
                break;
            case BLOCK_FENCE_GATE_CLOSED_W_E:
                blockType = BLOCKTYPE_FENCE_GATE_CLOSED_W_E;
                break;
        }

        switch (blockId) {
            case BLOCK_WALL_POST:
                blockType = BLOCKTYPE_WALL_POST;
                break;
            case BLOCK_WALL_POST_LOW_N:
                blockType = BLOCKTYPE_WALL_POST_LOW_N;
                break;
            case BLOCK_WALL_POST_LOW_E:
                blockType = BLOCKTYPE_WALL_POST_LOW_E;
                break;
            case BLOCK_WALL_POST_LOW_S:
                blockType = BLOCKTYPE_WALL_POST_LOW_S;
                break;
            case BLOCK_WALL_POST_LOW_W:
                blockType = BLOCKTYPE_WALL_POST_LOW_W;
                break;
            case BLOCK_WALL_POST_LOW_N_S:
                blockType = BLOCKTYPE_WALL_POST_LOW_N_S;
                break;
            case BLOCK_WALL_POST_LOW_W_E:
                blockType = BLOCKTYPE_WALL_POST_LOW_W_E;
                break;
            case BLOCK_WALL_POST_LOW_N_W:
                blockType = BLOCKTYPE_WALL_POST_LOW_N_W;
                break;
            case BLOCK_WALL_POST_LOW_N_E:
                blockType = BLOCKTYPE_WALL_POST_LOW_N_E;
                break;
            case BLOCK_WALL_POST_LOW_S_W:
                blockType = BLOCKTYPE_WALL_POST_LOW_S_W;
                break;
            case BLOCK_WALL_POST_LOW_S_E:
                blockType = BLOCKTYPE_WALL_POST_LOW_S_E;
                break;
            case BLOCK_WALL_POST_LOW_N_W_S:
                blockType = BLOCKTYPE_WALL_POST_LOW_N_W_S;
                break;
            case BLOCK_WALL_POST_LOW_N_E_S:
                blockType = BLOCKTYPE_WALL_POST_LOW_N_E_S;
                break;
            case BLOCK_WALL_POST_LOW_W_N_E:
                blockType = BLOCKTYPE_WALL_POST_LOW_W_N_E;
                break;
            case BLOCK_WALL_POST_LOW_W_S_E:
                blockType = BLOCKTYPE_WALL_POST_LOW_W_S_E;
                break;
            case BLOCK_WALL_POST_LOW_ALL:
                blockType = BLOCKTYPE_WALL_POST_LOW_ALL;
                break;
            case BLOCK_WALL_POST_TALL_N:
                blockType = BLOCKTYPE_WALL_POST_TALL_N;
                break;
            case BLOCK_WALL_POST_TALL_E:
                blockType = BLOCKTYPE_WALL_POST_TALL_E;
                break;
            case BLOCK_WALL_POST_TALL_S:
                blockType = BLOCKTYPE_WALL_POST_TALL_S;
                break;
            case BLOCK_WALL_POST_TALL_W:
                blockType = BLOCKTYPE_WALL_POST_TALL_W;
                break;
            case BLOCK_WALL_POST_TALL_N_S:
                blockType = BLOCKTYPE_WALL_POST_TALL_N_S;
                break;
            case BLOCK_WALL_POST_TALL_W_E:
                blockType = BLOCKTYPE_WALL_POST_TALL_W_E;
                break;
            case BLOCK_WALL_POST_TALL_N_W:
                blockType = BLOCKTYPE_WALL_POST_TALL_N_W;
                break;
            case BLOCK_WALL_POST_TALL_N_E:
                blockType = BLOCKTYPE_WALL_POST_TALL_N_E;
                break;
            case BLOCK_WALL_POST_TALL_S_W:
                blockType = BLOCKTYPE_WALL_POST_TALL_S_W;
                break;
            case BLOCK_WALL_POST_TALL_S_E:
                blockType = BLOCKTYPE_WALL_POST_TALL_S_E;
                break;
            case BLOCK_WALL_POST_TALL_N_W_S:
                blockType = BLOCKTYPE_WALL_POST_TALL_N_W_S;
                break;
            case BLOCK_WALL_POST_TALL_N_E_S:
                blockType = BLOCKTYPE_WALL_POST_TALL_N_E_S;
                break;
            case BLOCK_WALL_POST_TALL_W_N_E:
                blockType = BLOCKTYPE_WALL_POST_TALL_W_N_E;
                break;
            case BLOCK_WALL_POST_TALL_W_S_E:
                blockType = BLOCKTYPE_WALL_POST_TALL_W_S_E;
                break;
            case BLOCK_WALL_POST_TALL_ALL:
                blockType = BLOCKTYPE_WALL_POST_TALL_ALL;
                break;
            case BLOCK_WALL_LOW_N_S:
                blockType = BLOCKTYPE_WALL_LOW_N_S;
                break;
            case BLOCK_WALL_LOW_W_E:
                blockType = BLOCKTYPE_WALL_LOW_W_E;
                break;
            case BLOCK_WALL_TALL_N_S:
                blockType = BLOCKTYPE_WALL_TALL_N_S;
                break;
            case BLOCK_WALL_TALL_W_E:
                blockType = BLOCKTYPE_WALL_TALL_W_E;
                break;
        }

        switch (blockId) {
            case BLOCK_AMETHYST:
                blockType = BLOCKTYPE_AMETHYST;
                break;
            case BLOCK_DIAMOND:
                blockType = BLOCKTYPE_DIAMOND;
                break;
            case BLOCK_EMERALD:
                blockType = BLOCKTYPE_EMERALD;
                break;
            case BLOCK_HONEY:
                blockType = BLOCKTYPE_HONEY;
                break;
            case BLOCK_SLIME:
                blockType = BLOCKTYPE_SLIME;
                break;
            case BLOCK_SNOW:
                blockType = BLOCKTYPE_SNOW;
                break;
            case BLOCK_STAINED_GLASS_BLACK:
                blockType = BLOCKTYPE_STAINED_GLASS_BLACK;
                break;
            case BLOCK_STAINED_GLASS_BLUE:
                blockType = BLOCKTYPE_STAINED_GLASS_BLUE;
                break;
            case BLOCK_STAINED_GLASS_BROWN:
                blockType = BLOCKTYPE_STAINED_GLASS_BROWN;
                break;
            case BLOCK_STAINED_GLASS_CYAN:
                blockType = BLOCKTYPE_STAINED_GLASS_CYAN;
                break;
            case BLOCK_STAINED_GLASS_GRAY:
                blockType = BLOCKTYPE_STAINED_GLASS_GRAY;
                break;
            case BLOCK_STAINED_GLASS_GREEN:
                blockType = BLOCKTYPE_STAINED_GLASS_GREEN;
                break;
            case BLOCK_STAINED_GLASS_LIGHT_BLUE:
                blockType = BLOCKTYPE_STAINED_GLASS_LIGHT_BLUE;
                break;
            case BLOCK_STAINED_GLASS_LIGHT_GRAY:
                blockType = BLOCKTYPE_STAINED_GLASS_LIGHT_GRAY;
                break;
            case BLOCK_STAINED_GLASS_LIME:
                blockType = BLOCKTYPE_STAINED_GLASS_LIME;
                break;
            case BLOCK_STAINED_GLASS_MAGENTA:
                blockType = BLOCKTYPE_STAINED_GLASS_MAGENTA;
                break;
            case BLOCK_STAINED_GLASS_ORANGE:
                blockType = BLOCKTYPE_STAINED_GLASS_ORANGE;
                break;
            case BLOCK_STAINED_GLASS_PINK:
                blockType = BLOCKTYPE_STAINED_GLASS_PINK;
                break;
            case BLOCK_STAINED_GLASS_PURPLE:
                blockType = BLOCKTYPE_STAINED_GLASS_PURPLE;
                break;
            case BLOCK_STAINED_GLASS_RED:
                blockType = BLOCKTYPE_STAINED_GLASS_RED;
                break;
            case BLOCK_STAINED_GLASS_WHITE:
            case BLOCK_LEAVES:
                blockType = BLOCKTYPE_STAINED_GLASS_WHITE;
                break;
            case BLOCK_STAINED_GLASS_YELLOW:
                blockType = BLOCKTYPE_STAINED_GLASS_YELLOW;
                break;
        }

        return blockType;
    }
#endif
