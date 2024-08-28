uint BuildLpvMask(const in uint north, const in uint east, const in uint south, const in uint west, const in uint up, const in uint down) {
    return east | (west << 1) | (down << 2) | (up << 3) | (south << 4) | (north << 5);
}

void GetLpvBlockMask(const in uint blockId, out float mixWeight, out uint mixMask) {
    mixWeight = 0.0;
    mixMask = 0xFFFF;

    if (IsTraceOpenBlock(blockId)) mixWeight = 1.0;

    if (blockId == BLOCK_LEAVES || blockId == BLOCK_LEAVES_CHERRY) {
        mixWeight = 0.6;
    }
    // DOOR
    else if (blockId == BLOCK_DOOR_N) {
        mixMask = BuildLpvMask(0u, 1u, 1u, 1u, 1u, 1u);
        mixWeight = 1.0;
    }
    if (blockId == BLOCK_DOOR_S) {
        mixMask = BuildLpvMask(1u, 1u, 0u, 1u, 1u, 1u);
        mixWeight = 1.0;
    }
    else if (blockId == BLOCK_DOOR_W) {
        mixMask = BuildLpvMask(1u, 1u, 1u, 0u, 1u, 1u);
        mixWeight = 1.0;
    }
    else if (blockId == BLOCK_DOOR_E) {
        mixMask = BuildLpvMask(1u, 0u, 1u, 1u, 1u, 1u);
        mixWeight = 1.0;
    }
    // SLAB
    else if (blockId == BLOCK_SLAB_TOP) {
        mixMask = BuildLpvMask(1u, 1u, 1u, 1u, 0u, 1u);
        mixWeight = 0.5;
    }
    else if (blockId == BLOCK_SLAB_BOTTOM) {
        mixMask = BuildLpvMask(1u, 1u, 1u, 1u, 1u, 0u);
        mixWeight = 0.5;
    }
    // COPYCAT PANEL
    else if (blockId >= BLOCK_CREATE_COPYCAT_PANEL_N && blockId <= BLOCK_CREATE_COPYCAT_PANEL_DOWN) {
        mixWeight = 0.85;

        if (blockId == BLOCK_CREATE_COPYCAT_PANEL_N) {
            mixMask = BuildLpvMask(0u, 1u, 1u, 1u, 1u, 1u);
        }
        else if (blockId == BLOCK_CREATE_COPYCAT_PANEL_E) {
            mixMask = BuildLpvMask(1u, 0u, 1u, 1u, 1u, 1u);
        }
        else if (blockId == BLOCK_CREATE_COPYCAT_PANEL_S) {
            mixMask = BuildLpvMask(1u, 1u, 0u, 1u, 1u, 1u);
        }
        else if (blockId == BLOCK_CREATE_COPYCAT_PANEL_W) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 0u, 1u, 1u);
        }
        else if (blockId == BLOCK_CREATE_COPYCAT_PANEL_UP) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 1u, 1u, 0u);
        }
        else if (blockId == BLOCK_CREATE_COPYCAT_PANEL_DOWN) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 1u, 0u, 1u);
        }
    }
    // STAIRS
    else if (blockId >= BLOCK_STAIRS_MIN && blockId <= BLOCK_STAIRS_MAX) {
        mixWeight = 0.25;

        if (blockId == BLOCK_STAIRS_BOTTOM_N) {
            mixMask = BuildLpvMask(1u, 1u, 0u, 1u, 1u, 0u);
        }
        else if (blockId == BLOCK_STAIRS_BOTTOM_E) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 0u, 1u, 0u);
        }
        else if (blockId == BLOCK_STAIRS_BOTTOM_S) {
            mixMask = BuildLpvMask(0u, 1u, 1u, 1u, 1u, 0u);
        }
        else if (blockId == BLOCK_STAIRS_BOTTOM_W) {
            mixMask = BuildLpvMask(1u, 0u, 1u, 1u, 1u, 0u);
        }
        else if (blockId == BLOCK_STAIRS_BOTTOM_INNER_S_E) {
            mixMask = BuildLpvMask(0u, 1u, 1u, 0u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_BOTTOM_INNER_S_W) {
            mixMask = BuildLpvMask(0u, 0u, 1u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_BOTTOM_INNER_N_W) {
            mixMask = BuildLpvMask(1u, 0u, 0u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_BOTTOM_INNER_N_E) {
            mixMask = BuildLpvMask(1u, 1u, 0u, 0u, 0u, 1u);
        }
        else if (blockId >= BLOCK_STAIRS_BOTTOM_OUTER_N_W && blockId <= BLOCK_STAIRS_BOTTOM_OUTER_S_W) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_TOP_N) {
            mixMask = BuildLpvMask(1u, 1u, 0u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_TOP_E) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 0u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_TOP_S) {
            mixMask = BuildLpvMask(0u, 1u, 1u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_TOP_W) {
            mixMask = BuildLpvMask(1u, 0u, 1u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_TOP_INNER_S_E) {
            mixMask = BuildLpvMask(0u, 1u, 1u, 0u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_TOP_INNER_S_W) {
            mixMask = BuildLpvMask(0u, 0u, 1u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_TOP_INNER_N_W) {
            mixMask = BuildLpvMask(1u, 0u, 0u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_STAIRS_TOP_INNER_N_E) {
            mixMask = BuildLpvMask(1u, 1u, 0u, 0u, 0u, 1u);
        }
        else if (blockId >= BLOCK_STAIRS_TOP_OUTER_N_W && blockId <= BLOCK_STAIRS_TOP_OUTER_S_W) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 1u, 0u, 1u);
        }
    }
    // WALL
    else if (blockId >= BLOCK_WALL_MIN && blockId <= BLOCK_WALL_MAX) {
        mixWeight = 0.25;

        if (blockId == BLOCK_WALL_POST_TALL_ALL || blockId == BLOCK_WALL_TALL_ALL
              || blockId == BLOCK_WALL_POST_TALL_N_W_S
              || blockId == BLOCK_WALL_POST_TALL_N_E_S
              || blockId == BLOCK_WALL_POST_TALL_W_N_E
              || blockId == BLOCK_WALL_POST_TALL_W_S_E) {
            mixMask = BuildLpvMask(0u, 0u, 0u, 0u, 1u, 1u);
            mixWeight = 0.125;
        }
        else if (blockId == BLOCK_WALL_POST_TALL_N_S || blockId == BLOCK_WALL_TALL_N_S) {
            mixMask = BuildLpvMask(1u, 0u, 1u, 0u, 1u, 1u);
        }
        else if (blockId == BLOCK_WALL_POST_TALL_W_E || blockId == BLOCK_WALL_TALL_W_E) {
            mixMask = BuildLpvMask(0u, 1u, 0u, 1u, 1u, 1u);
        }
        // TODO: more walls
    }
    // TRAPDOOR
    else if (blockId >= BLOCK_TRAPDOOR_MIN && blockId <= BLOCK_TRAPDOOR_MAX) {
        mixWeight = 1.0;

        if (blockId == BLOCK_TRAPDOOR_BOTTOM) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 1u, 1u, 0u);
        }
        else if (blockId == BLOCK_TRAPDOOR_TOP) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 1u, 0u, 1u);
        }
        else if (blockId == BLOCK_TRAPDOOR_N) {
            mixMask = BuildLpvMask(0u, 1u, 1u, 1u, 1u, 1u);
        }
        else if (blockId == BLOCK_TRAPDOOR_E) {
            mixMask = BuildLpvMask(1u, 0u, 1u, 1u, 1u, 1u);
        }
        else if (blockId == BLOCK_TRAPDOOR_S) {
            mixMask = BuildLpvMask(1u, 1u, 0u, 1u, 1u, 1u);
        }
        else if (blockId == BLOCK_TRAPDOOR_W) {
            mixMask = BuildLpvMask(1u, 1u, 1u, 0u, 1u, 1u);
        }
    }
}
