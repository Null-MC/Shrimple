bool BoxRayTest(const in vec3 boxMin, const in vec3 boxMax, const in vec3 rayStart, const in vec3 rayInv) {
    vec3 t1 = (boxMin - rayStart) * rayInv;
    vec3 t2 = (boxMax - rayStart) * rayInv;

    vec3 tmin = min(t1, t2);
    vec3 tmax = max(t1, t2);

    float rmin = maxOf(tmin);
    float rmax = minOf(tmax);

    if (rmin >= 1.0) return false;

    return !isinf(rmin) && rmax >= max(rmin, 0.0);
}

bool BoxPointTest(const in vec3 boxMin, const in vec3 boxMax, const in vec3 point) {
    return all(greaterThanEqual(point, boxMin)) && all(lessThanEqual(point, boxMax));
}

bool CylinderRayTest(const in vec3 rayOrigin, const in vec3 rayVec, const in float radius, const in float height) {
    float rayLen = length(rayVec);
    vec3 rayDir = rayVec / max(rayLen, EPSILON);

    float k2 = 1.0 - _pow2(rayDir.y);
    float k1 = dot(rayOrigin, rayDir) - rayOrigin.y*rayDir.y;
    float k0 = length2(rayOrigin) - _pow2(rayOrigin.y) - _pow2(radius);
    
    float h = k1*k1 - k2*k0;
    if (h < 0.0) return false;

    h = sqrt(h);
    float t = (-k1 - h) / k2;

    float y = rayOrigin.y + t*rayDir.y;
    if (y > -height && y < height) return t > 0.0 && t < rayLen;
    
    t = (((y < 0.0) ? -height : height) - rayOrigin.y) / rayDir.y;
    if (abs(k1 + k2*t) < h) return t > 0.0 && t < rayLen;

    return false;
}

bool TraceHitTest(const in uint blockId, const in vec3 rayStart, const in vec3 rayInv) {
    uint shapeCount = CollissionMaps[blockId].Count;

    bool hit = false;
    for (uint i = 0; i < min(shapeCount, 5u) && !hit; i++) {
        uvec2 shapeBounds = CollissionMaps[blockId].Bounds[i];
        vec3 boundsMin = unpackUnorm4x8(shapeBounds.x).xyz;
        vec3 boundsMax = unpackUnorm4x8(shapeBounds.y).xyz;

        #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
            hit = BoxPointTest(boundsMin, boundsMax, rayStart);
        #else
            hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
        #endif
    }

    return hit;
}

