#if LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0
    vec3 GetLpvAmbient(const in vec3 lpvPos, const in vec3 normal) {
        vec3 lpvLight = SampleLpv(lpvPos, normal).rgb;
        //lpvLight = log2(lpvLight + EPSILON) / LpvRangeF;
        lpvLight *= 0.1;
        lpvLight /= (lpvLight + 2.0);
        //lpvLight *= DynamicLightAmbientF;
        return lpvLight;
    }
#endif

void GetVanillaLighting(out vec3 diffuse, const in vec2 lmcoord, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec3 shadowColor, in float sss) {
    vec2 lmFinal = lmcoord;

    #if defined WORLD_SKY_ENABLED && !defined RENDER_SHADOWS_ENABLED
        float skyNoLm = max(dot(texNormal, localSkyLightDirection), 0.0);
        lmFinal.y *= skyNoLm * 0.5 + 0.5;
    #endif

    lmFinal = LightMapTex(lmFinal);

    // #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            vec3 WorldSkyLightColor = GetSkyLightColor();
        #endif
    
        float lightMax = rcp(max(lmcoord.x + lmcoord.y, 1.0));

        vec3 lightmapBlock = textureLod(TEX_LIGHTMAP, vec2(lmFinal.x, lmCoordMin), 0).rgb;
        lightmapBlock = RGBToLinear(lightmapBlock) * DynamicLightBrightness * lightMax;
        lightmapBlock *= blackbody(LIGHTING_TEMP);

        vec3 lightmapSky = textureLod(TEX_LIGHTMAP, vec2(lmCoordMin, lmFinal.y), 0).rgb;
        lightmapSky = RGBToLinear(lightmapSky) * WorldSkyLightColor * lightMax;

        float horizonF = smoothstep(0.0, 0.12, abs(localSkyLightDirection.y));

        float ambientF = DynamicLightAmbientF;
        ambientF = 1.0 - (1.0 - ambientF) * horizonF;

        vec3 ambientLight = vec3(ambientF);

        if (any(greaterThan(abs(texNormal), EPSILON3)))
            ambientLight *= (texNormal.y * 0.3 + 0.7);

        float viewDist = length(localPos);
        float shadowDistF = 1.0 - saturate(viewDist / shadowDistance);
        shadowColor *= 1.0 + MaterialSssBoostF * sss * shadowDistF;

        shadowColor = ambientLight + (1.0 - ambientF) * shadowColor;

        diffuse = lightmapBlock + lightmapSky * shadowColor;
    // #else
    //     vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmFinal, 0).rgb;
    //     lightmapColor = RGBToLinear(lightmapColor);

    //     diffuse = lightmapColor;

    //     float viewDist = length(localPos);
    //     float shadowDistF = 1.0 - saturate(viewDist / shadowDistance);
    //     diffuse *= 1.0 + MaterialSssBoostF * sss * shadowDistF;
    // #endif

    #if LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0
        //vec3 surfacePos = localPos;
        //surfacePos += 0.501 * localNormal;// * (1.0 - sss);

        vec3 lpvPos = GetLPVPosition(localPos);
        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smoothstep(0.0, 1.0, lpvFade);

        //vec3 voxelPos = GetVoxelBlockPosition(surfacePos);
        vec3 lpvLight = GetLpvAmbient(lpvPos, localNormal);
        diffuse += lpvLight * lpvFade;
    #endif

    #if defined WORLD_SKY_ENABLED && defined IS_IRIS
        if (lightningStrength > EPSILON) {
            vec3 lightningOffset = lightningPosition - cameraPosition - localPos;
            float lightningDist = length(lightningOffset);
            float att = max(1.0 - lightningDist * LightningRangeInv, 0.0);
            // TODO: flatten vertical distance in ground-to-cloud range?

            vec3 lightningDir = lightningOffset / lightningDist;
            float lightningNoLm = max(dot(lightningDir, localNormal), 0.0);
            diffuse += lightningNoLm * lightningStrength * LightningBrightness * pow5(att);
        }
    #endif

    //diffuse = pow(lightmapColor, vec3(rcp(DynamicLightAmbientF)));
}

