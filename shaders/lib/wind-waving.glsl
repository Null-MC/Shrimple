const float wavingScale = 32.0;


float waveDx(const in vec2 position, const in vec2 direction, const in float frequency, const in float timeshift) {
    float x = mod(dot(direction, position) * frequency + timeshift, (2.0 * PI));
    return -exp(sin(x) - 1.0) * cos(x);
}

vec2 waving_fbm(const in vec2 worldPos, const in float time) {
    vec2 position = worldPos;

    float iter = 0.386;
    float frequency = 0.3;
    float speed = 0.9;
    float weight = 1.0;

    const float DRAG_MULT = 0.14;

    for (int i = 0; i < 8; i++) {
        float iterMod = mod(iter, (2.0 * PI));
        vec2 direction = vec2(sin(iterMod), cos(iterMod));
        float waveSample = weight * waveDx(position, direction, frequency, time * speed);

        position += waveSample * DRAG_MULT;

        iter += 0.04;
        weight *= 0.6;
        frequency *= 1.3;
        speed *= 1.3;
    }

    return position;
}


void GetBlockWaving(const in int blockId, out float waveBottom, out float waveTop, out bool waveSnap) {
    ivec2 blockUV = ivec2(blockId % 256, blockId / 256);
    uint wavingMask = texelFetch(texBlockWaving, blockUV, 0).r;

    waveBottom = bitfieldExtract(wavingMask, 0, 7) / 127.0;
    waveTop = bitfieldExtract(wavingMask, 7, 7) / 127.0;
    waveSnap = bitfieldExtract(wavingMask, 14, 1) == 1u;
}

vec2 GetWindStrength(vec2 wind, float midBlockY, float waveBottom, float waveTop) {
    float waveHeightF = 0.5 - midBlockY;
    float waveStrength = mix(waveBottom, waveTop, waveHeightF);
    waveStrength = _pow2(waveStrength);
    return waveStrength * wind;
}

vec3 GetWindWavingOffset(const in vec3 localPos, const in vec3 midBlock, const in int blockId, inout vec3 velocity, const in float time, const in float timeLast) {
    bool waveSnap;
    float waveBottom, waveTop;
    GetBlockWaving(blockId, waveBottom, waveTop, waveSnap);

    vec3 worldPos = localPos + cameraPosition;
    if (waveSnap) {
        worldPos += midBlock;
        worldPos.xz += hash22(floor(worldPos.xz)) * 4.0 - 2.0;
    }

    vec2 wind = waving_fbm(worldPos.xz, time) - worldPos.xz;
    vec2 windLast = waving_fbm(worldPos.xz, timeLast) - worldPos.xz;

    vec3 strength = vec3(GetWindStrength(wind, midBlock.y, waveBottom, waveTop), 0.0).xzy;
    vec3 strengthLast = vec3(GetWindStrength(windLast, midBlock.y, waveBottom, waveTop), 0.0).xzy;

    velocity += strength - strengthLast;
    return strength;
}

vec3 GetWindWavingOffset(const in vec3 localPos, const in vec3 midBlock, const in int blockId, const in float time) {
    bool waveSnap;
    float waveBottom, waveTop;
    GetBlockWaving(blockId, waveBottom, waveTop, waveSnap);

    vec3 worldPos = localPos + cameraPosition;
    if (waveSnap) {
        worldPos += midBlock;
        worldPos.xz += hash22(floor(worldPos.xz)) * 4.0 - 2.0;
    }

    vec2 wind = waving_fbm(worldPos.xz, time) - worldPos.xz;

    return vec3(GetWindStrength(wind, midBlock.y, waveBottom, waveTop), 0.0).xzy;
}
