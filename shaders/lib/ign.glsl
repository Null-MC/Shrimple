const vec4 ignF = vec4(1.0/16.0, 1.0/17.0, 12.9898, 78.233);


float InterleavedGradientNoise(const in vec2 seed) {
    return fract(dot(seed, ignF.xy) + 0.5 * fract(dot(seed.xy, ignF.zw)));
}
