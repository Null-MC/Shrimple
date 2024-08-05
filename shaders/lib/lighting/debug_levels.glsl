vec3 smoothHue(float h) {
    return normalize(pow2(cos(h * TAU - vec3(0.0, 1.0, 2.0) * (TAU / 3.0)) * 0.5 + 0.5));
}

vec3 GetLightLevelColor(const in float blockLight) {
    return smoothHue(blockLight * (2.0/3.0));

    float level = blockLight * 15.0;
    float danger = 1.0 - smoothstep(1.0, 10.0, level);
    float safe = smoothstep(8.0, 15.0, level);

    return vec3(
        danger,
        (1.0 - danger) * (1.0 - safe),
        safe);
}
