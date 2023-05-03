vec3 GetSceneItemLightColor(const in int itemId, const in vec2 noiseSample) {
    vec3 lightColor = vec3(0.0);

    switch (itemId) {
        case ITEM_AMETHYST_CLUSTER:
        case ITEM_AMETHYST_BUD_LARGE:
        case ITEM_AMETHYST_BUD_MEDIUM:
            lightColor = vec3(0.447, 0.188, 0.758);
            break;
        case ITEM_BEACON:
            lightColor = vec3(1.0, 1.0, 1.0);
            break;
        case ITEM_GLOW_BERRIES:
            lightColor = 0.4 * vec3(0.717, 0.541, 0.188);
            break;
        case ITEM_CRYING_OBSIDIAN:
            lightColor = vec3(0.390, 0.065, 0.646);
            break;
        case ITEM_END_ROD:
            lightColor = vec3(0.957, 0.929, 0.875);
            break;
        case ITEM_GLOWSTONE:
            lightColor = vec3(0.652, 0.583, 0.275);
            break;
        case ITEM_GLOW_LICHEN:
            lightColor = vec3(0.173, 0.374, 0.252);
            break;
        case ITEM_JACK_O_LANTERN:
            lightColor = vec3(0.768, 0.701, 0.325);
            break;
        case ITEM_LANTERN:
            lightColor = vec3(0.906, 0.737, 0.451);
            break;
        case ITEM_LIGHT:
            lightColor = vec3(1.0);
            break;
        case ITEM_MAGMA:
            lightColor = vec3(0.747, 0.323, 0.110);
            break;
        case ITEM_FROGLIGHT_OCHRE:
            lightColor = vec3(0.768, 0.648, 0.108);
            break;
        case ITEM_FROGLIGHT_PEARLESCENT:
            lightColor = vec3(0.737, 0.435, 0.658);
            break;
        case ITEM_REDSTONE_TORCH:
            lightColor = vec3(0.697, 0.130, 0.051);
            break;
        case ITEM_SCULK_CATALYST:
            lightColor = vec3(0.510, 0.831, 0.851);
            break;
        case ITEM_SEA_LANTERN:
            lightColor = vec3(0.570, 0.780, 0.800);
            break;
        case ITEM_SHROOMLIGHT:
            lightColor = vec3(0.848, 0.469, 0.205);
            break;
        case ITEM_SOUL_LANTERN:
        case ITEM_SOUL_TORCH:
            lightColor = vec3(0.203, 0.725, 0.758);
            break;
        case ITEM_TORCH:
            lightColor = vec3(0.768, 0.701, 0.325);
            break;
        case ITEM_FROGLIGHT_VERDANT:
            lightColor = vec3(0.463, 0.763, 0.409);
            break;
    }

    #ifdef DYN_LIGHT_OREBLOCKS
        switch (itemId) {
            case ITEM_AMETHYST_BLOCK:
                lightColor = vec3(0.600, 0.439, 0.820);
                break;
            case ITEM_DIAMOND_BLOCK:
                lightColor = vec3(0.489, 0.960, 0.912);
                break;
            case ITEM_EMERALD_BLOCK:
                lightColor = vec3(0.235, 0.859, 0.435);
                break;
            case ITEM_LAPIS_BLOCK:
                lightColor = vec3(0.180, 0.427, 0.813);
                break;
            case ITEM_REDSTONE_BLOCK:
                lightColor = vec3(0.980, 0.143, 0.026);
                break;
        }
    #endif

    lightColor = RGBToLinear(lightColor);

    #ifdef DYN_LIGHT_FLICKER
        // TODO: optimize branching
        //vec2 noiseSample = GetDynLightNoise(cameraPosition + blockLocalPos);
        float flickerNoise = GetDynLightFlickerNoise(noiseSample);

        if (itemId == ITEM_TORCH || itemId == ITEM_LANTERN) {
            float torchTemp = mix(TEMP_FIRE_MIN, TEMP_FIRE_MAX, flickerNoise);
            lightColor = 0.8 * blackbody(torchTemp);
        }

        if (itemId == ITEM_SOUL_TORCH || itemId == ITEM_SOUL_LANTERN) {
            float soulTorchTemp = mix(TEMP_SOUL_FIRE_MIN, TEMP_SOUL_FIRE_MAX, 1.0 - flickerNoise);
            lightColor = 0.8 * saturate(1.0 - blackbody(soulTorchTemp));
        }

        if (itemId == ITEM_JACK_O_LANTERN) {
            float candleTemp = mix(TEMP_CANDLE_MIN, TEMP_CANDLE_MAX, flickerNoise);
            lightColor = 0.7 * blackbody(candleTemp);
        }
    #endif

    return lightColor;
}

