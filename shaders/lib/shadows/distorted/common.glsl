float GetShadowRange() {
    return -2.0 / shadowProjectionEx[2][2];
}

float GetShadowNormalBias(const in float geoNoL) {
    return 0.08 * max(1.0 - geoNoL, 0.0) * ShadowBiasScale;
}

float GetShadowOffsetBias() {
    float shadowDepthRange = GetShadowRange();
    return 0.08 / shadowDepthRange * ShadowBiasScale;
}

vec3 distort(const in vec3 pos) {
    #if SHADOW_DISTORT_FACTOR == 0
        return pos;
    #else
        float factor = length(pos.xy) + ShadowDistortF;
        //float factor = maxOf(abs(pos.xy)) + ShadowDistortF;

        return vec3((pos.xy / factor) * (1.0 + ShadowDistortF), pos.z);

        // const float CURVE_FACTOR = 1.0;

        // vec2 absUV = abs(pos.xy);
        // float maxCoord = minOf(absUV) / maxOf(absUV);
        // float maxLen = sqrt(1.0 + _pow2(maxCoord));
        // float fac1 = length(pos.xy) + ShadowDistortF;
        // float fac = mix(1.0, fac1, pow(1.0 - length(pos.xy) / maxLen, CURVE_FACTOR));
        // return vec3(pos.xy / fac, pos.z);
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
