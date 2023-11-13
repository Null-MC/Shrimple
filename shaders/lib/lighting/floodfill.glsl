void GetFloodfillLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec2 lmcoord, const in vec3 shadowColor, const in vec3 albedo, const in float metal_f0, const in float roughL, const in float sss, const in bool tir) {
    vec2 lmFinal = saturate(lmcoord) * (15.0/16.0) + (0.5/16.0);
    vec3 lightDefault = textureLod(TEX_LIGHTMAP, lmFinal, 0).rgb;
    lightDefault = RGBToLinear(lightDefault);

    lightDefault = _pow2(lightDefault);

    #ifdef WORLD_SKY_ENABLED
        vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
    #endif

    vec3 localViewDir = normalize(localPos);

    vec3 lpvPos = GetLPVPosition(localPos);

    if (clamp(lpvPos, ivec3(0), SceneLPVSize - 1) == lpvPos) {
        vec3 surfaceNormal = localNormal;

        if (!all(lessThan(abs(texNormal), EPSILON3))) {
            surfaceNormal = normalize(localNormal + texNormal);
        }

        vec4 lpvSample = SampleLpv(lpvPos, surfaceNormal);
        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smoothstep(0.0, 1.0, lpvFade);
        //lpvFade *= 1.0 - LpvLightmapMixF;

        vec3 lpvLight = lpvSample.rgb / LpvBlockLightF;

        #if defined WORLD_SKY_ENABLED
            lmFinal = vec2(0.0, lmcoord.y);
            lmFinal = lmFinal * (15.0/16.0) + (0.5/16.0);
            vec3 lightSky = textureLod(TEX_LIGHTMAP, lmFinal, 0).rgb;
            lightSky = RGBToLinear(lightSky);

            #if LPV_SUN_SAMPLES > 0
                float lpvSkyLight = sqrt(saturate(lpvSample.a / LPV_SKYLIGHT_RANGE));
                lpvLight += lpvSkyLight * skyLightColor * DynamicLightAmbientF;

                lpvLight = mix(lpvLight, lightSky, LpvLightmapMixF * lpvFade);
            #else
                #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                    lpvLight += lightSky * DynamicLightAmbientF;
                #else
                    lpvLight += lightSky;
                #endif
            #endif
        #endif

        blockDiffuse += mix(lightDefault, lpvLight, lpvFade);

    }
    else blockDiffuse += lightDefault;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        float geoNoL = 1.0;
        if (!all(lessThan(abs(localNormal), EPSILON3)))
            geoNoL = dot(localNormal, localSkyLightDirection);

        float diffuseNoL = GetLightNoL(geoNoL, texNormal, localSkyLightDirection, sss);

        vec3 H = normalize(-localSkyLightDirection + localViewDir);
        float diffuseNoVm = max(dot(texNormal, -localViewDir), 0.0);
        float diffuseLoHm = max(dot(localSkyLightDirection, H), 0.0);
        float D = SampleLightDiffuse(diffuseNoVm, diffuseNoL, diffuseLoHm, roughL);
        vec3 skyDiffuse = D * skyLightColor * shadowColor;

        #if MATERIAL_SPECULAR != SPECULAR_NONE && !defined RENDER_CLOUDS
            vec3 f0 = GetMaterialF0(albedo, metal_f0);

            vec3 localSkyLightDir = localSkyLightDirection;
            //#if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
                const float skyLightSize = 480.0;

                vec3 r = reflect(localViewDir, texNormal);
                vec3 L = localSkyLightDir * 10000.0;
                vec3 centerToRay = dot(L, r) * r - L;
                vec3 closestPoint = L + centerToRay * saturate(skyLightSize / length(centerToRay));
                localSkyLightDir = normalize(closestPoint);
            //#endif

            vec3 skyH = normalize(localSkyLightDir + -localViewDir);
            float skyVoHm = max(dot(-localViewDir, skyH), 0.0);

            float skyNoLm = 1.0, skyNoVm = 1.0, skyNoHm = 1.0;
            if (!all(lessThan(abs(texNormal), EPSILON3))) {
                skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);
                skyNoVm = max(dot(texNormal, -localViewDir), 0.0);
                skyNoHm = max(dot(texNormal, skyH), 0.0);
            }

            vec3 skyF = F_schlickRough(skyVoHm, f0, roughL);

            skyLightColor *= 1.0 - 0.92*rainStrength;

            float invGeoNoL = saturate(geoNoL*40.0);
            blockSpecular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyF, roughL) * skyLightColor * shadowColor;

            #if MATERIAL_REFLECTIONS != REFLECT_NONE
                vec3 viewPos = (gbufferModelView * vec4(localPos, 1.0)).xyz;
                vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

                vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);

                skyDiffuse *= 1.0 - skyReflectF;

                if (tir) skyReflectF = vec3(1.0);

                #if !(MATERIAL_REFLECTIONS == REFLECT_SCREEN && defined RENDER_OPAQUE_FINAL)
                    blockSpecular += ApplyReflections(localPos, viewPos, texViewNormal, lmcoord.y, sqrt(roughL)) * skyReflectF;
                #endif
            #endif
        #endif

        blockDiffuse += skyDiffuse;
    #endif

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && !(defined RENDER_CLOUDS || defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
        // Required "hack" to force shadow pass on iris
        if (gl_FragCoord.x < 0) blockDiffuse = texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
    #endif
}

