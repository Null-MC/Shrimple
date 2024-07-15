// const float minShadowPixelRadius = Shadow_MinPcfSize * shadowPixelSize;


// float GetSssDither() {
//     #ifdef RENDER_FRAG
//         #ifdef EFFECT_TAA_ENABLED
//             return InterleavedGradientNoiseTime();
//         #else
//             return InterleavedGradientNoise();
//         #endif
//     #else
//         return 0.0;
//     #endif
// }

// float SampleDepth(const in vec2 shadowPos) {
//     #ifdef RENDER_TRANSLUCENT
//         return texture(shadowtex0, shadowPos).r;
//     #else
//         return texture(shadowtex1, shadowPos).r;
//     #endif
// }

// returns: [0] when depth occluded, [1] otherwise
// float CompareDepth(in vec3 shadowPos, const in vec2 offset, const in float bias) {
//     shadowPos = distort(shadowPos + vec3(offset, -bias));
//     shadowPos = shadowPos * 0.5 + 0.5;

//     #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
//         #ifdef RENDER_TRANSLUCENT
//             return texture(shadowtex0HW, shadowPos).r;
//         #else
//             return texture(shadowtex1HW, shadowPos).r;
//         #endif
//     #else
//         float texDepth = SampleDepth(shadowPos.xy);
//         return step(shadowPos.z, texDepth);
//     #endif
// }

float GetSss_PCF(const in vec3 shadowPos, const in vec2 pixelRadius, const in float offsetBias, const in float sssBias) {
    float dither = GetShadowDither();

    float angle = fract(dither) * TAU;
    float s = sin(angle), c = cos(angle);
    mat2 rotation = mat2(c, -s, s, c);

    float shadow = 0.0;
    for (int i = 0; i < SHADOW_SSS_SAMPLES; i++) {
        #ifdef IRIS_FEATURE_SSBO
            vec2 pixelOffset = (rotation * pcfDiskOffset[i]) * pixelRadius;
        #else
            float r = sqrt((i + 0.5) / SHADOW_SSS_SAMPLES);
            float theta = i * GoldenAngle + PHI;
            
            vec2 pcfDiskOffset = vec2(cos(theta), sin(theta)) * r;
            vec2 pixelOffset = (rotation * pcfDiskOffset) * pixelRadius;
        #endif

        float sampleBias = offsetBias + sssBias * InterleavedGradientNoiseTime(i);

        shadow += 1.0 - CompareDepth(shadowPos, pixelOffset, sampleBias);
    }

    return 1.0 - shadow * rcp(SHADOW_SSS_SAMPLES);
}

// vec2 GetSssPixelRadius(const in vec3 shadowPos, const in float blockRadius) {
//     // #ifndef IRIS_FEATURE_SSBO
//     //     mat4 shadowProjectionEx = shadowProjection;//BuildShadowProjectionMatrix();
//     //     shadowProjectionEx[2][2] = -2.0 / (3.0 * far);
//     //     shadowProjectionEx[3][2] = 0.0;
//     // #endif

//     vec2 shadowProjectionSize = 2.0 / vec2(shadowProjectionEx[0].x, shadowProjectionEx[1].y);

//     //float distortFactor = getDistortFactor(shadowPos.xy * 2.0 - 1.0);
//     //float maxRes = shadowMapSize / Shadow_DistortF;

//     vec2 pixelPerBlockScale = shadowMapSize / shadowProjectionSize;
//     return 2.0 * blockRadius * pixelPerBlockScale * shadowPixelSize;// * (1.0 - distortFactor);
// }

// PCF
float GetSssFactor(const in vec3 shadowPos, const in float offsetBias, const in float sss) {
    float zRange = GetShadowRange();
    float sssBias = sss * MATERIAL_SSS_MAXDIST / zRange;

    float sssRadius = sss * MATERIAL_SSS_SCATTER;
    vec2 pixelRadius = GetShadowPixelRadius(shadowPos, sssRadius);
    float shadow_sss = GetSss_PCF(shadowPos, pixelRadius, offsetBias, sssBias);
    return sss * shadow_sss;
}
