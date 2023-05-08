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


#define modelPart(x, y, z) (vec3(x, y, z)/16.0)

void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        uint blockId = uint(gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 40);
        if (blockId > 1200) return;

        uint shapeCount = 0u;
        vec3 boundsMin[BLOCK_MASK_PARTS];
        vec3 boundsMax[BLOCK_MASK_PARTS];

        if (blockId == BLOCK_LANTERN_CEIL || blockId == BLOCK_SOUL_LANTERN_CEIL) {
            shapeCount = 2u;
            boundsMin[0] = modelPart( 5,  1,  5);
            boundsMax[0] = modelPart(11,  8, 11);
            boundsMin[1] = modelPart( 6,  8,  6);
            boundsMax[1] = modelPart(10, 10, 10);
        }

        if (blockId == BLOCK_LANTERN_FLOOR || blockId == BLOCK_SOUL_LANTERN_FLOOR) {
            shapeCount = 2u;
            boundsMin[0] = modelPart( 5,  0,  5);
            boundsMax[0] = modelPart(11,  7, 11);
            boundsMin[1] = modelPart( 6,  7,  6);
            boundsMax[1] = modelPart(10,  9, 10);
        }

        // 400-500
        switch (blockId) {
            case BLOCK_COMPARATOR:
            case BLOCK_REPEATER:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16,  2, 16);
                break;
            case BLOCK_DAYLIGHT_DETECTOR:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16,  6, 16);
                break;
            case BLOCK_SCULK_SENSOR:
            case BLOCK_SCULK_SHRIEKER:
            case BLOCK_CREATE_SEAT:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16,  8, 16);
                break;
            case BLOCK_ENCHANTING_TABLE:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16, 12, 16);
                break;
        }

        if (blockId == BLOCK_ANVIL_N_S || blockId == BLOCK_ANVIL_W_E) {
            boundsMin[0] = modelPart( 2, 0,  2);
            boundsMax[0] = modelPart(14, 4, 14);
            shapeCount = 3u;

            switch (blockId) {
                case BLOCK_ANVIL_N_S:
                    boundsMin[1] = modelPart( 3, 10,  0);
                    boundsMax[1] = modelPart(13, 16, 16);
                    boundsMin[2] = modelPart( 6,  4,  4);
                    boundsMax[2] = modelPart(10, 12, 12);
                    break;
                case BLOCK_ANVIL_W_E:
                    boundsMin[1] = modelPart( 0, 10,  3);
                    boundsMax[1] = modelPart(16, 16, 13);
                    boundsMin[2] = modelPart( 4,  4,  6);
                    boundsMax[2] = modelPart(12, 12, 10);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_BEACON:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 2,  0,  2);
                boundsMax[0] = modelPart(14,  3, 14);
                boundsMin[1] = modelPart( 3,  3,  3);
                boundsMax[1] = modelPart(13, 14, 13);
                break;
        }

        if (blockId >= BLOCK_BED_HEAD_N && blockId <= BLOCK_BED_FOOT_W) {
            boundsMin[0] = modelPart( 0,  3,  0);
            boundsMax[0] = modelPart(16,  9, 16);
            shapeCount = 3u;

            switch (blockId) {
                case BLOCK_BED_HEAD_N:
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart( 3,  3,  3);
                    boundsMin[2] = modelPart(13,  0,  0);
                    boundsMax[2] = modelPart(16,  3,  3);
                    break;
                case BLOCK_BED_HEAD_E:
                    boundsMin[1] = modelPart(13,  0,  0);
                    boundsMax[1] = modelPart(16,  3,  3);
                    boundsMin[2] = modelPart(13,  0, 13);
                    boundsMax[2] = modelPart(16,  3, 16);
                    break;
                case BLOCK_BED_HEAD_S:
                    boundsMin[1] = modelPart( 0,  0, 13);
                    boundsMax[1] = modelPart( 3,  3, 16);
                    boundsMin[2] = modelPart(13,  0, 13);
                    boundsMax[2] = modelPart(16,  3, 16);
                    break;
                case BLOCK_BED_HEAD_W:
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart( 3,  3,  3);
                    boundsMin[2] = modelPart( 0,  0, 13);
                    boundsMax[2] = modelPart( 3,  3, 16);
                    break;

                case BLOCK_BED_FOOT_N:
                    boundsMin[1] = modelPart( 0,  0, 13);
                    boundsMax[1] = modelPart( 3,  3, 16);
                    boundsMin[2] = modelPart(13,  0, 13);
                    boundsMax[2] = modelPart(16,  3, 16);
                    break;
                case BLOCK_BED_FOOT_E:
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart( 3,  3,  3);
                    boundsMin[2] = modelPart( 0,  0, 13);
                    boundsMax[2] = modelPart( 3,  3, 16);
                    break;
                case BLOCK_BED_FOOT_S:
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart( 3,  3,  3);
                    boundsMin[2] = modelPart(13,  0,  0);
                    boundsMax[2] = modelPart(16,  3,  3);
                    break;
                case BLOCK_BED_FOOT_W:
                    boundsMin[1] = modelPart(13,  0,  0);
                    boundsMax[1] = modelPart(16,  3,  3);
                    boundsMin[2] = modelPart(13,  0, 13);
                    boundsMax[2] = modelPart(16,  3, 16);
                    break;
            }
        }

        if (blockId >= BLOCK_BELL_FLOOR_N_S && blockId <= BLOCK_BELL_CEILING) {
            shapeCount = 2u;
            boundsMin[0] = modelPart( 5,  6,  5);
            boundsMax[0] = modelPart(11, 13, 11);
            boundsMin[1] = modelPart( 4,  4,  4);
            boundsMax[1] = modelPart(12,  6, 12);
        }

        switch (blockId) {
            case BLOCK_BREWING_STAND:
                shapeCount = 4u;
                boundsMin[0] = modelPart( 7,  0,  7);
                boundsMax[0] = modelPart( 9, 14,  9);
                boundsMin[1] = modelPart( 9,  0,  5);
                boundsMax[1] = modelPart(15,  2, 11);
                boundsMin[2] = modelPart( 1,  0,  1);
                boundsMax[2] = modelPart( 7,  2,  7);
                boundsMin[3] = modelPart( 1,  0,  9);
                boundsMax[3] = modelPart( 7,  2, 15);
                break;

            case BLOCK_CACTUS:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1,  0,  1);
                boundsMax[0] = modelPart(15, 16, 15);
                break;

            case BLOCK_CAMPFIRE_N_S:
                shapeCount = 3u;
                boundsMin[0] = modelPart( 1,  0,  0);
                boundsMax[0] = modelPart(15,  4, 16);
                boundsMin[1] = modelPart( 0,  3,  1);
                boundsMax[1] = modelPart(16,  7,  5);
                boundsMin[2] = modelPart( 0,  3, 11);
                boundsMax[2] = modelPart(16,  7, 15);
                break;
            case BLOCK_CAMPFIRE_W_E:
                shapeCount = 3u;
                boundsMin[0] = modelPart( 0,  0,  1);
                boundsMax[0] = modelPart(16,  4, 15);
                boundsMin[1] = modelPart( 1,  3,  0);
                boundsMax[1] = modelPart( 5,  7, 16);
                boundsMin[2] = modelPart(11,  3,  0);
                boundsMax[2] = modelPart(15,  7, 16);
                break;

            case BLOCK_CANDLES_1:
            case BLOCK_CANDLES_LIT_1:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 7,  0,  7);
                boundsMax[0] = modelPart( 9,  6,  9);
                break;
            case BLOCK_CANDLES_2:
            case BLOCK_CANDLES_LIT_2:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 9,  0,  6);
                boundsMax[0] = modelPart(11,  6,  8);
                boundsMin[1] = modelPart( 5,  0,  7);
                boundsMax[1] = modelPart( 7,  5,  9);
                break;
            case BLOCK_CANDLES_3:
            case BLOCK_CANDLES_LIT_3:
                shapeCount = 3u;
                boundsMin[0] = modelPart( 8,  0,  6);
                boundsMax[0] = modelPart(10,  6,  8);
                boundsMin[1] = modelPart( 5,  0,  7);
                boundsMax[1] = modelPart( 7,  5,  9);
                boundsMin[2] = modelPart( 7,  0,  9);
                boundsMax[2] = modelPart( 9,  3, 11);
                break;
            case BLOCK_CANDLES_4:
            case BLOCK_CANDLES_LIT_4:
                shapeCount = 4u;
                boundsMin[0] = modelPart( 8,  0,  5);
                boundsMax[0] = modelPart(10,  6,  7);
                boundsMin[1] = modelPart( 5,  0,  5);
                boundsMax[1] = modelPart( 7,  5,  7);
                boundsMin[2] = modelPart( 9,  0,  8);
                boundsMax[2] = modelPart(11,  5, 10);
                boundsMin[3] = modelPart( 6,  0,  8);
                boundsMax[3] = modelPart( 8,  3, 10);
                break;
        }

        if (blockId == BLOCK_CAKE || blockId == BLOCK_CANDLE_CAKE || blockId == BLOCK_CANDLE_CAKE_LIT) {
            boundsMin[0] = modelPart( 1, 0,  1);
            boundsMax[0] = modelPart(15, 8, 15);

            switch (blockId) {
                case BLOCK_CAKE:
                    shapeCount = 1u;
                    break;

                case BLOCK_CANDLE_CAKE:
                case BLOCK_CANDLE_CAKE_LIT:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 7,  8,  7);
                    boundsMax[1] = modelPart( 9, 14,  9);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_CARPET:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16,  1, 16);
                break;

            case BLOCK_CAULDRON:
            case BLOCK_CAULDRON_LAVA:
                shapeCount = 5u;
                boundsMin[0] = modelPart( 0,  3,  0);
                boundsMax[0] = modelPart(16, 16, 16);
                boundsMin[1] = modelPart( 0,  0,  0);
                boundsMax[1] = modelPart( 4,  3,  4);
                boundsMin[2] = modelPart(12,  0,  0);
                boundsMax[2] = modelPart(16,  3,  4);
                boundsMin[3] = modelPart( 0,  0, 12);
                boundsMax[3] = modelPart( 4,  3, 16);
                boundsMin[4] = modelPart(12,  0, 12);
                boundsMax[4] = modelPart(16,  3, 16);
                break;

            case BLOCK_END_PORTAL_FRAME:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16, 13, 16);
                break;

            case BLOCK_FLOWER_POT:
            case BLOCK_POTTED_PLANT:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 5,  0,  5);
                boundsMax[0] = modelPart(10,  6, 10);
                break;

            case BLOCK_GRINDSTONE_FLOOR_N_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 4,  4,  2);
                boundsMax[0] = modelPart(12, 16, 14);
                break;
            case BLOCK_GRINDSTONE_FLOOR_W_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 2,  4,  4);
                boundsMax[0] = modelPart(14, 16, 12);
                break;
            case BLOCK_GRINDSTONE_WALL_N_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 4,  2,  2);
                boundsMax[0] = modelPart(12, 14, 14);
                break;
            case BLOCK_GRINDSTONE_WALL_W_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 2,  2,  4);
                boundsMax[0] = modelPart(14, 14, 12);
                break;
        }

        if (blockId >= BLOCK_HOPPER_DOWN && blockId <= BLOCK_HOPPER_W) {
            boundsMin[0] = modelPart( 0, 10,  0);
            boundsMax[0] = modelPart(16, 16, 16);
            boundsMin[1] = modelPart( 4,  4,  4);
            boundsMax[1] = modelPart(12, 10, 12);
            shapeCount = 3u;

            switch (blockId) {
                case BLOCK_HOPPER_DOWN:
                    boundsMin[2] = vec3(0.375, 0.00, 0.325);
                    boundsMax[2] = vec3(0.625, 0.25, 0.675);
                    break;
                case BLOCK_HOPPER_N:
                    boundsMin[2] = modelPart( 4,  4,  0);
                    boundsMax[2] = modelPart(12,  8,  4);
                    break;
                case BLOCK_HOPPER_E:
                    boundsMin[2] = modelPart(12,  4,  4);
                    boundsMax[2] = modelPart(16,  8, 12);
                    break;
                case BLOCK_HOPPER_S:
                    boundsMin[2] = modelPart( 4,  4, 12);
                    boundsMax[2] = modelPart(12,  8, 16);
                    break;
                case BLOCK_HOPPER_W:
                    boundsMin[2] = modelPart( 0,  4,  4);
                    boundsMax[2] = modelPart( 4,  8, 12);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_LECTERN:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16,  2, 16);
                boundsMin[1] = modelPart( 4,  0,  4);
                boundsMax[1] = modelPart(12, 13, 12);
                break;

            case BLOCK_LIGHTNING_ROD_N:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 7,  7,  0);
                boundsMax[0] = modelPart( 9,  9, 16);
                boundsMin[1] = modelPart( 6,  6,  0);
                boundsMax[1] = modelPart(10, 10,  4);
                break;
            case BLOCK_LIGHTNING_ROD_E:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  7,  7);
                boundsMax[0] = modelPart(16,  9,  9);
                boundsMin[1] = modelPart(12,  6,  6);
                boundsMax[1] = modelPart(16, 10, 10);
                break;
            case BLOCK_LIGHTNING_ROD_S:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 7,  7,  0);
                boundsMax[0] = modelPart( 9,  9, 16);
                boundsMin[1] = modelPart( 6,  6, 12);
                boundsMax[1] = modelPart(10, 10, 16);
                break;
            case BLOCK_LIGHTNING_ROD_W:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  7,  7);
                boundsMax[0] = modelPart(16,  9,  9);
                boundsMin[1] = modelPart( 0,  6,  6);
                boundsMax[1] = modelPart( 4, 10, 10);
                break;
            case BLOCK_LIGHTNING_ROD_UP:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 7,  0,  7);
                boundsMax[0] = modelPart( 9, 16,  9);
                boundsMin[1] = modelPart( 6, 12,  6);
                boundsMax[1] = modelPart(10, 16, 10);
                break;
            case BLOCK_LIGHTNING_ROD_DOWN:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 7,  0,  7);
                boundsMax[0] = modelPart( 9, 16,  9);
                boundsMin[1] = modelPart( 6,  0,  6);
                boundsMax[1] = modelPart(10,  4, 10);
                break;

            case BLOCK_PATHWAY:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16, 15, 16);
                break;

            case BLOCK_PISTON_EXTENDED_N:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0,  4);
                boundsMax[0] = modelPart(16, 16, 16);
                boundsMin[1] = vec3(0.375, 0.375, 0.0);
                boundsMax[1] = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_EXTENDED_E:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(12, 16, 16);
                boundsMin[1] = vec3(0.0, 0.375, 0.375);
                boundsMax[1] = vec3(1.0, 0.625, 0.625);
                break;
            case BLOCK_PISTON_EXTENDED_S:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16, 16, 12);
                boundsMin[1] = vec3(0.375, 0.375, 0.0);
                boundsMax[1] = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_EXTENDED_W:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 4,  0,  0);
                boundsMax[0] = modelPart(16, 16, 16);
                boundsMin[1] = vec3(0.0, 0.375, 0.375);
                boundsMax[1] = vec3(1.0, 0.625, 0.625);
                break;
            case BLOCK_PISTON_EXTENDED_UP:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16, 12, 16);
                boundsMin[1] = vec3(0.375, 0.0, 0.375);
                boundsMax[1] = vec3(0.625, 1.0, 0.625);
                break;
            case BLOCK_PISTON_EXTENDED_DOWN:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  4,  0);
                boundsMax[0] = modelPart(16, 16, 16);
                boundsMin[1] = vec3(0.375, 0.0, 0.375);
                boundsMax[1] = vec3(0.625, 1.0, 0.625);
                break;

            case BLOCK_PISTON_HEAD_N:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16, 16,  4);
                boundsMin[1] = vec3(0.375, 0.375, 0.0);
                boundsMax[1] = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_HEAD_E:
                shapeCount = 2u;
                boundsMin[0] = modelPart(12,  0,  0);
                boundsMax[0] = modelPart(16, 16, 16);
                boundsMin[1] = vec3(0.0, 0.375, 0.375);
                boundsMax[1] = vec3(1.0, 0.625, 0.625);
                break;
            case BLOCK_PISTON_HEAD_S:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0, 12);
                boundsMax[0] = modelPart(16, 16, 16);
                boundsMin[1] = vec3(0.375, 0.375, 0.0);
                boundsMax[1] = vec3(0.625, 0.625, 1.0);
                break;
            case BLOCK_PISTON_HEAD_W:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart( 4, 16, 16);
                boundsMin[1] = vec3(0.0, 0.375, 0.375);
                boundsMax[1] = vec3(1.0, 0.625, 0.625);
                break;
            case BLOCK_PISTON_HEAD_UP:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0, 12,  0);
                boundsMax[0] = modelPart(16, 16, 16);
                boundsMin[1] = vec3(0.375, 0.0, 0.375);
                boundsMax[1] = vec3(0.625, 1.0, 0.625);
                break;
            case BLOCK_PISTON_HEAD_DOWN:
                shapeCount = 2u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16,  4, 16);
                boundsMin[1] = vec3(0.375, 0.0, 0.375);
                boundsMax[1] = vec3(0.625, 1.0, 0.625);
                break;

            case BLOCK_PRESSURE_PLATE:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1,  0,  1);
                boundsMax[0] = modelPart(15,  1, 15);
                break;
            case BLOCK_PRESSURE_PLATE_DOWN:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1, 0.0,  1);
                boundsMax[0] = modelPart(15, 0.5, 15);
                break;
        }

        if (blockId >= BLOCK_SNOW_LAYERS_1 && blockId <= BLOCK_SNOW_LAYERS_7) {
            boundsMin[0] = modelPart( 0,  0,  0);
            shapeCount = 1u;

            switch (blockId) {
                case BLOCK_SNOW_LAYERS_1:
                    boundsMax[0] = modelPart(16,  2, 16);
                    break;
                case BLOCK_SNOW_LAYERS_2:
                    boundsMax[0] = modelPart(16,  4, 16);
                    break;
                case BLOCK_SNOW_LAYERS_3:
                    boundsMax[0] = modelPart(16,  6, 16);
                    break;
                case BLOCK_SNOW_LAYERS_4:
                    boundsMax[0] = modelPart(16,  8, 16);
                    break;
                case BLOCK_SNOW_LAYERS_5:
                    boundsMax[0] = modelPart(16, 10, 16);
                    break;
                case BLOCK_SNOW_LAYERS_6:
                    boundsMax[0] = modelPart(16, 12, 16);
                    break;
                case BLOCK_SNOW_LAYERS_7:
                    boundsMax[0] = modelPart(16, 14, 16);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_STONECUTTER:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16,  9, 16);
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
                boundsMin[0] = modelPart( 0,  0, 13);
                boundsMax[0] = modelPart(16, 16, 16);
                break;
            case BLOCK_DOOR_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart( 3, 16, 16);
                break;
            case BLOCK_DOOR_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16, 16,  3);
                break;
            case BLOCK_DOOR_W:
                shapeCount = 1u;
                boundsMin[0] = modelPart(13,  0,  0);
                boundsMax[0] = modelPart(16, 16, 16);
                break;
        }

        switch (blockId) {
            case BLOCK_LEVER_FLOOR_N_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 5,  0,  4);
                boundsMax[0] = modelPart(11,  3, 12);
                break;
            case BLOCK_LEVER_FLOOR_W_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 4,  0,  5);
                boundsMax[0] = modelPart(12,  3, 11);
                break;
            case BLOCK_LEVER_CEILING_N_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 5, 13,  4);
                boundsMax[0] = modelPart(11, 16, 12);
                break;
            case BLOCK_LEVER_CEILING_W_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 4, 13,  5);
                boundsMax[0] = modelPart(12, 16, 11);
                break;
            case BLOCK_LEVER_WALL_N:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 5,  4, 13);
                boundsMax[0] = modelPart(11, 12, 16);
                break;
            case BLOCK_LEVER_WALL_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  4,  5);
                boundsMax[0] = modelPart( 3, 12, 11);
                break;
            case BLOCK_LEVER_WALL_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 5,  4,  0);
                boundsMax[0] = modelPart(11, 12,  3);
                break;
            case BLOCK_LEVER_WALL_W:
                shapeCount = 1u;
                boundsMin[0] = modelPart(13,  4,  5);
                boundsMax[0] = modelPart(16, 12, 11);
                break;
        }

        switch (blockId) {
            case BLOCK_TRAPDOOR_BOTTOM:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16,  3, 16);
                break;
            case BLOCK_TRAPDOOR_TOP:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0, 13,  0);
                boundsMax[0] = modelPart(16, 16, 16);
                break;
            case BLOCK_TRAPDOOR_N:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0, 13);
                boundsMax[0] = modelPart(16, 16, 16);
                break;
            case BLOCK_TRAPDOOR_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart( 3, 16, 16);
                break;
            case BLOCK_TRAPDOOR_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  0);
                boundsMax[0] = modelPart(16, 16,  3);
                break;
            case BLOCK_TRAPDOOR_W:
                shapeCount = 1u;
                boundsMin[0] = modelPart(13,  0,  0);
                boundsMax[0] = modelPart(16, 16, 16);
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
                    boundsMin[0] = modelPart( 0,  8,  0);
                    boundsMax[0] = modelPart(16, 16, 16);
                    break;
                case BLOCK_SLAB_BOTTOM:
                    boundsMin[0] = modelPart( 0,  0,  0);
                    boundsMax[0] = modelPart(16,  8, 16);
                    break;
                case BLOCK_SLAB_VERTICAL_N:
                    boundsMin[0] = modelPart( 0,  0,  0);
                    boundsMax[0] = modelPart(16, 16,  8);
                    break;
                case BLOCK_SLAB_VERTICAL_E:
                    boundsMin[0] = modelPart( 8,  0,  0);
                    boundsMax[0] = modelPart(16, 16, 16);
                    break;
                case BLOCK_SLAB_VERTICAL_S:
                    boundsMin[0] = modelPart( 0,  0,  8);
                    boundsMax[0] = modelPart(16, 16, 16);
                    break;
                case BLOCK_SLAB_VERTICAL_W:
                    boundsMin[0] = modelPart( 0,  0,  0);
                    boundsMax[0] = modelPart( 8, 16, 16);
                    break;
            }
        }

        if (blockId >= BLOCK_STAIRS_BOTTOM_N && blockId <= BLOCK_STAIRS_BOTTOM_OUTER_S_W) {
            boundsMin[0] = modelPart( 0,  0,  0);
            boundsMax[0] = modelPart(16,  8, 16);

            switch (blockId) {
                case BLOCK_STAIRS_BOTTOM_N:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  8,  0);
                    boundsMax[1] = modelPart(16, 16,  8);
                    break;
                case BLOCK_STAIRS_BOTTOM_E:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 8,  8,  0);
                    boundsMax[1] = modelPart(16, 16, 16);
                    break;
                case BLOCK_STAIRS_BOTTOM_S:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  8,  8);
                    boundsMax[1] = modelPart(16, 16, 16);
                    break;
                case BLOCK_STAIRS_BOTTOM_W:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  8,  0);
                    boundsMax[1] = modelPart( 8, 16, 16);
                    break;

                case BLOCK_STAIRS_BOTTOM_INNER_N_W:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 0,  8,  0);
                    boundsMax[1] = modelPart(16, 16,  8);
                    boundsMin[2] = modelPart( 0,  8,  8);
                    boundsMax[2] = modelPart( 8, 16, 16);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 0,  8,  0);
                    boundsMax[1] = modelPart(16, 16,  8);
                    boundsMin[2] = modelPart( 8,  8,  8);
                    boundsMax[2] = modelPart(16, 16, 16);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_S_W:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 0,  8,  8);
                    boundsMax[1] = modelPart(16, 16, 16);
                    boundsMin[2] = modelPart( 0,  8,  0);
                    boundsMax[2] = modelPart( 8, 16,  8);
                    break;
                case BLOCK_STAIRS_BOTTOM_INNER_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 0,  8,  8);
                    boundsMax[1] = modelPart(16, 16, 16);
                    boundsMin[2] = modelPart( 8,  8,  0);
                    boundsMax[2] = modelPart(16, 16,  8);
                    break;

                case BLOCK_STAIRS_BOTTOM_OUTER_N_W:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  8,  0);
                    boundsMax[1] = modelPart( 8, 16,  8);
                    break;
                case BLOCK_STAIRS_BOTTOM_OUTER_N_E:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 8,  8,  0);
                    boundsMax[1] = modelPart(16, 16,  8);
                    break;
                case BLOCK_STAIRS_BOTTOM_OUTER_S_E:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 8,  8,  8);
                    boundsMax[1] = modelPart(16, 16, 16);
                    break;
                case BLOCK_STAIRS_BOTTOM_OUTER_S_W:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  8,  8);
                    boundsMax[1] = modelPart( 8, 16, 16);
                    break;
            }
        }

        if (blockId >= BLOCK_STAIRS_TOP_N && blockId <= BLOCK_STAIRS_TOP_OUTER_S_W) {
            boundsMin[0] = modelPart( 0,  8,  0);
            boundsMax[0] = modelPart(16, 16, 16);

            switch (blockId) {
                case BLOCK_STAIRS_TOP_N:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart(16,  8,  8);
                    break;
                case BLOCK_STAIRS_TOP_E:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 8,  0,  0);
                    boundsMax[1] = modelPart(16,  8, 16);
                    break;
                case BLOCK_STAIRS_TOP_S:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  0,  8);
                    boundsMax[1] = modelPart(16,  8, 16);
                    break;
                case BLOCK_STAIRS_TOP_W:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart( 8,  8, 16);
                    break;

                case BLOCK_STAIRS_TOP_INNER_N_W:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart(16,  8,  8);
                    boundsMin[2] = modelPart( 0,  0,  8);
                    boundsMax[2] = modelPart( 8,  8, 16);
                    break;
                case BLOCK_STAIRS_TOP_INNER_N_E:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart(16,  8,  8);
                    boundsMin[2] = modelPart( 8,  0,  8);
                    boundsMax[2] = modelPart(16,  8, 16);
                    break;
                case BLOCK_STAIRS_TOP_INNER_S_W:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 0,  0,  8);
                    boundsMax[1] = modelPart(16,  8, 16);
                    boundsMin[2] = modelPart( 0,  0,  0);
                    boundsMax[2] = modelPart( 8,  8,  8);
                    break;
                case BLOCK_STAIRS_TOP_INNER_S_E:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 0,  0,  8);
                    boundsMax[1] = modelPart(16,  8, 16);
                    boundsMin[2] = modelPart( 8,  0,  0);
                    boundsMax[2] = modelPart(16,  8,  8);
                    break;

                case BLOCK_STAIRS_TOP_OUTER_N_W:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  0,  0);
                    boundsMax[1] = modelPart( 8,  8,  8);
                    break;
                case BLOCK_STAIRS_TOP_OUTER_N_E:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 8,  0,  0);
                    boundsMax[1] = modelPart(16,  8,  8);
                    break;
                case BLOCK_STAIRS_TOP_OUTER_S_E:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 8,  0,  8);
                    boundsMax[1] = modelPart(16,  8, 16);
                    break;
                case BLOCK_STAIRS_TOP_OUTER_S_W:
                    shapeCount = 2u;
                    boundsMin[1] = modelPart( 0,  0,  8);
                    boundsMax[1] = modelPart( 8,  8, 16);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_CREATE_SHAFT_X:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  6,  6);
                boundsMax[0] = modelPart(16, 10, 10);
                break;
            case BLOCK_CREATE_SHAFT_Y:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 6,  0,  6);
                boundsMax[0] = modelPart(10, 16, 10);
                break;
            case BLOCK_CREATE_SHAFT_Z:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 6.0,  6,  0);
                boundsMax[0] = modelPart(10.0, 10, 16);
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
                    boundsMin[1] = modelPart( 7,  6,  0);
                    boundsMax[1] = modelPart( 9,  9,  8);
                    boundsMin[2] = modelPart( 7, 12,  0);
                    boundsMax[2] = modelPart( 9, 15,  8);
                    break;
                case BLOCK_FENCE_E:
                    shapeCount = 3u;
                    boundsMin[1] = modelPart( 8,  6,  7);
                    boundsMax[1] = modelPart(16,  9,  9);
                    boundsMin[2] = modelPart( 8, 12,  7);
                    boundsMax[2] = modelPart(16, 15,  9);
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
            boundsMin[0] = modelPart( 4,  0,  4);
            boundsMax[0] = modelPart(12, 16, 12);

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
                boundsMin[0] = modelPart( 4,  0,  4);
                boundsMax[0] = modelPart(12, 13, 12);
                break;
            case BLOCK_CHORUS_UP_DOWN:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 4,  0,  4);
                boundsMax[0] = modelPart(12, 16, 12);
                break;
            case BLOCK_CHORUS_OTHER:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 4,  4,  4);
                boundsMax[0] = modelPart(12, 12, 12);
                break;
        }

        if (blockId >= BLOCK_CHEST_N && blockId <= BLOCK_CHEST_W) {
            boundsMin[0] = modelPart( 1,  0,  1);
            boundsMax[0] = modelPart(15, 14, 15);
            shapeCount = 2u;

            switch (blockId) {
                case BLOCK_CHEST_N:
                    boundsMin[1] = modelPart( 7,  7,  0);
                    boundsMax[1] = modelPart( 9, 11,  1);
                    break;
                case BLOCK_CHEST_E:
                    boundsMin[1] = modelPart(15,  7,  7);
                    boundsMax[1] = modelPart(16, 11,  9);
                    break;
                case BLOCK_CHEST_S:
                    boundsMin[1] = modelPart( 7,  7, 15);
                    boundsMax[1] = modelPart( 9, 11, 16);
                    break;
                case BLOCK_CHEST_W:
                    boundsMin[1] = modelPart( 0,  7,  7);
                    boundsMax[1] = modelPart( 1, 11,  9);
                    break;
            }
        }

        switch (blockId) {
            case BLOCK_CHEST_LEFT_N:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1,  0,  1);
                boundsMax[0] = modelPart(16, 14, 15);
                break;
            case BLOCK_CHEST_RIGHT_N:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  1);
                boundsMax[0] = modelPart(15, 14, 15);
                break;
            case BLOCK_CHEST_LEFT_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1,  0,  1);
                boundsMax[0] = modelPart(15, 14, 16);
                break;
            case BLOCK_CHEST_RIGHT_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1,  0,  0);
                boundsMax[0] = modelPart(15, 14, 15);
                break;
            case BLOCK_CHEST_LEFT_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  0,  1);
                boundsMax[0] = modelPart(15, 14, 15);
                break;
            case BLOCK_CHEST_RIGHT_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1,  0,  1);
                boundsMax[0] = modelPart(16, 14, 15);
                break;
            case BLOCK_CHEST_LEFT_W:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1,  0,  0);
                boundsMax[0] = modelPart(15, 14, 15);
                break;
            case BLOCK_CHEST_RIGHT_W:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 1,  0,  1);
                boundsMax[0] = modelPart(15, 14, 16);
                break;
        }

        switch (blockId) {
            case BLOCK_SIGN_WALL_N:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  4.50, 14.25);
                boundsMax[0] = modelPart(16, 12.25, 15.75);
                break;
            case BLOCK_SIGN_WALL_E:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0.25,  4.50,  0);
                boundsMax[0] = modelPart( 1.75, 12.25, 16);
                break;
            case BLOCK_SIGN_WALL_S:
                shapeCount = 1u;
                boundsMin[0] = modelPart( 0,  4.50,  0.25);
                boundsMax[0] = modelPart(16, 12.25,  1.75);
                break;
            case BLOCK_SIGN_WALL_W:
                shapeCount = 1u;
                boundsMin[0] = modelPart(14.25,  4.50,  0);
                boundsMax[0] = modelPart(15.00, 12.25, 16);
                break;
        }

        CollissionMaps[blockId].Count = shapeCount;

        for (uint i = 0u; i < min(shapeCount, BLOCK_MASK_PARTS); i++) {
            CollissionMaps[blockId].Bounds[i] = uvec2(
                packUnorm4x8(vec4(boundsMin[i], 0.0)),
                packUnorm4x8(vec4(boundsMax[i], 0.0)));
        }
    #endif
}