// #if defined WORLD_SKY_ENABLED && !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
//     void GetSkyLightingFinal(inout vec3 skyDiffuse, inout vec3 skySpecular, const in vec3 shadowPos, const in vec3 shadowColor, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss, const in bool tir) {
//         vec3 localViewDir = -normalize(localPos);

//         vec2 lmSky = vec2(0.0, lmcoord.y);

//         vec3 skyLightColor = vec3(1.0);

//         #if !defined LIGHT_LEAK_FIX && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
//             float shadow = maxOf(abs(shadowPos * 2.0 - 1.0));
//             shadow = 1.0 - smoothstep(0.5, 0.8, shadow);

//             skyLightColor = mix(skyLightColor, vec3(1.0), shadow);
//         #endif

//         #ifndef IRIS_FEATURE_SSBO
//             vec3 WorldSkyLightColor = GetSkyLightColor();
//         #endif

//         skyLightColor *= CalculateSkyLightWeatherColor(WorldSkyLightColor);// * WorldSkyBrightnessF;
//         //skyLightColor *= 1.0 - 0.7 * rainStrength;
        
//         #ifndef IRIS_FEATURE_SSBO
//             #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
//                 vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
//             #else
//                 vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
//                 if (worldTime > 12000 && worldTime < 24000)
//                     localSkyLightDirection = -localSkyLightDirection;
//             #endif
//         #endif

//         float geoNoL = 1.0;
//         if (!all(lessThan(abs(localNormal), EPSILON3)))
//             geoNoL = dot(localNormal, localSkyLightDirection);

//         float diffuseNoL = GetLightNoL(geoNoL, texNormal, localSkyLightDirection, sss);

//         vec3 H = normalize(-localSkyLightDirection + -localViewDir);
//         float diffuseNoVm = max(dot(texNormal, localViewDir), 0.0);
//         float diffuseLoHm = max(dot(localSkyLightDirection, H), 0.0);
//         float D = SampleLightDiffuse(diffuseNoVm, diffuseNoL, diffuseLoHm, roughL);
//         vec3 accumDiffuse = D * skyLightColor * shadowColor;


//         vec2 lmcoordFinal = saturate(lmcoord);

//         #if DYN_LIGHT_MODE == DYN_LIGHT_LPV
//             lmcoordFinal.x = 0.0;
//         #endif

//         lmcoordFinal = lmcoordFinal * (15.0/16.0) + (0.5/16.0);

//         vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmcoordFinal, 0).rgb;

//         vec3 ambientLight = RGBToLinear(lightmapColor);

//         #if LPV_SIZE > 0 && DYN_LIGHT_MODE != DYN_LIGHT_LPV
//             vec3 surfacePos = localPos;
//             surfacePos += 0.501 * localNormal;// * (1.0 - sss);

//             vec3 lpvPos = GetLPVPosition(surfacePos);

