int GetItemBlockId(const in int itemId) {
    int blockId = BLOCK_EMPTY;

    switch (itemId) {
        case ITEM_AMETHYST_BUD_LARGE:
            blockId = BLOCK_AMETHYST_BUD_LARGE;
            break;
        case ITEM_AMETHYST_BUD_MEDIUM:
            blockId = BLOCK_AMETHYST_BUD_MEDIUM;
            break;
        case ITEM_AMETHYST_BUD_SMALL:
            blockId = BLOCK_AMETHYST_BUD_SMALL;
            break;
        case ITEM_AMETHYST_CLUSTER:
            blockId = BLOCK_AMETHYST_CLUSTER;
            break;
        case ITEM_BEACON:
            blockId = BLOCK_BEACON;
            break;
        case ITEM_CRYING_OBSIDIAN:
            blockId = BLOCK_CRYING_OBSIDIAN;
            break;
        case ITEM_END_ROD:
            blockId = BLOCK_END_ROD;
            break;
        case ITEM_FROGLIGHT_OCHRE:
            blockId = BLOCK_FROGLIGHT_OCHRE;
            break;
        case ITEM_FROGLIGHT_PEARLESCENT:
            blockId = BLOCK_FROGLIGHT_PEARLESCENT;
            break;
        case ITEM_FROGLIGHT_VERDANT:
            blockId = BLOCK_FROGLIGHT_VERDANT;
            break;
        case ITEM_GLOW_BERRIES:
            blockId = BLOCK_CAVEVINE_BERRIES;
            break;
        case ITEM_GLOWSTONE:
            blockId = BLOCK_GLOWSTONE;
            break;
        case ITEM_GLOW_LICHEN:
            blockId = BLOCK_GLOW_LICHEN;
            break;
        case ITEM_JACK_O_LANTERN:
            blockId = BLOCK_JACK_O_LANTERN_N;
            break;
        case ITEM_LANTERN:
            blockId = BLOCK_LANTERN_CEIL;
            break;
        case ITEM_LIGHT:
            blockId = BLOCK_LIGHT_12;
            break;
        case ITEM_MAGMA:
            blockId = BLOCK_MAGMA;
            break;
        case ITEM_REDSTONE_TORCH:
            blockId = BLOCK_REDSTONE_TORCH;
            break;
        case ITEM_SCULK_CATALYST:
            blockId = BLOCK_SCULK_CATALYST;
            break;
        case ITEM_SEA_LANTERN:
            blockId = BLOCK_SEA_LANTERN;
            break;
        case ITEM_SHROOMLIGHT:
            blockId = BLOCK_SHROOMLIGHT;
            break;
        case ITEM_SOUL_LANTERN:
            blockId = BLOCK_SOUL_LANTERN_CEIL;
            break;
        case ITEM_SOUL_TORCH:
            blockId = BLOCK_SOUL_TORCH;
            break;
        case ITEM_TORCH:
            blockId = BLOCK_TORCH;
            break;
    }

    #ifdef DYN_LIGHT_OREBLOCKS
        switch (itemId) {
            case ITEM_AMETHYST_BLOCK:
                blockId = BLOCK_AMETHYST;
                break;
            case ITEM_DIAMOND_BLOCK:
                blockId = BLOCK_DIAMOND;
                break;
            case ITEM_EMERALD_BLOCK:
                blockId = BLOCK_EMERALD;
                break;
            case ITEM_LAPIS_BLOCK:
                blockId = BLOCK_LAPIS;
                break;
            case ITEM_REDSTONE_BLOCK:
                blockId = BLOCK_REDSTONE;
                break;
        }
    #endif

    switch (itemId) {
        case ITEM_STREET_LAMP:
            blockId = BLOCK_STREET_LAMP_LIT;
            break;
        case ITEM_SOUL_STREET_LAMP:
            blockId = BLOCK_SOUL_STREET_LAMP_LIT;
            break;
        case ITEM_LAMP_BLACK:
            blockId = BLOCK_LAMP_LIT_BLACK;
            break;
        case ITEM_LAMP_BLUE:
            blockId = BLOCK_LAMP_LIT_BLUE;
            break;
        case ITEM_LAMP_BROWN:
            blockId = BLOCK_LAMP_LIT_BROWN;
            break;
        case ITEM_PAPER_LAMP_BLACK:
            blockId = BLOCK_PAPER_LAMP_LIT_BLACK;
            break;
        case ITEM_PAPER_LAMP_BLUE:
            blockId = BLOCK_PAPER_LAMP_LIT_BLUE;
            break;
        case ITEM_PAPER_LAMP_BROWN:
            blockId = BLOCK_PAPER_LAMP_LIT_BROWN;
            break;
        case ITEM_LAMP_CYAN:
            blockId = BLOCK_LAMP_LIT_CYAN;
            break;
        case ITEM_PAPER_LAMP_CYAN:
            blockId = BLOCK_PAPER_LAMP_LIT_CYAN;
            break;
        case ITEM_LAMP_GRAY:
            blockId = BLOCK_LAMP_LIT_GRAY;
            break;
        case ITEM_PAPER_LAMP_GRAY:
            blockId = BLOCK_PAPER_LAMP_LIT_GRAY;
            break;
        case ITEM_LAMP_GREEN:
            blockId = BLOCK_LAMP_LIT_GREEN;
            break;
        case ITEM_PAPER_LAMP_GREEN:
            blockId = BLOCK_PAPER_LAMP_LIT_GREEN;
            break;
        case ITEM_LAMP_LIGHT_BLUE:
            blockId = BLOCK_LAMP_LIT_LIGHT_BLUE;
            break;
        case ITEM_PAPER_LAMP_LIGHT_BLUE:
            blockId = BLOCK_PAPER_LAMP_LIT_LIGHT_BLUE;
            break;
        case ITEM_LAMP_LIGHT_GRAY:
            blockId = BLOCK_LAMP_LIT_LIGHT_GRAY;
            break;
        case ITEM_PAPER_LAMP_LIGHT_GRAY:
            blockId = BLOCK_PAPER_LAMP_LIT_LIGHT_GRAY;
            break;
        case ITEM_LAMP_LIME:
            blockId = BLOCK_LAMP_LIT_LIME;
            break;
        case ITEM_PAPER_LAMP_LIME:
            blockId = BLOCK_PAPER_LAMP_LIT_LIME;
            break;
        case ITEM_LAMP_MAGENTA:
            blockId = BLOCK_LAMP_LIT_MAGENTA;
            break;
        case ITEM_PAPER_LAMP_MAGENTA:
            blockId = BLOCK_PAPER_LAMP_LIT_MAGENTA;
            break;
        case ITEM_LAMP_ORANGE:
            blockId = BLOCK_LAMP_LIT_ORANGE;
            break;
        case ITEM_PAPER_LAMP_ORANGE:
            blockId = BLOCK_PAPER_LAMP_LIT_ORANGE;
            break;
        case ITEM_LAMP_PINK:
            blockId = BLOCK_LAMP_LIT_PINK;
            break;
        case ITEM_PAPER_LAMP_PINK:
            blockId = BLOCK_PAPER_LAMP_LIT_PINK;
            break;
        case ITEM_LAMP_PURPLE:
            blockId = BLOCK_LAMP_LIT_PURPLE;
            break;
        case ITEM_PAPER_LAMP_PURPLE:
            blockId = BLOCK_PAPER_LAMP_LIT_PURPLE;
            break;
        case ITEM_LAMP_RED:
            blockId = BLOCK_LAMP_LIT_RED;
            break;
        case ITEM_PAPER_LAMP_RED:
            blockId = BLOCK_PAPER_LAMP_LIT_RED;
            break;
        case ITEM_LAMP_WHITE:
            blockId = BLOCK_LAMP_LIT_WHITE;
            break;
        case ITEM_PAPER_LAMP_WHITE:
            blockId = BLOCK_PAPER_LAMP_LIT_WHITE;
            break;
        case ITEM_LAMP_YELLOW:
            blockId = BLOCK_LAMP_LIT_YELLOW;
            break;
        case ITEM_PAPER_LAMP_YELLOW:
            blockId = BLOCK_PAPER_LAMP_LIT_YELLOW;
            break;
    }

    return blockId;
}

