uint GetItemLightId(const in int itemId) {
    uint lightId = LIGHT_NONE;

    switch (itemId) {
        case ITEM_AMETHYST_BUD_LARGE:
            lightId = LIGHT_AMETHYST_BUD_LARGE;
            break;
        case ITEM_AMETHYST_BUD_MEDIUM:
            lightId = LIGHT_AMETHYST_BUD_MEDIUM;
            break;
        // case ITEM_AMETHYST_BUD_SMALL:
        //     lightId = LIGHT_AMETHYST_BUD_SMALL;
        //     break;
        case ITEM_AMETHYST_CLUSTER:
            lightId = LIGHT_AMETHYST_CLUSTER;
            break;
        case ITEM_BEACON:
            lightId = LIGHT_BEACON;
            break;
        case ITEM_BLAZE_ROD:
            lightId = LIGHT_CAVEVINE_BERRIES;
            break;
        case ITEM_CRYING_OBSIDIAN:
            lightId = LIGHT_CRYING_OBSIDIAN;
            break;
        case ITEM_END_ROD:
            lightId = LIGHT_END_ROD;
            break;
        case ITEM_FROGLIGHT_OCHRE:
            lightId = LIGHT_FROGLIGHT_OCHRE;
            break;
        case ITEM_FROGLIGHT_PEARLESCENT:
            lightId = LIGHT_FROGLIGHT_PEARLESCENT;
            break;
        case ITEM_FROGLIGHT_VERDANT:
            lightId = LIGHT_FROGLIGHT_VERDANT;
            break;
        case ITEM_GLOW_BERRIES:
            lightId = LIGHT_CAVEVINE_BERRIES;
            break;
        case ITEM_GLOWSTONE:
            lightId = LIGHT_GLOWSTONE;
            break;
        case ITEM_GLOWSTONE_DUST:
            lightId = LIGHT_GLOWSTONE_DUST;
            break;
        case ITEM_GLOW_LICHEN:
            lightId = LIGHT_GLOW_LICHEN;
            break;
        case ITEM_JACK_O_LANTERN:
            lightId = LIGHT_JACK_O_LANTERN_N;
            break;
        case ITEM_LANTERN:
            lightId = LIGHT_LANTERN;
            break;
        case ITEM_LIGHT:
            lightId = LIGHT_BLOCK_12;
            break;
        case ITEM_MAGMA:
            lightId = LIGHT_MAGMA;
            break;
        case ITEM_REDSTONE_TORCH:
            lightId = LIGHT_REDSTONE_TORCH_FLOOR;
            break;
        case ITEM_SCULK_CATALYST:
            lightId = LIGHT_SCULK_CATALYST;
            break;
        case ITEM_SEA_LANTERN:
            lightId = LIGHT_SEA_LANTERN;
            break;
        case ITEM_SHROOMLIGHT:
            lightId = LIGHT_SHROOMLIGHT;
            break;
        case ITEM_SOUL_LANTERN:
            lightId = LIGHT_SOUL_LANTERN;
            break;
        case ITEM_SOUL_TORCH:
            lightId = LIGHT_SOUL_TORCH_FLOOR;
            break;
        case ITEM_TORCH:
            lightId = LIGHT_TORCH_FLOOR;
            break;
    }

    #ifdef DYN_LIGHT_OREBLOCKS
        switch (itemId) {
            case ITEM_AMETHYST_BLOCK:
                lightId = LIGHT_AMETHYST;
                break;
            case ITEM_DIAMOND_BLOCK:
                lightId = LIGHT_DIAMOND;
                break;
            case ITEM_EMERALD_BLOCK:
                lightId = LIGHT_EMERALD;
                break;
            case ITEM_LAPIS_BLOCK:
                lightId = LIGHT_LAPIS;
                break;
            case ITEM_REDSTONE_BLOCK:
                lightId = LIGHT_REDSTONE;
                break;
        }
    #endif

    switch (itemId) {
        case ITEM_STREET_LAMP:
            lightId = LIGHT_STREET_LAMP;
            break;
        case ITEM_SOUL_STREET_LAMP:
            lightId = LIGHT_SOUL_STREET_LAMP;
            break;
        case ITEM_LAMP_BLACK:
            lightId = LIGHT_PAPER_LAMP_BLACK;
            break;
        case ITEM_LAMP_BLUE:
            lightId = LIGHT_PAPER_LAMP_BLUE;
            break;
        case ITEM_LAMP_BROWN:
            lightId = LIGHT_PAPER_LAMP_BROWN;
            break;
        case ITEM_PAPER_LAMP_BLACK:
            lightId = LIGHT_PAPER_LAMP_BLACK;
            break;
        case ITEM_PAPER_LAMP_BLUE:
            lightId = LIGHT_PAPER_LAMP_BLUE;
            break;
        case ITEM_PAPER_LAMP_BROWN:
            lightId = LIGHT_PAPER_LAMP_BROWN;
            break;
        case ITEM_LAMP_CYAN:
            lightId = LIGHT_PAPER_LAMP_CYAN;
            break;
        case ITEM_PAPER_LAMP_CYAN:
            lightId = LIGHT_PAPER_LAMP_CYAN;
            break;
        case ITEM_LAMP_GRAY:
            lightId = LIGHT_PAPER_LAMP_GRAY;
            break;
        case ITEM_PAPER_LAMP_GRAY:
            lightId = LIGHT_PAPER_LAMP_GRAY;
            break;
        case ITEM_LAMP_GREEN:
            lightId = LIGHT_PAPER_LAMP_GREEN;
            break;
        case ITEM_PAPER_LAMP_GREEN:
            lightId = LIGHT_PAPER_LAMP_GREEN;
            break;
        case ITEM_LAMP_LIGHT_BLUE:
            lightId = LIGHT_PAPER_LAMP_LIGHT_BLUE;
            break;
        case ITEM_PAPER_LAMP_LIGHT_BLUE:
            lightId = LIGHT_PAPER_LAMP_LIGHT_BLUE;
            break;
        case ITEM_LAMP_LIGHT_GRAY:
            lightId = LIGHT_PAPER_LAMP_LIGHT_GRAY;
            break;
        case ITEM_PAPER_LAMP_LIGHT_GRAY:
            lightId = LIGHT_PAPER_LAMP_LIGHT_GRAY;
            break;
        case ITEM_LAMP_LIME:
            lightId = LIGHT_PAPER_LAMP_LIME;
            break;
        case ITEM_PAPER_LAMP_LIME:
            lightId = LIGHT_PAPER_LAMP_LIME;
            break;
        case ITEM_LAMP_MAGENTA:
            lightId = LIGHT_PAPER_LAMP_MAGENTA;
            break;
        case ITEM_PAPER_LAMP_MAGENTA:
            lightId = LIGHT_PAPER_LAMP_MAGENTA;
            break;
        case ITEM_LAMP_ORANGE:
            lightId = LIGHT_PAPER_LAMP_ORANGE;
            break;
        case ITEM_PAPER_LAMP_ORANGE:
            lightId = LIGHT_PAPER_LAMP_ORANGE;
            break;
        case ITEM_LAMP_PINK:
            lightId = LIGHT_PAPER_LAMP_PINK;
            break;
        case ITEM_PAPER_LAMP_PINK:
            lightId = LIGHT_PAPER_LAMP_PINK;
            break;
        case ITEM_LAMP_PURPLE:
            lightId = LIGHT_PAPER_LAMP_PURPLE;
            break;
        case ITEM_PAPER_LAMP_PURPLE:
            lightId = LIGHT_PAPER_LAMP_PURPLE;
            break;
        case ITEM_LAMP_RED:
            lightId = LIGHT_PAPER_LAMP_RED;
            break;
        case ITEM_PAPER_LAMP_RED:
            lightId = LIGHT_PAPER_LAMP_RED;
            break;
        case ITEM_LAMP_WHITE:
            lightId = LIGHT_PAPER_LAMP_WHITE;
            break;
        case ITEM_PAPER_LAMP_WHITE:
            lightId = LIGHT_PAPER_LAMP_WHITE;
            break;
        case ITEM_LAMP_YELLOW:
            lightId = LIGHT_PAPER_LAMP_YELLOW;
            break;
        case ITEM_PAPER_LAMP_YELLOW:
            lightId = LIGHT_PAPER_LAMP_YELLOW;
            break;
    }

    return lightId;
}
