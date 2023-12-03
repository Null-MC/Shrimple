float GetVoxelFade(const in vec3 voxelPos) {
    const float padding = 8.0;
    const vec3 sizeInner = VoxelBlockCenter - padding;

    //vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
    vec3 dist = abs(voxelPos - VoxelBlockCenter);// - cameraOffset);
    vec3 distF = max(dist - sizeInner, vec3(0.0));
    return saturate(1.0 - maxOf((distF / padding)));
}

#if LPV_SIZE > 0
    vec3 GetLpvAmbientLighting(const in vec3 localPos, const in vec3 localNormal) {
        vec3 lpvPos = GetLPVPosition(localPos);
        if (clamp(lpvPos, ivec3(0), SceneLPVSize - 1) != lpvPos) return vec3(0.0);

        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smoothstep(0.0, 1.0, lpvFade);
        lpvFade *= 1.0 - LpvLightmapMixF;

        vec4 lpvSample = SampleLpv(lpvPos, localNormal);
        vec3 lpvLight = GetLpvBlockLight(lpvSample);

        // #ifdef LPV_GI
        //     lpvFade *= 0.5;
        // #endif

        return lpvLight * lpvFade * (DynamicLightBrightness * DynamicLightAmbientF);
    }

    // float GetLpvSkyLighting(const in vec3 localPos, const in vec3 localNormal) {
    //     vec3 lpvPos = GetLPVPosition(localPos);
    //     if (clamp(lpvPos, ivec3(0), SceneLPVSize - 1) != lpvPos) return 0.0;

    //     float lpvFade = GetLpvFade(lpvPos);
    //     lpvFade = smoothstep(0.0, 1.0, lpvFade);
    //     lpvFade *= 1.0 - LpvLightmapMixF;

    //     vec4 lpvSample = SampleLpv(lpvPos, localNormal);
    //     return GetLpvSkyLight(lpvSample);
    // }
#endif

