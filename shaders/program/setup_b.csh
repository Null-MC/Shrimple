#define RENDER_SETUP_COLLISSIONS
#define RENDER_SETUP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(5, 5, 1);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/blocks.glsl"

    #include "/lib/buffers/collissions.glsl"
#endif


void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        uint blockId = uint(gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 40);
        if (blockId > 1200) return;

        uint shapeCount = 0u;
        vec3 boundsMin[5], boundsMax[5];

        if (blockId == BLOCK_LANTERN_CEIL || blockId == BLOCK_SOUL_LANTERN_CEIL) {
            shapeCount = 2u;
            boundsMin[0] = vec3(( 5.0/16.0), (1.0/16.0), ( 5.0/16.0));
            boundsMax[0] = vec3((11.0/16.0), (8.0/16.0), (11.0/16.0));
            boundsMin[1] = vec3(( 6.0/16.0), ( 8.0/16.0), ( 6.0/16.0));
            boundsMax[1] = vec3((10.0/16.0), (10.0/16.0), (10.0/16.0));
        }

        if (blockId == BLOCK_LANTERN_FLOOR || blockId == BLOCK_SOUL_LANTERN_FLOOR) {
            shapeCount = 2u;
            boundsMin[0] = vec3(( 5.0/16.0),       0.0 , ( 5.0/16.0));
            boundsMax[0] = vec3((11.0/16.0), (7.0/16.0), (11.0/16.0));
            boundsMin[1] = vec3(( 6.0/16.0), (7.0/16.0), ( 6.0/16.0));
            boundsMax[1] = vec3((10.0/16.0), (9.0/16.0), (10.0/16.0));
        }

        // 400-500
        switch (blockId) {
            case BLOCK_COMPARATOR:
            case BLOCK_REPEATER:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (2.0/16.0), 1.0);
                break;
            case BLOCK_DAYLIGHT_DETECTOR:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (6.0/16.0), 1.0);
                break;
            case BLOCK_SCULK_SENSOR:
            case BLOCK_SCULK_SHRIEKER:
            case BLOCK_CREATE_SEAT:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (8.0/16.0), 1.0);
                break;
            case BLOCK_ENCHANTING_TABLE:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (12.0/16.0), 1.0);
                break;
        }

        if (blockId == BLOCK_ANVIL_N_S || blockId == BLOCK_ANVIL_W_E) {
            boundsMin[0] = vec3(( 2.0/16.0), 0.00, ( 2.0/16.0));
            boundsMax[0] = vec3((14.0/16.0), 0.25, (14.0/16.0));
            shapeCount = 3u;

            switch (blockId) {
                case BLOCK_ANVIL_N_S:
                    boundsMin[1] = vec3(( 3.0/16.0), (10.0/16.0), 0.0);
                    boundsMax[1] = vec3((13.0/16.0),         1.0, 1.0);
                    boundsMin[2] = vec3(( 6.0/16.0), 0.25, 0.25);
                    boundsMax[2] = vec3((10.0/16.0), 0.75, 0.75);
                    break;
                case BLOCK_ANVIL_W_E:
                    boundsMin[1] = vec3(0.0, (10.0/16.0), ( 3.0/16.0));
                    boundsMax[1] = vec3(1.0,         1.0, (13.0/16.0));
                    boundsMin[2] = vec3(0.25, 0.25, ( 6.0/16.0));
                    boundsMax[2] = vec3(0.75, 0.75, (10.0/16.0));
                    break;
            }
        }

        if (blockId >= BLOCK_BED_HEAD_N && blockId <= BLOCK_BED_FOOT_W) {
            boundsMin[0] = vec3(0.0, (3.0/16.0), 0.0);
            boundsMax[0] = vec3(1.0, (9.0/16.0), 1.0);
            shapeCount = 3u;

            switch (blockId) {
                case BLOCK_BED_HEAD_N:
                    boundsMin[1] = vec3((0.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax[1] = vec3((3.0/16.0), (3.0/16.0), (3.0/16.0));
                    boundsMin[2] = vec3((13.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax[2] = vec3((16.0/16.0), (3.0/16.0), (3.0/16.0));
                    break;
                case BLOCK_BED_HEAD_E:
                    boundsMin[1] = vec3((13.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax[1] = vec3((16.0/16.0), (3.0/16.0), (3.0/16.0));
                    boundsMin[2] = vec3((13.0/16.0), (0.0/16.0), (13.0/16.0));
                    boundsMax[2] = vec3((16.0/16.0), (3.0/16.0), (16.0/16.0));
                    break;
                case BLOCK_BED_HEAD_S:
                    boundsMin[1] = vec3((0.0/16.0), (0.0/16.0), (13.0/16.0));
                    boundsMax[1] = vec3((3.0/16.0), (3.0/16.0), (16.0/16.0));
                    boundsMin[2] = vec3((13.0/16.0), (0.0/16.0), (13.0/16.0));
                    boundsMax[2] = vec3((16.0/16.0), (3.0/16.0), (16.0/16.0));
                    break;
                case BLOCK_BED_HEAD_W:
                    boundsMin[1] = vec3((0.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax[1] = vec3((3.0/16.0), (3.0/16.0), (3.0/16.0));
                    boundsMin[2] = vec3((0.0/16.0), (0.0/16.0), (13.0/16.0));
                    boundsMax[2] = vec3((3.0/16.0), (3.0/16.0), (16.0/16.0));
                    break;

                case BLOCK_BED_FOOT_N:
                    boundsMin[1] = vec3((0.0/16.0), (0.0/16.0), (13.0/16.0));
                    boundsMax[1] = vec3((3.0/16.0), (3.0/16.0), (16.0/16.0));
                    boundsMin[2] = vec3((13.0/16.0), (0.0/16.0), (13.0/16.0));
                    boundsMax[2] = vec3((16.0/16.0), (3.0/16.0), (16.0/16.0));
                    break;
                case BLOCK_BED_FOOT_E:
                    boundsMin[1] = vec3((0.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax[1] = vec3((3.0/16.0), (3.0/16.0), (3.0/16.0));
                    boundsMin[2] = vec3((0.0/16.0), (0.0/16.0), (13.0/16.0));
                    boundsMax[2] = vec3((3.0/16.0), (3.0/16.0), (16.0/16.0));
                    break;
                case BLOCK_BED_FOOT_S:
                    boundsMin[1] = vec3((0.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax[1] = vec3((3.0/16.0), (3.0/16.0), (3.0/16.0));
                    boundsMin[2] = vec3((13.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax[2] = vec3((16.0/16.0), (3.0/16.0), (3.0/16.0));
                    break;
                case BLOCK_BED_FOOT_W:
                    boundsMin[1] = vec3((13.0/16.0), (0.0/16.0), (0.0/16.0));
                    boundsMax[1] = vec3((16.0/16.0), (3.0/16.0), (3.0/16.0));
                    boundsMin[2] = vec3((13.0/16.0), (0.0/16.0), (13.0/16.0));
                    boundsMax[2] = vec3((16.0/16.0), (3.0/16.0), (16.0/16.0));
                    break;
            }
        }

        if (blockId >= BLOCK_BELL_FLOOR_N_S && blockId <= BLOCK_BELL_CEILING) {
            shapeCount = 2u;
            boundsMin[0] = vec3(( 5.0/16.0), ( 6.0/16.0), ( 5.0/16.0));
            boundsMax[0] = vec3((11.0/16.0), (13.0/16.0), (11.0/16.0));
            boundsMin[1] = vec3(0.25,       0.25, 0.25);
            boundsMax[1] = vec3(0.75, (6.0/16.0), 0.75);
        }

        switch (blockId) {
            case BLOCK_CACTUS:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 1.0/16.0), 0.0, ( 1.0/16.0));
                boundsMax[0] = vec3((15.0/16.0), 1.0, (15.0/16.0));
                break;

            case BLOCK_CAMPFIRE_N_S:
                shapeCount = 3u;
                boundsMin[0] = vec3( (1.0/16.0),        0.0, 0.0);
                boundsMax[0] = vec3((15.0/16.0), (4.0/16.0), 1.0);
                boundsMin[1] = vec3(0.0, (3.0/16.0), (1.0/16.0));
                boundsMax[1] = vec3(1.0, (7.0/16.0), (5.0/16.0));
                boundsMin[2] = vec3(0.0, (3.0/16.0), (11.0/16.0));
                boundsMax[2] = vec3(1.0, (7.0/16.0), (15.0/16.0));
                break;
            case BLOCK_CAMPFIRE_W_E:
                shapeCount = 3u;
                boundsMin[0] = vec3(0.0,        0.0,  (1.0/16.0));
                boundsMax[0] = vec3(1.0, (4.0/16.0), (15.0/16.0));
                boundsMin[1] = vec3((1.0/16.0), (3.0/16.0), 0.0);
                boundsMax[1] = vec3((5.0/16.0), (7.0/16.0), 1.0);
                boundsMin[2] = vec3((11.0/16.0), (3.0/16.0), 0.0);
                boundsMax[2] = vec3((15.0/16.0), (7.0/16.0), 1.0);
                break;

            case BLOCK_CANDLES_1:
            case BLOCK_CANDLES_LIT_1:
                shapeCount = 1u;
                boundsMin[0] = vec3((7.0/16.0),       0.0 , (7.0/16.0));
                boundsMax[0] = vec3((9.0/16.0), (6.0/16.0), (9.0/16.0));
                break;
            case BLOCK_CANDLES_2:
            case BLOCK_CANDLES_LIT_2:
                shapeCount = 2u;
                boundsMin[0] = vec3(( 9.0/16.0),       0.0 , (6.0/16.0));
                boundsMax[0] = vec3((11.0/16.0), (6.0/16.0), (8.0/16.0));
                boundsMin[1] = vec3((5.0/16.0),       0.0 , (7.0/16.0));
                boundsMax[1] = vec3((7.0/16.0), (5.0/16.0), (9.0/16.0));
                break;
            case BLOCK_CANDLES_3:
            case BLOCK_CANDLES_LIT_3:
                shapeCount = 3u;
                boundsMin[0] = vec3(( 8.0/16.0),       0.0 , (6.0/16.0));
                boundsMax[0] = vec3((10.0/16.0), (6.0/16.0), (8.0/16.0));
                boundsMin[1] = vec3((5.0/16.0),       0.0 , (7.0/16.0));
                boundsMax[1] = vec3((7.0/16.0), (5.0/16.0), (9.0/16.0));
                boundsMin[2] = vec3((7.0/16.0),       0.0 , ( 9.0/16.0));
                boundsMax[2] = vec3((9.0/16.0), (3.0/16.0), (11.0/16.0));
                break;
            case BLOCK_CANDLES_4:
            case BLOCK_CANDLES_LIT_4:
                shapeCount = 4u;
                boundsMin[0] = vec3(( 8.0/16.0),       0.0 , (5.0/16.0));
                boundsMax[0] = vec3((10.0/16.0), (6.0/16.0), (7.0/16.0));
                boundsMin[1] = vec3((5.0/16.0),       0.0 , (5.0/16.0));
                boundsMax[1] = vec3((7.0/16.0), (5.0/16.0), (7.0/16.0));
                boundsMin[2] = vec3(( 9.0/16.0),       0.0 , ( 8.0/16.0));
                boundsMax[2] = vec3((11.0/16.0), (5.0/16.0), (10.0/16.0));
                boundsMin[3] = vec3((6.0/16.0),       0.0 , ( 8.0/16.0));
                boundsMax[3] = vec3((8.0/16.0), (3.0/16.0), (10.0/16.0));
                break;
        }

        if (blockId == BLOCK_CAKE || blockId == BLOCK_CANDLE_CAKE || blockId == BLOCK_CANDLE_CAKE_LIT) {
            boundsMin[0] = vec3(( 1.0/16.0), 0.0, ( 1.0/16.0));
            boundsMax[0] = vec3((15.0/16.0), 0.5, (15.0/16.0));

            switch (blockId) {
                case BLOCK_CAKE:
                    shapeCount = 1u;
                    break;

                case BLOCK_CANDLE_CAKE:
                case BLOCK_CANDLE_CAKE_LIT:
                    shapeCount = 2u;
                    boundsMin[1] = vec3((7.0/16.0),        0.5 , (7.0/16.0));
                    boundsMax[1] = vec3((9.0/16.0), (14.0/16.0), (9.0/16.0));
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_CARPET:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (1.0/16.0), 1.0);
                break;

            case BLOCK_CAULDRON:
            case BLOCK_CAULDRON_LAVA:
                shapeCount = 5u;
                boundsMin[0] = vec3(0.0, (3.0/16.0), 0.0);
                boundsMax[0] = vec3(1.0);
                boundsMin[1] = vec3(0.0);
                boundsMax[1] = vec3((4.0/16.0), (3.0/16.0), (4.0/16.0));
                boundsMin[2] = vec3((12.0/16.0),       0.0 ,       0.0 );
                boundsMax[2] = vec3(       1.0 , (3.0/16.0), (4.0/16.0));
                boundsMin[3] = vec3(      0.0 ,       0.0 , (12.0/16.0));
                boundsMax[3] = vec3((4.0/16.0), (3.0/16.0),        1.0 );
                boundsMin[4] = vec3((12.0/16.0),       0.0 , (12.0/16.0));
                boundsMax[4] = vec3(       1.0 , (3.0/16.0),        1.0 );
                break;

            case BLOCK_END_PORTAL_FRAME:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (13.0/16.0), 1.0);
                break;

            case BLOCK_FLOWER_POT:
            case BLOCK_POTTED_PLANT:
                shapeCount = 1u;
                boundsMin[0] = vec3((5.0/16.0), 0.0, (5.0/16.0));
                boundsMax[0] = vec3((10.0/16.0), (6.0/16.0), (10.0/16.0));
                break;

            case BLOCK_GRINDSTONE_FLOOR_N_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.25, 0.25, ( 2.0/16.0));
                boundsMax[0] = vec3(0.75, 1.00, (14.0/16.0));
                break;
            case BLOCK_GRINDSTONE_FLOOR_W_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 2.0/16.0), 0.25, 0.25);
                boundsMax[0] = vec3((14.0/16.0), 1.00, 0.75);
                break;
            case BLOCK_GRINDSTONE_WALL_N_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.25, ( 2.0/16.0), ( 2.0/16.0));
                boundsMax[0] = vec3(0.75, (14.0/16.0), (14.0/16.0));
                break;
            case BLOCK_GRINDSTONE_WALL_W_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 2.0/16.0), ( 2.0/16.0), 0.25);
                boundsMax[0] = vec3((14.0/16.0), (14.0/16.0), 0.75);
                break;
        }

        if (blockId >= BLOCK_HOPPER_DOWN && blockId <= BLOCK_HOPPER_W) {
            boundsMin[0] = vec3(0.0, (10.0/16.0), 0.0);
            boundsMax[0] = vec3(1.0);
            boundsMin[1] = vec3(0.25);
            boundsMax[1] = vec3(0.75, 0.625, 0.75);
            shapeCount = 3u;

            switch (blockId) {
                case BLOCK_HOPPER_DOWN:
                    boundsMin[2] = vec3(0.375, 0.00, 0.325);
                    boundsMax[2] = vec3(0.625, 0.25, 0.675);
                    break;
                case BLOCK_HOPPER_N:
                    boundsMin[2] = vec3(0.25, 0.25, 0.00);
                    boundsMax[2] = vec3(0.75, 0.50, 0.25);
                    break;
                case BLOCK_HOPPER_E:
                    boundsMin[2] = vec3(0.75, 0.25, 0.25);
                    boundsMax[2] = vec3(1.00, 0.50, 0.75);
                    break;
                case BLOCK_HOPPER_S:
                    boundsMin[2] = vec3(0.25, 0.25, 0.75);
                    boundsMax[2] = vec3(0.75, 0.50, 1.00);
                    break;
                case BLOCK_HOPPER_W:
                    boundsMin[2] = vec3(0.00, 0.25, 0.25);
                    boundsMax[2] = vec3(0.25, 0.50, 0.75);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_LECTERN:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (2.0/16.0), 1.0);
                boundsMin[1] = vec3(0.25,         0.0, 0.25);
                boundsMax[1] = vec3(0.75, (13.0/16.0), 0.75);
                break;

            case BLOCK_LIGHTNING_ROD_N:
                shapeCount = 2u;
                boundsMin[0] = vec3((7.0/16.0), (7.0/16.0), 0.0);
                boundsMax[0] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                boundsMin[1] = vec3( (6.0/16.0),  (6.0/16.0), 0.00);
                boundsMax[1] = vec3((10.0/16.0), (10.0/16.0), 0.25);
                break;
            case BLOCK_LIGHTNING_ROD_E:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0, (7.0/16.0), (7.0/16.0));
                boundsMax[0] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                boundsMin[1] = vec3(0.75,  (6.0/16.0),  (6.0/16.0));
                boundsMax[1] = vec3(1.00, (10.0/16.0), (10.0/16.0));
                break;
            case BLOCK_LIGHTNING_ROD_S:
                shapeCount = 2u;
                boundsMin[0] = vec3((7.0/16.0), (7.0/16.0), 0.0);
                boundsMax[0] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                boundsMin[1] = vec3( (6.0/16.0),  (6.0/16.0), 0.75);
                boundsMax[1] = vec3((10.0/16.0), (10.0/16.0), 1.00);
                break;
            case BLOCK_LIGHTNING_ROD_W:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0, (7.0/16.0), (7.0/16.0));
                boundsMax[0] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                boundsMin[1] = vec3(0.00,  (6.0/16.0),  (6.0/16.0));
                boundsMax[1] = vec3(0.25, (10.0/16.0), (10.0/16.0));
                break;
            case BLOCK_LIGHTNING_ROD_UP:
                shapeCount = 2u;
                boundsMin[0] = vec3((7.0/16.0), 0.0, (7.0/16.0));
                boundsMax[0] = vec3((9.0/16.0), 1.0, (9.0/16.0));
                boundsMin[1] = vec3( (6.0/16.0), 0.75,  (6.0/16.0));
                boundsMax[1] = vec3((10.0/16.0), 1.00, (10.0/16.0));
                break;
            case BLOCK_LIGHTNING_ROD_DOWN:
                shapeCount = 2u;
                boundsMin[0] = vec3((7.0/16.0), 0.0, (7.0/16.0));
                boundsMax[0] = vec3((9.0/16.0), 1.0, (9.0/16.0));
                boundsMin[1] = vec3( (6.0/16.0), 0.00,  (6.0/16.0));
                boundsMax[1] = vec3((10.0/16.0), 0.25, (10.0/16.0));
                break;

            case BLOCK_PATHWAY:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (15.0/16.0), 1.0);
                break;

            case BLOCK_PISTON_EXTENDED_N:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0, 0.0, 0.25);
                boundsMax[0] = vec3(1.0);
                boundsMin[1] = vec3(0.375, 0.375, 0.0);
                boundsMax[1] = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_EXTENDED_E:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(0.75, 1.0, 1.0);
                boundsMin[1] = vec3(0.0, 0.375, 0.375);
                boundsMax[1] = vec3(1.0, 0.625, 0.625);
                break;
            case BLOCK_PISTON_EXTENDED_S:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, 1.0, 0.75);
                boundsMin[1] = vec3(0.375, 0.375, 0.0);
                boundsMax[1] = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_EXTENDED_W:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.25, 0.0, 0.0);
                boundsMax[0] = vec3(1.0);
                boundsMin[1] = vec3(0.0, 0.375, 0.375);
                boundsMax[1] = vec3(1.0, 0.625, 0.625);
                break;
            case BLOCK_PISTON_EXTENDED_UP:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, 0.75, 1.0);
                boundsMin[1] = vec3(0.375, 0.0, 0.375);
                boundsMax[1] = vec3(0.625, 1.0, 0.625);
                break;
            case BLOCK_PISTON_EXTENDED_DOWN:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0, 0.25, 0.0);
                boundsMax[0] = vec3(1.0);
                boundsMin[1] = vec3(0.375, 0.0, 0.375);
                boundsMax[1] = vec3(0.625, 1.0, 0.625);
                break;

            case BLOCK_PISTON_HEAD_N:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, 1.0, 0.25);
                boundsMin[1] = vec3(0.375, 0.375, 0.0);
                boundsMax[1] = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_HEAD_E:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.75, 0.0, 0.0);
                boundsMax[0] = vec3(1.0);
                boundsMin[1] = vec3(0.0, 0.375, 0.375);
                boundsMax[1] = vec3(1.0, 0.625, 0.625);
                break;
            case BLOCK_PISTON_HEAD_S:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0, 0.0, 0.75);
                boundsMax[0] = vec3(1.0);
                boundsMin[1] = vec3(0.375, 0.375, 0.0);
                boundsMax[1] = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_HEAD_W:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(0.25, 1.0, 1.0);
                boundsMin[1] = vec3(0.0, 0.375, 0.375);
                boundsMax[1] = vec3(1.0, 0.625, 0.625);
                break;
            case BLOCK_PISTON_HEAD_UP:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0, 0.75, 0.0);
                boundsMax[0] = vec3(1.0);
                boundsMin[1] = vec3(0.375, 0.0, 0.375);
                boundsMax[1] = vec3(0.625, 1.0, 0.625);
                break;
            case BLOCK_PISTON_HEAD_DOWN:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, 0.25, 1.0);
                boundsMin[1] = vec3(0.375, 0.0, 0.375);
                boundsMax[1] = vec3(0.625, 1.0, 0.625);
                break;

            case BLOCK_PRESSURE_PLATE:
                shapeCount = 1u;
                boundsMin[0] = vec3((1.0/16.0), 0.0, (1.0/16.0));
                boundsMax[0] = vec3((15.0/16.0), (1.0/16.0), (15.0/16.0));
                break;
        }

        if (blockId >= BLOCK_SNOW_LAYERS_1 && blockId <= BLOCK_SNOW_LAYERS_7) {
            boundsMin[0] = vec3(0.0);
            shapeCount = 1u;

            switch (blockId) {
                case BLOCK_SNOW_LAYERS_1:
                    boundsMax[0] = vec3(1.0, (2.0/16.0), 1.0);
                    break;
                case BLOCK_SNOW_LAYERS_2:
                    boundsMax[0] = vec3(1.0, (4.0/16.0), 1.0);
                    break;
                case BLOCK_SNOW_LAYERS_3:
                    boundsMax[0] = vec3(1.0, (6.0/16.0), 1.0);
                    break;
                case BLOCK_SNOW_LAYERS_4:
                    boundsMax[0] = vec3(1.0, (8.0/16.0), 1.0);
                    break;
                case BLOCK_SNOW_LAYERS_5:
                    boundsMax[0] = vec3(1.0, (10.0/16.0), 1.0);
                    break;
                case BLOCK_SNOW_LAYERS_6:
                    boundsMax[0] = vec3(1.0, (12.0/16.0), 1.0);
                    break;
                case BLOCK_SNOW_LAYERS_7:
                    boundsMax[0] = vec3(1.0, (14.0/16.0), 1.0);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_STONECUTTER:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (9.0/16.0), 1.0);
                break;
        }

        switch (blockId) {
            case BLOCK_BUTTON_FLOOR_N_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 5.0/16.0), 0.000, ( 6.0/16.0));
                boundsMax[0] = vec3((11.0/16.0), 0.125, (10.0/16.0));
                break;
            case BLOCK_BUTTON_FLOOR_W_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 6.0/16.0), 0.000, ( 5.0/16.0));
                boundsMax[0] = vec3((10.0/16.0), 0.125, (11.0/16.0));
                break;
            case BLOCK_BUTTON_CEILING_N_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 5.0/16.0), 0.875, ( 6.0/16.0));
                boundsMax[0] = vec3((11.0/16.0), 1.000, (10.0/16.0));
                break;
            case BLOCK_BUTTON_CEILING_W_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 6.0/16.0), 0.875, ( 5.0/16.0));
                boundsMax[0] = vec3((10.0/16.0), 1.000, (11.0/16.0));
                break;
            case BLOCK_BUTTON_WALL_N:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 5.0/16.0), ( 6.0/16.0), 0.875);
                boundsMax[0] = vec3((11.0/16.0), (10.0/16.0), 1.000);
                break;
            case BLOCK_BUTTON_WALL_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.000, ( 6.0/16.0), ( 5.0/16.0));
                boundsMax[0] = vec3(0.125, (10.0/16.0), (11.0/16.0));
                break;
            case BLOCK_BUTTON_WALL_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 5.0/16.0), ( 6.0/16.0), 0.000);
                boundsMax[0] = vec3((11.0/16.0), (10.0/16.0), 0.125);
                break;
            case BLOCK_BUTTON_WALL_W:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.875, ( 6.0/16.0), ( 5.0/16.0));
                boundsMax[0] = vec3(1.000, (10.0/16.0), (11.0/16.0));
                break;
        }

        switch (blockId) {
            case BLOCK_DOOR_N:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0, 0.0, (13.0/16.0));
                boundsMax[0] = vec3(1.0);
                break;
            case BLOCK_DOOR_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3((3.0/16.0), 1.0, 1.0);
                break;
            case BLOCK_DOOR_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, 1.0, (3.0/16.0));
                break;
            case BLOCK_DOOR_W:
                shapeCount = 1u;
                boundsMin[0] = vec3((13.0/16.0), 0.0, 0.0);
                boundsMax[0] = vec3(1.0);
                break;
        }

        switch (blockId) {
            case BLOCK_LEVER_FLOOR_N_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 5.0/16.0),        0.0, ( 4.0/16.0));
                boundsMax[0] = vec3((11.0/16.0), (3.0/16.0), (12.0/16.0));
                break;
            case BLOCK_LEVER_FLOOR_W_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 4.0/16.0),        0.0, ( 5.0/16.0));
                boundsMax[0] = vec3((12.0/16.0), (3.0/16.0), (11.0/16.0));
                break;
            case BLOCK_LEVER_CEILING_N_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 5.0/16.0), (13.0/16.0), ( 4.0/16.0));
                boundsMax[0] = vec3((11.0/16.0),         1.0, (12.0/16.0));
                break;
            case BLOCK_LEVER_CEILING_W_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 4.0/16.0), (13.0/16.0), ( 5.0/16.0));
                boundsMax[0] = vec3((12.0/16.0),         1.0, (11.0/16.0));
                break;
            case BLOCK_LEVER_WALL_N:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 5.0/16.0), 0.25, (13.0/16.0));
                boundsMax[0] = vec3((11.0/16.0), 0.75,         1.0);
                break;
            case BLOCK_LEVER_WALL_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(       0.0, 0.25, ( 5.0/16.0));
                boundsMax[0] = vec3((3.0/16.0), 0.75, (11.0/16.0));
                break;
            case BLOCK_LEVER_WALL_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 5.0/16.0), 0.25,        0.0);
                boundsMax[0] = vec3((11.0/16.0), 0.75, (3.0/16.0));
                break;
            case BLOCK_LEVER_WALL_W:
                shapeCount = 1u;
                boundsMin[0] = vec3((13.0/16.0), 0.25, ( 5.0/16.0));
                boundsMax[0] = vec3(        1.0, 0.75, (11.0/16.0));
                break;
        }

        switch (blockId) {
            case BLOCK_TRAPDOOR_BOTTOM:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, (3.0/16.0), 1.0);
                break;
            case BLOCK_TRAPDOOR_TOP:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0, (13.0/16.0), 0.0);
                boundsMax[0] = vec3(1.0);
                break;
            case BLOCK_TRAPDOOR_N:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0, 0.0, (13.0/16.0));
                boundsMax[0] = vec3(1.0);
                break;
            case BLOCK_TRAPDOOR_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3((3.0/16.0), 1.0, 1.0);
                break;
            case BLOCK_TRAPDOOR_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0);
                boundsMax[0] = vec3(1.0, 1.0, (3.0/16.0));
                break;
            case BLOCK_TRAPDOOR_W:
                shapeCount = 1u;
                boundsMin[0] = vec3((13.0/16.0), 0.0, 0.0);
                boundsMax[0] = vec3(1.0);
                break;
        }

        switch (blockId) {
            case BLOCK_TRIPWIRE_HOOK_N:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.375, (1.0/16.0), 0.875);
                boundsMax[0] = vec3(0.625, (9.0/16.0), 1.000);
                break;
            case BLOCK_TRIPWIRE_HOOK_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.000, (1.0/16.0), 0.375);
                boundsMax[0] = vec3(0.125, (9.0/16.0), 0.625);
                break;
            case BLOCK_TRIPWIRE_HOOK_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.375, (1.0/16.0), 0.000);
                boundsMax[0] = vec3(0.625, (9.0/16.0), 0.125);
                break;
            case BLOCK_TRIPWIRE_HOOK_W:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.875, (1.0/16.0), 0.375);
                boundsMax[0] = vec3(1.000, (9.0/16.0), 0.625);
                break;
        }

        if (blockId >= BLOCK_SLAB_TOP && blockId <= BLOCK_SLAB_VERTICAL_W) {
            shapeCount = 1u;

            switch (blockId) {
                case BLOCK_SLAB_TOP:
                    boundsMin[0] = vec3(0.0, 0.5, 0.0);
                    boundsMax[0] = vec3(1.0);
                    break;
                case BLOCK_SLAB_BOTTOM:
                    boundsMin[0] = vec3(0.0);
                    boundsMax[0] = vec3(1.0, (8.0/16.0), 1.0);
                    break;
                case BLOCK_SLAB_VERTICAL_N:
                    boundsMin[0] = vec3(0.0);
                    boundsMax[0] = vec3(1.0, 1.0, 0.5);
                    break;
                case BLOCK_SLAB_VERTICAL_E:
                    boundsMin[0] = vec3(0.5, 0.0, 0.0);
                    boundsMax[0] = vec3(1.0);
                    break;
                case BLOCK_SLAB_VERTICAL_S:
                    boundsMin[0] = vec3(0.0, 0.0, 0.5);
                    boundsMax[0] = vec3(1.0);
                    break;
                case BLOCK_SLAB_VERTICAL_W:
                    boundsMin[0] = vec3(0.0);
                    boundsMax[0] = vec3(0.5, 1.0, 1.0);
                    break;
            }
        }

        if (blockId >= BLOCK_STAIRS_BOTTOM_N && blockId <= BLOCK_STAIRS_BOTTOM_OUTER_S_W) {
            boundsMin[0] = vec3(0.0);
            boundsMax[0] = vec3(1.0, 0.5, 1.0);

            switch (blockId) {
                case BLOCK_STAIRS_BOTTOM_N:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.0);
                    boundsMax[1] = vec3(1.0, 1.0, 0.5);
                    break;
                case BLOCK_STAIRS_BOTTOM_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.5, 0.5, 0.0);
                    boundsMax[1] = vec3(1.0, 1.0, 1.0);
                    break;
                case BLOCK_STAIRS_BOTTOM_S:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.5);
                    boundsMax[1] = vec3(1.0, 1.0, 1.0);
                    break;
                case BLOCK_STAIRS_BOTTOM_W:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.0);
                    boundsMax[1] = vec3(0.5, 1.0, 1.0);
                    break;

                case BLOCK_STAIRS_BOTTOM_INNER_N_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.0);
                    boundsMax[1] = vec3(1.0, 1.0, 0.5);
                    boundsMin[2] = vec3(0.0, 0.5, 0.5);
                    boundsMax[2] = vec3(0.5, 1.0, 1.0);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.0);
                    boundsMax[1] = vec3(1.0, 1.0, 0.5);
                    boundsMin[2] = vec3(0.5, 0.5, 0.5);
                    boundsMax[2] = vec3(1.0, 1.0, 1.0);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_S_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.5);
                    boundsMax[1] = vec3(1.0, 1.0, 1.0);
                    boundsMin[2] = vec3(0.0, 0.5, 0.0);
                    boundsMax[2] = vec3(0.5, 1.0, 0.5);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.5);
                    boundsMax[1] = vec3(1.0, 1.0, 1.0);
                    boundsMin[2] = vec3(0.5, 0.5, 0.0);
                    boundsMax[2] = vec3(1.0, 1.0, 0.5);
                    break;

                case BLOCK_STAIRS_BOTTOM_OUTER_N_W:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.0);
                    boundsMax[1] = vec3(0.5, 1.0, 0.5);
                    break;
                case BLOCK_STAIRS_BOTTOM_OUTER_N_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.5, 0.5, 0.0);
                    boundsMax[1] = vec3(1.0, 1.0, 0.5);
                    break;
                case BLOCK_STAIRS_BOTTOM_OUTER_S_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.5, 0.5, 0.5);
                    boundsMax[1] = vec3(1.0, 1.0, 1.0);
                    break;
                case BLOCK_STAIRS_BOTTOM_OUTER_S_W:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.5, 0.5);
                    boundsMax[1] = vec3(0.5, 1.0, 1.0);
                    break;
            }
        }

        if (blockId >= BLOCK_STAIRS_TOP_N && blockId <= BLOCK_STAIRS_TOP_OUTER_S_W) {
            boundsMin[0] = vec3(0.0, 0.5, 0.0);
            boundsMax[0] = vec3(1.0);

            switch (blockId) {
                case BLOCK_STAIRS_TOP_N:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.0);
                    boundsMax[1] = vec3(1.0, 0.5, 0.5);
                    break;
                case BLOCK_STAIRS_TOP_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.5, 0.0, 0.0);
                    boundsMax[1] = vec3(1.0, 0.5, 1.0);
                    break;
                case BLOCK_STAIRS_TOP_S:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.5);
                    boundsMax[1] = vec3(1.0, 0.5, 1.0);
                    break;
                case BLOCK_STAIRS_TOP_W:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.0);
                    boundsMax[1] = vec3(0.5, 0.5, 1.0);
                    break;

                case BLOCK_STAIRS_TOP_INNER_N_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.0);
                    boundsMax[1] = vec3(1.0, 0.5, 0.5);
                    boundsMin[2] = vec3(0.0, 0.0, 0.5);
                    boundsMax[2] = vec3(0.5, 0.5, 1.0);
                    break;
                case BLOCK_STAIRS_TOP_INNER_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.0);
                    boundsMax[1] = vec3(1.0, 0.5, 0.5);
                    boundsMin[2] = vec3(0.5, 0.0, 0.5);
                    boundsMax[2] = vec3(1.0, 0.5, 1.0);
                    break;
                case BLOCK_STAIRS_TOP_INNER_S_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.5);
                    boundsMax[1] = vec3(1.0, 0.5, 1.0);
                    boundsMin[2] = vec3(0.0, 0.0, 0.0);
                    boundsMax[2] = vec3(0.5, 0.5, 0.5);
                    break;
                case BLOCK_STAIRS_TOP_INNER_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.5);
                    boundsMax[1] = vec3(1.0, 0.5, 1.0);
                    boundsMin[2] = vec3(0.5, 0.0, 0.0);
                    boundsMax[2] = vec3(1.0, 0.5, 0.5);
                    break;

                case BLOCK_STAIRS_TOP_OUTER_N_W:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.0);
                    boundsMax[1] = vec3(0.5, 0.5, 0.5);
                    break;
                case BLOCK_STAIRS_TOP_OUTER_N_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.5, 0.0, 0.0);
                    boundsMax[1] = vec3(1.0, 0.5, 0.5);
                    break;
                case BLOCK_STAIRS_TOP_OUTER_S_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.5, 0.0, 0.5);
                    boundsMax[1] = vec3(1.0, 0.5, 1.0);
                    break;
                case BLOCK_STAIRS_TOP_OUTER_S_W:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.5);
                    boundsMax[1] = vec3(0.5, 0.5, 1.0);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_CREATE_SHAFT_X:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0, ( 6.0/16.0), ( 6.0/16.0));
                boundsMax[0] = vec3(1.0, (10.0/16.0), (10.0/16.0));
                break;
            case BLOCK_CREATE_SHAFT_Y:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 6.0/16.0), 0.0, ( 6.0/16.0));
                boundsMax[0] = vec3((10.0/16.0), 1.0, (10.0/16.0));
                break;
            case BLOCK_CREATE_SHAFT_Z:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 6.0/16.0), ( 6.0/16.0), 0.0);
                boundsMax[0] = vec3((10.0/16.0), (10.0/16.0), 1.0);
                break;
        }

        if (blockId >= BLOCK_FENCE_POST && blockId <= BLOCK_FENCE_ALL) {
            boundsMin[0] = vec3(0.375, 0.0, 0.375);
            boundsMax[0] = vec3(0.625, 1.0, 0.625);

            switch (blockId) {
                case BLOCK_FENCE_POST:
                    shapeCount = 1u;
                    break;

                case BLOCK_FENCE_N:
                    shapeCount = 3u;
                    boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.0);
                    boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 0.5);
                    boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 0.5);
                    break;
                case BLOCK_FENCE_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.5, (6.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                    boundsMin[2] = vec3(0.5, (12.0/16.0), (7.0/16.0));
                    boundsMax[2] = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCK_FENCE_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.5);
                    boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                    boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.5);
                    boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;
                case BLOCK_FENCE_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, (6.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3(0.5, (9.0/16.0), (9.0/16.0));
                    boundsMin[2] = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax[2] = vec3(0.5, (15.0/16.0), (9.0/16.0));
                    break;

                case BLOCK_FENCE_N_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.0);
                    boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                    boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;
                case BLOCK_FENCE_W_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, (6.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                    boundsMin[2] = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax[2] = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;

                case BLOCK_FENCE_N_W:
                    shapeCount = 5u;
                    boundsMin[1] = vec3(0.0, (6.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3(0.5, (9.0/16.0), (9.0/16.0));
                    boundsMin[2] = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax[2] = vec3(0.5, (15.0/16.0), (9.0/16.0));
                    boundsMin[3] = vec3((7.0/16.0), (6.0/16.0), 0.0);
                    boundsMax[3] = vec3((9.0/16.0), (9.0/16.0), 0.5);
                    boundsMin[4] = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax[4] = vec3((9.0/16.0), (15.0/16.0), 0.5);
                    break;
                case BLOCK_FENCE_N_E:
                    shapeCount = 5u;
                    boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.0);
                    boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 0.5);
                    boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 0.5);
                    boundsMin[3] = vec3(0.5, (6.0/16.0), (7.0/16.0));
                    boundsMax[3] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                    boundsMin[4] = vec3(0.5, (12.0/16.0), (7.0/16.0));
                    boundsMax[4] = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCK_FENCE_S_W:
                    shapeCount = 5u;
                    boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.5);
                    boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                    boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.5);
                    boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    boundsMin[3] = vec3(0.0, (6.0/16.0), (7.0/16.0));
                    boundsMax[3] = vec3(0.5, (9.0/16.0), (9.0/16.0));
                    boundsMin[4] = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax[4] = vec3(0.5, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCK_FENCE_S_E:
                    shapeCount = 5u;
                    boundsMin[1] = vec3(0.5, (6.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                    boundsMin[2] = vec3(0.5, (12.0/16.0), (7.0/16.0));
                    boundsMax[2] = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    boundsMin[3] = vec3((7.0/16.0), (6.0/16.0), 0.5);
                    boundsMax[3] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                    boundsMin[4] = vec3((7.0/16.0), (12.0/16.0), 0.5);
                    boundsMax[4] = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;

                case BLOCK_FENCE_W_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, (6.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                    boundsMin[2] = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax[2] = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCK_FENCE_W_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, (6.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                    boundsMin[2] = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax[2] = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;
                case BLOCK_FENCE_N_W_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.0);
                    boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                    boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;
                case BLOCK_FENCE_N_E_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.0);
                    boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                    boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    break;

                case BLOCK_FENCE_ALL:
                    shapeCount = 5u;
                    boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.0);
                    boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                    boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.0);
                    boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 1.0);
                    boundsMin[3] = vec3(0.0, (6.0/16.0), (7.0/16.0));
                    boundsMax[3] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                    boundsMin[4] = vec3(0.0, (12.0/16.0), (7.0/16.0));
                    boundsMax[4] = vec3(1.0, (15.0/16.0), (9.0/16.0));
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_FENCE_GATE_CLOSED_N_S:
                shapeCount = 5u;
                boundsMin[0] = vec3(( 6.0/16.0), ( 9.0/16.0), (7.0/16.0));
                boundsMax[0] = vec3((10.0/16.0), (12.0/16.0), (9.0/16.0));
                boundsMin[1] = vec3(0.0, (6.0/16.0), (7.0/16.0));
                boundsMax[1] = vec3(1.0, (9.0/16.0), (9.0/16.0));
                boundsMin[2] = vec3(0.0, (12.0/16.0), (7.0/16.0));
                boundsMax[2] = vec3(1.0, (15.0/16.0), (9.0/16.0));
                boundsMin[3] = vec3((0.0/16.0), (5.0/16.0), (7.0/16.0));
                boundsMax[3] = vec3((2.0/16.0),        1.0, (9.0/16.0));
                boundsMin[4] = vec3((14.0/16.0), (5.0/16.0), (7.0/16.0));
                boundsMax[4] = vec3(        1.0,        1.0, (9.0/16.0));
                break;
            case BLOCK_FENCE_GATE_CLOSED_W_E:
                shapeCount = 5u;
                boundsMin[0] = vec3((7.0/16.0), ( 9.0/16.0), ( 6.0/16.0));
                boundsMax[0] = vec3((9.0/16.0), (12.0/16.0), (10.0/16.0));
                boundsMin[1] = vec3((7.0/16.0), (6.0/16.0), 0.0);
                boundsMax[1] = vec3((9.0/16.0), (9.0/16.0), 1.0);
                boundsMin[2] = vec3((7.0/16.0), (12.0/16.0), 0.0);
                boundsMax[2] = vec3((9.0/16.0), (15.0/16.0), 1.0);
                boundsMin[3] = vec3((7.0/16.0), (5.0/16.0), (0.0/16.0));
                boundsMax[3] = vec3((9.0/16.0),        1.0, (2.0/16.0));
                boundsMin[4] = vec3((7.0/16.0), (5.0/16.0), (14.0/16.0));
                boundsMax[4] = vec3((9.0/16.0),        1.0,         1.0);
                break;
        }

        if (blockId >= BLOCK_WALL_POST && blockId <= BLOCK_WALL_POST_TALL_W_LOW_E) {
            boundsMin[0] = vec3(0.25, 0.0, 0.25);
            boundsMax[0] = vec3(0.75, 1.0, 0.75);

            switch (blockId) {
                case BLOCK_WALL_POST:
                    shapeCount = 1u;
                    break;
                case BLOCK_WALL_POST_LOW_N:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[1] = vec3(0.6875, 0.875, 0.5);
                    break;
                case BLOCK_WALL_POST_LOW_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.5, 0.000, 0.3125);
                    boundsMax[1] = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_S:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.5);
                    boundsMax[1] = vec3(0.6875, 0.875, 1.0);
                    break;
                case BLOCK_WALL_POST_LOW_W:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[1] = vec3(0.5, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_N_S:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[1] = vec3(0.6875, 0.875, 1.0);
                    break;
                case BLOCK_WALL_POST_LOW_W_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[1] = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_N_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[1] = vec3(0.5, 0.875, 0.6875);
                    boundsMin[2] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[2] = vec3(0.6875, 0.875, 0.5);
                    break;
                case BLOCK_WALL_POST_LOW_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[1] = vec3(0.6875, 0.875, 0.5);
                    boundsMin[2] = vec3(0.5, 0.000, 0.3125);
                    boundsMax[2] = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_S_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.5);
                    boundsMax[1] = vec3(0.6875, 0.875, 1.0);
                    boundsMin[2] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[2] = vec3(0.5, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.5, 0.000, 0.3125);
                    boundsMax[1] = vec3(1.0, 0.875, 0.6875);
                    boundsMin[2] = vec3(0.3125, 0.000, 0.5);
                    boundsMax[2] = vec3(0.6875, 0.875, 1.0);
                    break;
                case BLOCK_WALL_POST_LOW_N_W_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[1] = vec3(0.6875, 0.875, 1.0);
                    boundsMin[2] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[2] = vec3(0.5, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_N_E_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[1] = vec3(0.6875, 0.875, 1.0);
                    boundsMin[2] = vec3(0.5, 0.000, 0.3125);
                    boundsMax[2] = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_W_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[1] = vec3(0.6875, 0.875, 0.5);
                    boundsMin[2] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[2] = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_W_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.000, 0.5);
                    boundsMax[1] = vec3(0.6875, 0.875, 1.0);
                    boundsMin[2] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[2] = vec3(1.0, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_LOW_ALL:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[1] = vec3(1.0, 0.875, 0.6875);
                    boundsMin[2] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[2] = vec3(0.6875, 0.875, 1.0);
                    break;

                case BLOCK_WALL_POST_TALL_N:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[1] = vec3(0.6875, 1.0, 0.5);
                    break;
                case BLOCK_WALL_POST_TALL_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.5, 0.0, 0.3125);
                    boundsMax[1] = vec3(1.0, 1.0, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_S:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.5);
                    boundsMax[1] = vec3(0.6875, 1.0, 1.0);
                    break;
                case BLOCK_WALL_POST_TALL_W:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[1] = vec3(0.5, 1.0, 0.6875);
                    break;

                case BLOCK_WALL_POST_TALL_N_S:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[1] = vec3(0.6875, 1.0, 1.0);
                    break;
                case BLOCK_WALL_POST_TALL_W_E:
                    shapeCount = 2u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[1] = vec3(1.0, 1.0, 0.6875);
                    break;

                case BLOCK_WALL_POST_TALL_N_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[1] = vec3(0.5, 1.0, 0.6875);
                    boundsMin[2] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[2] = vec3(0.6875, 1.0, 0.5);
                    break;
                case BLOCK_WALL_POST_TALL_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[1] = vec3(0.6875, 1.0, 0.5);
                    boundsMin[2] = vec3(0.5, 0.0, 0.3125);
                    boundsMax[2] = vec3(1.0, 1.0, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_S_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.5);
                    boundsMax[1] = vec3(0.6875, 1.0, 1.0);
                    boundsMin[2] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[2] = vec3(0.5, 1.0, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.50, 0.0, 0.3125);
                    boundsMax[1] = vec3(1.00, 1.0, 0.6875);
                    boundsMin[2] = vec3(0.3125, 0.0, 0.5);
                    boundsMax[2] = vec3(0.6875, 1.0, 1.0);
                    break;

                case BLOCK_WALL_POST_TALL_N_W_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[1] = vec3(0.6875, 1.0, 1.0);
                    boundsMin[2] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[2] = vec3(0.5, 1.0, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_N_E_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[1] = vec3(0.6875, 1.0, 1.0);
                    boundsMin[2] = vec3(0.5, 0.0, 0.3125);
                    boundsMax[2] = vec3(1.0, 1.0, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_W_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[1] = vec3(1.0, 1.0, 0.6875);
                    boundsMin[2] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[2] = vec3(0.6875, 1.0, 0.5);
                    break;
                case BLOCK_WALL_POST_TALL_W_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[1] = vec3(1.0, 1.0, 0.6875);
                    boundsMin[2] = vec3(0.3125, 0.0, 0.5);
                    boundsMax[2] = vec3(0.6875, 1.0, 1.0);
                    break;

                case BLOCK_WALL_POST_TALL_ALL:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[1] = vec3(1.0, 1.0, 0.6875);
                    boundsMin[2] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[2] = vec3(0.6875, 1.0, 1.0);
                    break;

                case BLOCK_WALL_POST_TALL_N_LOW_S:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.0);
                    boundsMax[1] = vec3(0.6875, 1.0, 0.5);
                    boundsMin[2] = vec3(0.3125, 0.000, 0.5);
                    boundsMax[2] = vec3(0.6875, 0.875, 1.0);
                    break;
                case BLOCK_WALL_POST_TALL_E_LOW_W:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.5, 0.0, 0.3125);
                    boundsMax[1] = vec3(1.0, 1.0, 0.6875);
                    boundsMin[2] = vec3(0.0, 0.000, 0.3125);
                    boundsMax[2] = vec3(0.5, 0.875, 0.6875);
                    break;
                case BLOCK_WALL_POST_TALL_S_LOW_N:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.3125, 0.0, 0.5);
                    boundsMax[1] = vec3(0.6875, 1.0, 1.0);
                    boundsMin[2] = vec3(0.3125, 0.000, 0.0);
                    boundsMax[2] = vec3(0.6875, 0.875, 0.5);
                    break;
                case BLOCK_WALL_POST_TALL_W_LOW_E:
                    shapeCount = 3u;
                    boundsMin[1] = vec3(0.0, 0.0, 0.3125);
                    boundsMax[1] = vec3(0.5, 1.0, 0.6875);
                    boundsMin[2] = vec3(0.5, 0.000, 0.3125);
                    boundsMax[2] = vec3(1.0, 0.875, 0.6875);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_WALL_LOW_N_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.3125, 0.0, 0.0);
                boundsMax[0] = vec3(0.6875, (14.0/16.0), 1.0);
                break;
            case BLOCK_WALL_LOW_W_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0, 0.0, 0.3125);
                boundsMax[0] = vec3(1.0, (14.0/16.0), 0.6875);
                break;
            case BLOCK_WALL_LOW_ALL:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0000, 0.000, 0.3125);
                boundsMax[0] = vec3(1.0000, 0.875, 0.6875);
                boundsMin[1] = vec3(0.3125, 0.000, 0.0000);
                boundsMax[1] = vec3(0.6875, 0.875, 1.0000);
                break;

            case BLOCK_WALL_TALL_N_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.3125, 0.0, 0.0);
                boundsMax[0] = vec3(0.6875, 1.0, 1.0);
                break;
            case BLOCK_WALL_TALL_W_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0, 0.0, 0.3125);
                boundsMax[0] = vec3(1.0, 1.0, 0.6875);
                break;
            case BLOCK_WALL_TALL_ALL:
                shapeCount = 2u;
                boundsMin[0] = vec3(0.0000, 0.0, 0.3125);
                boundsMax[0] = vec3(1.0000, 1.0, 0.6875);
                boundsMin[1] = vec3(0.3125, 0.0, 0.0000);
                boundsMax[1] = vec3(0.6875, 1.0, 1.0000);
                break;
        }

        switch (blockId) {
            case BLOCK_CHORUS_DOWN:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.25,         0.0, 0.25);
                boundsMax[0] = vec3(0.75, (13.0/16.0), 0.75);
                break;
            case BLOCK_CHORUS_UP_DOWN:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.25, 0.0, 0.25);
                boundsMax[0] = vec3(0.75, 1.0, 0.75);
                break;
            case BLOCK_CHORUS_OTHER:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.25, 0.25, 0.25);
                boundsMax[0] = vec3(0.75, 0.75, 0.75);
                break;
        }

        if (blockId >= BLOCK_CHEST_N && blockId <= BLOCK_CHEST_W) {
            boundsMin[0] = vec3(( 1.0/16.0),        0.0 , ( 1.0/16.0));
            boundsMax[0] = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
            shapeCount = 2u;

            switch (blockId) {
                case BLOCK_CHEST_N:
                    boundsMin[1] = vec3((7.0/16.0), ( 7.0/16.0), (0.0/16.0));
                    boundsMax[1] = vec3((9.0/16.0), (11.0/16.0), (1.0/16.0));
                    break;
                case BLOCK_CHEST_E:
                    boundsMin[1] = vec3((15.0/16.0), ( 7.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3((16.0/16.0), (11.0/16.0), (9.0/16.0));
                    break;
                case BLOCK_CHEST_S:
                    boundsMin[1] = vec3((7.0/16.0), ( 7.0/16.0), (15.0/16.0));
                    boundsMax[1] = vec3((9.0/16.0), (11.0/16.0), (16.0/16.0));
                    break;
                case BLOCK_CHEST_W:
                    boundsMin[1] = vec3((0.0/16.0), ( 7.0/16.0), (7.0/16.0));
                    boundsMax[1] = vec3((1.0/16.0), (11.0/16.0), (9.0/16.0));
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_CHEST_LEFT_N:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 1.0/16.0),        0.0 , ( 1.0/16.0));
                boundsMax[0] = vec3(       1.0 , (14.0/16.0), (15.0/16.0));
                break;
            case BLOCK_CHEST_RIGHT_N:
                shapeCount = 1u;
                boundsMin[0] = vec3(       0.0 ,        0.0 , ( 1.0/16.0));
                boundsMax[0] = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
                break;
            case BLOCK_CHEST_LEFT_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 1.0/16.0),        0.0 , ( 1.0/16.0));
                boundsMax[0] = vec3((15.0/16.0), (14.0/16.0),        1.0 );
                break;
            case BLOCK_CHEST_RIGHT_E:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 1.0/16.0),        0.0 ,        0.0 );
                boundsMax[0] = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
                break;
            case BLOCK_CHEST_LEFT_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(       0.0 ,        0.0 , ( 1.0/16.0));
                boundsMax[0] = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
                break;
            case BLOCK_CHEST_RIGHT_S:
                shapeCount = 1u;
                boundsMin[0] = vec3((1.0/16.0),        0.0 , ( 1.0/16.0));
                boundsMax[0] = vec3(      1.0 , (14.0/16.0), (15.0/16.0));
                break;
            case BLOCK_CHEST_LEFT_W:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 1.0/16.0),        0.0 ,        0.0 );
                boundsMax[0] = vec3((15.0/16.0), (14.0/16.0), (15.0/16.0));
                break;
            case BLOCK_CHEST_RIGHT_W:
                shapeCount = 1u;
                boundsMin[0] = vec3(( 1.0/16.0),        0.0 , (1.0/16.0));
                boundsMax[0] = vec3((15.0/16.0), (14.0/16.0),       1.0 );
                break;
        }

        switch (blockId) {
            case BLOCK_SIGN_WALL_N:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0, ( 4.50/16.0), (14.25/16.0));
                boundsMax[0] = vec3(1.0, (12.25/16.0), (15.75/16.0));
                break;
            case BLOCK_SIGN_WALL_E:
                shapeCount = 1u;
                boundsMin[0] = vec3((0.25/16.0), ( 4.50/16.0), 0.0);
                boundsMax[0] = vec3((1.75/16.0), (12.25/16.0), 1.0);
                break;
            case BLOCK_SIGN_WALL_S:
                shapeCount = 1u;
                boundsMin[0] = vec3(0.0, ( 4.50/16.0), (0.25/16.0));
                boundsMax[0] = vec3(1.0, (12.25/16.0), (1.75/16.0));
                break;
            case BLOCK_SIGN_WALL_W:
                shapeCount = 1u;
                boundsMin[0] = vec3((14.25/16.0), ( 4.50/16.0), 0.0);
                boundsMax[0] = vec3((15.75/16.0), (12.25/16.0), 1.0);
                break;
        }

        CollissionMaps[blockId].Count = shapeCount;

        for (uint i = 0u; i < min(shapeCount, 5u); i++) {
            CollissionMaps[blockId].Bounds[i] = uvec2(
                packUnorm4x8(vec4(boundsMin[i], 0.0)),
                packUnorm4x8(vec4(boundsMax[i], 0.0)));
        }
    #endif
    
    //barrier();
}
