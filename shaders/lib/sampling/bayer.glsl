float Bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2. + a.y * a.y * .75);
}

#define Bayer4(a)   (Bayer2 (.5 *(a)) * .25 + Bayer2(a))
#define Bayer8(a)   (Bayer4 (.5 *(a)) * .25 + Bayer2(a))
#define Bayer16(a)  (Bayer8 (.5 *(a)) * .25 + Bayer2(a))
#define Bayer32(a)  (Bayer16(.5 *(a)) * .25 + Bayer2(a))
#define Bayer64(a)  (Bayer32(.5 *(a)) * .25 + Bayer2(a))


const mat4 BayerSamples = mat4(
    vec4(0.0000, 0.5000, 0.1250, 0.6250),
    vec4(0.7500, 0.2200, 0.8750, 0.3750),
    vec4(0.1875, 0.6875, 0.0625, 0.5625),
    vec4(0.9375, 0.4375, 0.8125, 0.3125));

float GetBayerValue(const in ivec2 position) {
    ivec2 offset = position % 4;
    return BayerSamples[offset.x][offset.y];
}

#ifndef RENDER_COMPUTE
    float GetScreenBayerValue(ivec2 offset) {return GetBayerValue(ivec2(gl_FragCoord.xy) + offset);}
    float GetScreenBayerValue() {return GetBayerValue(ivec2(gl_FragCoord.xy));}
#endif