float GetSceneItemLightRange(const in int itemId, const in float defaultValue) {
    float lightRange = defaultValue;

    switch (itemId) {
        case ITEM_AMETHYST_BUD_LARGE:
            lightRange = 4.0;
            break;
        case ITEM_AMETHYST_BUD_MEDIUM:
            lightRange = 2.0;
            break;
        case ITEM_AMETHYST_CLUSTER:
            lightRange = 5.0;
            break;
        case ITEM_BEACON:
            lightRange = 15.0;
            break;
        case ITEM_GLOW_BERRIES:
            lightRange = 14.0;
            break;
        case ITEM_CRYING_OBSIDIAN:
            lightRange = 10.0;
            break;
        case ITEM_END_ROD:
            lightRange = 14.0;
            break;
        case ITEM_GLOWSTONE:
            lightRange = 15.0;
            break;
        case ITEM_GLOW_LICHEN:
            lightRange = 7.0;
            break;
        case ITEM_JACK_O_LANTERN:
            lightRange = 15.0;
            break;
        case ITEM_LANTERN:
            lightRange = 12.0;
            break;
        case ITEM_MAGMA:
            lightRange = 3.0;
            break;
        case ITEM_FROGLIGHT_OCHRE:
            lightRange = 15.0;
            break;
        case ITEM_FROGLIGHT_PEARLESCENT:
            lightRange = 15.0;
            break;
        case ITEM_REDSTONE_TORCH:
            lightRange = 7.0;
            break;
        case ITEM_SCULK_CATALYST:
            lightRange = 6.0;
            break;
        case ITEM_SEA_LANTERN:
            lightRange = 15.0;
            break;
        case ITEM_SHROOMLIGHT:
            lightRange = 15.0;
            break;
        case ITEM_SOUL_LANTERN:
            lightRange = 12.0;
            break;
        case ITEM_SOUL_TORCH:
            lightRange = 12.0;
            break;
        case ITEM_TORCH:
            lightRange = 12.0;
            break;
        case ITEM_FROGLIGHT_VERDANT:
            lightRange = 15.0;
            break;
    }

    #ifdef DYN_LIGHT_OREBLOCKS
        switch (itemId) {
            case ITEM_AMETHYST_BLOCK:
            case ITEM_DIAMOND_BLOCK:
            case ITEM_EMERALD_BLOCK:
            case ITEM_LAPIS_BLOCK:
            case ITEM_REDSTONE_BLOCK:
                lightRange = 12.0;
                break;
        }
    #endif

    return lightRange;
}

float GetSceneItemLightSize(const in int itemId) {
    float size = 0.1;

    switch (itemId) {
        case ITEM_AMETHYST_BLOCK:
        case ITEM_CRYING_OBSIDIAN:
        case ITEM_FROGLIGHT_OCHRE:
        case ITEM_FROGLIGHT_PEARLESCENT:
        case ITEM_FROGLIGHT_VERDANT:
        case ITEM_GLOWSTONE:
        case ITEM_MAGMA:
        case ITEM_SEA_LANTERN:
        case ITEM_SHROOMLIGHT:
            size = 1.0;
            break;
        case ITEM_AMETHYST_CLUSTER:
            size = 0.8;
            break;
        case ITEM_AMETHYST_BUD_LARGE:
        case ITEM_BEACON:
        case ITEM_JACK_O_LANTERN:
            size = 0.6;
            break;
        case ITEM_END_ROD:
            size = 0.5;
        case ITEM_AMETHYST_BUD_MEDIUM:
        case ITEM_LANTERN:
        case ITEM_SOUL_LANTERN:
            size = 0.4;
            break;
        case ITEM_TORCH:
        case ITEM_SOUL_TORCH:
            size = 0.2;
            break;
    }

    //if (itemId == BLOCK_CAVEVINE_BERRIES) size = 0.4;

    return size;
}
