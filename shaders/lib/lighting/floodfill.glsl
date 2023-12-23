void GetFloodfillLighting(inout vec3 blockDiffuse, inout vec3 blockSpecular, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec2 lmcoord, const in vec3 shadowColor, const in vec3 albedo, const in float metal_f0, const in float roughL, const in float occlusion, const in float sss, const in bool tir) {
    vec2 lmBlockFinal = LightMapTex(vec2(lmcoord.x, 0.0));
    vec3 lmBlockLight = textureLod(TEX_LIGHTMAP, lmBlockFinal, 0).rgb;
    lmBlockLight = RGBToLinear(lmBlockLight);

    vec3 skyDiffuse = vec3(0.0);

    #ifdef WORLD_SKY_ENABLED
        vec2 lmSkyFinal = vec2(0.0, lmcoord.y);

        #ifdef RENDER_SHADOWS_ENABLED
            lmSkyFinal.y = _pow3(lmSkyFinal.y);
        #endif

        //float skyNoLm = max(dot(texNormal, localSkyLightDirection), 0.0);
        // float skyNoLm = dot(texNormal, localSkyLightDirection) * 0.5 + 0.5;
        
        // lmSkyFinal.y *= skyNoLm * 0.5 + 0.5;
        // float sunAngleRange = (1.0 - DynamicLightAmbientF) * localSkyLightDirection.y;
        // lmSkyFinal.y *= skyNoLm * sunAngleRange + (1.0 - sunAngleRange);

        lmSkyFinal = LightMapTex(lmSkyFinal);
        vec3 lmSkyLight = textureLod(TEX_LIGHTMAP, lmSkyFinal, 0).rgb;
        skyDiffuse = RGBToLinear(lmSkyLight);

        skyDiffuse *= 1.0 + MaterialSssStrengthF * sss;

        vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
    #endif

    vec3 localViewDir = normalize(localPos);

    float horizonF = smoothstep(0.0, 0.12, abs(localSkyLightDirection.y));

    float ambientF = DynamicLightAmbientF;
    ambientF *= max(dot(texNormal, localSkyLightDirection), 0.0) * 0.5 + 0.5;
    //ambientF *= dot(texNormal, localSkyLightDirection) * 0.5 + 0.5;
    ambientF = 1.0 - (1.0 - ambientF) * horizonF;

    vec3 lpvPos = GetLPVPosition(localPos);

    if (clamp(lpvPos, ivec3(0), SceneLPVSize - 1) == lpvPos) {
        vec3 surfaceNormal = localNormal;

        if (!all(lessThan(abs(texNormal), EPSILON3))) {
            surfaceNormal = normalize(localNormal + texNormal);
        }

        vec4 lpvSample = SampleLpv(lpvPos, surfaceNormal);
        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smootherstep(lpvFade);
        //lpvFade *= 1.0 - LpvLightmapMixF;

        vec3 lpvLight = GetLpvBlockLight(lpvSample) * DynamicLightBrightness;
        blockDiffuse += mix(lmBlockLight, lpvLight, lpvFade);

        #if defined WORLD_SKY_ENABLED //&& !defined LPV_GI
            #if LPV_SUN_SAMPLES > 0 && SHADOW_TYPE != SHADOW_TYPE_NONE
                float lpvSkyLight = GetLpvSkyLight(lpvSample);

                #ifdef LPV_GI
                    lpvSkyLight *= 0.25;
                #endif

                //lpvLight += mix(vec3(lpvSkyLight), lightSky, LpvLightmapMixF) * ambientF;
                //lpvLight += (lpvSkyLight + lightSky * LpvLightmapMixF);

                skyDiffuse = mix(skyDiffuse, vec3(lpvSkyLight * ambientF), (1.0 - LpvLightmapMixF) * lpvFade);
            // #else
            //     #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            //         lpvLight += lightSky * ambientF;
            //     #else
            //         lpvLight += lightSky;
            //     #endif
            #endif
        #endif

        //skyAmbient = mix(lightDefault, lpvLight, lpvFade);
    }
    else {
        //skyAmbient = lightDefault;
        blockDiffuse += lmBlockLight;
    }

    #ifdef WORLD_SKY_ENABLED
        blockDiffuse += skyDiffuse * skyLightColor * occlusion;

        skyDiffuse = vec3(0.0);

        float geoNoL = 1.0;
        if (!all(lessThan(abs(localNormal), EPSILON3)))
            geoNoL = dot(localNormal, localSkyLightDirection);

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            float diffuseNoL = GetLightNoL(geoNoL, texNormal, localSkyLightDirection, sss);

            float viewDist = length(localPos);
            //float shadowDistF = 1.0 - saturate(viewDist / shadowDistance);
            float shadowFade = smoothstep(0.9*shadowDistance, 0.7*shadowDistance, viewDist);

            vec3 H = normalize(-localSkyLightDirection + localViewDir);
            float diffuseNoVm = max(dot(texNormal, -localViewDir), 0.0);
            float diffuseLoHm = max(dot(localSkyLightDirection, H), 0.0);
            float D = SampleLightDiffuse(diffuseNoVm, diffuseNoL, diffuseLoHm, roughL);
            skyDiffuse = D * skyLightColor * shadowColor * (1.0 - ambientF);
            skyDiffuse *= 1.0 + MaterialSssStrengthF * sss;
            skyDiffuse *= shadowFade;
        #endif

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

            float skyNoLm = 1.0;
            float skyNoVm = 1.0, skyNoHm = 1.0;
            if (!all(lessThan(abs(texNormal), EPSILON3))) {
                skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);
                skyNoVm = max(dot(texNormal, -localViewDir), 0.0);
                skyNoHm = max(dot(texNormal, skyH), 0.0);
            }

            #ifdef RENDER_SHADOWS_ENABLED
                float skyVoHm = max(dot(-localViewDir, skyH), 0.0);
                vec3 skyF = F_schlickRough(skyVoHm, f0, roughL);

                float invGeoNoL = saturate(geoNoL*40.0);
                blockSpecular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyVoHm, skyF, roughL) * skyLightColor * shadowColor * (1.0 - ambientF);
            #endif

            #if MATERIAL_REFLECTIONS != REFLECT_NONE && !(defined RENDER_TEXTURED || defined RENDER_PARTICLES || defined RENDER_WEATHER)
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

        if (lightningStrength > EPSILON) {
            vec4 lightningDirectionStrength = GetLightningDirectionStrength(localPos);
            float lightningNoLm = max(dot(lightningDirectionStrength.xyz, texNormal), 0.0);
            skyDiffuse += lightningNoLm * lightningDirectionStrength.w * _pow2(lmcoord.y);
        }

        blockDiffuse += skyDiffuse;
    #endif

    #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != DYN_LIGHT_NONE && !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) && !(defined RENDER_CLOUDS || defined RENDER_DEFERRED || defined RENDER_COMPOSITE)
        // Required "hack" to force shadow pass on iris
        if (gl_FragCoord.x < 0) blockDiffuse = texelFetch(shadowcolor0, ivec2(0.0), 0).rgb;
    #endif
}

//#if !(defined RENDER_OPAQUE_RT_LIGHT || defined RENDER_TRANSLUCENT_RT_LIGHT)
    vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, const in vec3 specular, const in float occlusion) {
        #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
            vec3 final = vec3(WHITEWORLD_VALUE);
        #else
            vec3 final = albedo;
        #endif

        // TODO: handle specular occlusion
        return final * (WorldMinLightF * occlusion + diffuse) + specular * _pow3(occlusion);
    }
//#endif
