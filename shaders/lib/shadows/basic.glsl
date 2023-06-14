float GetShadowNormalBias(const in float geoNoL) {
    return 0.02 * max(1.0 - geoNoL, 0.0) * SHADOW_BIAS_SCALE;
}

float GetShadowOffsetBias() {
    return (0.00004 * SHADOW_BIAS_SCALE);
}

// euclidian distance is defined as sqrt(a^2 + b^2 + ...)
// this length function instead does cbrt(a^3 + b^3 + ...)
// this results in smaller distances along the diagonal axes.

float cubeLength(const in vec2 v) {
    return pow(abs(v.x * v.x * v.x) + abs(v.y * v.y * v.y), 1.0 / 3.0);
}

float getDistortFactor(const in vec2 v) {
    return cubeLength(v) + SHADOW_DISTORT_FACTOR;
}

vec3 distort(const in vec3 v, const in float factor) {
    return vec3(v.xy / factor, v.z);
}

vec3 distort(const in vec3 v) {
    return distort(v, getDistortFactor(v.xy));
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
