float SampleCloudsFinal(const in vec3 localPos, const in vec3 localDir, const in vec2 cloudOffset, const in vec3 camOffset, const in float roughness) {
    // vec3 vertexWorldPos = localPos + camOffset;
    // vec3 cloudTexPos = GetCloudShadowPosition(vertexWorldPos, localDir, cloudOffset);

    // float cloudHeightDifference = cloudHeight - vertexWorldPos.y;

    // const int maxLod = int(log2(256));
    // float cloudF = textureLod(TEX_CLOUDS_VANILLA, cloudTexPos.xy, roughness * maxLod).a;

    float cloudF = SampleClouds(localPos, localDir, cloudOffset, camOffset, roughness);

    //cloudF *= step(0.0, cloudTexPos.z);
    //cloudF *= step(0.0, localDir.y);

    #ifdef SKY_BORDER_FOG_ENABLED
        vec3 cloudLocalPos = localPos;
        //vec3 localViewDir = normalize(localPos);

        cloudLocalPos.xz += localDir.xz * (cloudHeightDifference / localDir.y);
        cloudLocalPos.y = cloudHeight;

        #if SKY_TYPE == SKY_TYPE_CUSTOM
            float fogDist = GetShapedFogDistance(cloudLocalPos);

            #ifdef IS_IRIS
                fogDist *= 0.5;
            #endif

            float fogF = GetCustomFogFactor(fogDist);
            cloudF *= 1.0 - fogF;
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            vec3 fogPos = cloudLocalPos;
            if (fogShape == 1) fogPos.y = 0.0;

            float viewDist = length(fogPos);

            float fogF = 1.0 - smoothstep(fogEnd * 1.8, fogEnd * 0.5, viewDist);
            cloudF *= 1.0 - fogF;
        #endif
    #endif

    return cloudF;
}
