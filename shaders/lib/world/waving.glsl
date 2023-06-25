const float wavingScale = 8.0;
const float wavingHeight = 0.6;

vec3 waving_fbm(const in vec3 worldPos) {
    vec2 position = worldPos.xz * rcp(wavingScale);

    float iter = 0.0;
    float frequency = 3.0;
    float speed = 1.0;
    float weight = 1.0;
    float height = 0.0;
    float waveSum = 0.0;

    float time = frameTimeCounter / 3.6;
    
    for (int i = 0; i < 8; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, position) * frequency + time * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        position -= force * 0.03;
        height += wave * weight;
        iter += 12.0;
        waveSum += weight;
        weight *= 0.8;
        frequency *= 1.1;
        speed *= 1.3;
    }

    position = (position * wavingScale) - worldPos.xz;
    return vec3(position.x, height / waveSum * wavingHeight - 0.5 * wavingHeight, position.y);
}

float GetWavingRange(const in int blockId, out uint attachment) {
    float range = 0.0;
    attachment = 0u;

    switch (blockId) {
        case BLOCK_DEAD_BUSH:
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

    return range;
}

void ApplyWavingOffset(inout vec3 position, const in int blockId) {
    uint attachment;
    float range = GetWavingRange(blockId, attachment);
    if (range < EPSILON) return;

    #if defined RENDER_SHADOW
        vec3 localPos = (shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
        vec3 worldPos = localPos + cameraPosition;
    #else
        vec3 localPos = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
        vec3 worldPos = localPos + cameraPosition;
    #endif

    vec3 offset = waving_fbm(worldPos);

    if (attachment != 0) {
        float attachOffset = 0.0;
        switch (attachment) {
            case 1u:
                attachOffset = 0.5;
                break;
            case 2u:
                attachOffset = -0.5;
                break;
        }

        float baseOffset = -at_midBlock.y / 64.0 + attachOffset;
        offset *= clamp(baseOffset, 0.0, 1.0);
    }

    position += offset;
}
