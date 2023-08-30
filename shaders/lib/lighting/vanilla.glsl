#if LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0
    vec3 GetLpvAmbient(const in vec3 voxelPos, const in vec3 lpvPos) {
        vec3 lpvLight = SampleLpvVoxel(voxelPos, lpvPos);
        //lpvLight = log2(lpvLight + EPSILON) / LpvRangeF;
        lpvLight *= 0.1;
        lpvLight /= (lpvLight + 2.0);
        //lpvLight *= DynamicLightAmbientF;
        return lpvLight;
    }
#endif

void GetVanillaLighting(out vec3 diffuse, const in vec2 lmcoord, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, in vec3 shadowColor, in float sss) {
    // if (!all(lessThan(abs(localNormal), EPSILON3))) {
    //     float geoNoL = dot(localNormal, localSkyLightDirection);
    //     geoNoL = pow(max(geoNoL, 0.0), 0.2);
    //     lmcoord.y *= max(geoNoL, DynamicLightAmbientF);
    // }

    //lmcoord = saturate(lmcoord) * (15.0/16.0) + (0.5/16.0);
    vec2 lmFinal = saturate(lmcoord) * (15.0/16.0) + (0.5/16.0);

    #ifdef RENDER_SHADOWS_ENABLED
        float lightMax = rcp(max(lmcoord.x + lmcoord.y, 1.0));
        const float lmEmpty = (0.5/16.0);

        vec3 lightmapBlock = textureLod(TEX_LIGHTMAP, vec2(lmFinal.x, lmEmpty), 0).rgb;
        lightmapBlock = RGBToLinear(lightmapBlock) * DynamicLightBrightness * lightMax;

        vec3 lightmapSky = textureLod(TEX_LIGHTMAP, vec2(lmEmpty, lmFinal.y), 0).rgb;
        lightmapSky = RGBToLinear(lightmapSky) * WorldSkyLightColor * lightMax;

        vec3 ambientLight = vec3(DynamicLightAmbientF);

        if (any(greaterThan(abs(texNormal), EPSILON3)))
            ambientLight *= (texNormal.y * 0.3 + 0.7);

        float viewDist = length(localPos);
        float shadowDistF = 1.0 - saturate(viewDist / shadowDistance);
        shadowColor *= 1.0 + 1.65 * sss * shadowDistF;

        shadowColor = ambientLight + (1.0 - DynamicLightAmbientF) * shadowColor;

        diffuse = lightmapBlock + lightmapSky * shadowColor;
    #else
        vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmFinal, 0).rgb;
        lightmapColor = RGBToLinear(lightmapColor);

        diffuse = lightmapColor;
    #endif

    #if LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0
        vec3 surfacePos = localPos;
        surfacePos += 0.501 * localNormal;// * (1.0 - sss);

        vec3 lpvPos = GetLPVPosition(surfacePos);

        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smoothstep(0.0, 1.0, lpvFade);

        vec3 voxelPos = GetVoxelBlockPosition(surfacePos);
        vec3 lpvLight = GetLpvAmbient(voxelPos, lpvPos);
        diffuse += lpvLight * lpvFade;
    #endif

    //diffuse = pow(lightmapColor, vec3(rcp(DynamicLightAmbientF)));
}

#if MATERIAL_SPECULAR != SPECULAR_NONE
    vec3 GetSkySpecular(const in vec3 localPos, const in float geoNoL, const in vec3 texNormal, const in vec3 albedo, const in vec3 shadowColor, const in vec2 lmcoord, const in float metal_f0, const in float roughL) {
        vec3 specular = vec3(0.0);

        vec3 localViewDir = -normalize(localPos);

        const float skyLightSize = 9.5e9;
        const float skyLightDist = 151.e9;

        vec3 localSkyLightDir = localSkyLightDirection;
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

            skyLightColor *= 1.0 - 0.92*rainStrength;

            float invGeoNoL = 1.0 - saturate(-geoNoL*40.0);
            specular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyF, roughL) * skyLightColor * shadowColor;
        #endif

        #if MATERIAL_REFLECTIONS != REFLECT_NONE && !(MATERIAL_REFLECTIONS == REFLECT_SCREEN && defined RENDER_OPAQUE_FINAL && defined RENDER_COMPOSITE)
        //#if MATERIAL_REFLECTIONS == REFLECT_SKY || (MATERIAL_REFLECTIONS == REFLECT_SCREEN && !defined DEFERRED_BUFFER_ENABLED)
            vec3 viewPos = (gbufferModelView * vec4(localPos, 1.0)).xyz;
            vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

            vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);
            specular += ApplyReflections(localPos, viewPos, texViewNormal, lmcoord.y, sqrt(roughL)) * skyReflectF;
        #endif

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

	final *= WorldMinLightF + diffuse * occlusion + emission * MaterialEmissionF;
	final += specular;

	return final;
}
