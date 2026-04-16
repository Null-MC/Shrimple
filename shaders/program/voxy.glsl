#include "/lib/constants.glsl"
#include "/lib/common.glsl"


#include "/lib/blocks.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"
#include "/lib/shadows.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_SPECULAR)
    #include "/lib/fresnel.glsl"
    #include "/lib/material/pbr.glsl"

    #ifdef MATERIAL_PBR_ENABLED
        #include "/lib/material/lazanyi.glsl"
    #endif
#endif

//#if defined(WATER_WAVE_ENABLED) && defined(RENDER_TRANSLUCENT)
//    #include "/lib/water-waves.glsl"
//#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        #include "/lib/sky-transmit.glsl"
        #include "/lib/sky-irradiance.glsl"
    #endif

    #include "/lib/enhanced-lighting.glsl"
#else
    #include "/lib/vanilla-light.glsl"
#endif

#ifdef LIGHTING_SPECULAR
    #include "/lib/lighting/specular.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif


#include "_output.glsl"

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    vec4 color = parameters.sampledColour;
    color.rgb *= parameters.tinting.rgb;

    vec3 ndcPos = gl_FragCoord.xyz;
    ndcPos.xy /= viewSize;
    ndcPos = ndcPos * 2.0 - 1.0;

    vec3 viewPos = project(vxProjInv, ndcPos);
    vec3 localPos = mul3(vxModelViewInv, viewPos);

    vec3 localNormal = vec3(
        uint((parameters.face >> 1) == 2),
        uint((parameters.face >> 1) == 0),
        uint((parameters.face >> 1) == 1)
    ) * (float(int(parameters.face) & 1) * 2.0 - 1.0);

    // TODO: if vanilla lighting, make foliage have "up" normals
    #ifndef MATERIAL_PBR_ENABLED
        bool isGrass = parameters.customId == BLOCK_GRASS_SHORT
            || parameters.customId == BLOCK_TALL_GRASS_LOWER
            || parameters.customId == BLOCK_TALL_GRASS_UPPER;

        if (isGrass) localNormal = vec3(0,1,0);
    #endif

    vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);

    vec3 localTexNormal = localNormal;
    #ifdef RENDER_TRANSLUCENT
        if (parameters.customId == BLOCK_WATER) {
            #ifndef WATER_TEXTURE_ENABLED
                //color = RGBToLinear(parameters.tinting.rgb);
                color = vec4(vec3(0.0), Water_f0);
            #endif

            #if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_SPECULAR)
                specularData = vec4(0.98, Water_f0, 0.0, 0.0);
            #endif

//            #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TRANSLUCENT)
//                vec2 waterWorldPos = (localPos.xz + cameraPosition.xz);
//                float waveHeight = wave_fbm(waterWorldPos, 12);
//                vec3 wavePos = vec3(localPos.xz, waveHeight);
//    //            wavePos.z += localPos.y - vIn.waveHeight;
//
//                vec3 dX = dFdx(wavePos);
//                vec3 dY = dFdy(wavePos);
//                localTexNormal = normalize(cross(normalize(dY), normalize(dX))).xzy;
//            #endif
        }
    #endif

    float viewDist = length(localPos);
    vec2 lmcoord_in = LightMapNorm(parameters.lightMap);
    vec3 albedo = RGBToLinear(color.rgb);

    vec3 localSkyLightDir = normalize(mat3(vxModelViewInv) * shadowLightPosition);
    vec3 localViewDir = normalize(localPos);

    float shadowF = 1.0;//pow4(lmcoord_in.y);
    #ifdef SHADOW_CLOUDS
        shadowF *= SampleCloudShadow(localPos, localSkyLightDir);
    #endif

    #ifdef LIGHTING_SPECULAR
//        #ifdef MATERIAL_PBR_ENABLED
//            float roughness = mat_roughness(specularData.r);
//            float metalness = mat_metalness(specularData.g);
//        #else
            float roughness = mat_roughness_lab(specularData.r);
            float metalness = mat_metalness_lab(specularData.g);
//        #endif

        float roughL = _pow2(roughness);
    #endif

    vec3 diffuseFinal = vec3(0.0);
    vec3 specularFinal = vec3(0.0);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        shadowF *= smoothstep((2.5/16.0), (13.5/16.0), lmcoord_in.y);

        vec2 lmcoord = _pow3(lmcoord_in);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

        diffuseFinal = blockLight + MinAmbientF;

        #ifdef WORLD_OVERWORLD
            vec3 skyLightColor = shadowF * GetSkyLightColor(localPos, sunLocalDir.y, localSkyLightDir.y);

            float skyLight_NoLm = dot(localSkyLightDir, localTexNormal);
