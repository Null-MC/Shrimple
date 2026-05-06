mat4 GetLodProjection(const in mat4 gbufferProjection, const in float near) {
    return mat4(
        gbufferProjection[0][0], 0.0, 0.0, 0.0,
        0.0, gbufferProjection[1][1], 0.0, 0.0,
        0.0, 0.0, 0.0, -1.0,
        0.0, 0.0, near, 0.0);
}

mat4 GetLodProjectionInverse(const in mat4 gbufferProjectionInverse, const in float near) {
    return mat4(
        gbufferProjectionInverse[0][0], 0.0, 0.0, 0.0,
        0.0, gbufferProjectionInverse[1][1], 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0/near,
        0.0, 0.0, -1.0, 0.0);
}
