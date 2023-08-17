float GetShadowNormalBias(const in float geoNoL) {
    return 0.02 * max(1.0 - geoNoL, 0.0) * SHADOW_BIAS_SCALE;
}

float GetShadowOffsetBias() {
    return (0.00004 * SHADOW_BIAS_SCALE);
}

vec3 distort(const in vec3 pos) {
    float factor = maxOf(abs(pos.xy)) + SHADOW_DISTORT_FACTOR;

    //float factor = length(pos.xy) + SHADOW_DISTORT_FACTOR;

    return vec3((pos.xy / factor) * (1.0 + SHADOW_DISTORT_FACTOR), pos.z * 0.5);
}

float computeBias(vec3 pos) {
    const float SHADOW_DISTORTED_BIAS = 1.0;

    float numerator = length(pos.xy) + SHADOW_DISTORT_FACTOR;
    return SHADOW_DISTORTED_BIAS / shadowMapResolution * _pow2(numerator) / SHADOW_DISTORT_FACTOR;
}

#if defined RENDER_VERTEX && !defined RENDER_SHADOW
    void ApplyShadows(const in vec3 localPos, const in vec3 localNormal, const in float geoNoL) {
        float bias = GetShadowNormalBias(geoNoL);

        float viewDist = 1.0;

        #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED
            viewDist += length(localPos);
        #endif

        vec3 offsetLocalPos = localPos + localNormal * viewDist * bias;

        #ifndef IRIS_FEATURE_SSBO
            vec3 shadowViewPos = (shadowModelView * vec4(offsetLocalPos, 1.0)).xyz;
            shadowPos = (shadowProjection * vec4(shadowViewPos, 1.0)).xyz;
        #else
            shadowPos = (shadowModelViewProjection * vec4(offsetLocalPos, 1.0)).xyz;
        #endif

        #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED
            shadowPos = distort(shadowPos);
        #endif

        shadowPos = shadowPos * 0.5 + 0.5;
    }
#endif
