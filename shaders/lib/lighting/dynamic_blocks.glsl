#if DYN_LIGHT_PT > 0
    bool IsDynLightSolidBlock(const in int blockId) {
        if (blockId == BLOCK_WATER) return false;
        if (blockId >= 200 && blockId < 400) {
            if (blockId == BLOCK_SLABS_BOTTOM || blockId == BLOCK_SLABS_TOP) return true;
            return false;
        }
        return true;
    }
#endif

#ifdef DYN_LIGHT_FLICKER
    vec2 GetDynLightNoise(const in vec3 blockLocalPos) {
        float time = frameTimeCounter / 3600.0;
        vec3 worldPos = cameraPosition + blockLocalPos;

        vec3 texPos = fract(worldPos.xzy * vec3(0.04, 0.04, 0.08));
        texPos.z += 200.0 * time;

        return texture(TEX_LIGHT_NOISE, vec2(0.3, 0.6)*texPos.y + texPos.xz).rg;
    }

    float GetDynLightFlickerNoise(const in vec2 noiseSample) {
        //vec2 noiseSample = GetDynLightNoise(blockLocalPos);
        return (1.0 - noiseSample.g) * (1.0 - pow2(noiseSample.r));
    }
#endif

vec3 GetSceneBlockLightColor(const in int blockId, const in vec2 noiseSample) {
    vec3 lightColor = vec3(0.0);
    switch (blockId) {
        case BLOCK_AMETHYST_CLUSTER:
        case BLOCK_AMETHYST_BUD_LARGE:
        case BLOCK_AMETHYST_BUD_MEDIUM:
        case ITEM_AMETHYST_CLUSTER:
        case ITEM_AMETHYST_BUD_LARGE:
        case ITEM_AMETHYST_BUD_MEDIUM:
            lightColor = vec3(0.447, 0.188, 0.758);
            break;
        case BLOCK_BEACON:
        case ITEM_BEACON:
            lightColor = vec3(1.0, 1.0, 1.0);
            break;
        case BLOCK_BLAST_FURNACE_LIT:
            lightColor = vec3(0.697, 0.654, 0.458);
            break;
        case BLOCK_BREWING_STAND:
            lightColor = vec3(0.636, 0.509, 0.179);
            break;
        case BLOCK_CANDLES_LIT_1:
        case BLOCK_CANDLES_LIT_2:
        case BLOCK_CANDLES_LIT_3:
        case BLOCK_CANDLES_LIT_4:
        case BLOCK_CANDLE_CAKE_LIT:
            lightColor = vec3(0.758, 0.553, 0.239);
            break;
        case BLOCK_CAVEVINE_BERRIES:
        case ITEM_GLOW_BERRIES:
            lightColor = 0.4 * vec3(0.717, 0.541, 0.188);
            break;
        case BLOCK_CRYING_OBSIDIAN:
        case ITEM_CRYING_OBSIDIAN:
            lightColor = vec3(0.390, 0.065, 0.646);
            break;
        case BLOCK_END_ROD:
        case ITEM_END_ROD:
            lightColor = vec3(0.957, 0.929, 0.875);
            break;
        case BLOCK_FIRE:
            lightColor = vec3(0.851, 0.616, 0.239);
            break;
        case BLOCK_FURNACE_LIT:
            lightColor = vec3(0.697, 0.654, 0.458);
            break;
        case BLOCK_GLOWSTONE:
        case ITEM_GLOWSTONE:
            lightColor = vec3(0.652, 0.583, 0.275);
            break;
        case BLOCK_GLOW_LICHEN:
        case ITEM_GLOW_LICHEN:
            lightColor = vec3(0.332, 0.495, 0.367);
            break;
        case BLOCK_JACK_O_LANTERN:
        case ITEM_JACK_O_LANTERN:
            lightColor = vec3(0.768, 0.701, 0.325);
            break;
        case BLOCK_LANTERN:
        case ITEM_LANTERN:
            lightColor = vec3(0.906, 0.737, 0.451);
            break;
        case BLOCK_LIGHTING_ROD_POWERED:
            lightColor = vec3(0.870, 0.956, 0.975);
            break;
        case BLOCK_LAVA:
        case BLOCK_LAVA_CAULDRON:
            lightColor = vec3(0.804, 0.424, 0.149);
            break;
        case BLOCK_MAGMA:
        case ITEM_MAGMA:
            lightColor = vec3(0.747, 0.323, 0.110);
            break;
        case BLOCK_NETHER_PORTAL:
            lightColor = vec3(0.502, 0.165, 0.831);
            break;
        case BLOCK_FROGLIGHT_OCHRE:
        case ITEM_FROGLIGHT_OCHRE:
            lightColor = vec3(0.768, 0.648, 0.108);
            break;
        case BLOCK_FROGLIGHT_PEARLESCENT:
        case ITEM_FROGLIGHT_PEARLESCENT:
            lightColor = vec3(0.737, 0.435, 0.658);
            break;
        case BLOCK_REDSTONE_LAMP:
            lightColor = vec3(0.953, 0.796, 0.496);
            break;
        case BLOCK_REDSTONE_TORCH:
        case ITEM_REDSTONE_TORCH:
            lightColor = vec3(0.697, 0.130, 0.051);
            break;
        case BLOCK_RESPAWN_ANCHOR_4:
        case BLOCK_RESPAWN_ANCHOR_3:
        case BLOCK_RESPAWN_ANCHOR_2:
        case BLOCK_RESPAWN_ANCHOR_1:
            lightColor = vec3(0.390, 0.065, 0.646);
            break;
        case BLOCK_SCULK_CATALYST:
        case ITEM_SCULK_CATALYST:
            lightColor = vec3(0.510, 0.831, 0.851);
            break;
        case BLOCK_SEA_LANTERN:
        case ITEM_SEA_LANTERN:
            lightColor = vec3(0.498, 0.894, 0.834);
            break;
        case BLOCK_SEA_PICKLE_WET_1:
        case BLOCK_SEA_PICKLE_WET_2:
        case BLOCK_SEA_PICKLE_WET_3:
        case BLOCK_SEA_PICKLE_WET_4:
            lightColor = vec3(0.498, 0.894, 0.834);
            break;
        case BLOCK_SHROOMLIGHT:
        case ITEM_SHROOMLIGHT:
            lightColor = vec3(0.848, 0.469, 0.205);
            break;
        case BLOCK_SMOKER_LIT:
            lightColor = vec3(0.697, 0.654, 0.458);
            break;
        case BLOCK_SOUL_LANTERN:
        case BLOCK_SOUL_TORCH:
        case ITEM_SOUL_LANTERN:
        case ITEM_SOUL_TORCH:
            lightColor = vec3(0.203, 0.725, 0.758);
            break;
        case BLOCK_TORCH:
        case ITEM_TORCH:
            lightColor = vec3(0.768, 0.701, 0.325);
            break;
        case BLOCK_FROGLIGHT_VERDANT:
        case ITEM_FROGLIGHT_VERDANT:
            lightColor = vec3(0.463, 0.763, 0.409);
            break;
    }

    lightColor = RGBToLinear(lightColor);

    #ifdef DYN_LIGHT_FLICKER
        // TODO: optimize branching
        //vec2 noiseSample = GetDynLightNoise(blockLocalPos);
        float flickerNoise = GetDynLightFlickerNoise(noiseSample);

        if (blockId == BLOCK_TORCH || blockId == BLOCK_LANTERN || blockId == BLOCK_FIRE) {
            float torchTemp = mix(3000, 4000, flickerNoise);
            lightColor = 0.8 * blackbody(torchTemp);
        }

        if (blockId == BLOCK_SOUL_TORCH || blockId == BLOCK_SOUL_LANTERN) {
            float soulTorchTemp = mix(1200, 1800, 1.0 - flickerNoise);
            lightColor = 0.8 * saturate(1.0 - blackbody(soulTorchTemp));
        }

        if (blockId == BLOCK_CANDLES_LIT_1 || blockId == BLOCK_CANDLES_LIT_2
         || blockId == BLOCK_CANDLES_LIT_3 || blockId == BLOCK_CANDLES_LIT_4
         || blockId == BLOCK_CANDLE_CAKE_LIT || blockId == BLOCK_JACK_O_LANTERN) {
            float candleTemp = mix(2600, 3600, flickerNoise);
            lightColor = 0.7 * blackbody(candleTemp);
        }
    #endif

    return lightColor;
}

