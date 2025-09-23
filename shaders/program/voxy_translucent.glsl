#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef DEFERRED_BUFFER_ENABLED
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out uvec4 outDeferredData;
    layout(location = 2) out vec3 outDeferredTexNormal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 1,3,9,7 */
        layout(location = 3) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 1,3,9 */
    #endif
#else
    layout(location = 0) out vec4 outFinal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 0,7 */
        layout(location = 1) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 0 */
    #endif
#endif

uniform int fogShape = 0;

#include "/lib/blocks.glsl"

#include "/lib/sampling/ign.glsl"
#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"

    #ifdef WORLD_WETNESS_ENABLED
//        #include "/lib/world/wetness.glsl"
//        #include "/lib/world/wetness_ripples.glsl"
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"

    #if WATER_WAVE_SIZE > 0
        #include "/lib/water/water_waves.glsl"
    #endif

    #if defined WATER_FOAM || defined WATER_FLOW
        #include "/lib/water/foam.glsl"
    #endif
#endif

#ifndef DEFERRED_BUFFER_ENABLED
    #include "/lib/sampling/erp.glsl"
    #include "/lib/sampling/noise.glsl"

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/clouds/cloud_common.glsl"
        #include "/lib/world/lightning.glsl"
    #endif

    #include "/lib/fog/fog_common.glsl"

    #if SKY_TYPE == SKY_TYPE_VANILLA
        #include "/lib/fog/fog_vanilla.glsl"
    #endif

    #include "/lib/lighting/fresnel.glsl"
    #include "/lib/lighting/sampling.glsl"
    #include "/lib/lighting/scatter_transmit.glsl"

    #ifdef IS_LPV_ENABLED
        #include "/lib/buffers/volume.glsl"

        #include "/lib/voxel/lpv/lpv.glsl"
        #include "/lib/voxel/lpv/lpv_render.glsl"
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        #if defined(WORLD_SKY_ENABLED) && defined(MATERIAL_REFLECT_CLOUDS)
            #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
                #include "/lib/clouds/cloud_custom.glsl"
            #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
                #include "/lib/clouds/cloud_vanilla.glsl"
            #endif
        #endif

        #include "/lib/lighting/reflections.glsl"
    #endif

    #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/sky/irradiance.glsl"
        #include "/lib/sky/sky_lighting.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/traced.glsl"
    #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        #include "/lib/lighting/floodfill.glsl"
    #else
        #include "/lib/lighting/vanilla.glsl"
    #endif
#endif


