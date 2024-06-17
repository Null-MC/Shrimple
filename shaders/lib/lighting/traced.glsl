float GetVoxelFade(const in vec3 voxelPos) {
    const float padding = 8.0;
    const vec3 sizeInner = VoxelBlockCenter - padding;

    //vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
    vec3 dist = abs(voxelPos - VoxelBlockCenter);// - cameraOffset);
    vec3 distF = max(dist - sizeInner, vec3(0.0));
    return saturate(1.0 - maxOf((distF / padding)));
}

#if LPV_SIZE > 0
    vec3 GetLpvAmbientLighting(const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal) {
        vec3 lpvPos = GetLPVPosition(localPos);
        if (clamp(lpvPos, ivec3(0), SceneLPVSize - 1) != lpvPos) return vec3(0.0);

        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smootherstep(lpvFade);
        lpvFade *= 1.0 - Lpv_LightmapMixF;

        vec4 lpvSample = SampleLpv(lpvPos, localNormal, texNormal);
        vec3 lpvLight = 0.5 * GetLpvBlockLight(lpvSample);

        return lpvLight * lpvFade * Lighting_AmbientF;
    }
#endif

void GetFinalBlockLighting(inout vec3 sampleDiffuse, inout vec3 sampleSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {
    vec2 lmBlock = LightMapTex(vec2(lmcoord.x, 0.0));
    vec3 blockLightDefault = textureLod(TEX_LIGHTMAP, lmBlock, 0).rgb;
    blockLightDefault = RGBToLinear(blockLightDefault);

    // #if defined IRIS_FEATURE_SSBO && !(defined RENDER_CLOUDS || defined RENDER_WEATHER || defined DYN_LIGHT_WEATHER)
    //     vec3 blockDiffuse = vec3(0.0);
    //     vec3 blockSpecular = vec3(0.0);
    //     SampleDynamicLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

    //     vec3 voxelPos = GetVoxelBlockPosition(localPos);
    //     float voxelFade = GetVoxelFade(voxelPos);

    //     sampleDiffuse += mix(blockLightDefault, blockDiffuse, voxelFade);
    //     sampleSpecular += blockSpecular * voxelFade;
    // #endif

    #if LPV_SIZE > 0 //&& LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        sampleDiffuse += GetLpvAmbientLighting(localPos, localNormal, texNormal) * occlusion;
    #endif
}

#if !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
    vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, const in vec3 specular, const in float occlusion) {
        #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
            vec3 final = vec3(WHITEWORLD_VALUE);
        #else
            vec3 final = albedo;
        #endif

        return final * (Lighting_MinF * occlusion + diffuse) + specular * _pow3(occlusion);
    }
#endif
