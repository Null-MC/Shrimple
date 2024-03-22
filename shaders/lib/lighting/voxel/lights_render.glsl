#if defined LIGHTING_FLICKER && !defined RENDER_SHADOWCOMP_LIGHT_NEIGHBORS //&& !((defined RENDER_SHADOW && defined RENDER_VERTEX) || defined RENDER_SHADOWCOMP_LIGHT_NEIGHBORS || defined RENDER_SETUP)
    void ApplyLightFlicker(inout vec3 lightColor, const in uint lightType, const in vec2 noiseSample) {
        float flickerNoise = GetDynLightFlickerNoise(noiseSample);
        float blackbodyTemp = 0.0;

        bool isBigFireSource = (lightType >= LIGHT_TORCH_FLOOR && lightType <= LIGHT_TORCH_WALL_W)
            || lightType == LIGHT_FIRE || lightType == LIGHT_CAMPFIRE
            || lightType == LIGHT_LANTERN || lightType == LIGHT_STREET_LAMP;

        bool isSmallFireSource = lightType == LIGHT_CANDLES_1 || lightType == LIGHT_CANDLES_2
            || lightType == LIGHT_CANDLES_3 || lightType == LIGHT_CANDLES_4 || lightType == LIGHT_CANDLE_CAKE
            || (lightType >= LIGHT_JACK_O_LANTERN_N && lightType <= LIGHT_JACK_O_LANTERN_W);

        bool isSoulFireSource = (lightType >= LIGHT_SOUL_TORCH_FLOOR && lightType <= LIGHT_SOUL_TORCH_WALL_W)
            || lightType == LIGHT_SOUL_FIRE || lightType == LIGHT_SOUL_CAMPFIRE
            || lightType == LIGHT_SOUL_LANTERN || lightType == LIGHT_SOUL_STREET_LAMP;

        if (isBigFireSource) {
            const float tempFireMax = LIGHTING_TEMP_FIRE;// + (0.5*TEMP_FIRE_RANGE);
            const float tempFireMin = LIGHTING_TEMP_FIRE - TEMP_FIRE_RANGE;
            blackbodyTemp = mix(tempFireMin, tempFireMax, flickerNoise);
        }

        if (isSoulFireSource) {
            blackbodyTemp = mix(TEMP_SOUL_FIRE_MIN, TEMP_SOUL_FIRE_MAX, 1.0 - flickerNoise);
        }

        if (isSmallFireSource) {
            blackbodyTemp = mix(TEMP_CANDLE_MIN, TEMP_CANDLE_MAX, flickerNoise);
        }

        vec3 blackbodyColor = vec3(1.0);
        if (blackbodyTemp > 0.0)
            blackbodyColor = blackbody(blackbodyTemp);

        float flickerBrightness = smootherstep(flickerNoise) * 0.4 + 0.6;

        if (isBigFireSource) {
            lightColor = flickerBrightness * blackbodyColor;
        }

        if (isSoulFireSource) {
            lightColor = flickerBrightness * saturate(1.0 - blackbodyColor);
        }

        if (isSmallFireSource) {
            lightColor = 0.4 * flickerBrightness * blackbodyColor;
        }
    }
#endif

// bool GetLightTraced(const in uint lightType) {
//     bool result = true;

//     #if DYN_LIGHT_GLOW_BERRIES != DYN_LIGHT_BLOCK_TRACE
//         if (lightType == LIGHT_CAVEVINE_BERRIES) result = false;
//     #endif

//     #if DYN_LIGHT_LAVA != DYN_LIGHT_BLOCK_TRACE
//         if (lightType == LIGHT_LAVA) result = false;
//     #endif

//     #if DYN_LIGHT_PORTAL != DYN_LIGHT_BLOCK_TRACE
//         if (lightType == LIGHT_NETHER_PORTAL) result = false;
//     #endif

//     #if DYN_LIGHT_REDSTONE != DYN_LIGHT_BLOCK_TRACE
//         if (lightType >= LIGHT_REDSTONE_WIRE_1 && lightType <= LIGHT_REDSTONE_WIRE_15) result = false;
//     #endif

//     return result;
// }

void ParseLightPosition(const in uvec4 data, out vec3 position) {
    const uvec3 offsets = uvec3(0u, 16u, 0u);
    uvec3 posHalf = (data.xxy >> offsets) & uint(0xffff);
    position = uintBitsToFloat(half2float(posHalf));
}

void ParseLightSize(const in uvec4 data, out float size) {
    size = ((data.y >> 16u) & 255u) / 255.0;
}

void ParseLightRange(const in uvec4 data, out float range) {
    range = ((data.y >> 24u) & 255u) / 4.0;
}

void ParseLightColor(const in uvec4 data, out vec3 color) {
    const uvec3 offsets = uvec3(8u, 16u, 24u);
    color = ((data.zzz >> offsets) & 255u) / 255.0;
}

void ParseLightData(const in uvec4 data, out vec3 position, out float size, out float range, out vec3 color) {
    ParseLightPosition(data, position);
    ParseLightSize(data, size);
    ParseLightRange(data, range);
    ParseLightColor(data, color);
}
