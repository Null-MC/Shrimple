const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);


float InterleavedGradientNoise(const in vec2 p) {
    float x = dot(p, magic.xy);
    return fract(magic.z * fract(x));
}

#ifndef RENDER_COMPUTE
    float InterleavedGradientNoise() {
        return InterleavedGradientNoise(gl_FragCoord.xy);
    }
#endif