vec3 GetSceneItemLightColor(const in int itemId, const in vec2 noiseSample) {
    vec3 lightColor = vec3(0.0);

    #if defined RENDER_HAND && defined IS_IRIS
        uint lightType = GetSceneLightType(itemId);
        if (lightType != LIGHT_EMPTY)
            return GetSceneLightColor(lightType, noiseSample);
    #else
        int blockId = GetItemBlockId(itemId);
        if (blockId != BLOCK_EMPTY) {
            uint lightType = GetSceneLightType(blockId);
            return GetSceneLightColor(lightType, noiseSample);
        }
    #endif

    // switch (itemId) {
    //     case ITEM_AMETHYST_BUD_MEDIUM:
    //         lightColor = vec3(0.447, 0.188, 0.758);
    //         break;
    // }

    // lightColor = RGBToLinear(lightColor);

    // #ifdef DYN_LIGHT_FLICKER
    //     // TODO: optimize branching
    //     //vec2 noiseSample = GetDynLightNoise(cameraPosition + blockLocalPos);
    //     float flickerNoise = GetDynLightFlickerNoise(noiseSample);

    //     if (itemId == ITEM_TORCH || itemId == ITEM_LANTERN) {
    //         float torchTemp = mix(TEMP_FIRE_MIN, TEMP_FIRE_MAX, flickerNoise);
    //         lightColor = 0.8 * blackbody(torchTemp);
    //     }

    //     if (itemId == ITEM_SOUL_TORCH || itemId == ITEM_SOUL_LANTERN) {
    //         float soulTorchTemp = mix(TEMP_SOUL_FIRE_MIN, TEMP_SOUL_FIRE_MAX, 1.0 - flickerNoise);
    //         lightColor = 0.8 * saturate(1.0 - blackbody(soulTorchTemp));
    //     }

    //     if (itemId == ITEM_JACK_O_LANTERN) {
    //         float candleTemp = mix(TEMP_CANDLE_MIN, TEMP_CANDLE_MAX, flickerNoise);
    //         lightColor = 0.7 * blackbody(candleTemp);
    //     }
    // #endif

    return lightColor;
}

