bool IsFoliageBlock(const in int blockId) {
    bool result = false;

    switch (blockId) {
        case BLOCK_LEAVES:
        case BLOCK_ALLIUM:
        case BLOCK_AZURE_BLUET:
        case BLOCK_BEETROOTS:
        case BLOCK_BLUE_ORCHID:
        case BLOCK_CARROTS:
        case BLOCK_CAVE_VINE:
        case BLOCK_CAVEVINE_BERRIES:
        case BLOCK_CORNFLOWER:
        case BLOCK_DANDELION:
        case BLOCK_FERN:
        case BLOCK_GRASS:
        case BLOCK_KELP:
        case BLOCK_LARGE_FERN_LOWER:
        case BLOCK_LARGE_FERN_UPPER:
        case BLOCK_LILAC_LOWER:
        case BLOCK_LILAC_UPPER:
        case BLOCK_LILY_OF_THE_VALLEY:
        case BLOCK_OXEYE_DAISY:
        case BLOCK_PEONY_LOWER:
        case BLOCK_PEONY_UPPER:
        case BLOCK_POPPY:
        case BLOCK_POTATOES:
        case BLOCK_ROSE_BUSH_LOWER:
        case BLOCK_ROSE_BUSH_UPPER:
        case BLOCK_SAPLING:
        case BLOCK_SEAGRASS:
        case BLOCK_SUGAR_CANE:
        case BLOCK_SUNFLOWER_LOWER:
        case BLOCK_SUNFLOWER_UPPER:
        case BLOCK_SWEET_BERRY_BUSH:
        case BLOCK_TALL_GRASS_LOWER:
        case BLOCK_TALL_GRASS_UPPER:
        case BLOCK_TULIP:
        case BLOCK_WHEAT:
        case BLOCK_WITHER_ROSE:
            result = true;
            break;
    }

    return result;
}
