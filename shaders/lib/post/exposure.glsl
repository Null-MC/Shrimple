#define POST_EXPOSURE_NIGHTVISION 3.0


float GetPostExposure() {
    float exposure = POST_EXPOSURE;

    exposure = mix(exposure, POST_EXPOSURE_NIGHTVISION, _smoothstep(nightVision));

    return exp2(exposure);
}

void ApplyPostExposure(inout vec3 color) {
    #ifdef EFFECT_AUTO_EXPOSE
        vec2 eyeBright = eyeBrightnessSmooth / 240.0;
        float brightF = 1.0 - max(eyeBright.x * 0.5, eyeBright.y);
        color *= mix(1.0, 3.0, pow(brightF, 1.5));
    #endif

    float exposure = GetPostExposure();
    color *= exposure;

    #if MC_VERSION > 11900
        //color *= (1.0 - 0.97*smootherstep(darknessFactor)) + 0.16 * smootherstep(darknessLightFactor);
    #endif
}
