#define LIGHT_NONE 0u
#define LIGHT_TORCH 1u


uint GetLightType(const in int blockId) {
    uint lightType = LIGHT_NONE;
    if (blockId < 1) return lightType;

    switch (blockId) {
        case BLOCK_TORCH:
            lightType = LIGHT_TORCH;
            break;
    }

    return lightType;
}
