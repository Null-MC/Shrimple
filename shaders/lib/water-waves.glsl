const float PI_2 = PI * 2.0;


float wave_gerstner(vec2 position, float angle, float freq, float speed, float steepness) {
    vec2 direction = normalize(vec2(cos(angle), sin(angle)));
    float x = mod(dot(position, direction) * freq + frameTimeCounter * speed, PI_2);
    return pow(exp(sin(x) - 1.0), steepness+1.0);
}

float wave_fbm(const in vec2 position, const in int count) {
    float height = 0.0;
    float freq = 0.7;    // Base integer frequency for tiling
    float amp = 0.14;     // Base amplitude
    float speed = 1.4;   // Base speed
    float steepness = 3.0;

    for (int i = 0; i < count; i++) {
        float angle = float(i) * 1.76 + 0.79;
        height += wave_gerstner(position, angle, freq, speed, steepness) * amp;

        freq *= 1.22;
        amp *= 0.75;
        speed *= 1.07;
        steepness *= 0.84;
    }

    return saturate(height);
}

float WaterWave_Vertex(const in vec3 localPos) {
    vec2 waterWorldPos = localPos.xz + cameraPosition.xz;
    return wave_fbm(waterWorldPos / WaterNormalScale, 8);
}

float WaterWave_Fragment(const in vec3 localPos) {
    vec2 waterWorldPos = (localPos.xz + cameraPosition.xz);
    return wave_fbm(waterWorldPos / WaterNormalScale, 24);
}
