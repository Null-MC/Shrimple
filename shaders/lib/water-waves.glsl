const float PI_2 = PI * 2.0;


float wave_gerstner(vec2 position, vec2 direction, float freq, float amp, float speed, float steepness) {
    float phase = dot(position, direction) * freq * PI_2 + frameTimeCounter * speed;
    return amp * pow(sin(mod(phase, PI_2)) * 0.5 + 0.5, steepness);
}

float wave_gerstner2(vec2 position, vec2 direction, float freq, float speed) {
    float x = mod(dot(position, direction) * freq + frameTimeCounter * speed, PI_2);
//    return -exp(sin(x) - 1.0) * cos(x);
    return exp(sin(x) - 1.0);
}

float wave_fbm(const in vec2 position, const in int count) {
    float height = 0.0;
    float freq = 0.4;    // Base integer frequency for tiling
    float amp = 0.3;     // Base amplitude
    float speed = 1.5;   // Base speed
//    float steepness = 1.5; // Increases the sharpness of the crests

    for (int i = 0; i < count; i++) {
        float angle = float(i) * 1.124 + 0.13;
        vec2 dir = normalize(vec2(cos(angle), sin(angle)));

//        height += wave_gerstner(position, dir, freq, amp, speed, steepness);
        height += wave_gerstner2(position, dir, freq, speed) * amp;

        freq *= 1.42;
        amp *= 0.52;
        speed *= 1.2;
//        steepness *= 1.2;
    }

    return saturate(height);
}