#ifdef IGNORED
bool TraceHitTest(const in uint blockId, const in vec3 rayStart, const in vec3 rayInv) {
    vec3 boundsMin = vec3(0.0);
    vec3 boundsMax = vec3(1.0);

    // 200
    switch (blockId) {
        case BLOCK_LANTERN_CEIL:
        case BLOCK_SOUL_LANTERN_CEIL:
            boundsMin = vec3(( 5.0/16.0), (1.0/16.0), ( 5.0/16.0));
            boundsMax = vec3((11.0/16.0), (8.0/16.0), (11.0/16.0));
            break;
        case BLOCK_LANTERN_FLOOR:
        case BLOCK_SOUL_LANTERN_FLOOR:
            boundsMin = vec3(( 5.0/16.0),       0.0 , ( 5.0/16.0));
            boundsMax = vec3((11.0/16.0), (7.0/16.0), (11.0/16.0));
            break;
    }

    // 400-500
    switch (blockId) {
        // case BLOCK_SOLID:
        //     boundsMin = vec3(0.0);
        //     boundsMax = vec3(1.0);
        //     break;

        case BLOCK_SNOW_LAYERS_1:
        case BLOCK_COMPARATOR:
        case BLOCK_LECTERN:
        case BLOCK_REPEATER:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (2.0/16.0), 1.0);
            break;
        case BLOCK_SNOW_LAYERS_2:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (4.0/16.0), 1.0);
            break;
        case BLOCK_SNOW_LAYERS_3:
        case BLOCK_DAYLIGHT_DETECTOR:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (6.0/16.0), 1.0);
            break;
        case BLOCK_SNOW_LAYERS_4:
        case BLOCK_SLAB_BOTTOM:
        case BLOCK_SCULK_SENSOR:
        case BLOCK_SCULK_SHRIEKER:
        case BLOCK_CREATE_SEAT:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (8.0/16.0), 1.0);
            break;
        case BLOCK_SNOW_LAYERS_5:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (10.0/16.0), 1.0);
            break;
        case BLOCK_SNOW_LAYERS_6:
        case BLOCK_ENCHANTING_TABLE:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (12.0/16.0), 1.0);
            break;
        case BLOCK_SNOW_LAYERS_7:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (14.0/16.0), 1.0);
            break;

        case BLOCK_ANVIL_N_S:
            boundsMin = vec3(( 3.0/16.0), (10.0/16.0), 0.0);
            boundsMax = vec3((13.0/16.0),         1.0, 1.0);
            break;
        case BLOCK_ANVIL_W_E:
            boundsMin = vec3(0.0, (10.0/16.0), ( 3.0/16.0));
            boundsMax = vec3(1.0,         1.0, (13.0/16.0));
            break;

        case BLOCK_BED_HEAD_N:
        case BLOCK_BED_HEAD_E:
        case BLOCK_BED_HEAD_S:
        case BLOCK_BED_HEAD_W:
        case BLOCK_BED_FOOT_N:
        case BLOCK_BED_FOOT_E:
        case BLOCK_BED_FOOT_S:
        case BLOCK_BED_FOOT_W:
            boundsMin = vec3(0.0, (3.0/16.0), 0.0);
            boundsMax = vec3(1.0, (9.0/16.0), 1.0);
            break;

        case BLOCK_BELL_FLOOR_N_S:
        case BLOCK_BELL_FLOOR_W_E:
        case BLOCK_BELL_WALL_N:
        case BLOCK_BELL_WALL_E:
        case BLOCK_BELL_WALL_S:
        case BLOCK_BELL_WALL_W:
        case BLOCK_BELL_WALL_N_S:
        case BLOCK_BELL_WALL_W_E:
        case BLOCK_BELL_CEILING:
            boundsMin = vec3(( 5.0/16.0), ( 6.0/16.0), ( 5.0/16.0));
            boundsMax = vec3((11.0/16.0), (13.0/16.0), (11.0/16.0));
            break;

        case BLOCK_CACTUS:
            boundsMin = vec3(( 1.0/16.0), 0.0, ( 1.0/16.0));
            boundsMax = vec3((15.0/16.0), 1.0, (15.0/16.0));
            break;

        case BLOCK_CAMPFIRE_N_S:
            boundsMin = vec3( (1.0/16.0),        0.0, 0.0);
            boundsMax = vec3((15.0/16.0), (4.0/16.0), 1.0);
            break;
        case BLOCK_CAMPFIRE_W_E:
            boundsMin = vec3(0.0,        0.0,  (1.0/16.0));
            boundsMax = vec3(1.0, (4.0/16.0), (15.0/16.0));
            break;

        case BLOCK_CANDLES_1:
        case BLOCK_CANDLES_LIT_1:
            boundsMin = vec3((7.0/16.0),       0.0 , (7.0/16.0));
            boundsMax = vec3((9.0/16.0), (6.0/16.0), (9.0/16.0));
            break;
        case BLOCK_CANDLES_2:
        case BLOCK_CANDLES_LIT_2:
            boundsMin = vec3(( 9.0/16.0),       0.0 , (6.0/16.0));
            boundsMax = vec3((11.0/16.0), (6.0/16.0), (8.0/16.0));
            break;
        case BLOCK_CANDLES_3:
        case BLOCK_CANDLES_LIT_3:
            boundsMin = vec3(( 8.0/16.0),       0.0 , (6.0/16.0));
            boundsMax = vec3((10.0/16.0), (6.0/16.0), (8.0/16.0));
            break;
        case BLOCK_CANDLES_4:
        case BLOCK_CANDLES_LIT_4:
            boundsMin = vec3(( 8.0/16.0),       0.0 , (5.0/16.0));
            boundsMax = vec3((10.0/16.0), (6.0/16.0), (7.0/16.0));
            break;

        case BLOCK_CAKE:
        case BLOCK_CANDLE_CAKE:
        case BLOCK_CANDLE_CAKE_LIT:
            boundsMin = vec3(( 1.0/16.0), 0.0, ( 1.0/16.0));
            boundsMax = vec3((15.0/16.0), 0.5, (15.0/16.0));
            break;

        case BLOCK_CARPET:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (1.0/16.0), 1.0);
            break;

        case BLOCK_CAULDRON:
        case BLOCK_CAULDRON_LAVA:
            boundsMin = vec3(0.0, (3.0/16.0), 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCK_END_PORTAL_FRAME:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (13.0/16.0), 1.0);
            break;

        case BLOCK_FLOWER_POT:
        case BLOCK_POTTED_PLANT:
            boundsMin = vec3((5.0/16.0), 0.0, (5.0/16.0));
            boundsMax = vec3((10.0/16.0), (6.0/16.0), (10.0/16.0));
            break;

        case BLOCK_GRINDSTONE_FLOOR_N_S:
            boundsMin = vec3(0.25, 0.25, ( 2.0/16.0));
            boundsMax = vec3(0.75, 1.00, (14.0/16.0));
            break;
        case BLOCK_GRINDSTONE_FLOOR_W_E:
            boundsMin = vec3(( 2.0/16.0), 0.25, 0.25);
            boundsMax = vec3((14.0/16.0), 1.00, 0.75);
            break;
        case BLOCK_GRINDSTONE_WALL_N_S:
            boundsMin = vec3(0.25, ( 2.0/16.0), ( 2.0/16.0));
            boundsMax = vec3(0.75, (14.0/16.0), (14.0/16.0));
            break;
        case BLOCK_GRINDSTONE_WALL_W_E:
            boundsMin = vec3(( 2.0/16.0), ( 2.0/16.0), 0.25);
            boundsMax = vec3((14.0/16.0), (14.0/16.0), 0.75);
            break;

        case BLOCK_HOPPER_DOWN:
        case BLOCK_HOPPER_N:
        case BLOCK_HOPPER_E:
        case BLOCK_HOPPER_S:
        case BLOCK_HOPPER_W:
            boundsMin = vec3(0.0, (10.0/16.0), 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCK_LIGHTNING_ROD_N:
        case BLOCK_LIGHTNING_ROD_S:
            boundsMin = vec3((7.0/16.0), (7.0/16.0), 0.0);
            boundsMax = vec3((9.0/16.0), (9.0/16.0), 1.0);
            break;
        case BLOCK_LIGHTNING_ROD_W:
        case BLOCK_LIGHTNING_ROD_E:
            boundsMin = vec3(0.0, (7.0/16.0), (7.0/16.0));
            boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
            break;
        case BLOCK_LIGHTNING_ROD_UP:
        case BLOCK_LIGHTNING_ROD_DOWN:
            boundsMin = vec3((7.0/16.0), 0.0, (7.0/16.0));
            boundsMax = vec3((9.0/16.0), 1.0, (9.0/16.0));
            break;

        case BLOCK_PATHWAY:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (15.0/16.0), 1.0);
            break;

        case BLOCK_PISTON_EXTENDED_N:
            boundsMin = vec3(0.0, 0.0, 0.25);
            boundsMax = vec3(1.0);
            break;
        case BLOCK_PISTON_EXTENDED_E:
            boundsMin = vec3(0.0);
            boundsMax = vec3(0.75, 1.0, 1.0);
            break;
        case BLOCK_PISTON_EXTENDED_S:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, 0.75);
            break;
        case BLOCK_PISTON_EXTENDED_W:
            boundsMin = vec3(0.25, 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCK_PISTON_EXTENDED_UP:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 0.75, 1.0);
            break;
        case BLOCK_PISTON_EXTENDED_DOWN:
            boundsMin = vec3(0.0, 0.25, 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCK_PISTON_HEAD_N:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, 0.25);
            break;
        case BLOCK_PISTON_HEAD_E:
            boundsMin = vec3(0.75, 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCK_PISTON_HEAD_S:
            boundsMin = vec3(0.0, 0.0, 0.75);
            boundsMax = vec3(1.0);
            break;
        case BLOCK_PISTON_HEAD_W:
            boundsMin = vec3(0.0);
            boundsMax = vec3(0.25, 1.0, 1.0);
            break;
        case BLOCK_PISTON_HEAD_UP:
            boundsMin = vec3(0.0, 0.75, 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCK_PISTON_HEAD_DOWN:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 0.25, 1.0);
            break;

        case BLOCK_PRESSURE_PLATE:
            boundsMin = vec3((1.0/16.0), 0.0, (1.0/16.0));
            boundsMax = vec3((15.0/16.0), (1.0/16.0), (15.0/16.0));
            break;

        case BLOCK_STONECUTTER:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (9.0/16.0), 1.0);
            break;

        case BLOCK_BUTTON_FLOOR_N_S:
            boundsMin = vec3(( 5.0/16.0), 0.000, ( 6.0/16.0));
            boundsMax = vec3((11.0/16.0), 0.125, (10.0/16.0));
            break;
        case BLOCK_BUTTON_FLOOR_W_E:
            boundsMin = vec3(( 6.0/16.0), 0.000, ( 5.0/16.0));
            boundsMax = vec3((10.0/16.0), 0.125, (11.0/16.0));
            break;
        case BLOCK_BUTTON_CEILING_N_S:
            boundsMin = vec3(( 5.0/16.0), 0.875, ( 6.0/16.0));
            boundsMax = vec3((11.0/16.0), 1.000, (10.0/16.0));
            break;
        case BLOCK_BUTTON_CEILING_W_E:
            boundsMin = vec3(( 6.0/16.0), 0.875, ( 5.0/16.0));
            boundsMax = vec3((10.0/16.0), 1.000, (11.0/16.0));
            break;
        case BLOCK_BUTTON_WALL_N:
            boundsMin = vec3(( 5.0/16.0), ( 6.0/16.0), 0.875);
            boundsMax = vec3((11.0/16.0), (10.0/16.0), 1.000);
            break;
        case BLOCK_BUTTON_WALL_E:
            boundsMin = vec3(0.000, ( 6.0/16.0), ( 5.0/16.0));
            boundsMax = vec3(0.125, (10.0/16.0), (11.0/16.0));
            break;
        case BLOCK_BUTTON_WALL_S:
            boundsMin = vec3(( 5.0/16.0), ( 6.0/16.0), 0.000);
            boundsMax = vec3((11.0/16.0), (10.0/16.0), 0.125);
            break;
        case BLOCK_BUTTON_WALL_W:
            boundsMin = vec3(0.875, ( 6.0/16.0), ( 5.0/16.0));
            boundsMax = vec3(1.000, (10.0/16.0), (11.0/16.0));
            break;

        case BLOCK_DOOR_N:
            boundsMin = vec3(0.0, 0.0, (13.0/16.0));
            boundsMax = vec3(1.0);
            break;
        case BLOCK_DOOR_E:
            boundsMin = vec3(0.0);
            boundsMax = vec3((3.0/16.0), 1.0, 1.0);
            break;
        case BLOCK_DOOR_S:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, (3.0/16.0));
            break;
        case BLOCK_DOOR_W:
            boundsMin = vec3((13.0/16.0), 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCK_LEVER_FLOOR_N_S:
            boundsMin = vec3(( 5.0/16.0),        0.0, ( 4.0/16.0));
            boundsMax = vec3((11.0/16.0), (3.0/16.0), (12.0/16.0));
            break;
        case BLOCK_LEVER_FLOOR_W_E:
            boundsMin = vec3(( 4.0/16.0),        0.0, ( 5.0/16.0));
            boundsMax = vec3((12.0/16.0), (3.0/16.0), (11.0/16.0));
            break;
        case BLOCK_LEVER_CEILING_N_S:
            boundsMin = vec3(( 5.0/16.0), (13.0/16.0), ( 4.0/16.0));
            boundsMax = vec3((11.0/16.0),         1.0, (12.0/16.0));
            break;
        case BLOCK_LEVER_CEILING_W_E:
            boundsMin = vec3(( 4.0/16.0), (13.0/16.0), ( 5.0/16.0));
            boundsMax = vec3((12.0/16.0),         1.0, (11.0/16.0));
            break;
        case BLOCK_LEVER_WALL_N:
            boundsMin = vec3(( 5.0/16.0), 0.25, (13.0/16.0));
            boundsMax = vec3((11.0/16.0), 0.75,         1.0);
            break;
        case BLOCK_LEVER_WALL_E:
            boundsMin = vec3(       0.0, 0.25, ( 5.0/16.0));
            boundsMax = vec3((3.0/16.0), 0.75, (11.0/16.0));
            break;
        case BLOCK_LEVER_WALL_S:
            boundsMin = vec3(( 5.0/16.0), 0.25,        0.0);
            boundsMax = vec3((11.0/16.0), 0.75, (3.0/16.0));
            break;
        case BLOCK_LEVER_WALL_W:
            boundsMin = vec3((13.0/16.0), 0.25, ( 5.0/16.0));
            boundsMax = vec3(        1.0, 0.75, (11.0/16.0));
            break;

        case BLOCK_TRAPDOOR_BOTTOM:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, (3.0/16.0), 1.0);
            break;
        case BLOCK_TRAPDOOR_TOP:
            boundsMin = vec3(0.0, (13.0/16.0), 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCK_TRAPDOOR_N:
            boundsMin = vec3(0.0, 0.0, (13.0/16.0));
            boundsMax = vec3(1.0);
            break;
        case BLOCK_TRAPDOOR_E:
            boundsMin = vec3(0.0);
            boundsMax = vec3((3.0/16.0), 1.0, 1.0);
            break;
        case BLOCK_TRAPDOOR_S:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, (3.0/16.0));
            break;
        case BLOCK_TRAPDOOR_W:
            boundsMin = vec3((13.0/16.0), 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCK_TRIPWIRE_HOOK_N:
            boundsMin = vec3(0.375, (1.0/16.0), 0.875);
            boundsMax = vec3(0.625, (9.0/16.0), 1.000);
            break;
        case BLOCK_TRIPWIRE_HOOK_E:
            boundsMin = vec3(0.000, (1.0/16.0), 0.375);
            boundsMax = vec3(0.125, (9.0/16.0), 0.625);
            break;
        case BLOCK_TRIPWIRE_HOOK_S:
            boundsMin = vec3(0.375, (1.0/16.0), 0.000);
            boundsMax = vec3(0.625, (9.0/16.0), 0.125);
            break;
        case BLOCK_TRIPWIRE_HOOK_W:
            boundsMin = vec3(0.875, (1.0/16.0), 0.375);
            boundsMax = vec3(1.000, (9.0/16.0), 0.625);
            break;

        case BLOCK_STAIRS_BOTTOM_N:
        case BLOCK_STAIRS_BOTTOM_E:
        case BLOCK_STAIRS_BOTTOM_S:
        case BLOCK_STAIRS_BOTTOM_W:
        case BLOCK_STAIRS_BOTTOM_INNER_N_W:
        case BLOCK_STAIRS_BOTTOM_INNER_N_E:
        case BLOCK_STAIRS_BOTTOM_INNER_S_W:
        case BLOCK_STAIRS_BOTTOM_INNER_S_E:
        case BLOCK_STAIRS_BOTTOM_OUTER_N_W:
        case BLOCK_STAIRS_BOTTOM_OUTER_N_E:
        case BLOCK_STAIRS_BOTTOM_OUTER_S_W:
        case BLOCK_STAIRS_BOTTOM_OUTER_S_E:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 0.5, 1.0);
            break;
        case BLOCK_SLAB_TOP:
        case BLOCK_STAIRS_TOP_N:
        case BLOCK_STAIRS_TOP_E:
        case BLOCK_STAIRS_TOP_S:
        case BLOCK_STAIRS_TOP_W:
        case BLOCK_STAIRS_TOP_INNER_N_W:
        case BLOCK_STAIRS_TOP_INNER_N_E:
        case BLOCK_STAIRS_TOP_INNER_S_W:
        case BLOCK_STAIRS_TOP_INNER_S_E:
        case BLOCK_STAIRS_TOP_OUTER_N_W:
        case BLOCK_STAIRS_TOP_OUTER_N_E:
        case BLOCK_STAIRS_TOP_OUTER_S_W:
        case BLOCK_STAIRS_TOP_OUTER_S_E:
            boundsMin = vec3(0.0, 0.5, 0.0);
            boundsMax = vec3(1.0);
            break;

        case BLOCK_SLAB_VERTICAL_N:
            boundsMin = vec3(0.0);
            boundsMax = vec3(1.0, 1.0, 0.5);
            break;
        case BLOCK_SLAB_VERTICAL_E:
            boundsMin = vec3(0.5, 0.0, 0.0);
            boundsMax = vec3(1.0);
            break;
        case BLOCK_SLAB_VERTICAL_S:
            boundsMin = vec3(0.0, 0.0, 0.5);
            boundsMax = vec3(1.0);
            break;
        case BLOCK_SLAB_VERTICAL_W:
            boundsMin = vec3(0.0);
            boundsMax = vec3(0.5, 1.0, 1.0);
            break;

        case BLOCK_CREATE_SHAFT_X:
            boundsMin = vec3(0.0, ( 6.0/16.0), ( 6.0/16.0));
            boundsMax = vec3(1.0, (10.0/16.0), (10.0/16.0));
            break;
        case BLOCK_CREATE_SHAFT_Y:
            boundsMin = vec3(( 6.0/16.0), 0.0, ( 6.0/16.0));
            boundsMax = vec3((10.0/16.0), 1.0, (10.0/16.0));
            break;
        case BLOCK_CREATE_SHAFT_Z:
            boundsMin = vec3(( 6.0/16.0), ( 6.0/16.0), 0.0);
            boundsMax = vec3((10.0/16.0), (10.0/16.0), 1.0);
            break;

        case BLOCK_FENCE_POST:
        case BLOCK_FENCE_N:
        case BLOCK_FENCE_E:
        case BLOCK_FENCE_S:
        case BLOCK_FENCE_W:
        case BLOCK_FENCE_N_S:
        case BLOCK_FENCE_W_E:
        case BLOCK_FENCE_N_W:
        case BLOCK_FENCE_N_E:
        case BLOCK_FENCE_S_W:
        case BLOCK_FENCE_S_E:
        case BLOCK_FENCE_W_N_E:
        case BLOCK_FENCE_W_S_E:
        case BLOCK_FENCE_N_W_S:
        case BLOCK_FENCE_N_E_S:
        case BLOCK_FENCE_ALL:
            boundsMin = vec3(0.375, 0.0, 0.375);
            boundsMax = vec3(0.625, 1.0, 0.625);
            break;
        case BLOCK_FENCE_GATE_CLOSED_N_S:
            boundsMin = vec3(( 6.0/16.0), ( 9.0/16.0), (7.0/16.0));
            boundsMax = vec3((10.0/16.0), (12.0/16.0), (9.0/16.0));
            break;
        case BLOCK_FENCE_GATE_CLOSED_W_E:
            boundsMin = vec3((7.0/16.0), ( 9.0/16.0), ( 6.0/16.0));
            boundsMax = vec3((9.0/16.0), (12.0/16.0), (10.0/16.0));
            break;

        case BLOCK_WALL_POST:
        case BLOCK_WALL_POST_LOW_N:
        case BLOCK_WALL_POST_LOW_E:
        case BLOCK_WALL_POST_LOW_S:
        case BLOCK_WALL_POST_LOW_W:
        case BLOCK_WALL_POST_LOW_N_S:
        case BLOCK_WALL_POST_LOW_W_E:
        case BLOCK_WALL_POST_LOW_N_W:
        case BLOCK_WALL_POST_LOW_N_E:
        case BLOCK_WALL_POST_LOW_S_W:
        case BLOCK_WALL_POST_LOW_S_E:
        case BLOCK_WALL_POST_LOW_N_W_S:
        case BLOCK_WALL_POST_LOW_N_E_S:
        case BLOCK_WALL_POST_LOW_W_N_E:
        case BLOCK_WALL_POST_LOW_W_S_E:
        case BLOCK_WALL_POST_TALL_N:
        case BLOCK_WALL_POST_TALL_E:
        case BLOCK_WALL_POST_TALL_S:
        case BLOCK_WALL_POST_TALL_W:
        case BLOCK_WALL_POST_TALL_N_S:
        case BLOCK_WALL_POST_TALL_W_E:
        case BLOCK_WALL_POST_TALL_N_W_S:
        case BLOCK_WALL_POST_TALL_N_E_S:
        case BLOCK_WALL_POST_TALL_W_N_E:
        case BLOCK_WALL_POST_TALL_W_S_E:
        case BLOCK_WALL_POST_TALL_ALL:
            boundsMin = vec3(0.25, 0.0, 0.25);
            boundsMax = vec3(0.75, 1.0, 0.75);
            break;
        case BLOCK_WALL_LOW_N_S:
            boundsMin = vec3(0.3125, 0.0, 0.0);
            boundsMax = vec3(0.6875, (14.0/16.0), 1.0);
            break;
        case BLOCK_WALL_LOW_W_E:
            boundsMin = vec3(0.0, 0.0, 0.3125);
            boundsMax = vec3(1.0, (14.0/16.0), 0.6875);
            break;
        case BLOCK_WALL_TALL_N_S:
            boundsMin = vec3(0.3125, 0.0, 0.0);
            boundsMax = vec3(0.6875, 1.0, 1.0);
            break;
        case BLOCK_WALL_TALL_W_E:
            boundsMin = vec3(0.0, 0.0, 0.3125);
            boundsMax = vec3(1.0, 1.0, 0.6875);
            break;

        case BLOCK_CHORUS_DOWN:
            boundsMin = vec3(0.25,         0.0, 0.25);
            boundsMax = vec3(0.75, (13.0/16.0), 0.75);
            break;
        case BLOCK_CHORUS_UP_DOWN:
            boundsMin = vec3(0.25, 0.0, 0.25);
            boundsMax = vec3(0.75, 1.0, 0.75);
            break;
        case BLOCK_CHORUS_OTHER:
            boundsMin = vec3(0.25, 0.25, 0.25);
            boundsMax = vec3(0.75, 0.75, 0.75);
            break;
    }

    switch (blockId) {
        case BLOCK_CHEST_N:
        case BLOCK_CHEST_E:
        case BLOCK_CHEST_S:
        case BLOCK_CHEST_W:
            boundsMin = vec3(( 1.0/16.0),        0.0 , ( 1.0/16.0));
            boundsMax = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
            break;

        case BLOCK_CHEST_LEFT_N:
            boundsMin = vec3(( 1.0/16.0),        0.0 , ( 1.0/16.0));
            boundsMax = vec3(       1.0 , (14.0/16.0), (15.0/16.0));
            break;
        case BLOCK_CHEST_RIGHT_N:
            boundsMin = vec3(       0.0 ,        0.0 , ( 1.0/16.0));
            boundsMax = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
            break;
        case BLOCK_CHEST_LEFT_E:
            boundsMin = vec3(( 1.0/16.0),        0.0 , ( 1.0/16.0));
            boundsMax = vec3((15.0/16.0), (14.0/16.0),        1.0 );
            break;
        case BLOCK_CHEST_RIGHT_E:
            boundsMin = vec3(( 1.0/16.0),        0.0 ,        0.0 );
            boundsMax = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
            break;
        case BLOCK_CHEST_LEFT_S:
            boundsMin = vec3(       0.0 ,        0.0 , ( 1.0/16.0));
            boundsMax = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
            break;
        case BLOCK_CHEST_RIGHT_S:
            boundsMin = vec3((1.0/16.0),        0.0 , ( 1.0/16.0));
            boundsMax = vec3(      1.0 , (14.0/16.0), (15.0/16.0));
            break;
        case BLOCK_CHEST_LEFT_W:
            boundsMin = vec3(( 1.0/16.0),        0.0 ,        0.0 );
            boundsMax = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
            break;
        case BLOCK_CHEST_RIGHT_W:
            boundsMin = vec3(( 1.0/16.0),        0.0 , (1.0/16.0));
            boundsMax = vec3((15.0/16.0), (14.0/16.0),       1.0 );
            break;

        case BLOCK_SIGN_WALL_N:
            boundsMin = vec3(0.0, ( 4.50/16.0), (14.25/16.0));
            boundsMax = vec3(1.0, (12.25/16.0), (15.75/16.0));
            break;
        case BLOCK_SIGN_WALL_E:
            boundsMin = vec3((0.25/16.0), ( 4.50/16.0), 0.0);
            boundsMax = vec3((1.75/16.0), (12.25/16.0), 1.0);
            break;
        case BLOCK_SIGN_WALL_S:
            boundsMin = vec3(0.0, ( 4.50/16.0), (0.25/16.0));
            boundsMax = vec3(1.0, (12.25/16.0), (1.75/16.0));
            break;
        case BLOCK_SIGN_WALL_W:
            boundsMin = vec3((14.25/16.0), ( 4.50/16.0), 0.0);
            boundsMax = vec3((15.75/16.0), (12.25/16.0), 1.0);
            break;
    }

    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
        bool hit = BoxPointTest(boundsMin, boundsMax, rayStart);
    #else
        bool hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
    #endif

    if (!hit) {// && blockId >= 5u && blockId <= 28u) {
        boundsMin = vec3(-1.0);
        boundsMax = vec3(-1.0);

        // 200
        switch (blockId) {
            case BLOCK_LANTERN_CEIL:
            case BLOCK_SOUL_LANTERN_CEIL:
                boundsMin = vec3(( 6.0/16.0), ( 8.0/16.0), ( 6.0/16.0));
                boundsMax = vec3((10.0/16.0), (10.0/16.0), (10.0/16.0));
                break;
            case BLOCK_LANTERN_FLOOR:
            case BLOCK_SOUL_LANTERN_FLOOR:
                boundsMin = vec3(( 6.0/16.0), (7.0/16.0), ( 6.0/16.0));
                boundsMax = vec3((10.0/16.0), (9.0/16.0), (10.0/16.0));
                break;
        }

        // 400
        switch (blockId) {
            case BLOCK_ANVIL_N_S:
                boundsMin = vec3(( 6.0/16.0), 0.25, 0.25);
                boundsMax = vec3((10.0/16.0), 0.75, 0.75);
                break;
            case BLOCK_ANVIL_W_E:
                boundsMin = vec3(0.25, 0.25, ( 6.0/16.0));
                boundsMax = vec3(0.75, 0.75, (10.0/16.0));
                break;

            case BLOCK_BED_HEAD_N:
            case BLOCK_BED_FOOT_S:
            case BLOCK_BED_HEAD_W:
            case BLOCK_BED_FOOT_E:
                boundsMin = vec3((0.0/16.0), (0.0/16.0), (0.0/16.0));
                boundsMax = vec3((3.0/16.0), (3.0/16.0), (3.0/16.0));
                break;

            case BLOCK_BELL_FLOOR_N_S:
            case BLOCK_BELL_FLOOR_W_E:
            case BLOCK_BELL_WALL_N:
            case BLOCK_BELL_WALL_E:
            case BLOCK_BELL_WALL_S:
            case BLOCK_BELL_WALL_W:
            case BLOCK_BELL_WALL_N_S:
            case BLOCK_BELL_WALL_W_E:
            case BLOCK_BELL_CEILING:
                boundsMin = vec3(0.25,       0.25, 0.25);
                boundsMax = vec3(0.75, (6.0/16.0), 0.75);
                break;

            case BLOCK_CAMPFIRE_N_S:
                boundsMin = vec3(0.0, (3.0/16.0), (1.0/16.0));
                boundsMax = vec3(1.0, (7.0/16.0), (5.0/16.0));
                break;
            case BLOCK_CAMPFIRE_W_E:
                boundsMin = vec3((1.0/16.0), (3.0/16.0), 0.0);
                boundsMax = vec3((5.0/16.0), (7.0/16.0), 1.0);
                break;

            case BLOCK_CANDLE_CAKE:
            case BLOCK_CANDLE_CAKE_LIT:
                boundsMin = vec3((7.0/16.0),        0.5 , (7.0/16.0));
                boundsMax = vec3((9.0/16.0), (14.0/16.0), (9.0/16.0));
                break;
            case BLOCK_CANDLES_2:
            case BLOCK_CANDLES_LIT_2:
            case BLOCK_CANDLES_3:
            case BLOCK_CANDLES_LIT_3:
                boundsMin = vec3((5.0/16.0),       0.0 , (7.0/16.0));
                boundsMax = vec3((7.0/16.0), (5.0/16.0), (9.0/16.0));
                break;
            case BLOCK_CANDLES_4:
            case BLOCK_CANDLES_LIT_4:
                boundsMin = vec3((5.0/16.0),       0.0 , (5.0/16.0));
                boundsMax = vec3((7.0/16.0), (5.0/16.0), (7.0/16.0));
                break;

            case BLOCK_CAULDRON:
            case BLOCK_CAULDRON_LAVA:
                boundsMin = vec3(0.0);
                boundsMax = vec3((4.0/16.0), (3.0/16.0), (4.0/16.0));
                break;

            case BLOCK_CHEST_N:
                boundsMin = vec3((7.0/16.0), ( 7.0/16.0), (0.0/16.0));
                boundsMax = vec3((9.0/16.0), (11.0/16.0), (1.0/16.0));
                break;
            case BLOCK_CHEST_E:
                boundsMin = vec3((15.0/16.0), ( 7.0/16.0), (7.0/16.0));
                boundsMax = vec3((16.0/16.0), (11.0/16.0), (9.0/16.0));
                break;
            case BLOCK_CHEST_S:
                boundsMin = vec3((7.0/16.0), ( 7.0/16.0), (15.0/16.0));
                boundsMax = vec3((9.0/16.0), (11.0/16.0), (16.0/16.0));
                break;
            case BLOCK_CHEST_W:
                boundsMin = vec3((0.0/16.0), ( 7.0/16.0), (7.0/16.0));
                boundsMax = vec3((1.0/16.0), (11.0/16.0), (9.0/16.0));
                break;

            case BLOCK_HOPPER_DOWN:
            case BLOCK_HOPPER_N:
            case BLOCK_HOPPER_E:
            case BLOCK_HOPPER_S:
            case BLOCK_HOPPER_W:
                boundsMin = vec3(0.25);
                boundsMax = vec3(0.75, 0.625, 0.75);
                break;

            case BLOCK_LECTERN:
                boundsMin = vec3(0.25,         0.0, 0.25);
                boundsMax = vec3(0.75, (13.0/16.0), 0.75);
                break;

            case BLOCK_LIGHTNING_ROD_N:
                boundsMin = vec3( (6.0/16.0),  (6.0/16.0), 0.00);
                boundsMax = vec3((10.0/16.0), (10.0/16.0), 0.25);
                break;
            case BLOCK_LIGHTNING_ROD_E:
                boundsMin = vec3(0.75,  (6.0/16.0),  (6.0/16.0));
                boundsMax = vec3(1.00, (10.0/16.0), (10.0/16.0));
                break;
            case BLOCK_LIGHTNING_ROD_S:
                boundsMin = vec3( (6.0/16.0),  (6.0/16.0), 0.75);
                boundsMax = vec3((10.0/16.0), (10.0/16.0), 1.00);
                break;
            case BLOCK_LIGHTNING_ROD_W:
                boundsMin = vec3(0.00,  (6.0/16.0),  (6.0/16.0));
                boundsMax = vec3(0.25, (10.0/16.0), (10.0/16.0));
                break;
            case BLOCK_LIGHTNING_ROD_UP:
                boundsMin = vec3( (6.0/16.0), 0.75,  (6.0/16.0));
                boundsMax = vec3((10.0/16.0), 1.00, (10.0/16.0));
                break;
            case BLOCK_LIGHTNING_ROD_DOWN:
                boundsMin = vec3( (6.0/16.0), 0.00,  (6.0/16.0));
                boundsMax = vec3((10.0/16.0), 0.25, (10.0/16.0));
                break;

            case BLOCK_PISTON_HEAD_UP:
            case BLOCK_PISTON_HEAD_DOWN:
            case BLOCK_PISTON_EXTENDED_UP:
            case BLOCK_PISTON_EXTENDED_DOWN:
                boundsMin = vec3(0.375, 0.0, 0.375);
                boundsMax = vec3(0.625, 1.0, 0.625);
                break;
            case BLOCK_PISTON_HEAD_N:
            case BLOCK_PISTON_HEAD_S:
            case BLOCK_PISTON_EXTENDED_N:
            case BLOCK_PISTON_EXTENDED_S:
                boundsMin = vec3(0.375, 0.375, 0.0);
                boundsMax = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_HEAD_W:
            case BLOCK_PISTON_HEAD_E:
            case BLOCK_PISTON_EXTENDED_W:
            case BLOCK_PISTON_EXTENDED_E:
                boundsMin = vec3(0.0, 0.375, 0.375);
                boundsMax = vec3(1.0, 0.625, 0.625);
                break;
        }

        // 500-600
        switch (blockId) {
            case BLOCK_STAIRS_BOTTOM_N:
            case BLOCK_STAIRS_BOTTOM_INNER_N_W:
            case BLOCK_STAIRS_BOTTOM_INNER_N_E:
                boundsMin = vec3(0.0, 0.5, 0.0);
                boundsMax = vec3(1.0, 1.0, 0.5);
                break;
            case BLOCK_STAIRS_BOTTOM_E:
                boundsMin = vec3(0.5, 0.5, 0.0);
                boundsMax = vec3(1.0, 1.0, 1.0);
                break;
            case BLOCK_STAIRS_BOTTOM_S:
            case BLOCK_STAIRS_BOTTOM_INNER_S_W:
            case BLOCK_STAIRS_BOTTOM_INNER_S_E:
                boundsMin = vec3(0.0, 0.5, 0.5);
                boundsMax = vec3(1.0, 1.0, 1.0);
                break;
            case BLOCK_STAIRS_BOTTOM_W:
                boundsMin = vec3(0.0, 0.5, 0.0);
                boundsMax = vec3(0.5, 1.0, 1.0);
                break;

            case BLOCK_STAIRS_TOP_N:
            case BLOCK_STAIRS_TOP_INNER_N_W:
            case BLOCK_STAIRS_TOP_INNER_N_E:
                boundsMin = vec3(0.0, 0.0, 0.0);
                boundsMax = vec3(1.0, 0.5, 0.5);
                break;
            case BLOCK_STAIRS_TOP_E:
                boundsMin = vec3(0.5, 0.0, 0.0);
                boundsMax = vec3(1.0, 0.5, 1.0);
                break;
            case BLOCK_STAIRS_TOP_S:
            case BLOCK_STAIRS_TOP_INNER_S_W:
            case BLOCK_STAIRS_TOP_INNER_S_E:
                boundsMin = vec3(0.0, 0.0, 0.5);
                boundsMax = vec3(1.0, 0.5, 1.0);
                break;
            case BLOCK_STAIRS_TOP_W:
                boundsMin = vec3(0.0, 0.0, 0.0);
                boundsMax = vec3(0.5, 0.5, 1.0);
                break;

            case BLOCK_FENCE_N:
            case BLOCK_FENCE_N_E:
                boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.0);
                boundsMax = vec3((9.0/16.0), (9.0/16.0), 0.5);
                break;
            case BLOCK_FENCE_E:
            case BLOCK_FENCE_S_E:
                boundsMin = vec3(0.5, (6.0/16.0), (7.0/16.0));
                boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
                break;
            case BLOCK_FENCE_S:
            case BLOCK_FENCE_S_W:
                boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.5);
                boundsMax = vec3((9.0/16.0), (9.0/16.0), 1.0);
                break;
            case BLOCK_FENCE_W:
            case BLOCK_FENCE_N_W:
                boundsMin = vec3(0.0, (6.0/16.0), (7.0/16.0));
                boundsMax = vec3(0.5, (9.0/16.0), (9.0/16.0));
                break;
            case BLOCK_FENCE_N_S:
            case BLOCK_FENCE_N_W_S:
            case BLOCK_FENCE_N_E_S:
            case BLOCK_FENCE_ALL:
            case BLOCK_FENCE_GATE_CLOSED_W_E:
                boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.0);
                boundsMax = vec3((9.0/16.0), (9.0/16.0), 1.0);
                break;
            case BLOCK_FENCE_W_E:
            case BLOCK_FENCE_W_N_E:
            case BLOCK_FENCE_W_S_E:
            case BLOCK_FENCE_GATE_CLOSED_N_S:
                boundsMin = vec3(0.0, (6.0/16.0), (7.0/16.0));
                boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
                break;

            case BLOCK_WALL_POST_LOW_N:
            case BLOCK_WALL_POST_LOW_N_E:
            case BLOCK_WALL_POST_LOW_W_N_E:
                boundsMin = vec3(0.3125, 0.000, 0.0);
                boundsMax = vec3(0.6875, 0.875, 0.5);
                break;
            case BLOCK_WALL_POST_LOW_E:
            case BLOCK_WALL_POST_LOW_S_E:
                boundsMin = vec3(0.5, 0.000, 0.3125);
                boundsMax = vec3(1.0, 0.875, 0.6875);
                break;
            case BLOCK_WALL_POST_LOW_S:
            case BLOCK_WALL_POST_LOW_S_W:
            case BLOCK_WALL_POST_LOW_W_S_E:
                boundsMin = vec3(0.3125, 0.000, 0.5);
                boundsMax = vec3(0.6875, 0.875, 1.0);
                break;
            case BLOCK_WALL_POST_LOW_W:
            case BLOCK_WALL_POST_LOW_N_W:
                boundsMin = vec3(0.0, 0.000, 0.3125);
                boundsMax = vec3(0.5, 0.875, 0.6875);
                break;

            case BLOCK_WALL_POST_TALL_N:
            case BLOCK_WALL_POST_TALL_N_E:
            case BLOCK_WALL_POST_TALL_W_N_E:
                boundsMin = vec3(0.3125, 0.0, 0.0);
                boundsMax = vec3(0.6875, 1.0, 0.5);
                break;
            case BLOCK_WALL_POST_TALL_E:
            case BLOCK_WALL_POST_TALL_S_E:
                boundsMin = vec3(0.5, 0.0, 0.3125);
                boundsMax = vec3(1.0, 1.0, 0.6875);
                break;
            case BLOCK_WALL_POST_TALL_S:
            case BLOCK_WALL_POST_TALL_S_W:
            case BLOCK_WALL_POST_TALL_W_S_E:
                boundsMin = vec3(0.3125, 0.0, 0.5);
                boundsMax = vec3(0.6875, 1.0, 1.0);
                break;
            case BLOCK_WALL_POST_TALL_W:
            case BLOCK_WALL_POST_TALL_N_W:
                boundsMin = vec3(0.0, 0.0, 0.3125);
                boundsMax = vec3(0.5, 1.0, 0.6875);
                break;

            case BLOCK_WALL_POST_LOW_ALL:
                boundsMin = vec3(0.0, 0.000, 0.3125);
                boundsMax = vec3(1.0, 0.875, 0.6875);
                break;
            case BLOCK_WALL_POST_TALL_ALL:
                boundsMin = vec3(0.0, 0.000, 0.3125);
                boundsMax = vec3(1.0, 0.875, 0.6875);
                break;
        }

        #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
            hit = BoxPointTest(boundsMin, boundsMax, rayStart);
        #else
            hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
        #endif

        if (!hit) {// && ((blockId >= 9u && blockId <= 16u) || (blockId >= 21u && blockId <= 28u))) {
            boundsMin = vec3(-1.0);
            boundsMax = vec3(-1.0);

            // 400
            switch (blockId) {
                case BLOCK_ANVIL_N_S:
                case BLOCK_ANVIL_W_E:
                    boundsMin = vec3(( 2.0/16.0), 0.00, ( 2.0/16.0));
                    boundsMax = vec3((14.0/16.0), 0.25, (14.0/16.0));
                    break;

                case BLOCK_BED_HEAD_N:
                case BLOCK_BED_FOOT_S:
                case BLOCK_BED_HEAD_E:
                case BLOCK_BED_FOOT_W:
                    boundsMin = vec3((13.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax = vec3((16.0/16.0), (3.0/16.0), (3.0/16.0));
                    break;

                case BLOCK_CAMPFIRE_N_S:
                    boundsMin = vec3(0.0, (3.0/16.0), (11.0/16.0));
                    boundsMax = vec3(1.0, (7.0/16.0), (15.0/16.0));
                    break;
                case BLOCK_CAMPFIRE_W_E:
                    boundsMin = vec3((11.0/16.0), (3.0/16.0), 0.0);
                    boundsMax = vec3((15.0/16.0), (7.0/16.0), 1.0);
                    break;

                case BLOCK_CANDLES_3:
                case BLOCK_CANDLES_LIT_3:
                    boundsMin = vec3((7.0/16.0),       0.0 , ( 9.0/16.0));
                    boundsMax = vec3((9.0/16.0), (3.0/16.0), (11.0/16.0));
                    break;
                case BLOCK_CANDLES_4:
                case BLOCK_CANDLES_LIT_4:
                    boundsMin = vec3(( 9.0/16.0),       0.0 , ( 8.0/16.0));
                    boundsMax = vec3((11.0/16.0), (5.0/16.0), (10.0/16.0));
                    break;

                case BLOCK_CAULDRON:
                case BLOCK_CAULDRON_LAVA:
                    boundsMin = vec3((12.0/16.0),       0.0 ,       0.0 );
                    boundsMax = vec3(       1.0 , (3.0/16.0), (4.0/16.0));
                    break;

                case BLOCK_HOPPER_DOWN:
                    boundsMin = vec3(0.375, 0.00, 0.325);
                    boundsMax = vec3(0.625, 0.25, 0.675);
                    break;
                case BLOCK_HOPPER_N:
                    boundsMin = vec3(0.25, 0.25, 0.00);
                    boundsMax = vec3(0.75, 0.50, 0.25);
                    break;
                case BLOCK_HOPPER_E:
                    boundsMin = vec3(0.75, 0.25, 0.25);
                    boundsMax = vec3(1.00, 0.50, 0.75);
                    break;
                case BLOCK_HOPPER_S:
                    boundsMin = vec3(0.25, 0.25, 0.75);
                    boundsMax = vec3(0.75, 0.50, 1.00);
                    break;
                case BLOCK_HOPPER_W:
                    boundsMin = vec3(0.00, 0.25, 0.25);
                    boundsMax = vec3(0.25, 0.50, 0.75);
                    break;
            }

            // 500-600
            switch (blockId) {
                case BLOCK_STAIRS_BOTTOM_INNER_N_W:
                case BLOCK_STAIRS_BOTTOM_OUTER_S_W:
                    boundsMin = vec3(0.0, 0.5, 0.5);
                    boundsMax = vec3(0.5, 1.0, 1.0);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_S_W:
                case BLOCK_STAIRS_BOTTOM_OUTER_N_W:
                    boundsMin = vec3(0.0, 0.5, 0.0);
                    boundsMax = vec3(0.5, 1.0, 0.5);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_N_E:
                case BLOCK_STAIRS_BOTTOM_OUTER_S_E:
                    boundsMin = vec3(0.5, 0.5, 0.5);
                    boundsMax = vec3(1.0, 1.0, 1.0);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_S_E:
                case BLOCK_STAIRS_BOTTOM_OUTER_N_E:
                    boundsMin = vec3(0.5, 0.5, 0.0);
                    boundsMax = vec3(1.0, 1.0, 0.5);
                    break;

                case BLOCK_STAIRS_TOP_INNER_N_W:
                case BLOCK_STAIRS_TOP_OUTER_S_W:
                    boundsMin = vec3(0.0, 0.0, 0.5);
                    boundsMax = vec3(0.5, 0.5, 1.0);
                    break;
                case BLOCK_STAIRS_TOP_INNER_S_W:
                case BLOCK_STAIRS_TOP_OUTER_N_W:
                    boundsMin = vec3(0.0, 0.0, 0.0);
                    boundsMax = vec3(0.5, 0.5, 0.5);
                    break;
                case BLOCK_STAIRS_TOP_INNER_N_E:
                case BLOCK_STAIRS_TOP_OUTER_S_E:
                    boundsMin = vec3(0.5, 0.0, 0.5);
                    boundsMax = vec3(1.0, 0.5, 1.0);
                    break;
                case BLOCK_STAIRS_TOP_INNER_S_E:
                case BLOCK_STAIRS_TOP_OUTER_N_E:
                    boundsMin = vec3(0.5, 0.0, 0.0);
                    boundsMax = vec3(1.0, 0.5, 0.5);
                    break;

                case BLOCK_FENCE_N:
                case BLOCK_FENCE_N_E:
                    boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax = vec3((9.0/16.0), (15.0/16.0), 0.5);
                    break;
                case BLOCK_FENCE_E:
                case BLOCK_FENCE_S_E:
                    boundsMin = vec3(0.5, (12.0/16.0), (7.0/16.0));
                    boundsMax = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCK_FENCE_S:
                case BLOCK_FENCE_S_W:
                    boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.5);
                    boundsMax = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;
                case BLOCK_FENCE_W:
                case BLOCK_FENCE_N_W:
                    boundsMin = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax = vec3(0.5, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCK_FENCE_N_S:
                case BLOCK_FENCE_N_W_S:
                case BLOCK_FENCE_N_E_S:
                case BLOCK_FENCE_GATE_CLOSED_W_E:
                    boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;
                case BLOCK_FENCE_W_E:
                case BLOCK_FENCE_W_N_E:
                case BLOCK_FENCE_W_S_E:
                case BLOCK_FENCE_ALL:
                case BLOCK_FENCE_GATE_CLOSED_N_S:
                    boundsMin = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;

                case BLOCK_WALL_POST_LOW_N_S:
                case BLOCK_WALL_POST_LOW_N_W_S:
                case BLOCK_WALL_POST_LOW_N_E_S:
                case BLOCK_WALL_POST_LOW_ALL:
                    boundsMin = vec3(0.3125, 0.000, 0.0);
                    boundsMax = vec3(0.6875, 0.875, 1.0);
                    break;
                case BLOCK_WALL_POST_LOW_W_E:
                case BLOCK_WALL_POST_LOW_W_N_E:
                case BLOCK_WALL_POST_LOW_W_S_E:
                    boundsMin = vec3(0.0, 0.000, 0.3125);
                    boundsMax = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_N_W:
                    boundsMin = vec3(0.3125, 0.000, 0.0);
                    boundsMax = vec3(0.6875, 0.875, 0.5);
                    break;
                case BLOCK_WALL_POST_LOW_N_E:
                    boundsMin = vec3(0.5, 0.000, 0.3125);
                    boundsMax = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_S_E:
                    boundsMin = vec3(0.3125, 0.000, 0.5);
                    boundsMax = vec3(0.6875, 0.875, 1.0);
                    break;
                case BLOCK_WALL_POST_LOW_S_W:
                    boundsMin = vec3(0.0, 0.000, 0.3125);
                    boundsMax = vec3(0.5, 0.875, 0.6875);
                    break;

                case BLOCK_WALL_POST_TALL_N_S:
                    boundsMin = vec3(0.3125, 0.0, 0.0);
                    boundsMax = vec3(0.6875, 1.0, 1.0);
                    break;
                case BLOCK_WALL_POST_TALL_W_E:
                    boundsMin = vec3(0.0, 0.0, 0.3125);
                    boundsMax = vec3(1.0, 1.0, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_N_W:
                    boundsMin = vec3(0.3125, 0.0, 0.0);
                    boundsMax = vec3(0.6875, 1.0, 0.5);
                    break;
                case BLOCK_WALL_POST_TALL_N_E:
                    boundsMin = vec3(0.5, 0.0, 0.3125);
                    boundsMax = vec3(1.0, 1.0, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_S_E:
                    boundsMin = vec3(0.3125, 0.0, 0.5);
                    boundsMax = vec3(0.6875, 1.0, 1.0);
                    break;
                case BLOCK_WALL_POST_TALL_S_W:
                    boundsMin = vec3(0.0, 0.0, 0.3125);
                    boundsMax = vec3(0.5, 1.0, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_ALL:
                    boundsMin = vec3(0.3125, 0.0, 0.0);
                    boundsMax = vec3(0.6875, 1.0, 1.0);
                    break;
            }

            #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                hit = BoxPointTest(boundsMin, boundsMax, rayStart);
            #else
                hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
            #endif

            if (!hit) {
                boundsMin = vec3(-1.0);
                boundsMax = vec3(-1.0);

                // 400
                switch (blockId) {
                    case BLOCK_BED_FOOT_N:
                    case BLOCK_BED_HEAD_S:
                    case BLOCK_BED_HEAD_W:
                    case BLOCK_BED_FOOT_E:
                        boundsMin = vec3((0.0/16.0), (0.0/16.0), (13.0/16.0));
                        boundsMax = vec3((3.0/16.0), (3.0/16.0), (16.0/16.0));
                        break;

                    case BLOCK_CAULDRON:
                    case BLOCK_CAULDRON_LAVA:
                        boundsMin = vec3(      0.0 ,       0.0 , (12.0/16.0));
                        boundsMax = vec3((4.0/16.0), (3.0/16.0),        1.0 );
                        break;

                    case BLOCK_CANDLES_4:
                    case BLOCK_CANDLES_LIT_4:
                        boundsMin = vec3((6.0/16.0),       0.0 , ( 8.0/16.0));
                        boundsMax = vec3((8.0/16.0), (3.0/16.0), (10.0/16.0));
                        break;
                }

                // 500
                switch (blockId) {
                    case BLOCK_FENCE_ALL:
                        boundsMin = vec3(0.0, (6.0/16.0), (7.0/16.0));
                        boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
                        break;
                    case BLOCK_FENCE_N_E:
                        boundsMin = vec3(0.5, (6.0/16.0), (7.0/16.0));
                        boundsMax = vec3(1.0, (9.0/16.0), (9.0/16.0));
                        break;
                    case BLOCK_FENCE_N_W:
                        boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.0);
                        boundsMax = vec3((9.0/16.0), (9.0/16.0), 0.5);
                        break;
                    case BLOCK_FENCE_S_E:
                        boundsMin = vec3((7.0/16.0), (6.0/16.0), 0.5);
                        boundsMax = vec3((9.0/16.0), (9.0/16.0), 1.0);
                        break;
                    case BLOCK_FENCE_S_W:
                        boundsMin = vec3(0.0, (6.0/16.0), (7.0/16.0));
                        boundsMax = vec3(0.5, (9.0/16.0), (9.0/16.0));
                        break;
                    case BLOCK_FENCE_GATE_CLOSED_N_S:
                        boundsMin = vec3((0.0/16.0), (5.0/16.0), (7.0/16.0));
                        boundsMax = vec3((2.0/16.0),        1.0, (9.0/16.0));
                        break;
                    case BLOCK_FENCE_GATE_CLOSED_W_E:
                        boundsMin = vec3((7.0/16.0), (5.0/16.0), (0.0/16.0));
                        boundsMax = vec3((9.0/16.0),        1.0, (2.0/16.0));
                        break;
                }

                #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
                    hit = BoxPointTest(boundsMin, boundsMax, rayStart);
                #else
                    hit = BoxRayTest(boundsMin, boundsMax, rayStart, rayInv);
                #endif

                if (!hit) {
                    boundsMin = vec3(-1.0);
                    boundsMax = vec3(-1.0);

                    // 400
                    switch (blockId) {
                        case BLOCK_BED_FOOT_N:
                        case BLOCK_BED_HEAD_S:
                        case BLOCK_BED_HEAD_E:
                        case BLOCK_BED_FOOT_W:
                            boundsMin = vec3((13.0/16.0), (0.0/16.0), (13.0/16.0));
                            boundsMax = vec3((16.0/16.0), (3.0/16.0), (16.0/16.0));
                            break;

                        case BLOCK_CAULDRON:
                        case BLOCK_CAULDRON_LAVA:
                            boundsMin = vec3((12.0/16.0),       0.0 , (12.0/16.0));
                            boundsMax = vec3(       1.0 , (3.0/16.0),        1.0 );
                            break;
                    }

//==============================================================================================================

                    // 500
                    switch (blockId) {
                        case BLOCK_FENCE_ALL:
                            boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.0);
                            boundsMax = vec3((9.0/16.0), (15.0/16.0), 1.0);
                            break;
                        case BLOCK_FENCE_N_E:
                            boundsMin = vec3(0.5, (12.0/16.0), (7.0/16.0));
                            boundsMax = vec3(1.0, (15.0/16.0), (9.0/16.0));
                            break;
                        case BLOCK_FENCE_S_E:
                            boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.5);
                            boundsMax = vec3((9.0/16.0), (15.0/16.0), 1.0);
                            break;
                        case BLOCK_FENCE_S_W:
                            boundsMin = vec3(0.0, (12.0/16.0), (7.0/16.0));
                            boundsMax = vec3(0.5, (15.0/16.0), (9.0/16.0));
                            break;
                        case BLOCK_FENCE_N_W:
                            boundsMin = vec3((7.0/16.0), (12.0/16.0), 0.0);
                            boundsMax = vec3((9.0/16.0), (15.0/16.0), 0.5);
                            break;
                        case BLOCK_FENCE_GATE_CLOSED_N_S:
                            boundsMin = vec3((14.0/16.0), (5.0/16.0), (7.0/16.0));
                            boundsMax = vec3(        1.0,        1.0, (9.0/16.0));
                            break;
                        case BLOCK_FENCE_GATE_CLOSED_W_E:
                            boundsMin = vec3((7.0/16.0), (5.0/16.0), (14.0/16.0));
                            boundsMax = vec3((9.0/16.0),        1.0,         1.0);
                            break;
                    }

                    #if DYN_LIGHT_TRACE_METHOD == DYN_LIGHT_TRACE_RAY
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
#endif
