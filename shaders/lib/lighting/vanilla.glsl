#if LPV_SIZE > 0
    vec3 GetLpvAmbient(const in vec3 voxelPos, const in vec3 lpvPos) {
        vec3 lpvLight = SampleLpvVoxel(voxelPos, lpvPos);
        //lpvLight = log2(lpvLight + EPSILON) / LpvRangeF;
        lpvLight *= 0.1;
        lpvLight /= (lpvLight + 2.0);
        //lpvLight *= DynamicLightAmbientF;
        return lpvLight;
    }
#endif

void GetVanillaLighting(out vec3 diffuse, const in vec2 lmcoord, const in vec3 localPos, const in vec3 localNormal, in vec3 shadowColor) {
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

        shadowColor = DynamicLightAmbientF + (1.0 - DynamicLightAmbientF) * shadowColor;
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

vec3 GetSkySpecular(const in vec3 localPos, const in float geoNoL, const in vec3 texNormal, const in vec3 shadowColor, const in vec2 lmcoord, const in float metal_f0, const in float roughL) {
    float f0 = GetMaterialF0(metal_f0);

    #ifndef IRIS_FEATURE_SSBO
        vec3 WorldSkyLightColor = GetSkyLightColor();
    #endif

    vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);// * WorldSkyBrightnessF;

    vec3 localViewDir = -normalize(localPos);
    vec3 skyH = normalize(localSkyLightDirection + localViewDir);
    float skyVoHm = max(dot(localViewDir, skyH), 0.0);

    float skyNoLm = 1.0, skyNoVm = 1.0, skyNoHm = 1.0;
    if (!all(lessThan(abs(texNormal), EPSILON3))) {
        skyNoLm = max(dot(texNormal, localSkyLightDirection), 0.0);
        skyNoVm = max(dot(texNormal, localViewDir), 0.0);
        skyNoHm = max(dot(texNormal, skyH), 0.0);
    }

    float skyF = F_schlick(skyVoHm, f0, 1.0);
    skyLightColor *= 1.0 - 0.92*rainStrength;

    float invGeoNoL = 1.0 - saturate(-geoNoL*40.0);
    vec3 specular = invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyF, roughL) * skyLightColor * shadowColor;

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        vec3 viewPos = (gbufferModelView * vec4(localPos, 1.0)).xyz;
        vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

        vec3 diffuse = vec3(0.0);
        float skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);
        specular += ApplyReflections(viewPos, texViewNormal, skyReflectF, lmcoord.y, sqrt(roughL));
        diffuse *= 1.0 - skyReflectF;
    #endif

    return specular;
}

vec3 GetFinalLighting(const in vec3 albedo, in vec3 diffuse, in vec3 specular, const in float metal_f0, const in float roughL, const in float emission, const in float occlusion) {
    #if MATERIAL_SPECULAR != SPECULAR_NONE
        if (metal_f0 >= 0.5) {
            diffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
            specular *= albedo;
        }
    #endif

	vec3 final = albedo;
	final *= WorldMinLightF + diffuse * occlusion + emission * MaterialEmissionF;
	final += specular;

	return final;
}
