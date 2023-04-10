//#ifdef DYN_LIGHT_FLICKER
    vec2 GetDynLightNoise(const in vec3 worldPos) {
        float time = frameTimeCounter / 3600.0;

        vec3 texPos = fract(worldPos.xzy * vec3(0.04, 0.04, 0.08));
        texPos.z += 200.0 * time;

        return texture(TEX_LIGHT_NOISE, vec2(0.3, 0.6)*texPos.y + texPos.xz).rg;
    }

    float GetDynLightFlickerNoise(const in vec2 noiseSample) {
        return (1.0 - noiseSample.g) * (1.0 - _pow2(noiseSample.r));
    }
//#endif
