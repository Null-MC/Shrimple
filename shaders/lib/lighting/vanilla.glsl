void GetVanillaLighting(out vec3 diffuse, in vec2 lmcoord, const in vec3 localNormal, in vec3 shadowColor) {
    // if (!all(lessThan(abs(localNormal), EPSILON3))) {
    //     float geoNoL = dot(localNormal, localSkyLightDirection);
    //     geoNoL = pow(max(geoNoL, 0.0), 0.2);
    //     lmcoord.y *= max(geoNoL, DynamicLightAmbientF);
    // }

    lmcoord = saturate(lmcoord) * (15.0/16.0) + (0.5/16.0);
    vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmcoord, 0).rgb;
    lightmapColor = RGBToLinear(lightmapColor);

    shadowColor = DynamicLightAmbientF + (1.0 - DynamicLightAmbientF) * shadowColor;
    diffuse = lightmapColor * shadowColor;
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
        ApplyReflections(diffuse, specular, viewPos, texViewNormal, skyReflectF, lmcoord.y, sqrt(roughL));
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
