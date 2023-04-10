bool BoxRayTest(const in vec3 boxMin, const in vec3 boxMax, const in vec3 rayStart, const in vec3 rayInv) {
    vec3 t1 = (boxMin - rayStart) * rayInv;
    vec3 t2 = (boxMax - rayStart) * rayInv;

    vec3 tmin = min(t1, t2);
    vec3 tmax = max(t1, t2);

    float rmin = maxOf(tmin);
    float rmax = minOf(tmax);

    return !isinf(rmin) && rmax >= max(rmin, 0.0);
    //return rmax >= rmin;
}

bool BoxPointTest(const in vec3 boxMin, const in vec3 boxMax, const in vec3 point) {
    return all(greaterThanEqual(point, boxMin)) && all(lessThanEqual(point, boxMax));
}

bool TraceHitTest(const in uint blockType, const in vec3 rayStart, const in vec3 rayInv) {
    vec3 boundsMin = vec3(-1.0);
    vec3 boundsMax = vec3(-1.0);

    switch (blockType) {
        case BLOCKTYPE_SOLID:
        //case BLOCKTYPE_DIAMOND:
        //case BLOCKTYPE_EMERALD:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCKTYPE_LAYERS_2:
        case BLOCKTYPE_LECTERN:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (2.0/16.0), 1.0);
            break;
        case BLOCKTYPE_LAYERS_4:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (4.0/16.0), 1.0);
            break;
        case BLOCKTYPE_LAYERS_6:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (6.0/16.0), 1.0);
            break;
        case BLOCKTYPE_LAYERS_8:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (8.0/16.0), 1.0);
            break;
        case BLOCKTYPE_LAYERS_10:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (10.0/16.0), 1.0);
            break;
        case BLOCKTYPE_LAYERS_12:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (12.0/16.0), 1.0);
            break;
        case BLOCKTYPE_LAYERS_14:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (14.0/16.0), 1.0);
            break;

        case BLOCKTYPE_ANVIL_N_S:
            boundsMin = vec3(( 3.0/16.0), (10.0/16.0), 0.0);
            boundsMax = vec3((13.0/16.0),         1.0, 1.0);
            break;
        case BLOCKTYPE_ANVIL_W_E:
            boundsMin = vec3(0.0, (10.0/16.0), ( 3.0/16.0));
            boundsMax = vec3(1.0,         1.0, (13.0/16.0));
            break;

        case BLOCKTYPE_BELL_FLOOR_N_S:
        case BLOCKTYPE_BELL_FLOOR_W_E:
            boundsMin = vec3(( 5.0/16.0), ( 6.0/16.0), ( 5.0/16.0));
            boundsMax = vec3((11.0/16.0), (13.0/16.0), (11.0/16.0));
            break;

        case BLOCKTYPE_CACTUS:
            boundsMin = vec3(( 1.0/16.0), 0.0, ( 1.0/16.0));
            boundsMax = vec3((15.0/16.0), 1.0, (15.0/16.0));
            break;

        case BLOCKTYPE_CAMPFIRE_N_S:
            boundsMin = vec3( (1.0/16.0),        0.0, 0.0);
            boundsMax = vec3((15.0/16.0), (4.0/16.0), 1.0);
            break;
        case BLOCKTYPE_CAMPFIRE_W_E:
            boundsMin = vec3(0.0,        0.0,  (1.0/16.0));
            boundsMax = vec3(1.0, (4.0/16.0), (15.0/16.0));
            break;

        case BLOCKTYPE_CAKE:
        case BLOCKTYPE_CANDLE_CAKE:
            boundsMin = vec3(( 1.0/16.0), 0.0, ( 1.0/16.0));
            boundsMax = vec3((15.0/16.0), 0.5, (15.0/16.0));
            break;

        case BLOCKTYPE_CARPET:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (1.0/16.0), 1.0);
            break;

        case BLOCKTYPE_CAULDRON:
            boundsMin = vec3(0.0, (3.0/16.0), 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCKTYPE_END_PORTAL_FRAME:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (13.0/16.0), 1.0);
            break;

        case BLOCKTYPE_FLOWER_POT:
            boundsMin = vec3((5.0/16.0), 0.0, (5.0/16.0));
            boundsMax = vec3((10.0/16.0), (6.0/16.0), (10.0/16.0));
            break;

        case BLOCKTYPE_GRINDSTONE_FLOOR_N_S:
            boundsMin = vec3(0.25, 0.25, ( 2.0/16.0));
            boundsMax = vec3(0.75, 1.00, (14.0/16.0));
            break;
        case BLOCKTYPE_GRINDSTONE_FLOOR_W_E:
            boundsMin = vec3(( 2.0/16.0), 0.25, 0.25);
            boundsMax = vec3((14.0/16.0), 1.00, 0.75);
            break;
        case BLOCKTYPE_GRINDSTONE_WALL_N_S:
            boundsMin = vec3(0.25, ( 2.0/16.0), ( 2.0/16.0));
            boundsMax = vec3(0.75, (14.0/16.0), (14.0/16.0));
            break;
        case BLOCKTYPE_GRINDSTONE_WALL_W_E:
            boundsMin = vec3(( 2.0/16.0), ( 2.0/16.0), 0.25);
            boundsMax = vec3((14.0/16.0), (14.0/16.0), 0.75);
            break;

        case BLOCKTYPE_HOPPER_DOWN:
        case BLOCKTYPE_HOPPER_N:
        case BLOCKTYPE_HOPPER_E:
        case BLOCKTYPE_HOPPER_S:
        case BLOCKTYPE_HOPPER_W:
            boundsMin = vec3(0.0, (10.0/16.0), 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCKTYPE_LANTERN_CEIL:
            boundsMin = vec3(( 5.0/16.0), (1.0/16.0), ( 5.0/16.0));
            boundsMax = vec3((11.0/16.0), (8.0/16.0), (11.0/16.0));
            break;
        case BLOCKTYPE_LANTERN_FLOOR:
            boundsMin = vec3(( 5.0/16.0),       0.0 , ( 5.0/16.0));
            boundsMax = vec3((11.0/16.0), (7.0/16.0), (11.0/16.0));
            break;

        case BLOCKTYPE_LIGHTNING_ROD_N:
        case BLOCKTYPE_LIGHTNING_ROD_S:
            boundsMin = vec3((7.0/16.0), (7.0/16.0), 0.0);
            boundsMax = vec3((9.0/16.0), (9.0/16.0), 1.0);
            break;
        case BLOCKTYPE_LIGHTNING_ROD_W:
        case BLOCKTYPE_LIGHTNING_ROD_E:
            boundsMin = vec3(0.0, (7.0/16.0), (7.0/16.0));
            boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
            break;
        case BLOCKTYPE_LIGHTNING_ROD_UP:
        case BLOCKTYPE_LIGHTNING_ROD_DOWN:
            boundsMin = vec3((7.0/16.0), 0.0, (7.0/16.0));
            boundsMax = vec3((9.0/16.0), 1.0, (9.0/16.0));
            break;

        case BLOCKTYPE_PATHWAY:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (15.0/16.0), 1.0);
            break;

        case BLOCKTYPE_PISTON_EXTENDED_N:
            boundsMin = vec3(0.0, 0.0, 0.25);
            boundsMax = vec3(1.0);
            break;
        case BLOCKTYPE_PISTON_EXTENDED_E:
            boundsMin = vec3(0.0);
            boundsMax = vec3(0.75, 1.0, 1.0);
            break;
        case BLOCKTYPE_PISTON_EXTENDED_S:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, 0.75);
            break;
        case BLOCKTYPE_PISTON_EXTENDED_W:
            boundsMin = vec3(0.25, 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCKTYPE_PISTON_EXTENDED_UP:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 0.75, 1.0);
            break;
        case BLOCKTYPE_PISTON_EXTENDED_DOWN:
            boundsMin = vec3(0.0, 0.25, 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCKTYPE_PISTON_HEAD_N:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, 0.25);
            break;
        case BLOCKTYPE_PISTON_HEAD_E:
            boundsMin = vec3(0.75, 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCKTYPE_PISTON_HEAD_S:
            boundsMin = vec3(0.0, 0.0, 0.75);
            boundsMax = vec3(1.0);
            break;
        case BLOCKTYPE_PISTON_HEAD_W:
            boundsMin = vec3(0.0);
            boundsMax = vec3(0.25, 1.0, 1.0);
            break;
        case BLOCKTYPE_PISTON_HEAD_UP:
            boundsMin = vec3(0.0, 0.75, 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCKTYPE_PISTON_HEAD_DOWN:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 0.25, 1.0);
            break;

        case BLOCKTYPE_PRESSURE_PLATE:
            boundsMin = vec3((1.0/16.0), 0.0, (1.0/16.0));
            boundsMax = vec3((15.0/16.0), (1.0/16.0), (15.0/16.0));
            break;

        case BLOCKTYPE_STONECUTTER:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (9.0/16.0), 1.0);
            break;

        case BLOCKTYPE_BUTTON_FLOOR_N_S:
            boundsMin = vec3(( 5.0/16.0), 0.000, ( 6.0/16.0));
            boundsMax = vec3((11.0/16.0), 0.125, (10.0/16.0));
            break;
        case BLOCKTYPE_BUTTON_FLOOR_W_E:
            boundsMin = vec3(( 6.0/16.0), 0.000, ( 5.0/16.0));
            boundsMax = vec3((10.0/16.0), 0.125, (11.0/16.0));
            break;
        case BLOCKTYPE_BUTTON_CEILING_N_S:
            boundsMin = vec3(( 5.0/16.0), 0.875, ( 6.0/16.0));
            boundsMax = vec3((11.0/16.0), 1.000, (10.0/16.0));
            break;
        case BLOCKTYPE_BUTTON_CEILING_W_E:
            boundsMin = vec3(( 6.0/16.0), 0.875, ( 5.0/16.0));
            boundsMax = vec3((10.0/16.0), 1.000, (11.0/16.0));
            break;
        case BLOCKTYPE_BUTTON_WALL_N:
            boundsMin = vec3(( 5.0/16.0), ( 6.0/16.0), 0.875);
            boundsMax = vec3((11.0/16.0), (10.0/16.0), 1.000);
            break;
        case BLOCKTYPE_BUTTON_WALL_E:
            boundsMin = vec3(0.000, ( 6.0/16.0), ( 5.0/16.0));
            boundsMax = vec3(0.125, (10.0/16.0), (11.0/16.0));
            break;
        case BLOCKTYPE_BUTTON_WALL_S:
            boundsMin = vec3(( 5.0/16.0), ( 6.0/16.0), 0.000);
            boundsMax = vec3((11.0/16.0), (10.0/16.0), 0.125);
            break;
        case BLOCKTYPE_BUTTON_WALL_W:
            boundsMin = vec3(0.875, ( 6.0/16.0), ( 5.0/16.0));
            boundsMax = vec3(1.000, (10.0/16.0), (11.0/16.0));
            break;

        case BLOCKTYPE_DOOR_N:
            boundsMin = vec3(0.0, 0.0, (13.0/16.0));
            boundsMax = vec3(1.0);
            break;
        case BLOCKTYPE_DOOR_E:
            boundsMin = vec3(0.0);
            boundsMax = vec3((3.0/16.0), 1.0, 1.0);
            break;
        case BLOCKTYPE_DOOR_S:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, (3.0/16.0));
            break;
        case BLOCKTYPE_DOOR_W:
            boundsMin = vec3((13.0/16.0), 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCKTYPE_LEVER_FLOOR_N_S:
            boundsMin = vec3(( 5.0/16.0),        0.0, ( 4.0/16.0));
            boundsMax = vec3((11.0/16.0), (3.0/16.0), (12.0/16.0));
            break;
        case BLOCKTYPE_LEVER_FLOOR_W_E:
            boundsMin = vec3(( 4.0/16.0),        0.0, ( 5.0/16.0));
            boundsMax = vec3((12.0/16.0), (3.0/16.0), (11.0/16.0));
            break;
        case BLOCKTYPE_LEVER_CEILING_N_S:
            boundsMin = vec3(( 5.0/16.0), (13.0/16.0), ( 4.0/16.0));
            boundsMax = vec3((11.0/16.0),         1.0, (12.0/16.0));
            break;
        case BLOCKTYPE_LEVER_CEILING_W_E:
            boundsMin = vec3(( 4.0/16.0), (13.0/16.0), ( 5.0/16.0));
            boundsMax = vec3((12.0/16.0),         1.0, (11.0/16.0));
            break;
        case BLOCKTYPE_LEVER_WALL_N:
            boundsMin = vec3(( 5.0/16.0), 0.25, (13.0/16.0));
            boundsMax = vec3((11.0/16.0), 0.75,         1.0);
            break;
        case BLOCKTYPE_LEVER_WALL_E:
            boundsMin = vec3(       0.0, 0.25, ( 5.0/16.0));
            boundsMax = vec3((3.0/16.0), 0.75, (11.0/16.0));
            break;
        case BLOCKTYPE_LEVER_WALL_S:
            boundsMin = vec3(( 5.0/16.0), 0.25,        0.0);
            boundsMax = vec3((11.0/16.0), 0.75, (3.0/16.0));
            break;
        case BLOCKTYPE_LEVER_WALL_W:
            boundsMin = vec3((13.0/16.0), 0.25, ( 5.0/16.0));
            boundsMax = vec3(        1.0, 0.75, (11.0/16.0));
            break;

        case BLOCKTYPE_TRAPDOOR_BOTTOM:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (3.0/16.0), 1.0);
            break;
        case BLOCKTYPE_TRAPDOOR_TOP:
            boundsMin = vec3(0.0, (13.0/16.0), 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCKTYPE_TRAPDOOR_N:
            boundsMin = vec3(0.0, 0.0, (13.0/16.0));
            boundsMax = vec3(1.0);
            break;
        case BLOCKTYPE_TRAPDOOR_E:
            boundsMin = vec3(0.0);
            boundsMax = vec3((3.0/16.0), 1.0, 1.0);
            break;
        case BLOCKTYPE_TRAPDOOR_S:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, (3.0/16.0));
            break;
        case BLOCKTYPE_TRAPDOOR_W:
            boundsMin = vec3((13.0/16.0), 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCKTYPE_TRIPWIRE_HOOK_N:
            boundsMin = vec3(0.375, (1.0/16.0), 0.875);
            boundsMax = vec3(0.625, (9.0/16.0), 1.000);
            break;
        case BLOCKTYPE_TRIPWIRE_HOOK_E:
            boundsMin = vec3(0.000, (1.0/16.0), 0.375);
            boundsMax = vec3(0.125, (9.0/16.0), 0.625);
            break;
        case BLOCKTYPE_TRIPWIRE_HOOK_S:
            boundsMin = vec3(0.375, (1.0/16.0), 0.000);
            boundsMax = vec3(0.625, (9.0/16.0), 0.125);
            break;
        case BLOCKTYPE_TRIPWIRE_HOOK_W:
            boundsMin = vec3(0.875, (1.0/16.0), 0.375);
            boundsMax = vec3(1.000, (9.0/16.0), 0.625);
            break;

        case BLOCKTYPE_STAIRS_BOTTOM_N:
        case BLOCKTYPE_STAIRS_BOTTOM_E:
        case BLOCKTYPE_STAIRS_BOTTOM_S:
        case BLOCKTYPE_STAIRS_BOTTOM_W:
        case BLOCKTYPE_STAIRS_BOTTOM_INNER_N_W:
        case BLOCKTYPE_STAIRS_BOTTOM_INNER_N_E:
        case BLOCKTYPE_STAIRS_BOTTOM_INNER_S_W:
        case BLOCKTYPE_STAIRS_BOTTOM_INNER_S_E:
        case BLOCKTYPE_STAIRS_BOTTOM_OUTER_N_W:
        case BLOCKTYPE_STAIRS_BOTTOM_OUTER_N_E:
        case BLOCKTYPE_STAIRS_BOTTOM_OUTER_S_W:
        case BLOCKTYPE_STAIRS_BOTTOM_OUTER_S_E:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 0.5, 1.0);
            break;
        case BLOCKTYPE_SLAB_TOP:
        case BLOCKTYPE_STAIRS_TOP_N:
        case BLOCKTYPE_STAIRS_TOP_E:
        case BLOCKTYPE_STAIRS_TOP_S:
        case BLOCKTYPE_STAIRS_TOP_W:
        case BLOCKTYPE_STAIRS_TOP_INNER_N_W:
        case BLOCKTYPE_STAIRS_TOP_INNER_N_E:
        case BLOCKTYPE_STAIRS_TOP_INNER_S_W:
        case BLOCKTYPE_STAIRS_TOP_INNER_S_E:
        case BLOCKTYPE_STAIRS_TOP_OUTER_N_W:
        case BLOCKTYPE_STAIRS_TOP_OUTER_N_E:
        case BLOCKTYPE_STAIRS_TOP_OUTER_S_W:
        case BLOCKTYPE_STAIRS_TOP_OUTER_S_E:
            boundsMin = vec3(0.0, 0.5, 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCKTYPE_FENCE_POST:
        case BLOCKTYPE_FENCE_N:
        case BLOCKTYPE_FENCE_E:
        case BLOCKTYPE_FENCE_S:
        case BLOCKTYPE_FENCE_W:
        case BLOCKTYPE_FENCE_N_S:
        case BLOCKTYPE_FENCE_W_E:
        case BLOCKTYPE_FENCE_N_W:
        case BLOCKTYPE_FENCE_N_E:
        case BLOCKTYPE_FENCE_S_W:
        case BLOCKTYPE_FENCE_S_E:
        case BLOCKTYPE_FENCE_W_N_E:
        case BLOCKTYPE_FENCE_W_S_E:
        case BLOCKTYPE_FENCE_N_W_S:
        case BLOCKTYPE_FENCE_N_E_S:
        case BLOCKTYPE_FENCE_ALL:
            boundsMin = vec3(0.375, 0.0, 0.375);
            boundsMax = vec3(0.625, 1.0, 0.625);
            break;
        case BLOCKTYPE_FENCE_GATE_CLOSED_N_S:
            boundsMin = vec3(( 6.0/16.0), ( 9.0/16.0), (7.0/16.0));
            boundsMax = vec3((10.0/16.0), (12.0/16.0), (9.0/16.0));
            break;
        case BLOCKTYPE_FENCE_GATE_CLOSED_W_E:
            boundsMin = vec3((7.0/16.0), ( 9.0/16.0), ( 6.0/16.0));
            boundsMax = vec3((9.0/16.0), (12.0/16.0), (10.0/16.0));
            break;

        case BLOCKTYPE_WALL_POST:
        case BLOCKTYPE_WALL_POST_LOW_N:
        case BLOCKTYPE_WALL_POST_LOW_E:
        case BLOCKTYPE_WALL_POST_LOW_S:
        case BLOCKTYPE_WALL_POST_LOW_W:
        case BLOCKTYPE_WALL_POST_LOW_N_S:
        case BLOCKTYPE_WALL_POST_LOW_W_E:
        case BLOCKTYPE_WALL_POST_LOW_N_W:
        case BLOCKTYPE_WALL_POST_LOW_N_E:
        case BLOCKTYPE_WALL_POST_LOW_S_W:
        case BLOCKTYPE_WALL_POST_LOW_S_E:
        case BLOCKTYPE_WALL_POST_LOW_N_W_S:
        case BLOCKTYPE_WALL_POST_LOW_N_E_S:
        case BLOCKTYPE_WALL_POST_LOW_W_N_E:
        case BLOCKTYPE_WALL_POST_LOW_W_S_E:
        case BLOCKTYPE_WALL_POST_TALL_N:
        case BLOCKTYPE_WALL_POST_TALL_E:
        case BLOCKTYPE_WALL_POST_TALL_S:
        case BLOCKTYPE_WALL_POST_TALL_W:
        case BLOCKTYPE_WALL_POST_TALL_N_S:
        case BLOCKTYPE_WALL_POST_TALL_W_E:
        case BLOCKTYPE_WALL_POST_TALL_N_W_S:
        case BLOCKTYPE_WALL_POST_TALL_N_E_S:
        case BLOCKTYPE_WALL_POST_TALL_W_N_E:
        case BLOCKTYPE_WALL_POST_TALL_W_S_E:
        case BLOCKTYPE_WALL_POST_TALL_ALL:
            boundsMin = vec3(0.25, 0.0, 0.25);
            boundsMax = vec3(0.75, 1.0, 0.75);
            break;
        case BLOCKTYPE_WALL_LOW_N_S:
            boundsMin = vec3(0.3125, 0.0, 0.0);
            boundsMax = vec3(0.6875, (14.0/16.0), 1.0);
            break;
        case BLOCKTYPE_WALL_LOW_W_E:
            boundsMin = vec3(0.0, 0.0, 0.3125);
            boundsMax = vec3(1.0, (14.0/16.0), 0.6875);
            break;
        case BLOCKTYPE_WALL_TALL_N_S:
            boundsMin = vec3(0.3125, 0.0, 0.0);
            boundsMax = vec3(0.6875, 1.0, 1.0);
            break;
        case BLOCKTYPE_WALL_TALL_W_E:
            boundsMin = vec3(0.0, 0.0, 0.3125);
            boundsMax = vec3(1.0, 1.0, 0.6875);
            break;

        case BLOCKTYPE_CHORUS_DOWN:
            boundsMin = vec3(0.25,         0.0, 0.25);
            boundsMax = vec3(0.75, (13.0/16.0), 0.75);
            break;
        case BLOCKTYPE_CHORUS_UP_DOWN:
            boundsMin = vec3(0.25, 0.0, 0.25);
            boundsMax = vec3(0.75, 1.0, 0.75);
            break;
        case BLOCKTYPE_CHORUS_OTHER:
            boundsMin = vec3(0.25, 0.25, 0.25);
            boundsMax = vec3(0.75, 0.75, 0.75);
            break;
    }

    #if DYN_LIGHT_TRACE_METHOD == 1
        bool hit = BoxPointTest(boundsMin, boundsMax, rayStart);
    #else
        bool hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
    #endif

    if (!hit) {// && blockType >= 5u && blockType <= 28u) {
        boundsMin = vec3(-1.0);
        boundsMax = vec3(-1.0);

        switch (blockType) {
            case BLOCKTYPE_ANVIL_N_S:
                boundsMin = vec3(( 6.0/16.0), 0.25, 0.25);
                boundsMax = vec3((10.0/16.0), 0.75, 0.75);
                break;
            case BLOCKTYPE_ANVIL_W_E:
                boundsMin = vec3(0.25, 0.25, ( 6.0/16.0));
                boundsMax = vec3(0.75, 0.75, (10.0/16.0));
                break;

            case BLOCKTYPE_BELL_FLOOR_N_S:
            case BLOCKTYPE_BELL_FLOOR_W_E:
                boundsMin = vec3(0.25,       0.25, 0.25);
                boundsMax = vec3(0.75, (6.0/16.0), 0.75);
                break;

            case BLOCKTYPE_CAMPFIRE_N_S:
                boundsMin = vec3(0.0, (3.0/16.0), (1.0/16.0));
                boundsMax = vec3(1.0, (7.0/16.0), (5.0/16.0));
                break;
            case BLOCKTYPE_CAMPFIRE_W_E:
                boundsMin = vec3((1.0/16.0), (3.0/16.0), 0.0);
                boundsMax = vec3((5.0/16.0), (7.0/16.0), 1.0);
                break;

            case BLOCKTYPE_CANDLE_CAKE:
                boundsMin = vec3((7.0/16.0),         0.5, (7.0/16.0));
                boundsMax = vec3((9.0/16.0), (14.0/16.0), (9.0/16.0));
                break;

            case BLOCKTYPE_CAULDRON:
                boundsMin = vec3(0.0);
                boundsMax = vec3((4.0/16.0), (3.0/16.0), (4.0/16.0));
                break;

            case BLOCKTYPE_LANTERN_CEIL:
                boundsMin = vec3(( 6.0/16.0), ( 8.0/16.0), ( 6.0/16.0));
                boundsMax = vec3((10.0/16.0), (10.0/16.0), (10.0/16.0));
                break;
            case BLOCKTYPE_LANTERN_FLOOR:
                boundsMin = vec3(( 6.0/16.0), (7.0/16.0), ( 6.0/16.0));
                boundsMax = vec3((10.0/16.0), (9.0/16.0), (10.0/16.0));
                break;

            case BLOCKTYPE_LECTERN:
                boundsMin = vec3(0.25,         0.0, 0.25);
                boundsMax = vec3(0.75, (13.0/16.0), 0.75);
                break;

            case BLOCKTYPE_LIGHTNING_ROD_N:
                boundsMin = vec3( (6.0/16.0),  (6.0/16.0), 0.00);
                boundsMax = vec3((10.0/16.0), (10.0/16.0), 0.25);
                break;
            case BLOCKTYPE_LIGHTNING_ROD_E:
                boundsMin = vec3(0.75,  (6.0/16.0),  (6.0/16.0));
                boundsMax = vec3(1.00, (10.0/16.0), (10.0/16.0));
                break;
            case BLOCKTYPE_LIGHTNING_ROD_S:
                boundsMin = vec3( (6.0/16.0),  (6.0/16.0), 0.75);
                boundsMax = vec3((10.0/16.0), (10.0/16.0), 1.00);
                break;
            case BLOCKTYPE_LIGHTNING_ROD_W:
                boundsMin = vec3(0.00,  (6.0/16.0),  (6.0/16.0));
                boundsMax = vec3(0.25, (10.0/16.0), (10.0/16.0));
                break;
            case BLOCKTYPE_LIGHTNING_ROD_UP:
                boundsMin = vec3( (6.0/16.0), 0.75,  (6.0/16.0));
                boundsMax = vec3((10.0/16.0), 1.00, (10.0/16.0));
                break;
            case BLOCKTYPE_LIGHTNING_ROD_DOWN:
                boundsMin = vec3( (6.0/16.0), 0.00,  (6.0/16.0));
                boundsMax = vec3((10.0/16.0), 0.25, (10.0/16.0));
                break;

            case BLOCKTYPE_PISTON_HEAD_UP:
            case BLOCKTYPE_PISTON_HEAD_DOWN:
            case BLOCKTYPE_PISTON_EXTENDED_UP:
            case BLOCKTYPE_PISTON_EXTENDED_DOWN:
                boundsMin = vec3(0.375, 0.0, 0.375);
                boundsMax = vec3(0.625, 1.0, 0.625);
                break;
            case BLOCKTYPE_PISTON_HEAD_N:
            case BLOCKTYPE_PISTON_HEAD_S:
            case BLOCKTYPE_PISTON_EXTENDED_N:
            case BLOCKTYPE_PISTON_EXTENDED_S:
                boundsMin = vec3(0.375, 0.375, 0.0);
                boundsMax = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCKTYPE_PISTON_HEAD_W:
            case BLOCKTYPE_PISTON_HEAD_E:
            case BLOCKTYPE_PISTON_EXTENDED_W:
            case BLOCKTYPE_PISTON_EXTENDED_E:
                boundsMin = vec3(0.0, 0.375, 0.375);
                boundsMax = vec3(1.0, 0.625, 0.625);
                break;

            case BLOCKTYPE_STAIRS_BOTTOM_N:
            case BLOCKTYPE_STAIRS_BOTTOM_INNER_N_W:
            case BLOCKTYPE_STAIRS_BOTTOM_INNER_N_E:
                boundsMin = vec3(0.0, 0.5, 0.0);
                boundsMax = vec3(1.0, 1.0, 0.5);
                break;
            case BLOCKTYPE_STAIRS_BOTTOM_E:
                boundsMin = vec3(0.5, 0.5, 0.0);
                boundsMax = vec3(1.0, 1.0, 1.0);
                break;
            case BLOCKTYPE_STAIRS_BOTTOM_S:
            case BLOCKTYPE_STAIRS_BOTTOM_INNER_S_W:
            case BLOCKTYPE_STAIRS_BOTTOM_INNER_S_E:
                boundsMin = vec3(0.0, 0.5, 0.5);
                boundsMax = vec3(1.0, 1.0, 1.0);
                break;
            case BLOCKTYPE_STAIRS_BOTTOM_W:
                boundsMin = vec3(0.0, 0.5, 0.0);
                boundsMax = vec3(0.5, 1.0, 1.0);
                break;

            case BLOCKTYPE_STAIRS_TOP_N:
            case BLOCKTYPE_STAIRS_TOP_INNER_N_W:
            case BLOCKTYPE_STAIRS_TOP_INNER_N_E:
                boundsMin = vec3(0.0, 0.0, 0.0);
                boundsMax = vec3(1.0, 0.5, 0.5);
                break;
            case BLOCKTYPE_STAIRS_TOP_E:
                boundsMin = vec3(0.5, 0.0, 0.0);
                boundsMax = vec3(1.0, 0.5, 1.0);
                break;
            case BLOCKTYPE_STAIRS_TOP_S:
            case BLOCKTYPE_STAIRS_TOP_INNER_S_W:
            case BLOCKTYPE_STAIRS_TOP_INNER_S_E:
                boundsMin = vec3(0.0, 0.0, 0.5);
                boundsMax = vec3(1.0, 0.5, 1.0);
                break;
            case BLOCKTYPE_STAIRS_TOP_W:
                boundsMin = vec3(0.0, 0.0, 0.0);
                boundsMax = vec3(0.5, 0.5, 1.0);
                break;

            case BLOCKTYPE_FENCE_N:
            case BLOCKTYPE_FENCE_N_E:
                boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.0);
                boundsMax = vec3((9.0/16.0), (9.0/16.0), 0.5);
                break;
            case BLOCKTYPE_FENCE_E:
            case BLOCKTYPE_FENCE_S_E:
                boundsMin = vec3(0.5, (6.0/16.0), (7.0/16.0));
                boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
                break;
            case BLOCKTYPE_FENCE_S:
            case BLOCKTYPE_FENCE_S_W:
                boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.5);
                boundsMax = vec3((9.0/16.0), (9.0/16.0), 1.0);
                break;
            case BLOCKTYPE_FENCE_W:
            case BLOCKTYPE_FENCE_N_W:
                boundsMin = vec3(0.0, (6.0/16.0), (7.0/16.0));
                boundsMax = vec3(0.5, (9.0/16.0), (9.0/16.0));
                break;
            case BLOCKTYPE_FENCE_N_S:
            case BLOCKTYPE_FENCE_N_W_S:
            case BLOCKTYPE_FENCE_N_E_S:
            case BLOCKTYPE_FENCE_ALL:
            case BLOCKTYPE_FENCE_GATE_CLOSED_W_E:
                boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.0);
                boundsMax = vec3((9.0/16.0), (9.0/16.0), 1.0);
                break;
            case BLOCKTYPE_FENCE_W_E:
            case BLOCKTYPE_FENCE_W_N_E:
            case BLOCKTYPE_FENCE_W_S_E:
            case BLOCKTYPE_FENCE_GATE_CLOSED_N_S:
                boundsMin = vec3(0.0, (6.0/16.0), (7.0/16.0));
                boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
                break;

            case BLOCKTYPE_WALL_POST_LOW_N:
            case BLOCKTYPE_WALL_POST_LOW_N_E:
            case BLOCKTYPE_WALL_POST_LOW_W_N_E:
                boundsMin = vec3(0.3125, 0.000, 0.0);
                boundsMax = vec3(0.6875, 0.875, 0.5);
                break;
            case BLOCKTYPE_WALL_POST_LOW_E:
            case BLOCKTYPE_WALL_POST_LOW_S_E:
                boundsMin = vec3(0.5, 0.000, 0.3125);
                boundsMax = vec3(1.0, 0.875, 0.6875);
                break;
            case BLOCKTYPE_WALL_POST_LOW_S:
            case BLOCKTYPE_WALL_POST_LOW_S_W:
            case BLOCKTYPE_WALL_POST_LOW_W_S_E:
                boundsMin = vec3(0.3125, 0.000, 0.5);
                boundsMax = vec3(0.6875, 0.875, 1.0);
                break;
            case BLOCKTYPE_WALL_POST_LOW_W:
            case BLOCKTYPE_WALL_POST_LOW_N_W:
                boundsMin = vec3(0.0, 0.000, 0.3125);
                boundsMax = vec3(0.5, 0.875, 0.6875);
                break;

            case BLOCKTYPE_WALL_POST_TALL_N:
            case BLOCKTYPE_WALL_POST_TALL_N_E:
            case BLOCKTYPE_WALL_POST_TALL_W_N_E:
                boundsMin = vec3(0.3125, 0.0, 0.0);
                boundsMax = vec3(0.6875, 1.0, 0.5);
                break;
            case BLOCKTYPE_WALL_POST_TALL_E:
            case BLOCKTYPE_WALL_POST_TALL_S_E:
                boundsMin = vec3(0.5, 0.0, 0.3125);
                boundsMax = vec3(1.0, 1.0, 0.6875);
                break;
            case BLOCKTYPE_WALL_POST_TALL_S:
            case BLOCKTYPE_WALL_POST_TALL_S_W:
            case BLOCKTYPE_WALL_POST_TALL_W_S_E:
                boundsMin = vec3(0.3125, 0.0, 0.5);
                boundsMax = vec3(0.6875, 1.0, 1.0);
                break;
            case BLOCKTYPE_WALL_POST_TALL_W:
            case BLOCKTYPE_WALL_POST_TALL_N_W:
                boundsMin = vec3(0.0, 0.0, 0.3125);
                boundsMax = vec3(0.5, 1.0, 0.6875);
                break;

            case BLOCKTYPE_WALL_POST_LOW_ALL:
                boundsMin = vec3(0.0, 0.000, 0.3125);
                boundsMax = vec3(1.0, 0.875, 0.6875);
                break;
            case BLOCKTYPE_WALL_POST_TALL_ALL:
                boundsMin = vec3(0.0, 0.000, 0.3125);
                boundsMax = vec3(1.0, 0.875, 0.6875);
                break;

            case BLOCKTYPE_HOPPER_DOWN:
            case BLOCKTYPE_HOPPER_N:
            case BLOCKTYPE_HOPPER_E:
            case BLOCKTYPE_HOPPER_S:
            case BLOCKTYPE_HOPPER_W:
                boundsMin = vec3(0.25);
                boundsMax = vec3(0.75, 0.625, 0.75);
                break;
        }

        #if DYN_LIGHT_TRACE_METHOD == 1
            hit = BoxPointTest(boundsMin, boundsMax, rayStart);
        #else
            hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
        #endif

        if (!hit) {// && ((blockType >= 9u && blockType <= 16u) || (blockType >= 21u && blockType <= 28u))) {
            boundsMin = vec3(-1.0);
            boundsMax = vec3(-1.0);

            switch (blockType) {
                case BLOCKTYPE_ANVIL_N_S:
                case BLOCKTYPE_ANVIL_W_E:
                    boundsMin = vec3(( 2.0/16.0), 0.00, ( 2.0/16.0));
                    boundsMax = vec3((14.0/16.0), 0.25, (14.0/16.0));
                    break;

                case BLOCKTYPE_CAMPFIRE_N_S:
                    boundsMin = vec3(0.0, (3.0/16.0), (11.0/16.0));
                    boundsMax = vec3(1.0, (7.0/16.0), (15.0/16.0));
                    break;
                case BLOCKTYPE_CAMPFIRE_W_E:
                    boundsMin = vec3((11.0/16.0), (3.0/16.0), 0.0);
                    boundsMax = vec3((15.0/16.0), (7.0/16.0), 1.0);
                    break;

                case BLOCKTYPE_CAULDRON:
                    boundsMin = vec3((12.0/16.0),       0.0 ,       0.0 );
                    boundsMax = vec3(       1.0 , (3.0/16.0), (4.0/16.0));
                    break;

                case BLOCKTYPE_STAIRS_BOTTOM_INNER_N_W:
                case BLOCKTYPE_STAIRS_BOTTOM_OUTER_S_W:
                    boundsMin = vec3(0.0, 0.5, 0.5);
                    boundsMax = vec3(0.5, 1.0, 1.0);
                    break;
                case BLOCKTYPE_STAIRS_BOTTOM_INNER_S_W:
                case BLOCKTYPE_STAIRS_BOTTOM_OUTER_N_W:
                    boundsMin = vec3(0.0, 0.5, 0.0);
                    boundsMax = vec3(0.5, 1.0, 0.5);
                    break;
                case BLOCKTYPE_STAIRS_BOTTOM_INNER_N_E:
                case BLOCKTYPE_STAIRS_BOTTOM_OUTER_S_E:
                    boundsMin = vec3(0.5, 0.5, 0.5);
                    boundsMax = vec3(1.0, 1.0, 1.0);
                    break;
                case BLOCKTYPE_STAIRS_BOTTOM_INNER_S_E:
                case BLOCKTYPE_STAIRS_BOTTOM_OUTER_N_E:
                    boundsMin = vec3(0.5, 0.5, 0.0);
                    boundsMax = vec3(1.0, 1.0, 0.5);
                    break;

                case BLOCKTYPE_STAIRS_TOP_INNER_N_W:
                case BLOCKTYPE_STAIRS_TOP_OUTER_S_W:
                    boundsMin = vec3(0.0, 0.0, 0.5);
                    boundsMax = vec3(0.5, 0.5, 1.0);
                    break;
                case BLOCKTYPE_STAIRS_TOP_INNER_S_W:
                case BLOCKTYPE_STAIRS_TOP_OUTER_N_W:
                    boundsMin = vec3(0.0, 0.0, 0.0);
                    boundsMax = vec3(0.5, 0.5, 0.5);
                    break;
                case BLOCKTYPE_STAIRS_TOP_INNER_N_E:
                case BLOCKTYPE_STAIRS_TOP_OUTER_S_E:
                    boundsMin = vec3(0.5, 0.0, 0.5);
                    boundsMax = vec3(1.0, 0.5, 1.0);
                    break;
                case BLOCKTYPE_STAIRS_TOP_INNER_S_E:
                case BLOCKTYPE_STAIRS_TOP_OUTER_N_E:
                    boundsMin = vec3(0.5, 0.0, 0.0);
                    boundsMax = vec3(1.0, 0.5, 0.5);
                    break;

                case BLOCKTYPE_FENCE_N:
                case BLOCKTYPE_FENCE_N_E:
                    boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax = vec3((9.0/16.0), (15.0/16.0), 0.5);
                    break;
                case BLOCKTYPE_FENCE_E:
                case BLOCKTYPE_FENCE_S_E:
                    boundsMin = vec3(0.5, (12.0/16.0), (7.0/16.0));
                    boundsMax = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCKTYPE_FENCE_S:
                case BLOCKTYPE_FENCE_S_W:
                    boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.5);
                    boundsMax = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;
                case BLOCKTYPE_FENCE_W:
                case BLOCKTYPE_FENCE_N_W:
                    boundsMin = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax = vec3(0.5, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCKTYPE_FENCE_N_S:
                case BLOCKTYPE_FENCE_N_W_S:
                case BLOCKTYPE_FENCE_N_E_S:
                case BLOCKTYPE_FENCE_GATE_CLOSED_W_E:
                    boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;
                case BLOCKTYPE_FENCE_W_E:
                case BLOCKTYPE_FENCE_W_N_E:
                case BLOCKTYPE_FENCE_W_S_E:
                case BLOCKTYPE_FENCE_ALL:
                case BLOCKTYPE_FENCE_GATE_CLOSED_N_S:
                    boundsMin = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;

                case BLOCKTYPE_HOPPER_DOWN:
                    boundsMin = vec3(0.375, 0.00, 0.325);
                    boundsMax = vec3(0.625, 0.25, 0.675);
                    break;
                case BLOCKTYPE_HOPPER_N:
                    boundsMin = vec3(0.25, 0.25, 0.00);
                    boundsMax = vec3(0.75, 0.50, 0.25);
                    break;
                case BLOCKTYPE_HOPPER_E:
                    boundsMin = vec3(0.75, 0.25, 0.25);
                    boundsMax = vec3(1.00, 0.50, 0.75);
                    break;
                case BLOCKTYPE_HOPPER_S:
                    boundsMin = vec3(0.25, 0.25, 0.75);
                    boundsMax = vec3(0.75, 0.50, 1.00);
                    break;
                case BLOCKTYPE_HOPPER_W:
                    boundsMin = vec3(0.00, 0.25, 0.25);
                    boundsMax = vec3(0.25, 0.50, 0.75);
                    break;

                case BLOCKTYPE_WALL_POST_LOW_N_S:
                case BLOCKTYPE_WALL_POST_LOW_N_W_S:
                case BLOCKTYPE_WALL_POST_LOW_N_E_S:
                case BLOCKTYPE_WALL_POST_LOW_ALL:
                    boundsMin = vec3(0.3125, 0.000, 0.0);
                    boundsMax = vec3(0.6875, 0.875, 1.0);
                    break;
                case BLOCKTYPE_WALL_POST_LOW_W_E:
                case BLOCKTYPE_WALL_POST_LOW_W_N_E:
                case BLOCKTYPE_WALL_POST_LOW_W_S_E:
                    boundsMin = vec3(0.0, 0.000, 0.3125);
                    boundsMax = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCKTYPE_WALL_POST_LOW_N_W:
                    boundsMin = vec3(0.3125, 0.000, 0.0);
                    boundsMax = vec3(0.6875, 0.875, 0.5);
                    break;
                case BLOCKTYPE_WALL_POST_LOW_N_E:
                    boundsMin = vec3(0.5, 0.000, 0.3125);
                    boundsMax = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCKTYPE_WALL_POST_LOW_S_E:
                    boundsMin = vec3(0.3125, 0.000, 0.5);
                    boundsMax = vec3(0.6875, 0.875, 1.0);
                    break;
                case BLOCKTYPE_WALL_POST_LOW_S_W:
                    boundsMin = vec3(0.0, 0.000, 0.3125);
                    boundsMax = vec3(0.5, 0.875, 0.6875);
                    break;

                case BLOCKTYPE_WALL_POST_TALL_N_S:
                    boundsMin = vec3(0.3125, 0.0, 0.0);
                    boundsMax = vec3(0.6875, 1.0, 1.0);
                    break;
                case BLOCKTYPE_WALL_POST_TALL_W_E:
                    boundsMin = vec3(0.0, 0.0, 0.3125);
                    boundsMax = vec3(1.0, 1.0, 0.6875);
                    break;
                case BLOCKTYPE_WALL_POST_TALL_N_W:
                    boundsMin = vec3(0.3125, 0.0, 0.0);
                    boundsMax = vec3(0.6875, 1.0, 0.5);
                    break;
                case BLOCKTYPE_WALL_POST_TALL_N_E:
                    boundsMin = vec3(0.5, 0.0, 0.3125);
                    boundsMax = vec3(1.0, 1.0, 0.6875);
                    break;
                case BLOCKTYPE_WALL_POST_TALL_S_E:
                    boundsMin = vec3(0.3125, 0.0, 0.5);
                    boundsMax = vec3(0.6875, 1.0, 1.0);
                    break;
                case BLOCKTYPE_WALL_POST_TALL_S_W:
                    boundsMin = vec3(0.0, 0.0, 0.3125);
                    boundsMax = vec3(0.5, 1.0, 0.6875);
                    break;
                case BLOCKTYPE_WALL_POST_TALL_ALL:
                    boundsMin = vec3(0.3125, 0.0, 0.0);
                    boundsMax = vec3(0.6875, 1.0, 1.0);
                    break;
            }

            #if DYN_LIGHT_TRACE_METHOD == 1
                hit = BoxPointTest(boundsMin, boundsMax, rayStart);
            #else
                hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
            #endif

            if (!hit) {
                boundsMin = vec3(-1.0);
                boundsMax = vec3(-1.0);

                switch (blockType) {
                    case BLOCKTYPE_CAULDRON:
                        boundsMin = vec3(      0.0 ,       0.0 , (12.0/16.0));
                        boundsMax = vec3((4.0/16.0), (3.0/16.0),        1.0 );
                        break;

                    case BLOCKTYPE_FENCE_ALL:
                        boundsMin = vec3(0.0, (6.0/16.0), (7.0/16.0));
                        boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
                        break;
                    case BLOCKTYPE_FENCE_N_E:
                        boundsMin = vec3(0.5, (6.0/16.0), (7.0/16.0));
                        boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
                        break;
                    case BLOCKTYPE_FENCE_N_W:
                        boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.0);
                        boundsMax = vec3((9.0/16.0), (9.0/16.0), 0.5);
                        break;
                    case BLOCKTYPE_FENCE_S_E:
                        boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.5);
                        boundsMax = vec3((9.0/16.0), (9.0/16.0), 1.0);
                        break;
                    case BLOCKTYPE_FENCE_S_W:
                        boundsMin = vec3(0.0, (6.0/16.0), (7.0/16.0));
                        boundsMax = vec3(0.5, (9.0/16.0), (9.0/16.0));
                        break;
                    case BLOCKTYPE_FENCE_GATE_CLOSED_N_S:
                        boundsMin = vec3((0.0/16.0), (5.0/16.0), (7.0/16.0));
                        boundsMax = vec3((2.0/16.0),        1.0, (9.0/16.0));
                        break;
                    case BLOCKTYPE_FENCE_GATE_CLOSED_W_E:
                        boundsMin = vec3((7.0/16.0), (5.0/16.0), (0.0/16.0));
                        boundsMax = vec3((9.0/16.0),        1.0, (2.0/16.0));
                        break;
                }

                #if DYN_LIGHT_TRACE_METHOD == 1
                    hit = BoxPointTest(boundsMin, boundsMax, rayStart);
                #else
                    hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
                #endif


                if (!hit) {
                    boundsMin = vec3(-1.0);
                    boundsMax = vec3(-1.0);

                    switch (blockType) {
                        case BLOCKTYPE_CAULDRON:
                            boundsMin = vec3((12.0/16.0),       0.0 , (12.0/16.0));
                            boundsMax = vec3(       1.0 , (3.0/16.0),        1.0 );
                            break;

                        case BLOCKTYPE_FENCE_ALL:
                            boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.0);
                            boundsMax = vec3((9.0/16.0), (15.0/16.0), 1.0);
                            break;
                        case BLOCKTYPE_FENCE_N_E:
                            boundsMin = vec3(0.5, (12.0/16.0), (7.0/16.0));
                            boundsMax = vec3(1.0, (15.0/16.0), (9.0/16.0));
                            break;
                        case BLOCKTYPE_FENCE_S_E:
                            boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.5);
                            boundsMax = vec3((9.0/16.0), (15.0/16.0), 1.0);
                            break;
                        case BLOCKTYPE_FENCE_S_W:
                            boundsMin = vec3(0.0, (12.0/16.0), (7.0/16.0));
                            boundsMax = vec3(0.5, (15.0/16.0), (9.0/16.0));
                            break;
                        case BLOCKTYPE_FENCE_N_W:
                            boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.0);
                            boundsMax = vec3((9.0/16.0), (15.0/16.0), 0.5);
                            break;
                        case BLOCKTYPE_FENCE_GATE_CLOSED_N_S:
                            boundsMin = vec3((14.0/16.0), (5.0/16.0), (7.0/16.0));
                            boundsMax = vec3(        1.0,        1.0, (9.0/16.0));
                            break;
                        case BLOCKTYPE_FENCE_GATE_CLOSED_W_E:
                            boundsMin = vec3((7.0/16.0), (5.0/16.0), (14.0/16.0));
                            boundsMax = vec3((9.0/16.0),        1.0,         1.0);
                            break;
                    }

                    #if DYN_LIGHT_TRACE_METHOD == 1
                        hit = BoxPointTest(boundsMin, boundsMax, rayStart);
                    #else
                        hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
                    #endif
                }
            }
        }
    }

    return hit;
}
