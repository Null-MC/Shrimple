const float wavingScale = 16.0;
const float wavingHeight = 0.6;
const float Wind_Variation = 0.1 * PI;


vec3 waving_fbm(const in vec3 worldPos, const in float time) {
    vec2 position = worldPos.xz / wavingScale;

    float iter = 0.0;
    float frequency = 3.0;
    float speed = 1.0;
    float weight = 1.0;
    float height = 0.0;
    float waveSum = 0.0;

    // float time = ap.timing.timeElapsed / 3.6 * 3.0;
    // time += Wind_Variation * time_dither;

//    [ForceUnroll]
    for (int i = 0; i < 4; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, position) * frequency + time * speed;
        x = mod(x, 2.0 * PI);

        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;

        position -= force * 0.24;
        height += wave * weight;
        iter += 0.33;
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

//    float waveBottom = bitfieldExtract(wavingMask, 2, 1);
//    float waveTop = bitfieldExtract(wavingMask, 3, 1);
    float waveBottom = bitfieldExtract(wavingMask, 0, 4) / 15.0;
    float waveTop = bitfieldExtract(wavingMask, 4, 4) / 15.0;

    float waveHeightF = 0.5 - at_midBlock.y / 64.0;
    float waveStrength = mix(waveBottom, waveTop, waveHeightF);

//    float time = mod(frameTimeCounter * 2.0, 2.0*PI);
//    vec2 waveOffset = 0.3 * vec2(cos(time), sin(time));
//    float time = frameTimeCounter / 3.6 * 3.0;
//    time += Wind_Variation * time_dither;
    vec3 waveOffset = waving_fbm(originPos + cameraPosition, windTime);

    return waveOffset * waveStrength;
}

//vec3 GetWavingOffset(const in vec3 origin_worldPos, const in vec3 midPos, const in uint blockTags, const in float timeElapsed) {
//    vec3 position_seed = origin_worldPos;
//    if ((blockTags & TAG_WAVING_FULL) == TAG_WAVING_FULL) position_seed.y = 0.0;
//    float time_dither = hash13(position_seed);
//
//    float waving_strength = 0.4;
//    waving_strength = lerp(waving_strength, 1.8, ap.world.rainStrength);
//    // waving_strength = lerp(waving_strength, 3.2, ap.world.thunderStrength);
//
//    float time = timeElapsed / 3.6 * 3.0;
//    time += Wind_Variation * time_dither;
//
//    vec3 offset_new = waving_fbm(origin_worldPos, time) * waving_strength;
//
//    vec3 offsetFinal = vec3(0.0);
//    if ((blockTags & TAG_WAVING_FULL) == TAG_WAVING_FULL) {
//        // no attach
//        offsetFinal = offset_new;
//    }
//    else if ((blockTags & TAG_WAVING_GROUND) == TAG_WAVING_GROUND) {
//        // ground attach
//        float attach_dist = 0.5 - midPos.y;
//
//        if (attach_dist > 0.0) {
//            vec3 new_pos = vec3(offset_new.x, attach_dist, offset_new.z);
//
//            new_pos *= attach_dist / length(new_pos);
//            new_pos.y -= attach_dist;
//
//            offsetFinal = new_pos;
//        }
//    }
//
//    return offsetFinal;
//}