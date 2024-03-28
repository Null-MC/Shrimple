const float skyLightSize = 8.0;
const float skyLightDist = 100.0;


vec3 GetAreaLightDir(const in vec3 localViewDir, const in vec3 localSkyLightDir, const in vec3 texNormal) {
    vec3 r = reflect(-localViewDir, texNormal);
    vec3 L = localSkyLightDir * skyLightDist;
    vec3 centerToRay = dot(L, r) * r - L;
    vec3 closestPoint = centerToRay * saturate(skyLightSize / length(centerToRay)) + L;
    return normalize(closestPoint);
}

float GetSkyDiffuseLighting(const in vec3 localViewDir, const in vec3 localSkyLightDir, const in float geoNoL, const in vec3 texNormal, const in vec3 H, const in float roughL, const in float sss) {
    float diffuseNoLm = GetLightNoL(geoNoL, texNormal, localSkyLightDir, sss);

    float diffuseNoVm = max(dot(texNormal, localViewDir), 0.0);
    float diffuseLoHm = max(dot(localSkyLightDir, H), 0.0);

    float D = SampleLightDiffuse(diffuseNoVm, diffuseNoLm, diffuseLoHm, roughL);
    return D * mix(1.0, MaterialSssStrengthF, sss);
}

void GetSkyLightingFinal(inout vec3 skyDiffuse, inout vec3 skySpecular, in vec3 shadowColor, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss, const in bool tir) {
    float viewDist = length(localPos);
    vec3 localViewDir = -localPos / viewDist;

    #ifndef RENDER_SHADOWS_ENABLED
        // shadowColor *= _pow3(lmcoord.y);
        shadowColor *= pow(lmcoord.y, 9);
    #endif
    
    #ifdef IRIS_FEATURE_SSBO
        vec3 localSkyLightDir = localSkyLightDirection;
    #else
        #ifdef RENDER_SHADOWS_ENABLED
            vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
        #else
            vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
            if (worldTime > 12000 && worldTime < 24000)
                localSkyLightDir = -localSkyLightDir;
        #endif
    #endif

    // #ifndef RENDER_SHADOWS_ENABLED
    //     localSkyLightDir = vec3(0.0, 1.0, 0.0);
    // #endif

    if (!all(lessThan(abs(texNormal), EPSILON3)))
        localSkyLightDir = GetAreaLightDir(localViewDir, localSkyLightDir, texNormal);

    float shadowDistF = saturate(viewDist / shadowDistance);
    float skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);

    #ifndef IRIS_FEATURE_SSBO
        vec3 WorldSkyLightColor = GetSkyLightColor();
    #endif

    vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);// * WorldSkyBrightnessF;

    vec3 skyLightShadowColor = shadowColor * skyLightColor;

    float geoNoL = 1.0;
    if (!all(lessThan(abs(localNormal), EPSILON3)))
        geoNoL = dot(localNormal, localSkyLightDir);

    vec3 H = normalize(localSkyLightDir + localViewDir);
    vec3 accumDiffuse = GetSkyDiffuseLighting(localViewDir, localSkyLightDir, geoNoL, texNormal, H, roughL, sss) * skyLightShadowColor;

    vec2 lmcoordFinal = vec2(0.0, lmcoord.y);
    lmcoordFinal = LightMapTex(lmcoordFinal);
    vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmcoordFinal, 0).rgb;
    vec3 ambientLight = RGBToLinear(lightmapColor);

    float diffuseF = 1.0;
    #if defined IS_LPV_SKYLIGHT_ENABLED && !defined RENDER_CLOUDS
        diffuseF = 0.75;

        vec3 lpvPos = GetLPVPosition(localPos);

        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smootherstep(lpvFade);
        lpvFade *= 1.0 - LpvLightmapMixF;

        vec4 lpvSample = SampleLpv(lpvPos, localNormal, texNormal);

        float lpvSkyLight = GetLpvSkyLight(lpvSample);

        #if LPV_SKYLIGHT == LPV_SKYLIGHT_FANCY
            #if LIGHTING_MODE >= LIGHTING_MODE_FLOODFILL
                lpvSkyLight *= 0.125;
            #endif

            vec3 lpvSkyLightColor = GetLpvBlockLight(lpvSample);

            // lpvSkyLightColor *= lpvSkyLight / max(luminance(lpvSkyLightColor), EPSILON);
            lpvSkyLightColor = RgbToHsv(lpvSkyLightColor);
            lpvSkyLightColor.z = lpvSkyLight;
            lpvSkyLightColor = HsvToRgb(lpvSkyLightColor);

            ambientLight = mix(ambientLight, lpvSkyLightColor, lpvFade);
        #else
            ambientLight = mix(ambientLight, vec3(lpvSkyLight), lpvFade);
        #endif
    #endif

    float horizonF = min(abs(localSunDirection.y + 0.1), 1.0);
    horizonF = pow(1.0 - horizonF, 8.0);

    float ambientF = mix(DynamicLightAmbientF, 2.0, horizonF);

    float sun_NoL = dot(texNormal, localSunDirection);
    float moon_NoL = max(-sun_NoL, 0.0) * 0.5 + 0.5;
    sun_NoL = max(sun_NoL, 0.0) * 0.5 + 0.5;

    sun_NoL *= max(localSunDirection.y, 0.0);
    moon_NoL *= max(-localSunDirection.y, 0.0);

    vec3 skyAmbientLight = sun_NoL * WorldSunLightColor * WorldSunBrightnessF;
    skyAmbientLight += moon_NoL * WorldMoonLightColor * WorldMoonBrightnessF;
    ambientLight *= skyAmbientLight * ambientF;

    // if (any(greaterThan(abs(texNormal), EPSILON3)))
    //     ambientLight *= (texNormal.y * 0.3 + 0.7);

    accumDiffuse += ambientLight * occlusion;// * roughL;

    #if MATERIAL_SPECULAR != SPECULAR_NONE
        #if MATERIAL_SPECULAR == SPECULAR_LABPBR
            if (IsMetal(metal_f0))
                accumDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
        #else
            accumDiffuse *= mix(vec3(1.0), albedo, metal_f0 * (1.0 - roughL));
        #endif
    #endif

    #if MATERIAL_SPECULAR != SPECULAR_NONE && !defined RENDER_CLOUDS
        #ifndef RENDER_SHADOWS_ENABLED
            localSkyLightDir = vec3(0.0, 1.0, 0.0);

            H = normalize(localSkyLightDir + localViewDir);

            geoNoL = 1.0;
            if (!all(lessThan(abs(localNormal), EPSILON3)))
                geoNoL = dot(localNormal, localSkyLightDir);
        #endif

        vec3 f0 = GetMaterialF0(albedo, metal_f0);
        float skyVoHm = max(dot(localViewDir, H), 0.0);
        vec3 skyF = F_schlickRough(skyVoHm, f0, roughL);

        skyNoLm = 1.0;
        float skyNoVm = 1.0, skyNoHm = 1.0;
        if (!all(lessThan(abs(texNormal), EPSILON3))) {
            skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);
            skyNoVm = max(dot(texNormal, localViewDir), 0.0);
            skyNoHm = max(dot(texNormal, H), 0.0);
        }

        float invGeoNoL = saturate(geoNoL*40.0);
        skySpecular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyVoHm, skyF, roughL) * skyLightShadowColor;

        #if MATERIAL_REFLECTIONS != REFLECT_NONE
            vec3 viewPos = mul3(gbufferModelView, localPos);
            vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

            vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);

            if (tir) skyReflectF = vec3(1.0);

            accumDiffuse *= 1.0 - skyReflectF;

            #if !(MATERIAL_REFLECTIONS == REFLECT_SCREEN && defined RENDER_OPAQUE_FINAL)
                skySpecular += ApplyReflections(localPos, viewPos, texViewNormal, lmcoord.y, sqrt(roughL)) * skyReflectF;
            #endif
        #endif
    #endif

    skyDiffuse += accumDiffuse * diffuseF;

    if (lightningStrength > EPSILON) {
        vec4 lightningDirectionStrength = GetLightningDirectionStrength(localPos);
        float lightningNoLm = max(dot(lightningDirectionStrength.xyz, texNormal), 0.0);
        skyDiffuse += lightningNoLm * lightningDirectionStrength.w * _pow2(lmcoord.y);
    }
}