void voxy_emitFragment(VoxyFragmentParameters parameters) {
    bool isWater = parameters.customId == BLOCK_WATER;

    vec4 color = parameters.sampledColour;
    color.rgb *= parameters.tinting.rgb;

    vec3 localGeoNormal = vec3(
        uint((parameters.face >> 1) == 2),
        uint((parameters.face >> 1) == 0),
        uint((parameters.face >> 1) == 1)
    ) * (float(int(parameters.face) & 1) * 2.0 - 1.0);

    vec3 albedo = RGBToLinear(color.rgb);
    vec2 lmcoord = LightMapNorm(parameters.lightMap);
    const float parallaxShadow = 1.0;

    float roughness = 0.86;//GetBlockRoughness(parameters.customId);
    const float emission = 0.0;//computeBlockEmission(parameters.customId);
    float metal_f0 = 0.04;//GetBlockMetalF0(parameters.customId);
    float sss = 0.0;//GetBlockSSS(parameters.customId);
    const float occlusion = 1.0;
    const float porosity = 0.0;

    vec3 ndcPos = gl_FragCoord.xyz;
    ndcPos.xy /= viewSize;
    ndcPos = ndcPos * 2.0 - 1.0;

    vec3 viewPos = unproject(gbufferProjectionInverse, ndcPos);
    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
    float viewDist = length(localPos);

    #ifdef WORLD_WATER_ENABLED
        // TODO: CHANGE TO IS_VOXEL_ENABLED! (doesn't exist rn)
        const bool isWaterCovered = false;
        vec3 waveOffset = vec3(0.0);
        float oceanFoam = 0.0;
//        #ifdef IS_LPV_ENABLED
//            if (isWater) {
//                ivec3 voxelPos = ivec3(GetVoxelPosition(vIn.originPos));
//                // TODO: offset in normal direction
//                voxelPos += ivec3(round(localNormal));
//
//                uint blockId = texelFetch(texVoxels, voxelPos, 0).r;
//                isWaterCovered = (blockId != 0u);
//            }
//        #endif

        if (isWater) {
            vec3 waterWorldPos = localPos + cameraPosition;

            #if WATER_WAVE_SIZE > 0
                if (abs(localGeoNormal.y) > 0.5) {
                    float time = GetAnimationFactor();
                    waveOffset = GetWaveHeight(waterWorldPos, lmcoord.y, time, WATER_WAVE_DETAIL);
                }
            #endif

//            #ifdef WATER_FOAM
//                oceanFoam = SampleWaterFoam(waterWorldPos + vec3(waveOffset.xz, 0.0).xzy, localGeoNormal);
//            #endif

            #ifdef WATER_TEXTURED
                // default specular values when not present
                if (roughness > 1.0-EPSILON) {
                    metal_f0 = 0.02;
                    roughness = WATER_ROUGH;
                    //sss = 0.0;
                }
            #else
                if (isWaterCovered) oceanFoam = 0.0;

                albedo = mix(albedo, vec3(1.0), oceanFoam);
                metal_f0  = mix(0.02, 0.04, oceanFoam);
                roughness = mix(WATER_ROUGH, 0.50, oceanFoam);
                sss = oceanFoam;

                color.a = max(color.a, 0.02);
                color.a = mix(color.a, 1.0, oceanFoam);
            #endif
        }
    #endif

    vec3 localTexNormal = localGeoNormal;
//    #if defined(WORLD_WATER_ENABLED) && defined(WATER_TEXTURED) && WATER_WAVE_SIZE > 0
//        if (isWater && localGeoNormaL.y > 0.5) {
//            float waveDistF = 32.0 / (32.0 + viewDist);
//
//            vec3 wavePos = waterLocalPos;
//            wavePos.y += waveOffset.y * waveDistF;
//
//            vec3 dX = dFdx(wavePos);
//            vec3 dY = dFdy(wavePos);
//            localTexNormal = normalize(cross(dX, dY));
//            //waterUvOffset = waveOffset.xz * waveDistF;
//
//            // TODO: regen tangent?
//
////            if (localNormal.y >= 1.0 - EPSILON) {
////                localCoord += waterUvOffset;
////                atlasCoord = GetAtlasCoord(localCoord, vIn.atlasBounds);
////            }
//        }
//    #endif

    #if defined DEFERRED_BUFFER_ENABLED || defined EFFECT_SSAO_ENABLED
        outDeferredTexNormal = localTexNormal * 0.5 + 0.5;
    #endif

    //albedo = vec3(0.0);

    #ifdef DEFERRED_BUFFER_ENABLED
//        #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
//            ApplySkyWetness(roughness, porosity, skyWetness, puddleF);
//        #endif

        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vIn.localPos);
        #endif

        color.rgb = LinearToRGB(albedo);
        outDeferredColor = color + dither;

        outDeferredData.r = packUnorm4x8(vec4(localGeoNormal * 0.5 + 0.5, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(lmcoord, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(0.0, parallaxShadow, 0.0, 0.0) + dither);
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0) + dither);
    #else
        float roughL = _pow2(roughness);

        vec3 shadowColor = vec3(1.0);
        #ifdef RENDER_SHADOWS_ENABLED
            #ifndef IRIS_FEATURE_SSBO
                vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
            #endif

            float skyGeoNoL = dot(localGeoNormal, localSkyLightDirection);

            if (skyGeoNoL < EPSILON && sss < EPSILON) {
                shadowColor = vec3(0.0);
            }
            else {
                #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                    float shadowFade = 0.0;
                    float lmShadow = 1.0;
                #else
                    float shadowFade = float(vIn.shadowPos != clamp(vIn.shadowPos, -1.0, 1.0));

                    float lmShadow = pow(lmcoord.y, 9);
                    if (vIn.shadowPos == clamp(vIn.shadowPos, -0.85, 0.85)) lmShadow = 1.0;
                #endif

                #ifdef SHADOW_COLORED
                    // shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);
                    //if (vIn.shadowPos == clamp(vIn.shadowPos, -1.0, 1.0))
                    if (shadowFade < 1.0)
                        shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);

                    //shadowColor = mix(shadowColor, vec3(lmShadow), shadowFade);
                    shadowColor = min(shadowColor, vec3(lmShadow));
                #else
                    float shadowF = 1.0;
                    // if (vIn.shadowPos == clamp(vIn.shadowPos, -1.0, 1.0))
                    if (shadowFade < 1.0)
                        shadowF = GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss);

                    // float shadowF = GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss);
                    //shadowF = mix(shadowF, lmShadow, shadowFade);
                    shadowF = min(shadowF, lmShadow);
                    shadowColor = vec3(shadowF);
                #endif
            }
        #else
            // shadowColor = vec3(pow(lmcoord.y, 9));
        #endif

        // #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
        //     float cloudShadow = TraceCloudShadow(cameraPosition + vIn.localPos, localSkyLightDirection, CLOUD_GROUND_SHADOW_STEPS);
        //     deferredShadow.rgb *= 1.0 - (1.0 - cloudShadow) * (1.0 - Shadow_CloudBrightnessF);
        // #endif

