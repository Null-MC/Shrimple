const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);


float InterleavedGradientNoise(const in vec2 pixel) {
    float x = dot(pixel, magic.xy);
    return fract(magic.z * fract(x));
}

float InterleavedGradientNoiseTime(const in vec2 pixel) {
    // https://www.shadertoy.com/view/fdl3zn
    
    vec2 uv = pixel;
    if ((frameCounter & 2u) != 0u) uv = vec2(-uv.y, uv.x);
    if ((frameCounter & 1u) != 0u) uv.x = -uv.x;
    
    const vec3 vf = vec3(0.7548776662, 0.56984029, 0.41421356);
    return fract(dot(vec3(uv, frameCounter), vf));
}

#ifndef RENDER_COMPUTE
    float InterleavedGradientNoise() {
        return InterleavedGradientNoise(gl_FragCoord.xy);
    }
    
    float InterleavedGradientNoiseTime() {
        return InterleavedGradientNoiseTime(gl_FragCoord.xy);
    }
#endif
