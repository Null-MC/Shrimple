// returns: tile [0-3] or -1 if excluded
int GetShadowTile(const in mat4 matShadowProjections[4], const in vec3 blockPos) {
    //#ifdef SHADOW_CSM_FITRANGE
    //    const int max = 3;
    //#else
        // const int max = 4;
    //#endif

    for (int i = 0; i < 4; i++) {
        if (CascadeContainsPosition(blockPos, i, -3.0)) return i;
    }

    //#ifdef SHADOW_CSM_FITRANGE
    //    return 3;
    //#else
        return -1;
    //#endif
}

void ApplyShadows(const in vec3 localPos, const in vec3 localNormal, const in float geoNoL, out vec3 shadowPos[4], out int shadowTile) {
    for (int i = 0; i < 4; i++) {
        float bias = GetShadowNormalBias(i, geoNoL);
        vec3 offsetLocalPos = localNormal * bias + localPos;

        vec3 shadowViewPos = mul3(shadowModelViewEx, offsetLocalPos);

        // convert to shadow screen space
        shadowPos[i] = mul3(cascadeProjection[i], shadowViewPos);

        shadowPos[i] = shadowPos[i] * 0.5 + 0.5;
        shadowPos[i].xy = shadowPos[i].xy * 0.5 + shadowProjectionPos[i];
    }

    #if defined RENDER_HAND //|| defined RENDER_ENTITIES
        vec3 blockPos = vec3(0.0);
    #elif defined RENDER_TERRAIN || defined RENDER_WATER
        vec3 blockPos = at_midBlock / 64.0 + localPos + 0.5;
        blockPos = floor(blockPos + fract(cameraPosition));
        // blockPos = (gl_ModelViewMatrix * vec4(blockPos, 1.0)).xyz;
        // blockPos = (shadowModelViewEx * (gbufferModelViewInverse * vec4(blockPos, 1.0))).xyz;
        blockPos = mul3(shadowModelViewEx, blockPos);
    #else
        vec3 blockPos = floor(localPos + fract(cameraPosition) + 0.5);
        blockPos = mul3(shadowModelViewEx, blockPos);
    #endif

    shadowTile = GetShadowTile(cascadeProjection, blockPos);
}
