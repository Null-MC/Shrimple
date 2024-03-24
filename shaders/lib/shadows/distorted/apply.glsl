vec3 ApplyShadows(const in vec3 localPos, const in vec3 localNormal, const in float geoNoL) {
    float bias = GetShadowNormalBias(geoNoL);
    vec3 offsetLocalPos = localNormal * bias + localPos;

    #ifndef IRIS_FEATURE_SSBO
        vec3 shadowViewPos = mul3(shadowModelView, offsetLocalPos);
        return mul3(shadowProjection, shadowViewPos);
    #else
        return mul3(shadowModelViewProjection, offsetLocalPos);
    #endif
}
