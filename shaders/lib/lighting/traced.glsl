float GetVoxelFade(const in vec3 voxelPos) {
    const float padding = 8.0;
    const vec3 sizeInner = VoxelBufferCenter - padding;

    vec3 dist = abs(voxelPos - VoxelBufferCenter);
    vec3 distF = max(dist - sizeInner, vec3(0.0));
    return saturate(1.0 - maxOf((distF / padding)));
}

#ifdef IS_LPV_ENABLED
    vec3 GetLpvAmbientLighting(const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in float lmBlock) {
        vec3 lpvPos = GetVoxelPosition(localPos);
        if (!IsInVoxelBounds(ivec3(lpvPos))) return vec3(0.0);

        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smootherstep(lpvFade);
        lpvFade *= 1.0 - Lpv_LightmapMixF;

        vec4 lpvSample = SampleLpv(lpvPos, localNormal, texNormal);

        #ifdef LPV_VANILLA_BRIGHTNESS
            vec3 lpvLight = GetLpvBlockLight(lpvSample, lmBlock);
        #else
            vec3 lpvLight = GetLpvBlockLight(lpvSample);
        #endif

        return LIGHTING_TRACE_LPV_AMBIENT * lpvLight * lpvFade;// * Lighting_AmbientF;
    }
#endif

void GetFinalBlockLighting(inout vec3 sampleDiffuse, inout vec3 sampleSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {
    #ifdef IS_LPV_ENABLED
        vec3 lpvPos = GetVoxelPosition(localPos);
        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = 1.0 - _smoothstep(lpvFade);

        vec3 lmBlockLight = (_pow3(lmcoord.x) * Lighting_Brightness) * blackbody(LIGHTING_TEMP);
        sampleDiffuse += lmBlockLight * lpvFade * occlusion;

        sampleDiffuse += GetLpvAmbientLighting(localPos, localNormal, texNormal, lmcoord.x) * occlusion;
    #endif
}

#if !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
    vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, const in vec3 specular, const in float occlusion) {
        vec3 diffuseFinal = albedo * (Lighting_MinF * occlusion + diffuse);
        vec3 specularFinal = specular * _pow3(occlusion);
        return diffuseFinal + specularFinal;
    }
#endif