//             float lpvFade = GetLpvFade(lpvPos);
//             lpvFade = smoothstep(0.0, 1.0, lpvFade);

//             //lmFinal.x *= 1.0 - lpvFade;

//             vec3 voxelPos = GetVoxelBlockPosition(surfacePos);

//             vec3 lpvLight = GetLpvAmbient(voxelPos, lpvPos);

//             //#if DYN_LIGHT_MODE != DYN_LIGHT_LPV
//                 //ambientLight = _pow3(ambientLight);
//                 lpvFade *= 1.0 - LpvLightmapMixF;
//             //#endif

//             #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && LPV_LIGHTMAP_MIX != 100
//                 ambientLight *= 1.0 - lpvFade;
//                 lpvLight *= 1.0 - LpvLightmapMixF;
//             #endif
            
//             ambientLight += lpvLight * lpvFade;
//         #endif

//         // ambientLight *= DynamicLightAmbientF;

//         // ambientLight *= occlusion;

//         // if (any(greaterThan(abs(texNormal), EPSILON3)))
//         //     ambientLight *= (texNormal.y * 0.3 + 0.7);

//         accumDiffuse += ambientLight;// * roughL;

//         #if MATERIAL_SPECULAR != SPECULAR_NONE
//             #if MATERIAL_SPECULAR == SPECULAR_LABPBR
//                 if (IsMetal(metal_f0))
//                     accumDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
//             #else
//                 accumDiffuse *= mix(vec3(1.0), albedo, metal_f0 * (1.0 - roughL));
//             #endif
//         #endif

//         #if MATERIAL_SPECULAR != SPECULAR_NONE && !defined RENDER_CLOUDS
//             vec3 f0 = GetMaterialF0(albedo, metal_f0);

//             vec3 localSkyLightDir = localSkyLightDirection;
//             //#if DYN_LIGHT_TYPE == LIGHT_TYPE_AREA
//                 const float skyLightSize = 480.0;

//                 vec3 r = reflect(-localViewDir, texNormal);
//                 vec3 L = localSkyLightDir * 10000.0;
//                 vec3 centerToRay = dot(L, r) * r - L;
//                 vec3 closestPoint = L + centerToRay * saturate(skyLightSize / length(centerToRay));
//                 localSkyLightDir = normalize(closestPoint);
//             //#endif

//             vec3 skyH = normalize(localSkyLightDir + localViewDir);
//             float skyVoHm = max(dot(localViewDir, skyH), 0.0);

//             float skyNoLm = 1.0, skyNoVm = 1.0, skyNoHm = 1.0;
//             if (!all(lessThan(abs(texNormal), EPSILON3))) {
//                 skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);
//                 skyNoVm = max(dot(texNormal, localViewDir), 0.0);
//                 skyNoHm = max(dot(texNormal, skyH), 0.0);
//             }

//             vec3 skyF = F_schlickRough(skyVoHm, f0, roughL);

//             skyLightColor *= 1.0 - 0.92*rainStrength;

//             float invGeoNoL = saturate(geoNoL*40.0);
//             skySpecular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyF, roughL) * skyLightColor * shadowColor;

//             #if MATERIAL_REFLECTIONS != REFLECT_NONE
//                 vec3 viewPos = (gbufferModelView * vec4(localPos, 1.0)).xyz;
//                 vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

//                 vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);

//                 accumDiffuse *= 1.0 - skyReflectF;

//                 if (tir) skyReflectF = vec3(1.0);

//                 #if !(MATERIAL_REFLECTIONS == REFLECT_SCREEN && defined RENDER_OPAQUE_FINAL)
//                     skySpecular += ApplyReflections(localPos, viewPos, texViewNormal, lmcoord.y, sqrt(roughL)) * skyReflectF;
//                 #endif
//             #endif
//         #endif

//         skyDiffuse += accumDiffuse;
//     }

//     void GetSkyLightingFinal(inout vec3 skyDiffuse, inout vec3 skySpecular, const in vec3 shadowPos, const in vec3 shadowColor, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss) {
//         GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, shadowColor, localPos, localNormal, texNormal, albedo, lmcoord, roughL, metal_f0, occlusion, sss, false);
//     }
// #endif

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
