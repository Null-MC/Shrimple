const float skyLightSize = 8.0;
const float skyLightDist = 100.0;


void GetSkyLightingFinal(inout vec3 skyDiffuse, inout vec3 skySpecular, const in vec3 shadowColor, const in vec3 localPos, const in vec3 localNormal, const in vec3 texNormal, const in vec3 albedo, const in vec2 lmcoord, const in float roughL, const in float metal_f0, const in float occlusion, const in float sss, const in bool tir) {
    vec3 localViewDir = -normalize(localPos);

    //vec2 lmSky = vec2(0.0, lmcoord.y);

    //vec3 skyLightColor = vec3(1.0);

    // #if !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE)
    //     skyLightColor *= _pow3(lmcoord.y);
    // #endif

    // #if !defined LIGHT_LEAK_FIX && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
    // //     float shadow = maxOf(abs(shadowPos * 2.0 - 1.0));
    // //     shadow = 1.0 - smoothstep(0.5, 0.8, shadow);

    //     skyLightColor = mix(skyLightColor, vec3(1.0), shadowFade);
    // #endif
    
    #ifdef IRIS_FEATURE_SSBO
        vec3 localSkyLightDir = localSkyLightDirection;
    #else
        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            vec3 localSkyLightDir = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
        #else
            vec3 localSkyLightDir = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            if (worldTime > 12000 && worldTime < 24000)
                localSkyLightDir = -localSkyLightDir;
        #endif
    #endif

    #ifndef RENDER_SHADOWS_ENABLED
        localSkyLightDir = vec3(0.0, 1.0, 0.0);
    #endif

    if (!all(lessThan(abs(texNormal), EPSILON3))) {
        vec3 r = reflect(-localViewDir, texNormal);
        vec3 L = localSkyLightDir * skyLightDist;
        vec3 centerToRay = dot(L, r) * r - L;
        vec3 closestPoint = L + centerToRay * saturate(skyLightSize / length(centerToRay));
        localSkyLightDir = normalize(closestPoint);
    }

    float viewDist = length(localPos);
    float shadowDistF = saturate(viewDist / shadowDistance);
    float skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);

    #ifndef IRIS_FEATURE_SSBO
        vec3 WorldSkyLightColor = GetSkyLightColor();
    #endif

    vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);// * WorldSkyBrightnessF;
    //skyLightColor *= 1.0 - 0.7 * rainStrength;

    vec3 skyLightShadowColor = shadowColor;

    #ifdef RENDER_SHADOWS_ENABLED
        skyLightShadowColor *= mix(1.0, pow5(lmcoord.y) * skyNoLm, smoothstep(0.6, 1.0, shadowDistF));
    #else
        skyLightShadowColor *= pow5(lmcoord.y);// * skyNoLm;
        //skyLightShadowColor *= smootherstep(lmcoord.y);
    #endif

    skyLightShadowColor *= skyLightColor;

    // #ifndef RENDER_SHADOWS_ENABLED
    //     skyLightShadowColor *= pow5(lmcoord.y);
    // #endif

    float geoNoL = 1.0;
    if (!all(lessThan(abs(localNormal), EPSILON3)))
        geoNoL = dot(localNormal, localSkyLightDir);

    float diffuseNoLm = GetLightNoL(geoNoL, texNormal, localSkyLightDir, sss);

    float invAO = saturate(1.0 - occlusion);
    diffuseNoLm = max(diffuseNoLm - _pow2(invAO), 0.0);

    vec3 H = normalize(localSkyLightDir + localViewDir);
    float diffuseNoVm = max(dot(texNormal, localViewDir), 0.0);
    float diffuseLoHm = max(dot(localSkyLightDir, H), 0.0);
    float D = SampleLightDiffuse(diffuseNoVm, diffuseNoLm, diffuseLoHm, roughL);
    D *= mix(1.0, MaterialSssStrengthF, sss);
    vec3 accumDiffuse = D * skyLightShadowColor;// * (1.0 - shadowDistF);
    //accumDiffuse *= 1.0 + MaterialSssStrengthF * sss;

    vec2 lmcoordFinal = vec2(0.0, lmcoord.y);
    // #ifdef RENDER_SHADOWS_ENABLED
    //     lmcoordFinal.y = _pow3(lmcoordFinal.y);
    // #endif

    // float skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0) * 0.5 + 0.5;
    // //float skyNoLm = dot(texNormal, localSkyLightDir) * 0.5 + 0.5;

    // #ifdef LIGHTING_OLD
    //     lmcoordFinal.y *= 0.5 + 0.5 * diffuseNoLm;
    //     float sunAngleRange = (1.0 - DynamicLightAmbientF) * localSkyLightDir.y;
    //     lmcoordFinal.y *= skyNoLm * sunAngleRange + (1.0 - sunAngleRange);
    // #endif

    lmcoordFinal = LightMapTex(lmcoordFinal);

    vec3 lightmapColor = textureLod(TEX_LIGHTMAP, lmcoordFinal, 0).rgb;
    vec3 ambientLight = RGBToLinear(lightmapColor);

    //ambientLight = _pow2(ambientLight);

    ambientLight *= max(dot(texNormal, localSkyLightDir), 0.0) * 0.5 + 0.5;
    //ambientF *= dot(texNormal, localSkyLightDir) * 0.5 + 0.5;

    ambientLight *= DynamicLightAmbientF;


    #if LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0 && !defined RENDER_CLOUDS //&& LIGHTING_MODE != DYN_LIGHT_LPV
        vec3 lpvPos = GetLPVPosition(localPos);

        float lpvFade = GetLpvFade(lpvPos);
        lpvFade = smootherstep(lpvFade);
        lpvFade *= 1.0 - LpvLightmapMixF;

        vec4 lpvSample = SampleLpv(lpvPos, texNormal);
        float lpvSkyLight = GetLpvSkyLight(lpvSample);

        // #ifdef LPV_GI
        //     lpvSkyLight *= 0.5;
        // #endif

        ambientLight = vec3(lpvSkyLight);//mix(ambientLight, vec3(lpvSkyLight), lpvFade);
    #endif

    ambientLight *= skyLightColor;

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
        vec3 f0 = GetMaterialF0(albedo, metal_f0);

        //vec3 skyH = normalize(localSkyLightDir + localViewDir);
        float skyVoHm = max(dot(localViewDir, H), 0.0);

        skyNoLm = 1.0;
        float skyNoVm = 1.0, skyNoHm = 1.0;
        if (!all(lessThan(abs(texNormal), EPSILON3))) {
            skyNoLm = max(dot(texNormal, localSkyLightDir), 0.0);
            skyNoVm = max(dot(texNormal, localViewDir), 0.0);
            skyNoHm = max(dot(texNormal, H), 0.0);
        }

        vec3 skyF = F_schlickRough(skyVoHm, f0, roughL);

        // TODO: might want this for vanilla/no clouds
        //skyLightColor *= 1.0 - 0.92*rainStrength;

        float invGeoNoL = saturate(geoNoL*40.0);
        skySpecular += invGeoNoL * SampleLightSpecular(skyNoVm, skyNoLm, skyNoHm, skyVoHm, skyF, roughL) * skyLightShadowColor;

        #if MATERIAL_REFLECTIONS != REFLECT_NONE
            vec3 viewPos = (gbufferModelView * vec4(localPos, 1.0)).xyz;
            vec3 texViewNormal = mat3(gbufferModelView) * texNormal;

            vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);

            if (tir) skyReflectF = vec3(1.0);

            accumDiffuse *= 1.0 - skyReflectF;

            #if !(MATERIAL_REFLECTIONS == REFLECT_SCREEN && defined RENDER_OPAQUE_FINAL)
                skySpecular += ApplyReflections(localPos, viewPos, texViewNormal, lmcoord.y, sqrt(roughL)) * skyReflectF;
            #endif
        #endif
    #endif

    skyDiffuse += accumDiffuse;

    if (lightningStrength > EPSILON) {
        vec4 lightningDirectionStrength = GetLightningDirectionStrength(localPos);
        float lightningNoLm = max(dot(lightningDirectionStrength.xyz, texNormal), 0.0);
        skyDiffuse += lightningNoLm * lightningDirectionStrength.w * _pow2(lmcoord.y);
    }
}
