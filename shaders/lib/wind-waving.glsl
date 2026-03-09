const float wavingScale = 32.0;


vec3 waving_fbm(const in vec3 worldPos, const in float time) {
    vec2 position = worldPos.xz / wavingScale;

    float iter = 0.0;
    float frequency = 3.0;
    float speed = 1.0;
    float weight = 1.0;
    float height = 0.0;
    float waveSum = 0.0;

    for (int i = 0; i < 4; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, position) * frequency + time * speed;
        x = mod(x, 2.0 * PI);

        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;

        position -= force * 0.24;
        height += wave * weight;
        iter += 0.04;
        waveSum += weight;
        weight *= 0.8;
        frequency *= 1.1;
        speed *= 1.3;
    }

    position = ((position * wavingScale) - worldPos.xz) / wavingScale;
    vec3 offset = vec3(position.x, 0.0, position.y);
    return -offset;
}

vec3 GetWindWavingOffset(const in vec3 originPos, const in int blockId) {
    ivec2 blockUV = ivec2(blockId % 256, blockId / 256);
    uint wavingMask = texelFetch(texBlockWaving, blockUV, 0).r;

    float waveBottom = bitfieldExtract(wavingMask, 0, 4) / 15.0;
    float waveTop = bitfieldExtract(wavingMask, 4, 4) / 15.0;

    float waveHeightF = 0.5 - at_midBlock.y / 64.0;
    float waveStrength = mix(waveBottom, waveTop, waveHeightF);
    waveStrength = _pow2(waveStrength);

    vec3 worldPos = originPos + cameraPosition;
    worldPos.xz += hash22(floor(worldPos.xz)) * 4.0 - 2.0;
    vec3 waveOffset = 2.0 * waving_fbm(worldPos, windTime);

    return waveOffset * waveStrength;
}
