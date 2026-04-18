#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(32, 32, 1);

#ifdef WIND_ENABLED
    layout(r16ui) uniform writeonly uimage2D imgBlockWaving;
#endif

#if defined(LIGHTING_COLORED) || defined(PHOTONICS_BLOCK_LIGHT_ENABLED)
    layout(rgba8) uniform writeonly image2D imgBlockLight;
#endif

#ifdef LIGHTING_COLORED
    layout(r16ui) uniform writeonly uimage2D imgBlockMask;
#endif

#include "/lib/entities.glsl"
#include "/lib/blocks.glsl"
#include "/lib/items.glsl"


const vec3 color_White = vec3(255);
const vec3 color_Amethyst = vec3(118, 58, 201);
const vec3 color_Candle = vec3(230, 144, 76);
const vec3 color_CopperBulb = vec3(230, 204, 128);
const vec3 color_CopperLantern = vec3(107, 227, 191);
const vec3 color_CopperTorch = vec3(126, 230, 25);
const vec3 color_Fire = vec3(220, 152, 89);
const vec3 color_Furnace = vec3(196, 159, 114);
const vec3 color_RedstoneTorch = vec3(232, 59, 21);
const vec3 color_RespawnAnchor = vec3(99, 17, 165);
const vec3 color_SeaPickle = vec3(72, 100, 54);
const vec3 color_SoulFire = vec3(25, 184, 229);
const vec3 color_Torch = vec3(245, 117, 66);

const vec3 color_CandleBlack = vec3(51, 51, 51);
const vec3 color_CandleBlue = vec3(0, 66, 255);
const vec3 color_CandleBrown = vec3(117, 67, 38);
const vec3 color_CandleCyan = vec3(0, 214, 214);
const vec3 color_CandleGray = vec3(84, 91, 99);
const vec3 color_CandleGreen = vec3(67, 115, 0);
const vec3 color_CandleLightBlue = vec3(39, 175, 255);
const vec3 color_CandleLightGray = vec3(161, 160, 159);
const vec3 color_CandleLime = vec3(112, 227, 0);
const vec3 color_CandleMagenta = vec3(193, 25, 207);
const vec3 color_CandleOrange = vec3(255, 117, 0);
const vec3 color_CandlePink = vec3(255, 141, 183);
const vec3 color_CandlePurple = vec3(145, 0, 255);
const vec3 color_CandleRed = vec3(219, 0, 0);
const vec3 color_CandleYellow = vec3(255, 224, 0);


//uint BuildLpvMask(const in uint north, const in uint east, const in uint south, const in uint west, const in uint up, const in uint down) {
//    return east | (west << 1) | (down << 2) | (up << 3) | (south << 4) | (north << 5);
//}

#define MASK(N,E,S,W,U,D) (E | (W << 1) | (D << 2) | (U << 3) | (S << 4) | (N << 5))