//            #ifdef MATERIAL_PBR_ENABLED
//                skyLight_NoLm = (skyLight_NoLm + sss) / (1.0 + sss);
//            #endif

            skyLight_NoLm = max(skyLight_NoLm, 0.0);
            vec3 skyLight = skyLight_NoLm * skyLightColor;

            #ifndef SHADOWS_ENABLED
                skyLight *= lmcoord.y;
            #endif

            skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(localTexNormal);

            diffuseFinal += skyLight;

            #ifdef LIGHTING_SPECULAR
                if (skyLight_NoLm > 0.0) {
                    vec3 skySpecularLightDir = GetAreaLightDir(localTexNormal, localViewDir, localSkyLightDir, 100.0, 8.0);
                    skySpecularLightDir = normalize(skySpecularLightDir + 0.1*localSkyLightDir);

                    vec3 H = normalize(skySpecularLightDir - localViewDir);
                    float sky_NoH = max(dot(localTexNormal, H), 0.0);
                    float sky_LoH = max(dot(skySpecularLightDir, H), 0.0);
                    float sky_NoV = max(dot(localTexNormal, -localViewDir), 0.0);

//                    #ifdef MATERIAL_PBR_ENABLED
//                        LazanyiF sky_L = mat_f0_lazanyi(albedo, specularData.g);
//                        vec3 sky_F = F_lazanyi(sky_LoH, sky_L.f0, sky_L.f82);
//                    #else
                        float f0 = mat_f0_lab(specularData.g);
                        float sky_F = F_schlick(sky_LoH, f0, 1.0);
//                    #endif

                    float alpha = max(roughL, 0.02);
                    specularFinal += skyLight_NoLm * D_GGX(sky_NoH, alpha) * V_Approx(skyLight_NoLm, sky_NoV, alpha) * sky_F * skyLightColor;
                }

                // apply metal tint
                specularFinal *= mix(vec3(1.0), albedo, metalness);
            #endif
        #endif
    #else
        vec2 lmcoord = lmcoord_in;

        lmcoord.y = min(lmcoord.y, shadowF * (1.0 - AmbientLightF) + AmbientLightF);

        lmcoord = LightMapTex(lmcoord);
        diffuseFinal = texture(lightmap, lmcoord).rgb;
        float oldLighting = GetOldLighting(localTexNormal);
//        #ifdef MATERIAL_PBR_ENABLED
//            oldLighting = mix(oldLighting, 1.0, sss);
//        #endif
        diffuseFinal *= oldLighting;
        diffuseFinal = RGBToLinear(diffuseFinal);
    #endif

    #ifdef LIGHTING_SPECULAR
        float NoV = dot(localTexNormal, -localViewDir);

        float smoothness = 1.0 - roughness;
//        #ifdef MATERIAL_PBR_ENABLED
//            LazanyiF lF = mat_f0_lazanyi(albedo, specularData.g);
//            vec3 F = F_lazanyi(NoV, lF.f0, lF.f82);
//
//            diffuseFinal *= 1.0 - metalness * sqrt(smoothness);
//            color.a = max(color.a, maxOf(F));
//        #else
            float f0 = mat_f0_lab(specularData.g);
            float F = F_schlick(NoV, f0, 1.0);

            color.a = max(color.a, F);
//        #endif

        diffuseFinal *= 1.0 - F * _pow2(smoothness);

        #if !(defined(SSR_ENABLED) || defined(PHOTONICS_REFLECT_ENABLED))
            // TODO: reflect in view space to avoid view-bob
            //            vec3 reflectViewDir = normalize(reflect(viewDir, texViewNormal));
            vec3 reflectLocalDir = normalize(reflect(localViewDir, localTexNormal));

            //            vec3 reflectLocalDir = mat3(gbufferModelViewInverse) * reflectViewDir;
            vec3 reflectColor = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), reflectLocalDir);
            //            reflectColor *= _pow3(lmcoord.y);
            reflectColor *= lmcoord.y;

            // apply metal tint
            reflectColor *= mix(vec3(1.0), albedo, metalness);

            specularFinal += F * _pow2(smoothness) * reflectColor;
        #endif
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        float emission = mat_emission(specularData);
        TransformEmission(emission);
        diffuseFinal += emission;
    #endif

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        outFinal.rgb = albedo/PI * diffuseFinal * color.a + specularFinal;
    #else
        outFinal.rgb = albedo * diffuseFinal + specularFinal;
    #endif
    outFinal.a = color.a;

    #if !defined(SSAO_ENABLED) || defined(RENDER_TRANSLUCENT)
        float borderFogF = GetBorderFogStrength(viewDist);
        float envFogF = GetEnvFogStrength(viewDist);
        float fogF = saturate(max(borderFogF, envFogF));

        vec3 fogColorL = RGBToLinear(fogColor);
        vec3 skyColorL = RGBToLinear(skyColor);
        vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

        outFinal.rgb = mix(outFinal.rgb, fogColorFinal, fogF);
    #endif

    outAlbedo = color;

//    #ifdef RENDER_TRANSLUCENT
//        vec3 tint = LinearToRGB(albedo * color.a);
//        uint matID = 0;
//
//        if (parameters.customId == BLOCK_WATER) {
//            matID = MAT_WATER;
//            tint = parameters.tinting.rgb * 0.65;
//        }
//
//        if (parameters.customId >= BLOCK_STAINED_GLASS_BLACK && parameters.customId <= BLOCK_TINTED_GLASS)
//            matID = MAT_STAINED_GLASS;
//
//        outAlbedo = vec4(tint, (matID + 0.5) / 255.0);
//    #endif

    #ifdef VELOCITY_ENABLED
        outVelocity = vec3(0.0);
    #endif

    #ifdef DEFERRED_ENABLED
        const float occlusion = 1.0;
        uint matId = 0;
        #ifdef RENDER_TRANSLUCENT
            if (parameters.customId == BLOCK_WATER) matId = MAT_WATER;
            else if (parameters.customId >= BLOCK_STAINED_GLASS_BLACK && parameters.customId <= BLOCK_TINTED_GLASS) {
                matId = MAT_STAINED_GLASS;
            }
        #endif

        vec3 viewNormal = mat3(gbufferModelView) * localTexNormal;
        outNormals = vec4(OctEncode(localNormal), OctEncode(viewNormal));

        outSpecularMeta = uvec2(
            packUnorm4x8(specularData),
            packUnorm4x8(vec4(lmcoord, occlusion, matId / 255.0))
        );
    #endif
}
