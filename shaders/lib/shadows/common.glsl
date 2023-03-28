void GetFrustumMinMax(const in mat4 matProjection, out vec3 clipMin, out vec3 clipMax) {
    vec3 frustum[8] = vec3[](
        vec3(-1.0, -1.0, -1.0),
        vec3( 1.0, -1.0, -1.0),
        vec3(-1.0,  1.0, -1.0),
        vec3( 1.0,  1.0, -1.0),
        vec3(-1.0, -1.0,  1.0),
        vec3( 1.0, -1.0,  1.0),
        vec3(-1.0,  1.0,  1.0),
        vec3( 1.0,  1.0,  1.0));

    for (int i = 0; i < 8; i++) {
        vec3 shadowClipPos = unproject(matProjection * vec4(frustum[i], 1.0));

        if (i == 0) {
            clipMin = shadowClipPos;
            clipMax = shadowClipPos;
        }
        else {
            clipMin = min(clipMin, shadowClipPos);
            clipMax = max(clipMax, shadowClipPos);
        }
    }
}
