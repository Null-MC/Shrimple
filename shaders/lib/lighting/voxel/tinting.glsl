vec3 GetLightGlassTint(const in uint blockId) {
    vec3 stepTint = vec3(1.0);

    switch (blockId) {
        case BLOCK_HONEY:
            stepTint = vec3(0.984, 0.733, 0.251);
            break;
        case BLOCK_LEAVES:
            stepTint = vec3(0.718, 0.741, 0.71);
            break;
        case BLOCK_LEAVES_CHERRY:
            stepTint = vec3(0.9, 0.2, 0.2);
            break;
        case BLOCK_ROOTS:
            stepTint = vec3(0.650, 0.700, 0.650);
            break;
        case BLOCK_SLIME:
            stepTint = vec3(0.408, 0.725, 0.329);
            break;
        case BLOCK_SNOW:
            stepTint = vec3(0.375, 0.546, 0.621);
            break;
        case BLOCK_STAINED_GLASS_BLACK:
            stepTint = vec3(0.3, 0.3, 0.3);
            break;
        case BLOCK_STAINED_GLASS_BLUE:
            stepTint = vec3(0.1, 0.1, 0.98);
            break;
        case BLOCK_STAINED_GLASS_BROWN:
            stepTint = vec3(0.566, 0.388, 0.148);
            break;
        case BLOCK_STAINED_GLASS_CYAN:
            stepTint = vec3(0.082, 0.533, 0.763);
            break;
        case BLOCK_STAINED_GLASS_GRAY:
            stepTint = vec3(0.4, 0.4, 0.4);
            break;
        case BLOCK_STAINED_GLASS_GREEN:
            stepTint = vec3(0.125, 0.808, 0.081);
            break;
        case BLOCK_STAINED_GLASS_LIGHT_BLUE:
            stepTint = vec3(0.320, 0.685, 0.955);
            break;
        case BLOCK_STAINED_GLASS_LIGHT_GRAY:
            stepTint = vec3(0.7, 0.7, 0.7);
            break;
        case BLOCK_STAINED_GLASS_LIME:
            stepTint = vec3(0.633, 0.924, 0.124);
            break;
        case BLOCK_STAINED_GLASS_MAGENTA:
            stepTint = vec3(0.698, 0.298, 0.847);
            break;
        case BLOCK_STAINED_GLASS_ORANGE:
            stepTint = vec3(0.919, 0.586, 0.185);
            break;
        case BLOCK_STAINED_GLASS_PINK:
            stepTint = vec3(0.949, 0.274, 0.497);
            break;
        case BLOCK_STAINED_GLASS_PURPLE:
            stepTint = vec3(0.578, 0.170, 0.904);
            break;
        case BLOCK_STAINED_GLASS_RED:
            stepTint = vec3(0.999, 0.188, 0.188);
            break;
        case BLOCK_STAINED_GLASS_WHITE:
            stepTint = vec3(0.96, 0.96, 0.96);
            break;
        case BLOCK_STAINED_GLASS_YELLOW:
            stepTint = vec3(0.965, 0.965, 0.123);
            break;
        case BLOCK_TINTED_GLASS:
            stepTint = vec3(0.2, 0.1, 0.2);
            break;
    }

    return RGBToLinear(stepTint);
}
