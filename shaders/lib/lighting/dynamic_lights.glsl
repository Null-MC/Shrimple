#define LIGHT_NONE 0u
#define LIGHT_BLOCK_1 1u
#define LIGHT_BLOCK_2 2u
#define LIGHT_BLOCK_3 3u
#define LIGHT_BLOCK_4 4u
#define LIGHT_BLOCK_5 5u
#define LIGHT_BLOCK_6 6u
#define LIGHT_BLOCK_7 7u
#define LIGHT_BLOCK_8 8u
#define LIGHT_BLOCK_9 9u
#define LIGHT_BLOCK_10 10u
#define LIGHT_BLOCK_11 11u
#define LIGHT_BLOCK_12 12u
#define LIGHT_BLOCK_13 13u
#define LIGHT_BLOCK_14 14u
#define LIGHT_BLOCK_15 15u
#define LIGHT_AMETHYST_BUD_LARGE 16u
#define LIGHT_AMETHYST_BUD_MEDIUM 17u
#define LIGHT_AMETHYST_CLUSTER 18u
#define LIGHT_BEACON 19u
#define LIGHT_BLAST_FURNACE_N 20u
#define LIGHT_BLAST_FURNACE_E 21u
#define LIGHT_BLAST_FURNACE_S 22u
#define LIGHT_BLAST_FURNACE_W 23u
#define LIGHT_BREWING_STAND 24u
#define LIGHT_CANDLES_1 25u
#define LIGHT_CANDLES_2 26u
#define LIGHT_CANDLES_3 27u
#define LIGHT_CANDLES_4 28u
#define LIGHT_CANDLE_CAKE 29u
#define LIGHT_CAVEVINE_BERRIES 30u
#define LIGHT_COMPARATOR 31u
#define LIGHT_CRYING_OBSIDIAN 32u
#define LIGHT_END_ROD 33u
#define LIGHT_CAMPFIRE 34u
#define LIGHT_FIRE 35u
#define LIGHT_FURNACE_N 36u
#define LIGHT_FURNACE_E 37u
#define LIGHT_FURNACE_S 38u
#define LIGHT_FURNACE_W 39u
#define LIGHT_GLOWSTONE 40u
#define LIGHT_GLOW_LICHEN 41u
#define LIGHT_JACK_O_LANTERN_N 42u
#define LIGHT_JACK_O_LANTERN_E 43u
#define LIGHT_JACK_O_LANTERN_S 44u
#define LIGHT_JACK_O_LANTERN_W 45u
#define LIGHT_LANTERN 46u
#define LIGHT_LIGHTING_ROD 47u
#define LIGHT_LAVA 48u
#define LIGHT_LAVA_CAULDRON 49u
#define LIGHT_MAGMA 50u
#define LIGHT_NETHER_PORTAL 51u
#define LIGHT_FROGLIGHT_OCHRE 52u
#define LIGHT_FROGLIGHT_PEARLESCENT 53u
#define LIGHT_FROGLIGHT_VERDANT 54u
#define LIGHT_RAIL_POWERED 55u
#define LIGHT_REDSTONE_LAMP 56u
#define LIGHT_REDSTONE_TORCH 57u
#define LIGHT_REDSTONE_WIRE_1 58u
#define LIGHT_REDSTONE_WIRE_2 59u
#define LIGHT_REDSTONE_WIRE_3 60u
#define LIGHT_REDSTONE_WIRE_4 61u
#define LIGHT_REDSTONE_WIRE_5 62u
#define LIGHT_REDSTONE_WIRE_6 63u
#define LIGHT_REDSTONE_WIRE_7 64u
#define LIGHT_REDSTONE_WIRE_8 65u
#define LIGHT_REDSTONE_WIRE_9 66u
#define LIGHT_REDSTONE_WIRE_10 67u
#define LIGHT_REDSTONE_WIRE_11 68u
#define LIGHT_REDSTONE_WIRE_12 69u
#define LIGHT_REDSTONE_WIRE_13 70u
#define LIGHT_REDSTONE_WIRE_14 71u
#define LIGHT_REDSTONE_WIRE_15 72u
#define LIGHT_REPEATER 73u
#define LIGHT_RESPAWN_ANCHOR_1 74u
#define LIGHT_RESPAWN_ANCHOR_2 75u
#define LIGHT_RESPAWN_ANCHOR_3 76u
#define LIGHT_RESPAWN_ANCHOR_4 77u
#define LIGHT_SCULK_CATALYST 78u
#define LIGHT_SEA_LANTERN 79u
#define LIGHT_SEA_PICKLE_1 80u
#define LIGHT_SEA_PICKLE_2 81u
#define LIGHT_SEA_PICKLE_3 82u
#define LIGHT_SEA_PICKLE_4 83u
#define LIGHT_SHROOMLIGHT 84u
#define LIGHT_SMOKER_N 85u
#define LIGHT_SMOKER_E 86u
#define LIGHT_SMOKER_S 87u
#define LIGHT_SMOKER_W 88u
#define LIGHT_SOUL_LANTERN 89u
#define LIGHT_SOUL_TORCH 90u
#define LIGHT_SOUL_CAMPFIRE 91u
#define LIGHT_SOUL_FIRE 92u
#define LIGHT_TORCH 93u