void GetFinalBlockLighting(inout vec3 sampleDiffuse, inout vec3 sampleSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {
    vec2 lmBlock = LightMapTex(vec2(lmcoord.x, 0.0));
    vec3 blockLightDefault = textureLod(TEX_LIGHTMAP, lmBlock, 0).rgb;
    blockLightDefault = RGBToLinear(blockLightDefault);

    #if defined IRIS_FEATURE_SSBO && !(defined RENDER_CLOUDS || defined RENDER_WEATHER || defined DYN_LIGHT_WEATHER)
        vec3 blockDiffuse = vec3(0.0);
        vec3 blockSpecular = vec3(0.0);
        SampleDynamicLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

        vec3 voxelPos = GetVoxelBlockPosition(localPos);
        float voxelFade = GetVoxelFade(voxelPos);

        sampleDiffuse += mix(blockLightDefault, blockDiffuse, voxelFade);
        sampleSpecular += blockSpecular * voxelFade;
    #endif

    #if LPV_SIZE > 0 //&& DYN_LIGHT_MODE == DYN_LIGHT_LPV
        sampleDiffuse += GetLpvAmbientLighting(localPos, localNormal) * occlusion;
    #endif

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && !(defined RENDER_CLOUDS || defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
        // Required "hack" to force shadow pass on iris
        if (gl_FragCoord.x < 0) sampleDiffuse = texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
    #endif
}

#if defined WORLD_SKY_ENABLED && !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
    void GetSkyLightingFinal(inout vec3 skyDiffuse, inout vec3 skySpecular, const in vec3 shadowPos, const in vec3 shadowColor, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss, const in bool tir) {
        vec3 localViewDir = -normalize(localPos);

        vec2 lmSky = vec2(0.0, lmcoord.y);

        vec3 skyLightColor = vec3(1.0);

        #if !defined LIGHT_LEAK_FIX && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
            float shadow = maxOf(abs(shadowPos * 2.0 - 1.0));
            shadow = 1.0 - smoothstep(0.5, 0.8, shadow);

            skyLightColor = mix(skyLightColor, vec3(1.0), shadow);
        #endif

        #ifndef IRIS_FEATURE_SSBO
            vec3 WorldSkyLightColor = GetSkyLightColor();
        #endif

        skyLightColor *= CalculateSkyLightWeatherColor(WorldSkyLightColor);// * WorldSkyBrightnessF;
        //skyLightColor *= 1.0 - 0.7 * rainStrength;
        
        #ifndef IRIS_FEATURE_SSBO
            #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
            #else
                vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
                if (worldTime > 12000 && worldTime < 24000)
                    localSkyLightDirection = -localSkyLightDirection;
            #endif
        #endif

        float geoNoL = 1.0;
        if (!all(lessThan(abs(localNormal), EPSILON3)))
            geoNoL = dot(localNormal, localSkyLightDirection);

        float diffuseNoLm = GetLightNoL(geoNoL, texNormal, localSkyLightDirection, sss);

        float invAO = saturate(1.0 - occlusion);
        diffuseNoLm = max(diffuseNoLm - _pow2(invAO), 0.0);

        vec3 H = normalize(-localSkyLightDirection + -localViewDir);
        float diffuseNoVm = max(dot(texNormal, localViewDir), 0.0);
        float diffuseLoHm = max(dot(localSkyLightDirection, H), 0.0);
        float D = SampleLightDiffuse(diffuseNoVm, diffuseNoLm, diffuseLoHm, roughL);
        vec3 accumDiffuse = D * skyLightColor * shadowColor;
        
        float viewDist = length(localPos);
        float shadowDistF = 1.0 - saturate(viewDist / shadowDistance);
        accumDiffuse *= 1.0 + MaterialSssBoostF * sss * shadowDistF;

        vec2 lmcoordFinal = LightMapTex(vec2(0.0, lmcoord.y));
        vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmcoordFinal, 0).rgb;
        vec3 ambientLight = RGBToLinear(lightmapColor);

        //ambientLight = _pow2(ambientLight);

        #if LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0 //&& DYN_LIGHT_MODE != DYN_LIGHT_LPV
        //     //vec3 surfacePos = localPos;
        //     //surfacePos += 0.501 * localNormal;// * (1.0 - sss);

            vec3 lpvPos = GetLPVPosition(localPos);

            float lpvFade = GetLpvFade(lpvPos);
            lpvFade = smoothstep(0.0, 1.0, lpvFade);
            lpvFade *= 1.0 - LpvLightmapMixF;

            vec4 lpvSample = SampleLpv(lpvPos, localNormal);
            float lpvSkyLight = GetLpvSkyLight(lpvSample);

            #ifdef LPV_GI
                lpvSkyLight *= 0.5;
            #endif

            ambientLight = mix(ambientLight, vec3(lpvSkyLight), lpvFade);

            //lmFinal.x *= 1.0 - lpvFade;

        //     //vec3 voxelPos = GetVoxelBlockPosition(surfacePos);

        //     //vec3 lpvLight = GetLpvAmbient(lpvPos, localNormal);
        //     vec4 lpvSample = SampleLpv(lpvPos, localNormal);
        //     vec3 lpvLight = lpvSample.rgb / LpvBlockLightF;
        //     //float skyLight = lpvSample.a;

        //     //#if DYN_LIGHT_MODE != DYN_LIGHT_LPV
        //         //ambientLight = _pow3(ambientLight);
        //         lpvFade *= 1.0 - LpvLightmapMixF;
        //     //#endif

        //     #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && LPV_LIGHTMAP_MIX != 100
        //         ambientLight *= 1.0 - lpvFade;
        //         lpvLight *= 1.0 - LpvLightmapMixF;
        //     #endif
            
        //     ambientLight += lpvLight * lpvFade;
        #endif

        ambientLight *= skyLightColor;

        ambientLight *= occlusion;

        // if (any(greaterThan(abs(texNormal), EPSILON3)))
        //     ambientLight *= (texNormal.y * 0.3 + 0.7);

        accumDiffuse += ambientLight * DynamicLightAmbientF;// * roughL;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            #if MATERIAL_SPECULAR == SPECULAR_LABPBR
                if (IsMetal(metal_f0))
                    accumDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
            #else
                accumDiffuse *= mix(vec3(1.0), albedo, metal_f0 * (1.0 - roughL));
            #endif
        #endif

        #if MATERIAL_SPECULAR != SPECULAR_NONE && !defined RENDER_CLOUDS
            vec3 f0 = GetMaterialF0(albedo, metal_f0);

            vec3 localSkyLightDir = localSkyLightDirection;
            //#if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
                const float skyLightSize = 480.0;

                vec3 r = reflect(-localViewDir, texNormal);
                vec3 L = localSkyLightDir * 10000.0;
                vec3 centerToRay = dot(L, r) * r - L;
                vec3 closestPoint = L + centerToRay * saturate(skyLightSize / length(centerToRay));
                localSkyLightDir = normalize(closestPoint);
            //#endif

            vec3 skyH = normalize(localSkyLightDir + localViewDir);
            float skyVoHm = max(dot(localViewDir, skyH), 0.0);

            float skyNoLm = 1.0, skyNoVm = 1.0, skyNoHm = 1.0;
            if (!all(lessThan(abs(texNormal), EPSILON3))) {
                skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);
                skyNoVm = max(dot(texNormal, localViewDir), 0.0);
                skyNoHm = max(dot(texNormal, skyH), 0.0);
            }

            vec3 skyF = F_schlickRough(skyVoHm, f0, roughL);

            skyLightColor *= 1.0 - 0.92*rainStrength;

            float invGeoNoL = saturate(geoNoL*40.0);
            skySpecular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyF, roughL) * skyLightColor * shadowColor;

            #if MATERIAL_REFLECTIONS != REFLECT_NONE
                vec3 viewPos = (gbufferModelView * vec4(localPos, 1.0)).xyz;
                vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

                vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);

                accumDiffuse *= 1.0 - skyReflectF;

                if (tir) skyReflectF = vec3(1.0);

                #if !(MATERIAL_REFLECTIONS == REFLECT_SCREEN && defined RENDER_OPAQUE_FINAL)
                //#if MATERIAL_REFLECTIONS != REFLECT_NONE //&& defined RENDER_OPAQUE_FINAL)
                    skySpecular += ApplyReflections(localPos, viewPos, texViewNormal, lmcoord.y, sqrt(roughL)) * skyReflectF;
                #endif
            #endif
        #endif

        skyDiffuse += accumDiffuse;
    }

    void GetSkyLightingFinal(inout vec3 skyDiffuse, inout vec3 skySpecular, const in vec3 shadowPos, const in vec3 shadowColor, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {
        GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, shadowColor, localPos, localNormal, texNormal, albedo, lmcoord, roughL, metal_f0, occlusion, sss, false);
    }
#endif

#if !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
    vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, const in vec3 specular, const in float occlusion) {
        #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
            vec3 final = vec3(WHITEWORLD_VALUE);
        #else
            vec3 final = albedo;
        #endif

        // TODO: handle specular occlusion
        return final * (WorldMinLightF * occlusion + diffuse) + specular * _pow3(occlusion);
    }
#endif
