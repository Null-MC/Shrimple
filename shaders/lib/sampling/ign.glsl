const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);


float InterleavedGradientNoise(const in vec2 pixel) {
    float x = dot(pixel, magic.xy);
    return fract(magic.z * fract(x));
}

// https://www.shadertoy.com/view/WsfBDf
float InterleavedGradientNoiseTime(const in vec2 pixel) {
    vec2 uv = pixel + frameCounter * 5.588238;
    return fract(magic.z * fract(dot(magic.xy, uv)));
}

#ifndef RENDER_COMPUTE
    float InterleavedGradientNoise() {
        return InterleavedGradientNoise(gl_FragCoord.xy);
    }
    
    float InterleavedGradientNoiseTime() {
        return InterleavedGradientNoiseTime(gl_FragCoord.xy);
    }
    
    float InterleavedGradientNoiseTime(const in int offset) {
        return InterleavedGradientNoiseTime(gl_FragCoord.xy + offset);
    }
#endif
