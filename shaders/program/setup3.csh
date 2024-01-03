#define RENDER_SETUP_STATIC_BLOCK
#define RENDER_SETUP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(4, 5, 1);

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/blocks.glsl"
    #include "/lib/lights.glsl"

    #include "/lib/buffers/static_block.glsl"

    #include "/lib/world/waving_blocks.glsl"
    #include "/lib/material/specular_blocks.glsl"
    #include "/lib/material/subsurface_blocks.glsl"
    #include "/lib/lighting/voxel/block_light_map.glsl"
#endif


void main() {
    #ifdef IRIS_FEATURE_SSBO
        uint blockId = uint(gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 32);
        //if (blockId >= 1280) return;

        StaticBlockData block;
        // block.materialRough = 0.95;

        GetBlockWavingRangeAttachment(blockId, block.wavingRange, block.wavingAttachment);

        block.materialRough = GetBlockRoughness(blockId);
        block.materialMetalF0 = GetBlockMetalF0(blockId);
        block.materialSSS = GetBlockSSS(blockId);

        block.lightType = GetSceneLightType(blockId);

        // // 100
        // switch (blockId) {
        //     case BLOCK_BROWN_MUSHROOM_PLANT:
        //     case BLOCK_LILY_PAD:
        //     case BLOCK_NETHER_WART:
        //     case BLOCK_RED_MUSHROOM_PLANT:
        //         block.materialSSS = 0.2;
        //         break;
        //     case BLOCK_AZALEA:
        //     case BLOCK_BIG_DRIPLEAF:
        //     case BLOCK_BIG_DRIPLEAF_STEM:
        //     case BLOCK_CAVE_VINE:
        //     case BLOCK_CAVEVINE_BERRIES:
        //     case BLOCK_FERN:
        //     case BLOCK_KELP:
        //     case BLOCK_LARGE_FERN_LOWER:
        //     case BLOCK_LARGE_FERN_UPPER:
        //     case BLOCK_SAPLING:
        //     case BLOCK_SEAGRASS:
        //     case BLOCK_SMALL_DRIPLEAF:
        //     case BLOCK_SWEET_BERRY_BUSH:
        //     case BLOCK_TWISTING_VINES:
        //     case BLOCK_VINE:
        //     case BLOCK_WEEPING_VINES:
        //         block.materialSSS = 0.4;
        //         break;
        //     case BLOCK_ALLIUM:
        //     case BLOCK_AZURE_BLUET:
        //     case BLOCK_BEETROOTS:
        //     case BLOCK_BLUE_ORCHID:
        //     case BLOCK_CARROTS:
        //     case BLOCK_CORNFLOWER:
        //     case BLOCK_DANDELION:
        //     case BLOCK_LILAC_LOWER:
        //     case BLOCK_LILAC_UPPER:
        //     case BLOCK_LILY_OF_THE_VALLEY:
        //     case BLOCK_OXEYE_DAISY:
        //     case BLOCK_PEONY_LOWER:
        //     case BLOCK_PEONY_UPPER:
        //     case BLOCK_POPPY:
        //     case BLOCK_POTATOES:
        //     case BLOCK_ROSE_BUSH_LOWER:
        //     case BLOCK_ROSE_BUSH_UPPER:
        //     case BLOCK_SPORE_BLOSSOM:
        //     case BLOCK_SUNFLOWER_LOWER:
        //     case BLOCK_SUNFLOWER_UPPER:
        //     case BLOCK_TULIP:
        //     case BLOCK_WHEAT:
        //     case BLOCK_WITHER_ROSE:
        //         block.materialSSS = 0.6;
        //         break;
        //     case BLOCK_GRASS:
        //     case BLOCK_TALL_GRASS_UPPER:
        //     case BLOCK_TALL_GRASS_LOWER:
        //         block.materialSSS = 0.8;
        //         break;
        // }

        // // 200
        // switch (blockId) {
        //     case BLOCK_AMETHYST:
        //     case BLOCK_AMETHYST_CLUSTER:
        //     case BLOCK_AMETHYST_BUD_LARGE:
        //     case BLOCK_AMETHYST_BUD_SMALL:
        //         smoothness = 0.8;
        //         break;
        //     case BLOCK_CRYING_OBSIDIAN:
        //         smoothness = 0.75;
        //         break;
        //     case BLOCK_DIAMOND:
        //         smoothness = 0.85;
        //         break;
        //     case BLOCK_EMERALD:
        //     case BLOCK_LAPIS:
        //         smoothness = 0.70;
        //         break;
        //     case BLOCK_REDSTONE:
        //         smoothness = 0.80;
        //         break;
        // }

        StaticBlockMap[blockId] = block;
    #endif
}
