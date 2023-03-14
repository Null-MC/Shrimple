vec3 waving_noise(vec3 p) {
    vec3 f = fract(p);
    p = floor(p);
    return mix(
        mix(
            mix(
                hash33(p + vec3(0, 0, 0)),
                hash33(p + vec3(0, 0, 1)),
                f.z
            ),
            mix(
                hash33(p + vec3(0, 1, 0)),
                hash33(p + vec3(0, 1, 1)),
                f.z
            ),
            f.y
        ),
        mix(
            mix(
                hash33(p + vec3(1, 0, 0)),
                hash33(p + vec3(1, 0, 1)),
                f.z
            ),
            mix(
                hash33(p + vec3(1, 1, 0)),
                hash33(p + vec3(1, 1, 1)),
                f.z
            ),
            f.y
        ),
        f.x
    );
}

vec3 waving_fbm(vec3 pos) {
    vec3 val = vec3(0);
    float weight = 0.8;
    float totalWeight = 0.0;
    float frequency = 0.8;
    for (int i = 0; i < 8; i++) {
        val += waving_noise(pos * frequency) * weight;
        totalWeight += weight;
        weight *= 0.8;
        frequency *= 1.2;
    }
    return val / totalWeight;
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
        case BLOCK_LEAVES:
        case BLOCK_LILAC_UPPER:
        case BLOCK_PEONY_UPPER:
        case BLOCK_ROSE_BUSH_UPPER:
        case BLOCK_TALL_GRASS_UPPER:
            // fast, no attachment
            range = 0.06;
            break;
    }

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

	vec3 hash = mod(waving_fbm(worldPos) * 2.0 * PI + 1.2 * frameTimeCounter, 2.0 * PI);
	vec3 offset = sin(hash) * range;

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