void AddSceneBlockLight(const in int blockId, const in vec3 blockLocalPos) {
    #ifdef DYN_LIGHT_FLICKER
        vec2 noiseSample = GetDynLightNoise(blockLocalPos);
        vec3 lightColor = GetSceneBlockLightColor(blockId, noiseSample);
    #endif

    vec3 lightOffset = vec3(0.0);
    float lightRange = 0.0;

    float flicker = 0.0;
    //float pulse = 0.0;
    float glow = 0.0;

    #ifdef DYN_LIGHT_FLICKER
        float time = frameTimeCounter / 3600.0;
    //     vec3 worldPos = cameraPosition + blockLocalPos;

    //     vec3 texPos = fract(worldPos.xzy * vec3(0.04, 0.04, 0.08));
    //     texPos.z += 200.0 * time;

    //     vec2 noiseSample = texture(TEX_LIGHT_NOISE, vec2(0.3, 0.6)*texPos.y + texPos.xz).rg;
        float flickerNoise = GetDynLightFlickerNoise(noiseSample);
    #endif

    switch (blockId) {
        case BLOCK_AMETHYST_CLUSTER:
        case ITEM_AMETHYST_CLUSTER:
            lightRange = 5.0;
            glow = 0.2;
            break;
        case BLOCK_BEACON:
        case ITEM_BEACON:
            lightRange = 15.0;
            break;
        case BLOCK_BLAST_FURNACE_LIT:
            lightOffset = vec3(0.0, -0.4, 0.0);
            lightRange = 6.0;
            break;
        case BLOCK_BREWING_STAND:
            lightRange = 1.0;
            break;
        case BLOCK_CANDLES_LIT_1:
            lightRange = 3.0;
            flicker = 0.14;
            break;
        case BLOCK_CANDLES_LIT_2:
            lightRange = 6.0;
            flicker = 0.14;
            break;
        case BLOCK_CANDLES_LIT_3:
            lightRange = 9.0;
            flicker = 0.14;
            break;
        case BLOCK_CANDLES_LIT_4:
            lightRange = 12.0;
            flicker = 0.14;
            break;
        case BLOCK_CANDLE_CAKE_LIT:
            lightOffset = vec3(0.0, 0.4, 0.0);
            lightRange = 3.0;
            flicker = 0.14;
            break;
        case BLOCK_CAVEVINE_BERRIES:
        case ITEM_GLOW_BERRIES:
            lightRange = 14.0;
            break;
        case BLOCK_CRYING_OBSIDIAN:
        case ITEM_CRYING_OBSIDIAN:
            lightRange = 10.0;
            glow = 0.3;
            break;
        case BLOCK_END_ROD:
        case ITEM_END_ROD:
            lightRange = 14.0;
            break;
        case BLOCK_FIRE:
            lightOffset = vec3(0.0, -0.3, 0.0);
            lightRange = 15.0;
            flicker = 0.5;
            break;
        case BLOCK_FURNACE_LIT:
            lightOffset = vec3(0.0, -0.2, 0.0);
            lightRange = 6.0;
            break;
        case BLOCK_GLOWSTONE:
        case ITEM_GLOWSTONE:
            lightRange = 15.0;
            glow = 0.4;
            break;
        case BLOCK_GLOW_LICHEN:
        case ITEM_GLOW_LICHEN:
            lightRange = 7.0;
            glow = 0.2;
            break;
        case BLOCK_JACK_O_LANTERN:
        case ITEM_JACK_O_LANTERN:
            lightRange = 15.0;
            flicker = 0.3;
            break;
        case BLOCK_LANTERN:
        case ITEM_LANTERN:
            lightOffset = vec3(0.0, -0.25, 0.0);
            lightRange = 12.0;
            flicker = 0.05;
            break;
        case BLOCK_LIGHTING_ROD_POWERED:
            lightRange = 8.0;
            flicker = 0.8;
            break;
        case BLOCK_AMETHYST_BUD_LARGE:
        case ITEM_AMETHYST_BUD_LARGE:
            lightRange = 4.0;
            glow = 0.2;
            break;
        case BLOCK_LAVA:
            #ifndef LIGHT_LAVA_ENABLED
                return;
            #endif
        case BLOCK_LAVA_CAULDRON:
            lightRange = 15.0;
            glow = 0.4;
            break;
        case BLOCK_MAGMA:
        case ITEM_MAGMA:
            lightRange = 3.0;
            glow = 0.2;
            break;
        case BLOCK_AMETHYST_BUD_MEDIUM:
        case ITEM_AMETHYST_BUD_MEDIUM:
            lightRange = 2.0;
            glow = 0.2;
            break;
        case BLOCK_NETHER_PORTAL:
            lightRange = 11.0;
            glow = 0.8;
            break;
        case BLOCK_FROGLIGHT_OCHRE:
        case ITEM_FROGLIGHT_OCHRE:
            lightRange = 15.0;
            glow = 0.2;
            break;
        case BLOCK_FROGLIGHT_PEARLESCENT:
        case ITEM_FROGLIGHT_PEARLESCENT:
            lightRange = 15.0;
            glow = 0.2;
            break;
        case BLOCK_REDSTONE_LAMP:
            lightRange = 15.0;
            break;
        case BLOCK_REDSTONE_TORCH:
        case ITEM_REDSTONE_TORCH:
            lightRange = 7.0;
            break;
        case BLOCK_RESPAWN_ANCHOR_4:
            lightOffset = vec3(0.0, 0.4, 0.0);
            lightRange = 15.0;
            glow = 0.6;
            break;
        case BLOCK_RESPAWN_ANCHOR_3:
            lightOffset = vec3(0.0, 0.4, 0.0);
            lightRange = 11.0;
            glow = 0.6;
            break;
        case BLOCK_RESPAWN_ANCHOR_2:
            lightOffset = vec3(0.0, 0.4, 0.0);
            lightRange = 7.0;
            glow = 0.6;
            break;
        case BLOCK_RESPAWN_ANCHOR_1:
            lightOffset = vec3(0.0, 0.4, 0.0);
            lightRange = 3.0;
            glow = 0.6;
            break;
        case BLOCK_SCULK_CATALYST:
        case ITEM_SCULK_CATALYST:
            lightOffset = vec3(0.0, 0.4, 0.0);
            lightRange = 6.0;
            break;
        case BLOCK_SEA_LANTERN:
        case ITEM_SEA_LANTERN:
            lightRange = 15.0;
            glow = 0.4;
            break;
        case BLOCK_SEA_PICKLE_WET_1:
            lightRange = 6.0;
            glow = 0.4;
            break;
        case BLOCK_SEA_PICKLE_WET_2:
            lightRange = 9.0;
            glow = 0.4;
            break;
        case BLOCK_SEA_PICKLE_WET_3:
            lightRange = 12.0;
            glow = 0.4;
            break;
        case BLOCK_SEA_PICKLE_WET_4:
            lightRange = 15.0;
            glow = 0.4;
            break;
        case BLOCK_SHROOMLIGHT:
        case ITEM_SHROOMLIGHT:
            lightRange = 15.0;
            glow = 0.6;
            break;
        case BLOCK_SMOKER_LIT:
            lightOffset = vec3(0.0, -0.3, 0.0);
            lightRange = 6.0;
            break;
        case BLOCK_SOUL_LANTERN:
        case ITEM_SOUL_LANTERN:
            lightOffset = vec3(0.0, -0.25, 0.0);
            lightRange = 12.0;
            flicker = 0.1;
            break;
        case BLOCK_SOUL_TORCH:
        case ITEM_SOUL_TORCH:
            lightRange = 12.0;
            flicker = 0.1;
            break;
        case BLOCK_TORCH:
        case ITEM_TORCH:
            lightOffset = vec3(0.0, 0.4, 0.0);
            lightRange = 12.0;
            flicker = 0.4;
            break;
        case BLOCK_FROGLIGHT_VERDANT:
        case ITEM_FROGLIGHT_VERDANT:
            lightRange = 15.0;
            glow = 0.2;
            break;
    }

    bool intersects = true;
    if (lightRange > EPSILON) {
        #ifdef DYN_LIGHT_FRUSTUM_TEST
            vec3 lightViewPos = (gbufferModelView * vec4(blockLocalPos, 1.0)).xyz;

            if (lightViewPos.z > lightRange) intersects = false;
            else if (lightViewPos.z < -far - lightRange) intersects = false;
            else {
                if (dot(sceneViewUp,   lightViewPos) > lightRange) intersects = false;
                if (dot(sceneViewDown, lightViewPos) > lightRange) intersects = false;
                if (dot(sceneViewLeft,  lightViewPos) > lightRange) intersects = false;
                if (dot(sceneViewRight, lightViewPos) > lightRange) intersects = false;
            }
        #endif

        if (intersects) {
            // if (blockId == BLOCK_TORCH) {
            //     //vec3 texPos = worldPos.xzy * vec3(0.04, 0.04, 0.02);
            //     //texPos.z += 2.0 * time;

            //     //vec2 s = texture(TEX_CLOUD_NOISE, texPos).rg;

            //     //lightOffset = 0.08 * hash44(vec4(worldPos * 0.04, 2.0 * time)).xyz - 0.04;
            //     //lightOffset = 0.12 * hash44(vec4(worldPos * 0.04, 4.0 * time)).xyz - 0.06;
            // }

            #ifdef DYN_LIGHT_FLICKER
                if (flicker > EPSILON) {
                    lightColor.rgb *= 1.0 - flicker * (1.0 - flickerNoise);
                }

                if (glow > EPSILON) {
                    float cycle = sin(fract(time * 1000.0) * TAU) * 0.5 + 0.5;
                    lightColor.rgb *= 1.0 - glow * smoothstep(0.0, 1.0, noiseSample.r);
                }
            #endif

            AddSceneLight(blockLocalPos + lightOffset, lightRange, vec4(lightColor, 1.0));
        }
    }

    #if DYN_LIGHT_PT > 0
        if ((lightRange < EPSILON || !intersects) && IsDynLightSolidBlock(blockId)) {
            ivec3 gridCell, blockCell;
            vec3 gridPos = GetLightGridPosition(blockLocalPos);
            
            if (GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
                uint blockType = BLOCKTYPE_SOLID;

                // TODO: set other block tpyes
                if (blockId == BLOCK_SLABS_BOTTOM)
                    blockType = BLOCKTYPE_SLAB_BOTTOM;
                else if (blockId == BLOCK_SLABS_TOP)
                    blockType = BLOCKTYPE_SLAB_TOP;

                uint gridIndex = GetSceneLightGridIndex(gridCell);
                SetSceneBlockMask(blockCell, gridIndex, blockType);
            }
        }
    #endif
}