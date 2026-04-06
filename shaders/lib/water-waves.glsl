const float PI_2 = PI * 2.0;


float wave_gerstner(vec2 position, float angle, float freq, float speed, float steepness) {
    vec2 direction = normalize(vec2(cos(angle), sin(angle)));
    float x = mod(dot(position, direction) * freq + frameTimeCounter * speed, PI_2);
    return pow(exp(sin(x) - 1.0), steepness);
}

float wave_fbm(const in vec2 position, const in int count) {
    float height = 0.0;
    float freq = 0.7;    // Base integer frequency for tiling
    float amp = 0.12;     // Base amplitude
    float speed = 1.8;   // Base speed
    float steepness = 1.0;

    for (int i = 0; i < count; i++) {
        float angle = float(i) * 2.76 + 0.13;
        height += wave_gerstner(position, angle, freq, speed, steepness) * amp;

        freq *= 1.32;
        amp *= 0.52;
        speed *= 1.12;
        steepness *= 1.05;
    }

    return saturate(height);
}
