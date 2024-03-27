void GetBlockWavingRangeAttachment(const in uint blockId, out float range, out uint attachment) {
    range = 0.0;
    attachment = 0u;

    switch (blockId) {
        case BLOCK_DEAD_BUSH:
        case BLOCK_NETHER_SPROUTS:
        case BLOCK_SUNFLOWER_LOWER:
        case BLOCK_SWEET_BERRY_BUSH:
            // slow, attach bottom
            range = 0.01;
            attachment = 1u;
            break;
        case BLOCK_HANGING_ROOTS:
            // slow, attach top
            range = 0.01;
            attachment = 2u;
            break;
        case BLOCK_ALLIUM:
        case BLOCK_AZURE_BLUET:
        case BLOCK_BEETROOTS:
        case BLOCK_BLUE_ORCHID:
        case BLOCK_CARROTS:
        case BLOCK_CORNFLOWER:
        case BLOCK_CRIMSON_ROOTS:
        case BLOCK_DANDELION:
        case BLOCK_FERN:
        case BLOCK_GRASS:
        case BLOCK_LARGE_FERN_LOWER:
        case BLOCK_LILAC_LOWER:
        case BLOCK_LILY_OF_THE_VALLEY:
        case BLOCK_OXEYE_DAISY:
        case BLOCK_PEONY_LOWER:
        case BLOCK_POPPY:
        case BLOCK_POTATOES:
        case BLOCK_ROSE_BUSH_LOWER:
        case BLOCK_SAPLING:
        case BLOCK_TALL_GRASS_LOWER:
        case BLOCK_TULIP:
        case BLOCK_WARPED_ROOTS:
        case BLOCK_WHEAT:
        case BLOCK_WITHER_ROSE:
            // fast, attach bottom
            range = 0.06;
            attachment = 1u;
            break;
        case BLOCK_SUNFLOWER_UPPER:
            // slow, no attachment
            range = 0.01;
            break;
        case BLOCK_LARGE_FERN_UPPER:
        case BLOCK_LILAC_UPPER:
        case BLOCK_PEONY_UPPER:
        case BLOCK_ROSE_BUSH_UPPER:
        case BLOCK_TALL_GRASS_UPPER:
            // fast, no attachment
            range = 0.06;
            break;
    }

    if (blockId == BLOCK_LEAVES || blockId == BLOCK_LEAVES_CHERRY) range = 0.06;
}
