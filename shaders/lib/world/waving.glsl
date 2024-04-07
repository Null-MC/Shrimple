const float wavingHeight = 0.6;

vec3 waving_fbm(const in vec3 worldPos, const in float time) {
    vec2 position = worldPos.xz * rcp(WORLD_WIND_STRENGTH);
    // float time = GetAnimationFactor() / 3.6;

    float iter = 0.0;
    float frequency = 2.5;
    float speed = 1.6;
    float weight = 1.0;
    float height = 0.0;
    float waveSum = 0.0;

    for (int i = 0; i < 8; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, position) * frequency + time * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        position -= force * 0.03;
        height += wave * weight;
        iter += 1.3;
        waveSum += weight;
        weight *= 0.6;
        frequency *= 1.1;
        speed *= 1.4;
    }

    position = (position * WORLD_WIND_STRENGTH) - worldPos.xz;
    return vec3(position.x, height / waveSum * wavingHeight - 0.5 * wavingHeight, position.y);
}

void ApplyWavingOffset(inout vec3 vertexPos, const in vec3 localPos, const in int blockId) {
    StaticBlockData blockData = StaticBlockMap[blockId];
    uint attachment = blockData.wavingAttachment;
    float range = blockData.wavingRange;
    if (range < EPSILON) return;

    vec3 worldPos = localPos + cameraPosition;
    float time = GetAnimationFactor();
    vec3 offset = waving_fbm(worldPos, time / 3.6);

    #if defined EFFECT_TAA_ENABLED && defined RENDER_TERRAIN
        float timePrev = time - frameTime;
        vec3 offsetPrev = waving_fbm(worldPos, timePrev / 3.6);
    #endif

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
        offset *= saturate(baseOffset);

        #if defined EFFECT_TAA_ENABLED && defined RENDER_TERRAIN
            offsetPrev *= saturate(baseOffset);
        #endif
    }

    vertexPos += offset;

    #if defined EFFECT_TAA_ENABLED && defined RENDER_TERRAIN
        vOut.velocity += offset - offsetPrev;
    #endif
}
