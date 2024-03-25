float GetShadowRange() {
    return -2.0 / shadowProjectionEx[2][2];
}

float GetShadowNormalBias(const in float geoNoL) {
    return 0.08 * max(1.0 - geoNoL, 0.0) * ShadowBiasScale;
}

float GetShadowOffsetBias(const in vec3 pos) {
    // float shadowDepthRange = GetShadowRange();
    // return 0.08 / shadowDepthRange * ShadowBiasScale;

    #if SHADOW_DISTORT_FACTOR > 0
        float numerator = length(pos.xy) + ShadowDistortF;
        return ShadowBiasScale * rcp(shadowMapResolution) * _pow2(numerator) / ShadowDistortF;
    #else
        return ShadowBiasScale * rcp(shadowMapResolution);
    #endif
}

vec3 distort(const in vec3 pos) {
    #if SHADOW_DISTORT_FACTOR > 0
        float factor = length(pos.xy) + ShadowDistortF;
        return vec3((pos.xy / factor) * (1.0 + ShadowDistortF), pos.z);
    #else
        return pos;
    #endif
}

// float computeBias(vec3 pos) {
//     const float SHADOW_DISTORTED_BIAS = 1.0;

//     float numerator = length(pos.xy) + ShadowDistortF;
//     return SHADOW_DISTORTED_BIAS / shadowMapResolution * _pow2(numerator) / ShadowDistortF;
// }

// #if (defined RENDER_VERTEX || defined RENDER_TESS_EVAL) && !defined RENDER_SHADOW
//     vec3 ApplyShadows(const in vec3 localPos, const in vec3 localNormal, const in float geoNoL) {
//         float bias = GetShadowNormalBias(geoNoL);
//         vec3 offsetLocalPos = localNormal * bias + localPos;

//         #ifndef IRIS_FEATURE_SSBO
//             vec3 shadowViewPos = mul3(shadowModelView, offsetLocalPos);
//             return mul3(shadowProjection, shadowViewPos);
//         #else
//             return mul3(shadowModelViewProjection, offsetLocalPos);
//         #endif
//     }
// #endif