//        #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
//            ApplySkyWetness(albedo, roughness, porosity, skyWetness, puddleF);
//        #endif

        vec3 diffuseFinal = vec3(0.0);
        vec3 specularFinal = vec3(0.0);

        #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
            GetFloodfillLighting(diffuseFinal, specularFinal, localPos, localGeoNormal, localTexNormal, lmcoord, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);

            diffuseFinal += emission * MaterialEmissionF;
        #elif LIGHTING_MODE < LIGHTING_MODE_FLOODFILL
            GetVanillaLighting(diffuseFinal, lmcoord, shadowColor, occlusion);
        #endif

        #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
            const bool tir = false;
            const bool isUnderWater = false;
            GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, localPos, localGeoNormal, localTexNormal, albedo, lmcoord, roughL, metal_f0, occlusion, sss, isUnderWater, tir);
        #else
            diffuseFinal += WorldAmbientF;
        #endif

        #if MATERIAL_SPECULAR != SPECULAR_NONE && LIGHTING_MODE != LIGHTING_MODE_NONE
            ApplyMetalDarkening(diffuseFinal, specularFinal, albedo, metal_f0, roughL);
        #endif

        #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
        #elif LIGHTING_MODE < LIGHTING_MODE_FLOODFILL
            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
        #endif

        #ifdef SKY_BORDER_FOG_ENABLED
            ApplyFog(color, localPos, localViewDir);
            color.a = 1.0;
        #endif

        #if defined WORLD_SKY_ENABLED && LIGHTING_VOLUMETRIC != VOL_TYPE_NONE //&& SKY_CLOUD_TYPE <= CLOUDS_VANILLA
            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 0) {
            #endif

            float maxDist = min(viewDist, far);

            vec3 vlLight = (phaseAir + AirAmbientF) * WorldSkyLightColor;
            vec4 scatterTransmit = ApplyScatteringTransmission(maxDist, vlLight, AirScatterColor, AirExtinctColor);
            color.rgb = color.rgb * scatterTransmit.a + scatterTransmit.rgb;

            #ifdef WORLD_WATER_ENABLED
                }
            #endif
        #endif

        outFinal = color;
    #endif

    #ifdef EFFECT_TAA_ENABLED
        outVelocity = vec4(0.0);
    #endif
}