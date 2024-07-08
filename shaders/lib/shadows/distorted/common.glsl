float GetShadowRange() {
    return -2.0 / shadowProjection[2][2];
}

vec3 GetShadowSize() {
    return vec3(2.0, 2.0, -2.0) / vec3(
        shadowProjection[0].x,
        shadowProjection[1].y,
        shadowProjection[2].z);
}

float GetShadowNormalBias(const in float geoNoL) {
    return 0.08 * max(1.0 - geoNoL, 0.0) * Shadow_BiasScale;
}

float GetShadowOffsetBias(const in vec3 pos, const in float geoNoL) {
    float len = length(pos.xy);
    float factor = len / (len + Shadow_DistortF);
    vec3 shadowSize = GetShadowSize();

    float bias_xy = 0.00001 * (maxOf(shadowSize.xy) / shadowMapResolution);// / factor;
    float bias_z = 0.0000001 * shadowSize.z;

    return mix(bias_xy, bias_z, abs(geoNoL)) * Shadow_BiasScale;
}

vec3 distort(const in vec3 pos) {
    #if SHADOW_DISTORT_FACTOR > 0
        float factor = length(pos.xy) + Shadow_DistortF;
        // return vec3((pos.xy / factor) * (1.0 + Shadow_DistortF), pos.z);
        return vec3(pos.xy / factor, pos.z);
    #else
        return pos;
    #endif
}

// float computeBias(vec3 pos) {
//     const float SHADOW_DISTORTED_BIAS = 1.0;

//     float numerator = length(pos.xy) + Shadow_DistortF;
//     return SHADOW_DISTORTED_BIAS / shadowMapResolution * _pow2(numerator) / Shadow_DistortF;
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