void main() {
    uint blockId = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 256u;

    float mixWeight = 0.0;
    uint mixMask = UINT_MAX;
    vec3 color = vec3(0.0);
    float range = 0.0;

    float wavingBottom = 0.0;
    float wavingTop = 0.0;
    bool waveSnap = true;


    // foliage
    if (blockId >= 100 && blockId < 200) mixWeight = 1.0;

    switch (blockId) {
        case ENTITY_BLAZE:
            mixWeight = 1.0;
            color = color_Fire;
            range = 8;
            break;
    }

    switch (blockId) {
        case BLOCK_AZURE_BLUET:
        case BLOCK_BEETROOTS:
        case BLOCK_BLUE_ORCHID:
        case BLOCK_BUSH:
        case BLOCK_CARROTS:
        case BLOCK_CORNFLOWER:
        case BLOCK_DANDELION:
        case BLOCK_FERN:
        case BLOCK_GROUND_LEAVES:
        case BLOCK_GRASS_SHORT:
        case BLOCK_LILY_OF_THE_VALLEY:
        case BLOCK_OXEYE_DAISY:
        case BLOCK_POPPY:
        case BLOCK_POTATOES:
        case BLOCK_SAPLING:
        case BLOCK_TULIP:
        case BLOCK_WHEAT:
            wavingTop = 1.0;
            break;
        case BLOCK_LARGE_FERN_LOWER:
        case BLOCK_LILAC_LOWER:
        case BLOCK_PEONY_LOWER:
        case BLOCK_ROSE_BUSH_LOWER:
        case BLOCK_SUNFLOWER_LOWER:
        case BLOCK_TALL_GRASS_LOWER:
            wavingTop = 0.5;
            break;
        case BLOCK_LARGE_FERN_UPPER:
        case BLOCK_LILAC_UPPER:
        case BLOCK_PEONY_UPPER:
        case BLOCK_ROSE_BUSH_UPPER:
        case BLOCK_SUNFLOWER_UPPER:
        case BLOCK_TALL_GRASS_UPPER:
            wavingBottom = 0.5;
            wavingTop = 1.0;
            break;
        case BLOCK_HANGING_ROOTS:
            wavingBottom = 0.5;
            break;
    }

    switch (blockId) {
//        case BLOCK_KELP:
        case BLOCK_LEAVES:
            wavingTop = 1.0;
            wavingBottom = 1.0;
            waveSnap = false;
            break;
    }

    // IGNORED
    if (blockId > 900 && blockId < 1000) mixWeight = 1.0;

    if (blockId == BLOCK_CARPET) mixWeight = 1.0;
    if (blockId >= BLOCK_FENCE_POST && blockId <= BLOCK_FENCE_GATE_CLOSED_W_E) mixWeight = 1.0;


    switch (blockId) {
        case BLOCK_LIGHT_1:
            mixWeight = 1.0;
            color = color_White;
            range = 1;
            break;
        case BLOCK_LIGHT_2:
            mixWeight = 1.0;
            color = color_White;
            range = 2;
            break;
        case BLOCK_LIGHT_3:
            mixWeight = 1.0;
            color = color_White;
            range = 3;
            break;
        case BLOCK_LIGHT_4:
            mixWeight = 1.0;
            color = color_White;
            range = 4;
            break;
        case BLOCK_LIGHT_5:
            mixWeight = 1.0;
            color = color_White;
            range = 5;
            break;
        case BLOCK_LIGHT_6:
            mixWeight = 1.0;
            color = color_White;
            range = 6;
            break;
        case BLOCK_LIGHT_7:
            mixWeight = 1.0;
            color = color_White;
            range = 7;
            break;
        case BLOCK_LIGHT_8:
            mixWeight = 1.0;
            color = color_White;
            range = 8;
            break;
        case BLOCK_LIGHT_9:
            mixWeight = 1.0;
            color = color_White;
            range = 9;
            break;
        case BLOCK_LIGHT_10:
            mixWeight = 1.0;
            color = color_White;
            range = 10;
            break;
        case BLOCK_LIGHT_11:
            mixWeight = 1.0;
            color = color_White;
            range = 11;
            break;
        case BLOCK_LIGHT_12:
            mixWeight = 1.0;
            color = color_White;
            range = 12;
            break;
        case BLOCK_LIGHT_13:
            mixWeight = 1.0;
            color = color_White;
            range = 13;
            break;
        case BLOCK_LIGHT_14:
            mixWeight = 1.0;
            color = color_White;
            range = 14;
            break;
        case BLOCK_LIGHT_15:
            mixWeight = 1.0;
            color = color_White;
            range = 15;
            break;
        case BLOCK_AMETHYST_BUD_LARGE:
            mixWeight = 0.7;
            color = color_Amethyst;
            range = 4;
            break;
        case BLOCK_AMETHYST_BUD_MEDIUM:
            mixWeight = 0.8;
            color = color_Amethyst;
            range = 2;
            break;
        case BLOCK_AMETHYST_CLUSTER:
            mixWeight = 0.6;
            color = color_Amethyst;
            range = 5;
            break;
        case BLOCK_BEACON:
            mixWeight = 0.4;
            color = color_White;
            range = 15;
            break;
        case BLOCK_BLAST_FURNACE_LIT_N:
        case BLOCK_BLAST_FURNACE_LIT_E:
        case BLOCK_BLAST_FURNACE_LIT_S:
        case BLOCK_BLAST_FURNACE_LIT_W:
            color = color_Furnace;
            range = 6;
            break;
        case BLOCK_BREWING_STAND:
            mixWeight = 0.7;
            color = color_Furnace;
            range = 2;
            break;
        case BLOCK_CANDLE_CAKE:
            color = color_Candle;
            range = 3;
            break;
        case BLOCK_CAVEVINE_BERRIES:
            mixWeight = 0.85;
            color = vec3(230, 120, 30);
            range = 14;
            break;
        case BLOCK_COPPER_BULB_LIT:
            color = color_CopperBulb;
            range = 15;
            break;
        case BLOCK_COPPER_BULB_EXPOSED_LIT:
            color = color_CopperBulb;
            range = 12;
            break;
        case BLOCK_COPPER_BULB_OXIDIZED_LIT:
            color = color_CopperBulb;
            range = 4;
            break;
        case BLOCK_COPPER_BULB_WEATHERED_LIT:
            color = color_CopperBulb;
            range = 8;
            break;
        case BLOCK_COPPER_LANTERN:
        case BLOCK_EXPOSED_COPPER_LANTERN:
        case BLOCK_WEATHERED_COPPER_LANTERN:
        case BLOCK_OXIDIZED_COPPER_LANTERN:
            mixWeight = 0.85;
            color = color_CopperLantern;
            range = 15;
            break;
        case BLOCK_COPPER_TORCH_FLOOR:
        case BLOCK_COPPER_TORCH_WALL_N:
        case BLOCK_COPPER_TORCH_WALL_E:
        case BLOCK_COPPER_TORCH_WALL_S:
        case BLOCK_COPPER_TORCH_WALL_W:
            mixWeight = 0.95;
            color = vec3(color_CopperTorch);
            range = 14;
            break;
        case BLOCK_CREAKING_HEART:
            color = vec3(230, 128, 47);
            range = 8;
            break;
        case BLOCK_CREATE_XP:
            color = vec3(157, 232, 80);
            range = 15;
            break;
        case BLOCK_DOOR_N:
            mixMask = MASK(0, 1, 1, 1, 1, 1);
            mixWeight = 1.0;
            break;
        case BLOCK_DOOR_E:
            mixMask = MASK(1, 0, 1, 1, 1, 1);
            mixWeight = 1.0;
            break;
        case BLOCK_DOOR_S:
            mixMask = MASK(1, 1, 0, 1, 1, 1);
            mixWeight = 1.0;
            break;
        case BLOCK_DOOR_W:
            mixMask = MASK(1, 1, 1, 0, 1, 1);
            mixWeight = 1.0;
            break;
        case BLOCK_EYEBLOSSOM_OPEN:
            mixWeight = 0.90;
            color = vec3(230, 128, 47);
            range = 2;
            break;
        case BLOCK_CRYING_OBSIDIAN:
            color = vec3(99, 17, 165);
            range = 10;
            break;
        case BLOCK_END_ROD:
            mixWeight = 0.95;
            color = vec3(244, 237, 223);
            range = 14;
            break;
        case BLOCK_CAMPFIRE_LIT_N_S:
        case BLOCK_CAMPFIRE_LIT_W_E:
        case BLOCK_FIRE:
            mixWeight = 1.0;
            color = color_Fire;
            range = 15;
            break;
        case BLOCK_FROGLIGHT_OCHRE:
            color = vec3(196, 165, 28);
            range = 15;
            break;
        case BLOCK_FROGLIGHT_PEARLESCENT:
            color = vec3(188, 111, 168);
            range = 15;
            break;
        case BLOCK_FROGLIGHT_VERDANT:
            color = vec3(118, 195, 104);
            range = 15;
            break;
        case BLOCK_FURNACE_LIT_N:
        case BLOCK_FURNACE_LIT_E:
        case BLOCK_FURNACE_LIT_S:
        case BLOCK_FURNACE_LIT_W:
            mixWeight = 0.0;
            color = color_Furnace;
            range = 6;
            break;
        case BLOCK_GLOWSTONE:
            mixWeight = 0.0;
            color = vec3(190, 151, 83);
            range = 15;
            break;
//        case BLOCK_GLOWSTONE_DUST:
//            color = vec4(190, 151, 83, 6);
//            break;
        case BLOCK_GLOW_LICHEN:
            mixWeight = 1.0;
            color = vec3(87, 184, 110);
            range = 7;
            break;
        case BLOCK_JACK_O_LANTERN:
            mixWeight = 0.0;
            color = vec3(196, 179, 83);
            range = 15;
            break;
        case BLOCK_LANTERN:
            mixWeight = 0.85;
            color = vec3(231, 188, 115);
            range = 12;
            break;
        case BLOCK_LAVA:
            mixWeight = 0.0;
            color = vec3(color_Torch);
            range = 15;
            break;
//        case BLOCK_LIGHTING_ROD:
//            mixWeight = 1.0;
//            break;
        case BLOCK_LIGHTING_ROD_POWERED:
            mixWeight = 1.0;
            color = vec3(222, 244, 249);
            range = 8;
            break;
        case BLOCK_MAGMA:
            mixWeight = 0.0;
            color = vec3(190, 82, 28);
            range = 3;
            break;
        case BLOCK_NETHER_PORTAL:
            mixWeight = 1.0;
            color = vec3(128, 42, 212);
            range = 11;
            break;
//        case BLOCK_REDSTONE_LAMP:
//            mixWeight = 0.0;
//            break;
        case BLOCK_REDSTONE_LAMP_LIT:
            mixWeight = 0.0;
            color = vec3(243, 203, 126);
            range = 15;
            break;
        case BLOCK_REDSTONE_ORE_LIT:
            mixWeight = 0.0;
            color = color_RedstoneTorch;
            range = 9;
            break;
        case BLOCK_REDSTONE_TORCH_LIT:
            mixWeight = 0.95;
            color = color_RedstoneTorch;
            range = 7;
            break;
        case BLOCK_REDSTONE_WIRE_1:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 1.0;
            break;
        case BLOCK_REDSTONE_WIRE_2:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 1.5;
            break;
        case BLOCK_REDSTONE_WIRE_3:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 2.0;
            break;
        case BLOCK_REDSTONE_WIRE_4:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 2.5;
            break;
        case BLOCK_REDSTONE_WIRE_5:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 3.0;
            break;
        case BLOCK_REDSTONE_WIRE_6:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 3.5;
            break;
        case BLOCK_REDSTONE_WIRE_7:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 4.0;
            break;
        case BLOCK_REDSTONE_WIRE_8:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 4.5;
            break;
        case BLOCK_REDSTONE_WIRE_9:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 5.0;
            break;
        case BLOCK_REDSTONE_WIRE_10:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 5.5;
            break;
        case BLOCK_REDSTONE_WIRE_11:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 6.0;
            break;
        case BLOCK_REDSTONE_WIRE_12:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 6.5;
            break;
        case BLOCK_REDSTONE_WIRE_13:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 7.0;
            break;
        case BLOCK_REDSTONE_WIRE_14:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 7.5;
            break;
        case BLOCK_REDSTONE_WIRE_15:
            mixWeight = 1.0;
            color = color_RedstoneTorch;
            range = 8.0;
            break;
        case BLOCK_REPEATER_LIT:
            mixWeight = 0.9;
            color = color_RedstoneTorch;
            range = 7;
            break;
        case BLOCK_RESPAWN_ANCHOR_1:
            color = color_RespawnAnchor;
            range = 3;
            break;
        case BLOCK_RESPAWN_ANCHOR_2:
            color = color_RespawnAnchor;
            range = 7;
            break;
        case BLOCK_RESPAWN_ANCHOR_3:
            color = color_RespawnAnchor;
            range = 11;
            break;
        case BLOCK_RESPAWN_ANCHOR_4:
            color = color_RespawnAnchor;
            range = 15;
            break;
        case BLOCK_SCULK_CATALYST:
            mixWeight = 0.5;
            color = vec3(46, 91, 94);
            range = 6;
            break;
        case BLOCK_SEA_LANTERN:
            mixWeight = 0.0;
            color = vec3(141, 191, 219);
            range = 15;
            break;
        case BLOCK_SEA_PICKLE_WET_1:
            mixWeight = 0.95;
            color = color_SeaPickle;
            range = 6;
            break;
        case BLOCK_SEA_PICKLE_WET_2:
            mixWeight = 0.90;
            color = color_SeaPickle;
            range = 9;
            break;
        case BLOCK_SEA_PICKLE_WET_3:
            mixWeight = 0.85;
            color = color_SeaPickle;
            range = 12;
            break;
        case BLOCK_SEA_PICKLE_WET_4:
            mixWeight = 0.80;
            color = color_SeaPickle;
            range = 15;
            break;
        case BLOCK_SHROOMLIGHT:
            mixWeight = 0.0;
            color = vec3(216, 120, 52);
            range = 15;
            break;
        case BLOCK_SLAB_TOP:
            mixMask = MASK(1, 1, 1, 1, 0, 1);
            mixWeight = 0.5;
            break;
        case BLOCK_SLAB_BOTTOM:
            mixMask = MASK(1, 1, 1, 1, 1, 0);
            mixWeight = 0.5;
            break;
        case BLOCK_SMOKER_LIT:
            mixWeight = 0.0;
            color = color_Furnace;
            range = 6;
            break;
        case BLOCK_SOUL_CAMPFIRE_LIT:
        case BLOCK_SOUL_FIRE:
        case BLOCK_SOUL_LANTERN:
            mixWeight = 0.9;
            color = color_SoulFire;
            range = 12;
            break;
        case BLOCK_SOUL_TORCH:
            mixWeight = 1.0;
            color = color_SoulFire;
            range = 10;
            break;
        case BLOCK_TORCH:
            mixWeight = 1.0;
            color = vec3(color_Torch);
            range = 12;
            break;
        case BLOCK_TRAPDOOR_BOTTOM:
            mixMask = MASK(1, 1, 1, 1, 1, 0);
            mixWeight = 1.0;
            break;
        case BLOCK_TRAPDOOR_TOP:
            mixMask = MASK(1, 1, 1, 1, 0, 1);
            mixWeight = 1.0;
            break;
        case BLOCK_TRAPDOOR_N:
            mixMask = MASK(0, 1, 1, 1, 1, 1);
            mixWeight = 1.0;
            break;
        case BLOCK_TRAPDOOR_E:
            mixMask = MASK(1, 0, 1, 1, 1, 1);
            mixWeight = 1.0;
            break;
        case BLOCK_TRAPDOOR_S:
            mixMask = MASK(1, 1, 0, 1, 1, 1);
            mixWeight = 1.0;
            break;
        case BLOCK_TRAPDOOR_W:
            mixMask = MASK(1, 1, 1, 0, 1, 1);
            mixWeight = 1.0;
            break;
    }

    switch (blockId) {
        case BLOCK_HONEY:
            color = vec3(251, 187, 64);
            mixWeight = 1.0;
            break;
        case BLOCK_LEAVES:
        case BLOCK_LEAVES_CHERRY:
            color = vec3(128, 128, 128);
            mixWeight = 0.5;
            break;
        case BLOCK_ROOTS:
            color = vec3(166, 179, 166);
            mixWeight = 0.9;
            break;
        case BLOCK_SLIME:
            color = vec3(104, 185, 84);
            mixWeight = 1.0;
            break;
        case BLOCK_SNOW:
            color = vec3(96, 139, 158);
            break;
        case BLOCK_STAINED_GLASS_BLACK:
            color = vec3(77, 77, 77);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_BLUE:
            color = vec3(26, 26, 250);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_BROWN:
            color = vec3(144, 99, 38);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_CYAN:
            color = vec3(21, 136, 195);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_GRAY:
            color = vec3(102, 102, 102);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_GREEN:
            color = vec3(32, 206, 21);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_LIGHT_BLUE:
            color = vec3(82, 175, 244);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_LIGHT_GRAY:
            color = vec3(179, 179, 179);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_LIME:
            color = vec3(161, 236, 32);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_MAGENTA:
            color = vec3(178, 76, 216);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_ORANGE:
            color = vec3(234, 149, 47);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_PINK:
            color = vec3(242, 70, 127);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_PURPLE:
            color = vec3(147, 43, 231);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_RED:
            color = vec3(255, 48, 48);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_WHITE:
            color = vec3(245, 245, 245);
            mixWeight = 1.0;
            break;
        case BLOCK_STAINED_GLASS_YELLOW:
            color = vec3(246, 246, 31);
            mixWeight = 1.0;
            break;
        case BLOCK_TINTED_GLASS:
            color = vec3(51, 26, 51);
            mixWeight = 1.0;
            break;

//        case BLOCK_CANDLE_CAKE_LIT:
//            lightType = LIGHT_CANDLE_CAKE;
//            break;
//        case BLOCK_CANDLE_HOLDER_LIT_1:
//        lightType = LIGHT_CANDLES_1;
//        break;
//        case BLOCK_CANDLE_HOLDER_LIT_2:
//        lightType = LIGHT_CANDLES_2;
//        break;
//        case BLOCK_CANDLE_HOLDER_LIT_3:
//        lightType = LIGHT_CANDLES_3;
//        break;
//        case BLOCK_CANDLE_HOLDER_LIT_4:
//        lightType = LIGHT_CANDLES_4;
//        break;
//        case BLOCK_CAULDRON_LAVA:
//            lightType = LIGHT_LAVA_CAULDRON;
//            break;
    }

    #ifdef LIGHTING_COLORED_CANDLES
        switch (blockId) {
            case BLOCK_PLAIN_CANDLES_LIT_1:
                color = color_Candle;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_PLAIN_CANDLES_LIT_2:
                color = color_Candle;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_PLAIN_CANDLES_LIT_3:
                color = color_Candle;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_PLAIN_CANDLES_LIT_4:
                color = color_Candle;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_BLACK_CANDLES_LIT_1:
                color = color_CandleBlack;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_BLACK_CANDLES_LIT_2:
                color = color_CandleBlack;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_BLACK_CANDLES_LIT_3:
                color = color_CandleBlack;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_BLACK_CANDLES_LIT_4:
                color = color_CandleBlack;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_BLUE_CANDLES_LIT_1:
                color = color_CandleBlue;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_BLUE_CANDLES_LIT_2:
                color = color_CandleBlue;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_BLUE_CANDLES_LIT_3:
                color = color_CandleBlue;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_BLUE_CANDLES_LIT_4:
                color = color_CandleBlue;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_BROWN_CANDLES_LIT_1:
                color = color_CandleBrown;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_BROWN_CANDLES_LIT_2:
                color = color_CandleBrown;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_BROWN_CANDLES_LIT_3:
                color = color_CandleBrown;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_BROWN_CANDLES_LIT_4:
                color = color_CandleBrown;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_CYAN_CANDLES_LIT_1:
                color = color_CandleCyan;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_CYAN_CANDLES_LIT_2:
                color = color_CandleCyan;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_CYAN_CANDLES_LIT_3:
                color = color_CandleCyan;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_CYAN_CANDLES_LIT_4:
                color = color_CandleCyan;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_GRAY_CANDLES_LIT_1:
                color = color_CandleGray;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_GRAY_CANDLES_LIT_2:
                color = color_CandleGray;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_GRAY_CANDLES_LIT_3:
                color = color_CandleGray;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_GRAY_CANDLES_LIT_4:
                color = color_CandleGray;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_GREEN_CANDLES_LIT_1:
                color = color_CandleGreen;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_GREEN_CANDLES_LIT_2:
                color = color_CandleGreen;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_GREEN_CANDLES_LIT_3:
                color = color_CandleGreen;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_GREEN_CANDLES_LIT_4:
                color = color_CandleGreen;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_LIGHT_BLUE_CANDLES_LIT_1:
                color = color_CandleLightBlue;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_LIGHT_BLUE_CANDLES_LIT_2:
                color = color_CandleLightBlue;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_LIGHT_BLUE_CANDLES_LIT_3:
                color = color_CandleLightBlue;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_LIGHT_BLUE_CANDLES_LIT_4:
                color = color_CandleLightBlue;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_LIGHT_GRAY_CANDLES_LIT_1:
                color = color_CandleLightGray;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_LIGHT_GRAY_CANDLES_LIT_2:
                color = color_CandleLightGray;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_LIGHT_GRAY_CANDLES_LIT_3:
                color = color_CandleLightGray;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_LIGHT_GRAY_CANDLES_LIT_4:
                color = color_CandleLightGray;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_LIME_CANDLES_LIT_1:
                color = color_CandleLime;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_LIME_CANDLES_LIT_2:
                color = color_CandleLime;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_LIME_CANDLES_LIT_3:
                color = color_CandleLime;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_LIME_CANDLES_LIT_4:
                color = color_CandleLime;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_MAGENTA_CANDLES_LIT_1:
                color = color_CandleMagenta;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_MAGENTA_CANDLES_LIT_2:
                color = color_CandleMagenta;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_MAGENTA_CANDLES_LIT_3:
                color = color_CandleMagenta;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_MAGENTA_CANDLES_LIT_4:
                color = color_CandleMagenta;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_ORANGE_CANDLES_LIT_1:
                color = color_CandleOrange;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_ORANGE_CANDLES_LIT_2:
                color = color_CandleOrange;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_ORANGE_CANDLES_LIT_3:
                color = color_CandleOrange;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_ORANGE_CANDLES_LIT_4:
                color = color_CandleOrange;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_PINK_CANDLES_LIT_1:
                color = color_CandlePink;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_PINK_CANDLES_LIT_2:
                color = color_CandlePink;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_PINK_CANDLES_LIT_3:
                color = color_CandlePink;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_PINK_CANDLES_LIT_4:
                color = color_CandlePink;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_PURPLE_CANDLES_LIT_1:
                color = color_CandlePurple;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_PURPLE_CANDLES_LIT_2:
                color = color_CandlePurple;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_PURPLE_CANDLES_LIT_3:
                color = color_CandlePurple;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_PURPLE_CANDLES_LIT_4:
                color = color_CandlePurple;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_RED_CANDLES_LIT_1:
                color = color_CandleRed;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_RED_CANDLES_LIT_2:
                color = color_CandleRed;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_RED_CANDLES_LIT_3:
                color = color_CandleRed;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_RED_CANDLES_LIT_4:
                color = color_CandleRed;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_WHITE_CANDLES_LIT_1:
                color = color_White;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_WHITE_CANDLES_LIT_2:
                color = color_White;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_WHITE_CANDLES_LIT_3:
                color = color_White;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_WHITE_CANDLES_LIT_4:
                color = color_White;
                range = 12;
                mixWeight = 1.0;
                break;
            case BLOCK_YELLOW_CANDLES_LIT_1:
                color = color_CandleYellow;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_YELLOW_CANDLES_LIT_2:
                color = color_CandleYellow;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_YELLOW_CANDLES_LIT_3:
                color = color_CandleYellow;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_YELLOW_CANDLES_LIT_4:
                color = color_CandleYellow;
                range = 12;
                mixWeight = 1.0;
                break;
        }
    #else
        switch (blockId) {
            case BLOCK_CANDLES_LIT_1:
                color = color_Candle;
                range = 3;
                mixWeight = 1.0;
                break;
            case BLOCK_CANDLES_LIT_2:
                color = color_Candle;
                range = 6;
                mixWeight = 1.0;
                break;
            case BLOCK_CANDLES_LIT_3:
                color = color_Candle;
                range = 9;
                mixWeight = 1.0;
                break;
            case BLOCK_CANDLES_LIT_4:
                color = color_Candle;
                range = 12;
                mixWeight = 1.0;
                break;
        }
    #endif

    switch (blockId) {
        case ITEM_TORCH:
            color = vec3(color_Torch);
            range = 12;
            mixWeight = 1.0;
            break;
        case ITEM_COPPER_TORCH:
            color = vec3(color_CopperTorch);
            range = 14;
            mixWeight = 1.0;
            break;
        case ITEM_SOUL_TORCH:
            color = color_SoulFire;
            range = 10;
            mixWeight = 1.0;
            break;
        case ITEM_REDSTONE_TORCH:
            color = color_RedstoneTorch;
            range = 7;
            mixWeight = 1.0;
            break;
    }

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    #if defined(LIGHTING_COLORED) || defined(PHOTONICS_BLOCK_LIGHT_ENABLED)
        vec4 dataLight = vec4(color / 255.0, range / 32.0);
        imageStore(imgBlockLight, uv, dataLight);
    #endif

    #ifdef LIGHTING_COLORED
        uint dataMask = packUnorm4x8(vec4(mixWeight, 0.0, 0.0, 0.0));
        dataMask = bitfieldInsert(dataMask, mixMask, 8, 8);
        imageStore(imgBlockMask, uv, uvec4(dataMask));
    #endif

    #ifdef WIND_ENABLED
        uint wavingData = bitfieldInsert(0u, uint(wavingBottom * 127.0), 0, 7);
        wavingData = bitfieldInsert(wavingData, uint(wavingTop * 127.0), 7, 7);
        wavingData = bitfieldInsert(wavingData, uint(waveSnap), 14, 1);
        imageStore(imgBlockWaving, uv, uvec4(wavingData));
    #endif
}