#if MATERIAL_SPECULAR != SPECULAR_NONE
    vec3 GetSkySpecular(const in vec3 localPos, const in float geoNoL, const in vec3 texNormal, const in vec3 albedo, const in vec3 shadowColor, const in vec2 lmcoord, const in float metal_f0, const in float roughL) {
        vec3 specular = vec3(0.0);

        vec3 localViewDir = -normalize(localPos);

        const float skyLightSize = 9.5e9;
        const float skyLightDist = 151.e9;

        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
        #else
            vec3 localSkyLightDir = localSkyLightDirection;
        #endif

        vec3 r = reflect(-localViewDir, texNormal);
        vec3 L = localSkyLightDir * skyLightDist;
        vec3 centerToRay = dot(L, r) * r - L;
        vec3 closestPoint = L + centerToRay * saturate(skyLightSize / length(centerToRay));
        localSkyLightDir = normalize(closestPoint);

        vec3 skyH = normalize(localSkyLightDir + localViewDir);
        float skyVoHm = max(dot(localViewDir, skyH), 0.0);

        float skyNoVm = 1.0;
        if (!all(lessThan(abs(texNormal), EPSILON3))) {
            skyNoVm = max(dot(texNormal, localViewDir), 0.0);
        }

        #ifdef HCM_LAZANYI
            vec3 f0, f82;
            F_LazanyiRough(skyVoHm, f0, f82, roughL);
        #else
            vec3 f0 = GetMaterialF0(albedo, metal_f0);
            vec3 skyF = F_schlickRough(skyVoHm, f0, roughL);
        #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            #ifndef IRIS_FEATURE_SSBO
                vec3 WorldSkyLightColor = GetSkyLightColor();
            #endif

            vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);// * WorldSkyBrightnessF;

            float skyNoLm = 1.0, skyNoHm = 1.0;
            if (!all(lessThan(abs(texNormal), EPSILON3))) {
                skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);
                skyNoHm = max(dot(texNormal, skyH), 0.0);
            }

            skyLightColor *= 1.0 - 0.92*skyRainStrength;

            float invGeoNoL = 1.0 - saturate(-geoNoL*40.0);
            specular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyF, roughL) * skyLightColor * shadowColor;
        #endif

        #if MATERIAL_REFLECTIONS != REFLECT_NONE && !(MATERIAL_REFLECTIONS == REFLECT_SCREEN && defined RENDER_OPAQUE_FINAL && defined RENDER_COMPOSITE) && !(defined RENDER_CLOUDS || defined RENDER_TEXTURED || defined RENDER_WEATHER || defined RENDER_PARTICLES)
        //#if MATERIAL_REFLECTIONS == REFLECT_SKY || (MATERIAL_REFLECTIONS == REFLECT_SCREEN && !defined DEFERRED_BUFFER_ENABLED)
            vec3 viewPos = (gbufferModelView * vec4(localPos, 1.0)).xyz;
            vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

            vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);
            specular += ApplyReflections(localPos, viewPos, texViewNormal, lmcoord.y, sqrt(roughL)) * skyReflectF;
        #endif

        // TODO: Lightning specular

        return specular;
    }
#endif

vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, in vec3 specular, const in float metal_f0, const in float roughL, const in float emission, const in float occlusion) {
    #if MATERIAL_SPECULAR != SPECULAR_NONE
        #if MATERIAL_SPECULAR == SPECULAR_LABPBR
            if (IsMetal(metal_f0))
                diffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
        #else
            diffuse *= mix(vec3(1.0), albedo, metal_f0 * (1.0 - roughL));
        #endif

        specular *= GetMetalTint(albedo, metal_f0);
    
        // if (metal_f0 >= 0.5) {
        //     diffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
        //     //specular *= albedo;
        // }
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        vec3 final = vec3(WHITEWORLD_VALUE);
    #else
        vec3 final = albedo;
    #endif

	final *= (WorldMinLightF + diffuse) * occlusion + emission * MaterialEmissionF;
	final += specular;

	return final;
}
