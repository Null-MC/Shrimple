const float wavingScale = 32.0;


//struct WindData {
//    //
//};

vec2 waveDx(const in vec2 position, const in vec2 direction, const in float frequency, const in float timeshift) {
    float x = mod(dot(direction, position) * frequency + timeshift, (2.0 * PI));
    float wave = exp(sin(x) - 1.0);
    return vec2(wave, -wave * cos(x));
}

vec3 waving_fbm(const in vec3 worldPos, const in float time) {
    vec3 position = worldPos;
//    position.xz /= wavingScale;

    float iter = 0.386;
    float frequency = 0.5;
    float speed = 0.7;
    float weight = 0.8;

//    float height = 0.0;
//    float waveSum = 0.0;
    float weightSum = 0.0;
    float valueSum = 0.0;

    const float DRAG_MULT = 0.09;

    for (int i = 0; i < 8; i++) {
        float iterMod = mod(iter, (2.0 * PI));
        vec2 direction = vec2(sin(iterMod), cos(iterMod));
        vec2 waveSample = weight * waveDx(position.xz, direction, frequency, time * speed);

        position.xz += waveSample.y * DRAG_MULT;
        valueSum += waveSample.x;
        weightSum += weight;

//        vec2 direction = vec2(sin(iter), cos(iter));
//        float x = dot(direction, position) * frequency + ;
//        x = mod(x, 2.0 * PI);

//        float wave = exp(sin(x) - 1.0);
//        float result = wave * cos(x);
//        vec2 force = waveSample * weight;// * direction;

//        position -= force * 0.24;
//        height += wave * weight;

        iter += 0.04;
//        waveSum += weight;
        weight *= 0.8;
        frequency *= 1.1;
        speed *= 1.3;
    }

    position.y += valueSum / max(weightSum, EPSILON);
//    position.y += _pow2(heightDelta);
//    position.y -= WaterWaveSurfaceOffset;

//    position.xz *= wavingScale;
    return position;

    //    position = ((position * wavingScale) - worldPos.xz) / wavingScale;
//    return vec3(position.x, 0.0, position.y);

    // TODO: why was this negative?
    // return -offset;
}

vec3 GetWindForce(const in vec3 originPos, const in float time) {
    vec3 worldPos = originPos + cameraPosition;
//    worldPos.xz += hash22(floor(worldPos.xz)) * 8.0 - 4.0;
    return waving_fbm(worldPos, time) - worldPos;
}

vec3 GetWindWavingOffset(const in vec3 wind, const in int blockId) {
    ivec2 blockUV = ivec2(blockId % 256, blockId / 256);
    uint wavingMask = texelFetch(texBlockWaving, blockUV, 0).r;

    float waveBottom = bitfieldExtract(wavingMask, 0, 4) / 15.0;
    float waveTop = bitfieldExtract(wavingMask, 4, 4) / 15.0;

    float waveHeightF = 0.5 - at_midBlock.y / 64.0;
    float waveStrength = mix(waveBottom, waveTop, waveHeightF);
    waveStrength = _pow2(waveStrength);

//    vec3 worldPos = originPos + cameraPosition;
//    worldPos.xz += hash22(floor(worldPos.xz)) * 4.0 - 2.0;
//    vec3 waveOffset = 2.0 * waving_fbm(worldPos, time);
    vec3 waveOffset = 2.0 * vec3(wind.xz, 0.0).xzy;

    return waveOffset * waveStrength;
}
