void GetFrustumMinMax(const in mat4 matProjection, out vec3 clipMin, out vec3 clipMax) {
    for (int i = 0; i < 8; i++) {
        vec3 corner = vec3(ivec3(i, i / 2, i / 4) % 2) * 2.0 - 1.0;
        vec3 shadowClipPos = unproject(matProjection * vec4(corner, 1.0));

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

vec3 GetShadowIntervalOffset() {
    return fract(cameraPosition / shadowIntervalSize) * shadowIntervalSize;
}

mat4 BuildShadowViewMatrix(const in vec3 localLightDir) {
    const vec3 worldUp = vec3(1.0, 0.0, 0.0);

    vec3 zaxis = localLightDir;
    vec3 xaxis = normalize(cross(worldUp, zaxis));
    vec3 yaxis = normalize(cross(zaxis, xaxis));

    mat4 shadowModelViewEx = mat4(1.0);
    shadowModelViewEx[0].xyz = vec3(xaxis.x, yaxis.x, zaxis.x);
    shadowModelViewEx[1].xyz = vec3(xaxis.y, yaxis.y, zaxis.y);
    shadowModelViewEx[2].xyz = vec3(xaxis.z, yaxis.z, zaxis.z);

    vec3 intervalOffset = GetShadowIntervalOffset();
    mat4 translation = BuildTranslationMatrix(intervalOffset);

    return shadowModelViewEx * translation;
}

// mat4 BuildShadowViewMatrix() {
//     vec3 localLightDir = GetShadowLightLocalDir();
//     return BuildShadowViewMatrix(localLightDir);
// }

mat4 BuildShadowProjectionMatrix() {
    float maxDist = min(shadowDistance, far);
    return BuildOrthoProjectionMatrix(maxDist, maxDist, -far, far);
}

// #if defined RENDER_SHADOWS_ENABLED && defined SHADOW_CLOUD_ENABLED && defined RENDER_VERTEX && !(defined RENDER_SHADOW || defined RENDER_SHADOW_DH || defined RENDER_CLOUDS)
//     vec3 ApplyCloudShadows(const in vec3 localPos) {
//         #ifndef IRIS_FEATURE_SSBO
//             vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
//         #endif

//         vec2 cloudOffset = GetCloudOffset();
//         vec3 camOffset = GetCloudCameraOffset();
//         vec3 worldPos = localPos + camOffset;
//         return GetCloudShadowPosition(worldPos, localSkyLightDirection, cloudOffset);
//     }
// #endif
