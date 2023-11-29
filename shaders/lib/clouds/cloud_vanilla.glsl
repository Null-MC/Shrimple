vec2 GetCloudOffset() {
    vec2 cloudOffset = vec2(-cloudTime/12.0 , 0.33);
    cloudOffset = mod(cloudOffset, vec2(256.0));
    cloudOffset = mod(cloudOffset + 256.0, vec2(256.0));

    return cloudOffset;
}

vec3 GetCloudCameraOffset() {
    const float irisCamWrap = 1024.0;

    vec3 camOffset = (mod(cameraPosition.xyz, irisCamWrap) + min(sign(cameraPosition.xyz), 0.0) * irisCamWrap) - (mod(eyePosition.xyz, irisCamWrap) + min(sign(eyePosition.xyz), 0.0) * irisCamWrap);
    camOffset.xz -= ivec2(greaterThan(abs(camOffset.xz), vec2(10.0))) * irisCamWrap; // eyePosition precission issues can cause this to be wrong, since the camera is usally not farther than 5 blocks, this should be fine
    return camOffset;
}

vec3 GetCloudShadowPosition(in vec3 worldPos, const in vec3 localDir, const in vec2 cloudOffset) {
    //vec3 vertexWorldPos = localPos + camOffset;
    worldPos.xz += mod(eyePosition.xz, 3072.0); // 3072 is one full cloud pattern
    worldPos.y += eyePosition.y;

    float cloudHeightDifference = cloudHeight - worldPos.y;

    vec3 cloudTexPos = vec3((worldPos.xz + localDir.xz * cloudHeightDifference + vec2(0.0, 4.0))/12.0 - cloudOffset.xy, cloudHeightDifference);
    cloudTexPos.xy *= rcp(256.0);
    return cloudTexPos;
}

#ifndef RENDER_VERTEX
    float SampleClouds(const in vec3 localPos, const in vec3 localDir, const in vec2 cloudOffset, const in vec3 camOffset, const in float roughness) {
        vec3 vertexWorldPos = localPos + camOffset;
        vec3 cloudTexPos = GetCloudShadowPosition(vertexWorldPos, localDir, cloudOffset);

        float cloudHeightDifference = cloudHeight - vertexWorldPos.y;

        const int maxLod = int(log2(256));
        float cloudF = textureLod(TEX_CLOUDS, cloudTexPos.xy, roughness * maxLod).a;

        //cloudF *= step(0.0, cloudTexPos.z);
        //cloudF *= step(0.0, localDir.y);

        #if WORLD_FOG_MODE != FOG_MODE_NONE
            vec3 cloudLocalPos = localPos;
            //vec3 localViewDir = normalize(localPos);

            cloudLocalPos.xz += localDir.xz * (cloudHeightDifference / localDir.y);
            cloudLocalPos.y = cloudHeight;

            #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
                float fogDist = GetShapedFogDistance(cloudLocalPos);

                #ifdef IS_IRIS
                    fogDist *= 0.5;
                #endif

                float fogF = GetCustomFogFactor(fogDist);
                cloudF *= 1.0 - fogF;
            #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
                vec3 fogPos = cloudLocalPos;
                if (fogShape == 1) fogPos.y = 0.0;

                float viewDist = length(fogPos);

                float fogF = 1.0 - smoothstep(fogEnd * 1.8, fogEnd * 0.5, viewDist);
                cloudF *= 1.0 - fogF;
            #endif
        #endif

        return cloudF;
    }

    float SampleCloudShadow(const in vec3 localPos, const in vec3 localDir, const in vec2 cloudOffset, const in vec3 camOffset) {
        // TODO: unduplicate this from above!
    	vec3 vertexWorldPos = localPos + camOffset;
        vertexWorldPos.xz += mod(eyePosition.xz, 3072.0); // 3072 is one full cloud pattern
        vertexWorldPos.y += eyePosition.y;

    	float cloudHeightDifference = cloudHeight - vertexWorldPos.y;

    	// vec3 cloudTexPos = vec3((vertexWorldPos.xz + localDir.xz * cloudHeightDifference + vec2(0.0, 4.0))/12.0 - cloudOffset.xy, cloudHeightDifference);
    	// cloudTexPos.xy *= rcp(256.0);

        // float cloudF = textureLod(TEX_CLOUDS, cloudTexPos.xy, 0).a;

        // cloudF = 1.0 - cloudF * 0.5 * step(0.0, cloudTexPos.z);
        float cloudF = SampleClouds(localPos, localDir, cloudOffset, camOffset, 0.0);
        cloudF = 1.0 - 0.5 * cloudF;

        float cloudShadow = (1.0 - ShadowCloudBrightnessF) * min(cloudF, 1.0);

        // #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
        //     vec3 cloudLocalPos = localPos;
        //     //vec3 localViewDir = normalize(localPos);

        //     cloudLocalPos.xz += localDir.xz * (cloudHeightDifference / localDir.y);
        //     cloudLocalPos.y = cloudHeight;

        //     float fogDist = GetShapedFogDistance(cloudLocalPos);

        //     #ifdef IS_IRIS
        //         fogDist *= 0.5;
        //     #endif

        //     float fogF = GetCustomFogFactor(fogDist);
        //     cloudShadow *= 1.0 - fogF;
        // #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
        //     vec3 fogPos = localPos;
        //     if (fogShape == 1) fogPos.y = 0.0;

        //     float viewDist = length(fogPos);

        //     float fogF = 1.0 - smoothstep(fogEnd * 1.8, fogEnd * 0.5, viewDist);
        //     cloudShadow *= 1.0 - fogF;
        // #endif

        return 1.0 - cloudShadow;
    }
#endif