float GetSceneItemLightRange(const in int itemId, const in float defaultValue) {
    float lightRange = defaultValue;

    #if defined RENDER_HAND && defined IS_IRIS
        uint lightType = GetSceneLightType(itemId);
        if (lightType != LIGHT_EMPTY)
            return GetSceneLightRange(lightType);
    #else
        int blockId = GetItemBlockId(itemId);
        if (blockId != BLOCK_EMPTY) {
            uint lightType = GetSceneLightType(blockId);
            return GetSceneLightRange(lightType);
        }
    #endif

    // switch (itemId) {
    //     case ITEM_AMETHYST_BUD_LARGE:
    //         lightRange = 4.0;
    //         break;
    //     case ITEM_AMETHYST_BUD_MEDIUM:
    //         lightRange = 2.0;
    //         break;
    //     case ITEM_AMETHYST_CLUSTER:
    //         lightRange = 5.0;
    //         break;
    //     case ITEM_BEACON:
    //         lightRange = 15.0;
    //         break;
    //     case ITEM_GLOW_BERRIES:
    //         lightRange = 14.0;
    //         break;
    //     case ITEM_CRYING_OBSIDIAN:
    //         lightRange = 10.0;
    //         break;
    //     case ITEM_END_ROD:
    //         lightRange = 14.0;
    //         break;
    //     case ITEM_GLOWSTONE:
    //         lightRange = 15.0;
    //         break;
    //     case ITEM_GLOW_LICHEN:
    //         lightRange = 7.0;
    //         break;
    //     case ITEM_JACK_O_LANTERN:
    //         lightRange = 15.0;
    //         break;
    //     case ITEM_LANTERN:
    //         lightRange = 12.0;
    //         break;
    //     case ITEM_MAGMA:
    //         lightRange = 3.0;
    //         break;
    //     case ITEM_FROGLIGHT_OCHRE:
    //         lightRange = 15.0;
    //         break;
    //     case ITEM_FROGLIGHT_PEARLESCENT:
    //         lightRange = 15.0;
    //         break;
    //     case ITEM_REDSTONE_TORCH:
    //         lightRange = 7.0;
    //         break;
    //     case ITEM_SCULK_CATALYST:
    //         lightRange = 6.0;
    //         break;
    //     case ITEM_SEA_LANTERN:
    //         lightRange = 15.0;
    //         break;
    //     case ITEM_SHROOMLIGHT:
    //         lightRange = 15.0;
    //         break;
    //     case ITEM_SOUL_LANTERN:
    //         lightRange = 12.0;
    //         break;
    //     case ITEM_SOUL_TORCH:
    //         lightRange = 12.0;
    //         break;
    //     case ITEM_TORCH:
    //         lightRange = 12.0;
    //         break;
    //     case ITEM_FROGLIGHT_VERDANT:
    //         lightRange = 15.0;
    //         break;
    // }

    // #ifdef DYN_LIGHT_OREBLOCKS
    //     switch (itemId) {
    //         case ITEM_AMETHYST_BLOCK:
    //         case ITEM_DIAMOND_BLOCK:
    //         case ITEM_EMERALD_BLOCK:
    //         case ITEM_LAPIS_BLOCK:
    //         case ITEM_REDSTONE_BLOCK:
    //             lightRange = 12.0;
    //             break;
    //     }
    // #endif

    return lightRange;
}

float GetSceneItemLightSize(const in int itemId) {
    float size = 0.1;

    int blockId = GetItemBlockId(itemId);
    if (blockId != BLOCK_EMPTY) {
        uint lightType = GetSceneLightType(blockId);
        return GetSceneLightSize(lightType);
    }

    // switch (itemId) {
    //     case ITEM_AMETHYST_BLOCK:
    //     case ITEM_CRYING_OBSIDIAN:
    //     case ITEM_FROGLIGHT_OCHRE:
    //     case ITEM_FROGLIGHT_PEARLESCENT:
    //     case ITEM_FROGLIGHT_VERDANT:
    //     case ITEM_GLOWSTONE:
    //     case ITEM_MAGMA:
    //     case ITEM_SEA_LANTERN:
    //     case ITEM_SHROOMLIGHT:
    //         size = 1.0;
    //         break;
    //     case ITEM_AMETHYST_CLUSTER:
    //         size = 0.8;
    //         break;
    //     case ITEM_AMETHYST_BUD_LARGE:
    //     case ITEM_BEACON:
    //     case ITEM_JACK_O_LANTERN:
    //         size = 0.6;
    //         break;
    //     case ITEM_END_ROD:
    //         size = 0.5;
    //     case ITEM_AMETHYST_BUD_MEDIUM:
    //     case ITEM_LANTERN:
    //     case ITEM_SOUL_LANTERN:
    //         size = 0.4;
    //         break;
    //     case ITEM_TORCH:
    //     case ITEM_SOUL_TORCH:
    //         size = 0.2;
    //         break;
    // }

    return size;
}