#define LIGHT_IGNORED 255u


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
        case BLOCK_LANTERN_CEIL:
        case BLOCK_LANTERN_FLOOR:
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
        case BLOCK_SOUL_LANTERN_CEIL:
        case BLOCK_SOUL_LANTERN_FLOOR:
            lightType = LIGHT_SOUL_LANTERN;
            break;
        case BLOCK_SOUL_TORCH:
        case BLOCK_SOUL_TORCH_WALL:
            lightType = LIGHT_SOUL_TORCH;
            break;
        case BLOCK_TORCH:
        case BLOCK_TORCH_WALL:
            lightType = LIGHT_TORCH;
            break;
    }

    return lightType;
}

vec3 GetSceneLightColor(const in uint lightType, const in vec2 noiseSample) {
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
        case LIGHT_BEACON:
            lightColor = vec3(1.0);
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
        case LIGHT_CRYING_OBSIDIAN:
            lightColor = vec3(0.390, 0.065, 0.646);
            break;
        case LIGHT_END_ROD:
            lightColor = vec3(0.957, 0.929, 0.875);
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
            lightColor = vec3(0.697, 0.654, 0.458);
            break;
        case LIGHT_GLOWSTONE:
            lightColor = vec3(0.652, 0.583, 0.275);
            break;
        case LIGHT_GLOW_LICHEN:
            lightColor = 0.8*vec3(0.173, 0.374, 0.252);
            break;
        case LIGHT_JACK_O_LANTERN_N:
        case LIGHT_JACK_O_LANTERN_E:
        case LIGHT_JACK_O_LANTERN_S:
        case LIGHT_JACK_O_LANTERN_W:
            lightColor = vec3(0.768, 0.701, 0.325);
            break;
        case LIGHT_LANTERN:
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
        case LIGHT_REDSTONE_TORCH:
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
            lightColor = vec3(0.510, 0.831, 0.851);
            break;
        case LIGHT_SEA_LANTERN:
            lightColor = vec3(0.498, 0.894, 0.834);
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
            lightColor = vec3(0.697, 0.654, 0.458);
            break;
        case LIGHT_SOUL_LANTERN:
        case LIGHT_SOUL_TORCH:
        case LIGHT_SOUL_CAMPFIRE:
        case LIGHT_SOUL_FIRE:
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

        if (lightType == LIGHT_TORCH || lightType == LIGHT_LANTERN || lightType == LIGHT_FIRE || lightType == LIGHT_CAMPFIRE) {
            float torchTemp = mix(2000, 2400, flickerNoise);
            lightColor = 0.8 * blackbody(torchTemp);
        }

        if (lightType == LIGHT_SOUL_TORCH || lightType == LIGHT_SOUL_LANTERN || lightType == LIGHT_SOUL_FIRE || lightType == LIGHT_SOUL_CAMPFIRE) {
            float soulTorchTemp = mix(1200, 1800, 1.0 - flickerNoise);
            lightColor = 0.8 * saturate(1.0 - blackbody(soulTorchTemp));
        }

        if (lightType == LIGHT_CANDLES_1 || lightType == LIGHT_CANDLES_2
         || lightType == LIGHT_CANDLES_3 || lightType == LIGHT_CANDLES_4
         || lightType == LIGHT_CANDLE_CAKE || (lightType >= LIGHT_JACK_O_LANTERN_N && lightType <= LIGHT_JACK_O_LANTERN_W)) {
            float candleTemp = mix(2600, 3600, flickerNoise);
            lightColor = 0.7 * blackbody(candleTemp);
        }
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
            lightRange = 8.0;
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
        case LIGHT_REDSTONE_TORCH:
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
        if (lightType == LIGHT_COMPARATOR
         || lightType == LIGHT_REPEATER
         || lightType == LIGHT_RAIL_POWERED) return 0.0;

        if (lightType >= LIGHT_REDSTONE_WIRE_1
         && lightType <= LIGHT_REDSTONE_WIRE_15) return 0.0;
    #endif
    
    #if DYN_LIGHT_LAVA == 0
        if (lightType == LIGHT_LAVA) return 0.0;
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
        case LIGHT_CRYING_OBSIDIAN:
        case LIGHT_FIRE:
        case LIGHT_FROGLIGHT_OCHRE:
        case LIGHT_FROGLIGHT_PEARLESCENT:
        case LIGHT_FROGLIGHT_VERDANT:
        case LIGHT_GLOWSTONE:
        case LIGHT_LAVA:
        case LIGHT_MAGMA:
        case LIGHT_SOUL_FIRE:
            size = (16.0/16.0);
            break;
        case LIGHT_LAVA_CAULDRON:
        case LIGHT_SEA_LANTERN:
        case LIGHT_REDSTONE_LAMP:
            size = (14.0/16.0);
            break;
        case LIGHT_CAMPFIRE:
        case LIGHT_SOUL_CAMPFIRE:
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
            size = (8.0/16.0);
            break;
        case LIGHT_CANDLES_3:
        case LIGHT_LANTERN:
        case LIGHT_SOUL_LANTERN:
            size = (6.0/16.0);
            break;
        case LIGHT_CANDLES_2:
        case LIGHT_TORCH:
        case LIGHT_SOUL_TORCH:
            size = (4.0/16.0);
            break;
        case LIGHT_CANDLES_1:
        case LIGHT_REDSTONE_TORCH:
            size = (2.0/16.0);
            break;
    }

    #if DYN_LIGHT_LAVA != 2
        if (lightType == LIGHT_LAVA) size = 0.0;
    #endif

    #if DYN_LIGHT_REDSTONE != 2
        if (lightType >= LIGHT_REDSTONE_WIRE_1 && lightType <= LIGHT_REDSTONE_WIRE_15) size = 0.0;
    #endif

    //if (lightType == LIGHT_CAVEVINE_BERRIES) size = 0.4;

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
        case LIGHT_TORCH:
        case LIGHT_SOUL_TORCH:
            lightOffset = vec3(0.0, (1.0/16.0), 0.0);
            break;
    }

    return lightOffset;
}

#ifdef RENDER_SHADOWCOMP
    uint BuildLightMask(const in uint lightType, const in float lightSize) {
        uint lightData;

        // trace
        lightData = lightSize > EPSILON ? 1u : 0u;

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

        // size
        uint bitSize = uint(saturate(lightSize) * 31.0 + 0.5);
        lightData |= bitSize << 8u;

        return lightData;
    }
#endif
