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

vec3 GetShadowIntervalOffset() {
    return fract(cameraPosition / shadowIntervalSize) * shadowIntervalSize;
}

mat4 BuildShadowViewMatrix(const in vec3 localLightDir) {
    //#ifndef WORLD_END
    //    return shadowModelView;
    //#else
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
    //#endif
}

// mat4 BuildShadowViewMatrix() {
//     vec3 localLightDir = GetShadowLightLocalDir();
//     return BuildShadowViewMatrix(localLightDir);
// }

mat4 BuildShadowProjectionMatrix() {
    float maxDist = min(shadowDistance, far);
    return BuildOrthoProjectionMatrix(maxDist, maxDist, -far, far);
}

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_CLOUD_ENABLED && defined RENDER_VERTEX && !defined RENDER_SHADOW
    // out vec3 cloudPos;
    // uniform float cloudTime;
    // #if defined RENDER_BASIC || defined RENDER_TEXTURED || defined RENDER_CLOUDS || defined RENDER_PARTICLES || defined RENDER_WEATHER
    //  uniform vec3 eyePosition;
    // #endif

    vec3 GetCloudShadowPosition(const in vec3 localPos, const in vec3 skyLightDir) {
        const float irisCamWrap = 1024.0;

        vec2 cloudOffset = vec2(-cloudTime/12.0, 0.33);
        cloudOffset = mod(cloudOffset, vec2(256.0));
        cloudOffset = mod(cloudOffset + 256.0, vec2(256.0));

        vec3 camOffset = (mod(cameraPosition.xyz, irisCamWrap) + min(sign(cameraPosition.xyz), 0.0) * irisCamWrap) - (mod(eyePosition.xyz, irisCamWrap) + min(sign(eyePosition.xyz), 0.0) * irisCamWrap);
        camOffset.xz -= ivec2(greaterThan(abs(camOffset.xz), vec2(10.0))) * irisCamWrap; // eyePosition precission issues can cause this to be wrong, since the camera is usally not farther than 5 blocks, this should be fine
        vec3 vertexWorldPos = localPos + mod(eyePosition, 3072.0) + camOffset; // 3072 is one full cloud pattern
        float cloudHeightDifference = 192.2 - vertexWorldPos.y;

        vec3 lightWorldDir = skyLightDir / skyLightDir.y;
        cloudPos = vec3((vertexWorldPos.xz + lightWorldDir.xz * cloudHeightDifference + vec2(0.0, 4.0))/12.0 - cloudOffset.xy, cloudHeightDifference);
        cloudPos.xy *= rcp(256.0);

        return cloudPos;
    }

    void ApplyCloudShadows(const in vec3 localPos) {
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
        #endif

        cloudPos = GetCloudShadowPosition(localPos, localSkyLightDirection);
    }
#endif
