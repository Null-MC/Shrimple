#define LIGHT_NONE 0u
#define LIGHT_BEACON 1u
#define LIGHT_BLAST_FURNACE_N 2u
#define LIGHT_BLAST_FURNACE_E 3u
#define LIGHT_BLAST_FURNACE_S 4u
#define LIGHT_BLAST_FURNACE_W 5u
#define LIGHT_BREWING_STAND 6u
#define LIGHT_CANDLES_1 7u
#define LIGHT_CANDLES_2 8u
#define LIGHT_CANDLES_3 9u
#define LIGHT_CANDLES_4 10u
#define LIGHT_CAVEVINE_BERRIES 11u
#define LIGHT_GLOWSTONE 12u
#define LIGHT_REDSTONE_LAMP 13u
#define LIGHT_REDSTONE_TORCH 14u
#define LIGHT_SEA_LANTERN 15u
#define LIGHT_SOUL_TORCH 16u
#define LIGHT_TORCH 17u
#define LIGHT_IGNORED 255u


uint GetSceneLightType(const in int blockId) {
    uint lightType = LIGHT_NONE;
    if (blockId < 1) return lightType;

    switch (blockId) {
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
        case BLOCK_GLOWSTONE:
            lightType = LIGHT_GLOWSTONE;
            break;
        case BLOCK_REDSTONE_LAMP_LIT:
            lightType = LIGHT_REDSTONE_LAMP;
            break;
        case BLOCK_REDSTONE_TORCH_LIT:
            lightType = LIGHT_REDSTONE_TORCH;
            break;
        case BLOCK_SEA_LANTERN:
            lightType = LIGHT_SEA_LANTERN;
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

vec3 GetSceneLightColor(const in uint lightType, const in vec2 noiseSample) {
    vec3 lightColor = vec3(0.0);

    switch (lightType) {
        case LIGHT_BEACON:
            lightColor = vec3(1.0, 1.0, 1.0);
            break;
        case LIGHT_BLAST_FURNACE_N:
        case LIGHT_BLAST_FURNACE_E:
        case LIGHT_BLAST_FURNACE_S:
        case LIGHT_BLAST_FURNACE_W:
            lightColor = vec3(0.697, 0.654, 0.458);
            break;
        case LIGHT_BREWING_STAND:
            lightColor = vec3(0.636, 0.509, 0.179);
            break;
        case LIGHT_CANDLES_1:
        case LIGHT_CANDLES_2:
        case LIGHT_CANDLES_3:
        case LIGHT_CANDLES_4:
            lightColor = vec3(0.758, 0.553, 0.239);
            break;
        case LIGHT_CAVEVINE_BERRIES:
            lightColor = 0.4 * vec3(0.717, 0.541, 0.188);
            break;
        case LIGHT_GLOWSTONE:
            lightColor = vec3(0.652, 0.583, 0.275);
            break;
        case LIGHT_REDSTONE_LAMP:
            lightColor = vec3(0.953, 0.796, 0.496);
            break;
        case LIGHT_REDSTONE_TORCH:
            lightColor = vec3(0.697, 0.130, 0.051);
            break;
        case LIGHT_SEA_LANTERN:
            lightColor = vec3(0.498, 0.894, 0.834);
            break;
        case LIGHT_SOUL_TORCH:
            lightColor = vec3(0.203, 0.725, 0.758);
            break;
        case LIGHT_TORCH:
            lightColor = vec3(0.768, 0.701, 0.325);
            break;
    }
    
    lightColor = RGBToLinear(lightColor);

    #ifdef DYN_LIGHT_FLICKER
        // TODO: optimize branching
        //vec2 noiseSample = GetDynLightNoise(cameraPosition + blockLocalPos);
        float flickerNoise = GetDynLightFlickerNoise(noiseSample);

        if (lightType == LIGHT_TORCH || lightType == BLOCK_LANTERN || lightType == BLOCK_FIRE || lightType == BLOCK_CAMPFIRE_LIT) {
            float torchTemp = mix(1600, 3400, flickerNoise);
            lightColor = 0.8 * blackbody(torchTemp);
        }

        if (lightType == LIGHT_SOUL_TORCH || lightType == BLOCK_SOUL_LANTERN || lightType == BLOCK_SOUL_FIRE || lightType == BLOCK_SOUL_CAMPFIRE_LIT) {
            float soulTorchTemp = mix(1200, 1800, 1.0 - flickerNoise);
            lightColor = 0.8 * saturate(1.0 - blackbody(soulTorchTemp));
        }

        if (lightType == LIGHT_CANDLES_1 || lightType == BLOCK_CANDLES_2
         || lightType == LIGHT_CANDLES_3 || lightType == BLOCK_CANDLES_4
         || lightType == BLOCK_CANDLE_CAKE_LIT || (lightType >= BLOCK_JACK_O_LANTERN_N && lightType <= BLOCK_JACK_O_LANTERN_W)) {
            float candleTemp = mix(2600, 3600, flickerNoise);
            lightColor = 0.7 * blackbody(candleTemp);
        }
    #endif

    return lightColor;
}

float GetSceneLightRange(const in uint lightType) {
    float lightRange = 0.0;

    switch (lightType) {
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
            lightRange = 1.0;
            break;
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
        case LIGHT_CAVEVINE_BERRIES:
            lightRange = 14.0;
            break;
        case LIGHT_GLOWSTONE:
            lightRange = 15.0;
            break;
        case LIGHT_REDSTONE_LAMP:
            lightRange = 15.0;
            break;
        case LIGHT_REDSTONE_TORCH:
            lightRange = 7.0;
            break;
        case LIGHT_SEA_LANTERN:
            lightRange = 15.0;
            break;
        case LIGHT_SOUL_TORCH:
            lightRange = 10.0;
            break;
        case LIGHT_TORCH:
            lightRange = 12.0;
            break;
    }

    return lightRange;
}

float GetSceneLightLevel(const in uint lightType) {
    #if DYN_LIGHT_REDSTONE == 0
        if (lightType == BLOCK_COMPARATOR_LIT
         || lightType == BLOCK_REPEATER_LIT
         || lightType == BLOCK_RAIL_POWERED) return 0.0;

        if (lightType >= BLOCK_REDSTONE_WIRE_1
         && lightType <= BLOCK_REDSTONE_WIRE_15) return 0.0;
    #endif
    
    #if DYN_LIGHT_LAVA == 0
        if (lightType == BLOCK_LAVA) return 0.0;
    #endif

    return GetSceneLightRange(lightType);
}

// float GetSceneBlockEmission(const in uint lightType) {
//     float range = GetSceneBlockLightRange(lightType);

//     if (lightType == BLOCK_LAVA) range *= 2.0;
//     if (lightType == BLOCK_CAVEVINE_BERRIES) range = 0.0;

//     return range / 15.0;
// }

float GetSceneLightSize(const in uint lightType) {
    float size = (1.0/16.0);

    switch (lightType) {
        case LIGHT_GLOWSTONE:
            size = (16.0/16.0);
            break;
        case LIGHT_SEA_LANTERN:
        case LIGHT_REDSTONE_LAMP:
            size = (14.0/16.0);
            break;
        case LIGHT_BEACON:
            size = 0.6;
            break;
        case LIGHT_CANDLES_4:
            size = 0.4;
            break;
        case LIGHT_CANDLES_3:
            size = 0.3;
            break;
        case LIGHT_CANDLES_2:
            size = 0.2;
            break;
        case LIGHT_CANDLES_1:
            size = 0.1;
            break;
        case LIGHT_TORCH:
        case LIGHT_SOUL_TORCH:
            size = (4.0/16.0);
            break;
        case LIGHT_REDSTONE_TORCH:
            size = (2.0/16.0);
            break;
    }

    #if DYN_LIGHT_LAVA != 2
        if (lightType == BLOCK_LAVA) size = 0.0;
    #endif

    #if DYN_LIGHT_REDSTONE != 2
        if (lightType >= BLOCK_REDSTONE_WIRE_1 && lightType <= BLOCK_REDSTONE_WIRE_15) size = 0.0;
    #endif

    //if (lightType == BLOCK_CAVEVINE_BERRIES) size = 0.4;

    return size;
}

#ifdef RENDER_SHADOWCOMP
    uint BuildLightMask(const in uint lightType, const in float lightSize) {
        uint lightData;

        // trace
        lightData = lightSize > EPSILON ? 1u : 0u;

        switch (lightType) {
            case BLOCK_BEACON:
                lightData |= 1u << LIGHT_MASK_DOWN;
                break;
            case BLOCK_JACK_O_LANTERN_N:
            case BLOCK_FURNACE_LIT_N:
            case BLOCK_BLAST_FURNACE_LIT_N:
            case BLOCK_SMOKER_LIT_N:
                lightData |= 1u << LIGHT_MASK_UP;
                lightData |= 1u << LIGHT_MASK_DOWN;
                lightData |= 1u << LIGHT_MASK_SOUTH;
                lightData |= 1u << LIGHT_MASK_WEST;
                lightData |= 1u << LIGHT_MASK_EAST;
                break;
            case BLOCK_JACK_O_LANTERN_E:
            case BLOCK_FURNACE_LIT_E:
            case BLOCK_BLAST_FURNACE_LIT_E:
            case BLOCK_SMOKER_LIT_E:
                lightData |= 1u << LIGHT_MASK_UP;
                lightData |= 1u << LIGHT_MASK_DOWN;
                lightData |= 1u << LIGHT_MASK_NORTH;
                lightData |= 1u << LIGHT_MASK_SOUTH;
                lightData |= 1u << LIGHT_MASK_WEST;
                break;
            case BLOCK_JACK_O_LANTERN_S:
            case BLOCK_FURNACE_LIT_S:
            case BLOCK_BLAST_FURNACE_LIT_S:
            case BLOCK_SMOKER_LIT_S:
                lightData |= 1u << LIGHT_MASK_UP;
                lightData |= 1u << LIGHT_MASK_DOWN;
                lightData |= 1u << LIGHT_MASK_NORTH;
                lightData |= 1u << LIGHT_MASK_WEST;
                lightData |= 1u << LIGHT_MASK_EAST;
                break;
            case BLOCK_JACK_O_LANTERN_W:
            case BLOCK_FURNACE_LIT_W:
            case BLOCK_BLAST_FURNACE_LIT_W:
            case BLOCK_SMOKER_LIT_W:
                lightData |= 1u << LIGHT_MASK_UP;
                lightData |= 1u << LIGHT_MASK_DOWN;
                lightData |= 1u << LIGHT_MASK_NORTH;
                lightData |= 1u << LIGHT_MASK_SOUTH;
                lightData |= 1u << LIGHT_MASK_EAST;
                break;
            // case BLOCK_LANTERN:
            // case BLOCK_SOUL_LANTERN:
            //     lightData |= 1u << LIGHT_MASK_UP;
            //     lightData |= 1u << LIGHT_MASK_DOWN;
            //     break;
            case BLOCK_LAVA_CAULDRON:
                lightData |= 1u << LIGHT_MASK_DOWN;
                lightData |= 1u << LIGHT_MASK_NORTH;
                lightData |= 1u << LIGHT_MASK_SOUTH;
                lightData |= 1u << LIGHT_MASK_WEST;
                lightData |= 1u << LIGHT_MASK_EAST;
                break;
        }

        // size
        uint bitSize = uint(saturate(lightSize) * 31.0 + 0.5);
        lightData |= bitSize << 8u;

        return lightData;
    }
#endif
