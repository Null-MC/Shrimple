#define RENDER_TRANSLUCENT_FINAL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    const bool colortex0MipmapEnabled = true;
#endif

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform sampler2D BUFFER_DEFERRED_SHADOW;
uniform usampler2D BUFFER_DEFERRED_DATA;
uniform sampler2D BUFFER_DEFERRED_NORMAL_TEX;
uniform sampler2D BUFFER_OVERLAY;
// uniform sampler2D TEX_LIGHTMAP;
uniform sampler2D texBlueNoise;

#if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform sampler2D texSkyIrradiance;

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        uniform sampler2D texSky;
    #endif
#endif

#ifdef VL_BUFFER_ENABLED
    uniform sampler2D BUFFER_VL_SCATTER;
    uniform sampler2D BUFFER_VL_TRANSMIT;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_NONE
    uniform sampler2D TEX_LIGHTMAP;
#elif LIGHTING_MODE == LIGHTING_MODE_TRACED
    uniform sampler2D BUFFER_BLOCK_DIFFUSE;

    #if MATERIAL_SPECULAR != SPECULAR_NONE
        uniform sampler2D BUFFER_BLOCK_SPECULAR;
    #endif
#endif

#ifdef IS_LPV_ENABLED
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform sampler2D texDepthNear;
    //layout(r32f) uniform readonly image2D imgDepthNear;
#endif

#if defined WORLD_SKY_ENABLED && defined IS_IRIS //&& defined MATERIAL_REFLECT_CLOUDS && MATERIAL_REFLECTIONS != REFLECT_NONE
    // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
    //     uniform sampler3D TEX_CLOUDS;
    #if SKY_CLOUD_TYPE == CLOUDS_VANILLA || SKY_CLOUD_TYPE == CLOUDS_SOFT
        uniform sampler2D TEX_CLOUDS_VANILLA;
    #endif
#endif

uniform sampler3D TEX_CLOUDS;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
    uniform sampler2D dhDepthTex1;
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 upPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;
uniform float farPlane;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform float blindnessSmooth;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifndef IRIS_FEATURE_SSBO
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferPreviousProjection;
#endif

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform mat4 gbufferProjection;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform float sunAngle;
    uniform vec3 sunPosition;
    uniform vec3 shadowLightPosition;
    uniform float rainStrength;
    uniform float weatherStrength;
    //uniform float wetness;
    uniform int moonPhase;

    uniform float cloudHeight;
    uniform float cloudTime;

    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        uniform float weatherCloudStrength;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef IS_LPV_ENABLED
    uniform mat4 gbufferPreviousModelView;
#endif

// #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
//     uniform int worldTime;
// #endif

uniform bool isSpectator;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform vec3 playerBodyVector;
uniform vec3 eyePosition;

// #if EFFECT_BLUR_TYPE == DIST_BLUR_DOF
//     uniform float centerDepthSmooth;
// #endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef DISTANT_HORIZONS
    uniform mat4 dhProjection;
    uniform mat4 dhProjectionInverse;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/light_static.glsl"

    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif

    // #if LIGHTING_MODE == LIGHTING_MODE_TRACED
    //     #include "/lib/buffers/light_voxel.glsl"
    // #endif
    
    // #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    //     #include "/lib/buffers/block_static.glsl"
    // #endif

    #if WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
        #include "/lib/water/water_depths_read.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/erp.glsl"
#include "/lib/sampling/gaussian.glsl"
// #include "/lib/sampling/bilateral_gaussian.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"
#include "/lib/utility/temporal_offset.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/blackbody.glsl"
#include "/lib/lighting/scatter_transmit.glsl"
#include "/lib/lighting/fresnel.glsl"

#include "/lib/world/common.glsl"
#include "/lib/world/atmosphere.glsl"
#include "/lib/fog/fog_common.glsl"

#ifdef LIGHTING_DEBUG_LEVELS
    #include "/lib/lighting/debug_levels.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
    #include "/lib/world/atmosphere_trace.glsl"
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
    
    #ifdef WORLD_WATER_ENABLED
        #include "/lib/fog/fog_water_custom.glsl"
    #endif
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#ifdef LIGHTING_FLICKER
    #include "/lib/lighting/flicker.glsl"
#endif

#include "/lib/material/mat_deferred.glsl"

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/hcm.glsl"
    #include "/lib/material/fresnel.glsl"
#endif

#if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
    #include "/lib/voxel/voxel_common.glsl"

    #include "/lib/voxel/lights/mask.glsl"
    // #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/voxel/blocks.glsl"
#endif

#if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lighting/sampling.glsl"

#ifdef WORLD_SKY_ENABLED
    //#if SKY_CLOUD_TYPE != CLOUDS_NONE
        #include "/lib/clouds/cloud_common.glsl"
    //#endif
    
    #include "/lib/world/lightning.glsl"

     #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
         #include "/lib/clouds/cloud_custom.glsl"
         //#include "/lib/clouds/cloud_custom_shadow.glsl"
         //#include "/lib/clouds/cloud_custom_trace.glsl"
     #endif
#endif

#include "/lib/lights.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"

// #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
//     #include "/lib/lighting/voxel/sampling.glsl"
// #endif

#ifdef IS_LPV_ENABLED
    #include "/lib/buffers/volume.glsl"
    #include "/lib/utility/hsv.glsl"
    
    #include "/lib/voxel/lpv/lpv.glsl"
    #include "/lib/voxel/lpv/lpv_render.glsl"
#endif

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/items.glsl"
#endif

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    #include "/lib/utility/depth_tiles.glsl"
    #include "/lib/effects/ssr.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/sky/sky_trace.glsl"
#endif

#if MATERIAL_REFLECTIONS != REFLECT_NONE && LIGHTING_MODE != LIGHTING_MODE_NONE
    #if defined MATERIAL_REFLECT_CLOUDS && defined WORLD_SKY_ENABLED
        #if SKY_CLOUD_TYPE == CLOUDS_VANILLA || SKY_CLOUD_TYPE == CLOUDS_SOFT
            #include "/lib/clouds/cloud_vanilla.glsl"
        #endif
    #endif
    
    #include "/lib/lighting/reflections.glsl"
#endif

#if defined(WORLD_SKY_ENABLED) && LIGHTING_MODE != LIGHTING_MODE_NONE
    #include "/lib/sky/irradiance.glsl"
    #include "/lib/sky/sky_lighting.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_TRACED
    // #if LIGHTING_TRACE_FILTER > 0
        #include "/lib/sampling/light_filter.glsl"
    // #endif

    #include "/lib/lighting/traced.glsl"
#elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
    #include "/lib/lighting/floodfill.glsl"
#else
    #include "/lib/lighting/vanilla.glsl"
#endif

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/basic_hand.glsl"
#endif

#ifdef VL_BUFFER_ENABLED
    #if VOLUMETRIC_BLUR_SIZE > 0
        #include "/lib/sampling/fog_filter.glsl"
    #endif
#endif

#ifdef EFFECT_BLUR_ENABLED
    #include "/lib/effects/blur.glsl"
#endif


layout(location = 0) out vec4 outFinal;
#if defined DEFERRED_BUFFER_ENABLED && (defined DEFER_TRANSLUCENT || defined MATERIAL_REFRACT_ENABLED)
    /* RENDERTARGETS: 0 */

    void main() {
        ivec2 iTex = ivec2(gl_FragCoord.xy);
        //vec2 viewSize = vec2(viewWidth, viewHeight);

        //float depthTrans = texelFetch(depthtex0, iTex, 0).r;
        //float handClipDepth = texelFetch(depthtex2, iTex, 0).r;
        float depthTrans = textureLod(depthtex0, texcoord, 0).r;
        float depthOpaque = textureLod(depthtex1, texcoord, 0).r;
        float handClipDepth = textureLod(depthtex2, texcoord, 0).r;
        bool isHand = handClipDepth > depthTrans;

        // if (isHand) {
        //     depthTrans = depthTrans * 2.0 - 1.0;
        //     depthTrans /= MC_HAND_DEPTH;
        //     depthTrans = depthTrans * 0.5 + 0.5;
        // }

        float depthOpaqueL = linearizeDepth(depthOpaque, near, farPlane);
        float depthTransL = linearizeDepth(depthTrans, near, farPlane);

        #ifdef DISTANT_HORIZONS
            //mat4 projectionInvOpaque = gbufferProjectionInverse;
            mat4 projectionInvTrans = gbufferProjectionInverse;

            float dhDepthTrans = textureLod(dhDepthTex, texcoord, 0).r;
            float dhDepthTransL = linearizeDepth(dhDepthTrans, dhNearPlane, dhFarPlane);

            if (dhDepthTransL < depthTransL || depthTrans >= 1.0) {
                depthTrans = dhDepthTrans;
                depthTransL = dhDepthTransL;
                projectionInvTrans = dhProjectionInverse;
            }

            float dhDepthOpaque = textureLod(dhDepthTex1, texcoord, 0).r;
            float dhDepthOpaqueL = linearizeDepth(dhDepthOpaque, dhNearPlane, dhFarPlane);

            if (dhDepthOpaqueL < depthOpaqueL || depthOpaque >= 1.0) {
                depthOpaque = dhDepthOpaque;
                depthOpaqueL = dhDepthOpaqueL;
                //projectionInvOpaque = dhProjectionInverse;
            }

            vec3 clipPos = vec3(texcoord, depthTrans) * 2.0 - 1.0;
            vec3 viewPos = unproject(projectionInvTrans, clipPos);
        #else
            vec3 clipPos = vec3(texcoord, depthTrans) * 2.0 - 1.0;
            vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
        #endif

        vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

        vec2 refraction = vec2(0.0);
        vec4 final = vec4(0.0);
        bool tir = false;

        // #ifndef IRIS_FEATURE_SSBO
        //     vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        // #else
        //     vec3 localPos = unproject(gbufferModelViewProjectionInverse * vec4(clipPos, 1.0));
        // #endif

        vec3 localViewDir = normalize(localPos);
        float viewDist = length(localPos);

        vec4 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0);
        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
        vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
        // vec4 deferredFog = unpackUnorm4x8(deferredData.b);
        vec2 deferredMaterialShadow = unpackUnorm4x8(deferredData.b).rg;

        vec3 albedo = RGBToLinear(deferredColor.rgb);
        uint matId = uint(deferredMaterialShadow.x*255.0+0.5);

        // #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        //     albedo = vec3(WHITEWORLD_VALUE);
        // #elif defined LIGHTING_DEBUG_LEVELS
        //     if (matId == 0u) albedo = GetLightLevelColor(deferredLighting.x);
        // #endif

        // vec3 fogColorFinal = GetVanillaFogColor(deferredFog.rgb, localViewDir.y);
        // fogColorFinal = RGBToLinear(fogColorFinal);

        bool isWater = false;
        float roughness = 1.0;
        float roughL = 1.0;
        vec3 texNormal;

        vec3 view_F = vec3(0.0);
        vec3 diffuseFinal = vec3(0.0);
        vec3 specularFinal = vec3(0.0);
        float occlusion = 1.0;
        float emission = 0.0;

        #if WATER_DEPTH_LAYERS > 1
            uint waterPixelIndex = GetWaterDepthIndex(uvec2(gl_FragCoord.xy));
        #endif

        if (deferredColor.a > (0.5/255.0) && depthTrans < 1.0) {
            // vec4 deferredLighting = unpackUnorm4x8(deferredData.g);

            vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
            vec3 localNormal = deferredNormal.rgb;

            if (any(greaterThan(localNormal, EPSILON3)))
                localNormal = normalize(localNormal * 2.0 - 1.0);

            // vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            // texNormal = deferredTexture.rgb;

            vec3 texNormal = texelFetch(BUFFER_DEFERRED_NORMAL_TEX, iTex, 0).rgb;

            if (any(greaterThan(texNormal, EPSILON3)))
                texNormal = normalize(texNormal * 2.0 - 1.0);

            // vec4 shadowColor = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0);

            float parallaxShadow = deferredMaterialShadow.g;
            isWater = matId == deferredMat_water;

            #ifdef MATERIAL_REFRACT_ENABLED
                vec3 texViewNormal = mat3(gbufferModelView) * (texNormal - localNormal);

                //const float ior = IOR_WATER;
                float refractEta = (IOR_AIR/IOR_WATER);//isEyeInWater == 1 ? (ior/IOR_AIR) : (IOR_AIR/ior);
                vec3 refractViewDir = vec3(0.0, 0.0, 1.0);//isEyeInWater == 1 ? normalize(viewPos) : vec3(0.0, 0.0, 1.0);

                vec3 refractDir = refract(refractViewDir, texViewNormal, refractEta);
                //depthOpaqueL = linearizeDepthFast(depthOpaque, near, far);
                float linearDist = depthOpaqueL - depthTransL;

                vec2 refractMax = vec2(0.2);
                refractMax.x *= viewWidth / viewHeight;
                refraction = clamp(vec2(0.025 * linearDist * RefractionStrengthF), -refractMax, refractMax) * refractDir.xy;

                #ifdef REFRACTION_SNELL
                    if (isEyeInWater == 1) {
                        texViewNormal = mat3(gbufferModelView) * texNormal;

                        refractEta = (IOR_WATER/IOR_AIR);//isEyeInWater == 1 ? (ior/IOR_AIR) : (IOR_AIR/ior);
                        refractViewDir = normalize(viewPos);
                        refractDir = refract(refractViewDir, texViewNormal, refractEta);

                        tir = all(lessThan(abs(refractDir), EPSILON3));
                    }
                #endif
            #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                vec3 deferredRoughMetalF0Porosity = unpackUnorm4x8(deferredData.a).rgb;
                roughness = deferredRoughMetalF0Porosity.r;
                float metal_f0 = deferredRoughMetalF0Porosity.g;

                roughL = _pow2(roughness);
            #else
                float metal_f0 = 0.04;
            #endif

            vec3 shadowColor = vec3(1.0);
            float shadowSSS = 0.0;

            #ifdef RENDER_SHADOWS_ENABLED
                vec4 deferredShadowSss = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0);
                shadowColor = deferredShadowSss.rgb;
                shadowSSS = deferredShadowSss.a;
            #endif

            // #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED
            //     #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            //         shadowColor *= TraceCloudShadow(cameraPosition + localPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
            //     // #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
            //     //     shadow *= SampleCloudShadow(localSkyLightDirection, cloudPos);
            //     #endif
            // #endif

            occlusion = deferredLighting.z;
            emission = deferredLighting.a;
            float sss = deferredNormal.a;

            //if (isWater) deferredColor.a *= Water_OpacityF;

//            vec3 diffuseFinal = vec3(0.0);
//            vec3 specularFinal = vec3(0.0);

            #if LIGHTING_MODE > LIGHTING_MODE_BASIC
                #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
                    GetFinalBlockLighting(diffuseFinal, specularFinal, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, occlusion, sss);

                    vec3 sampleDiffuse = vec3(0.0);
                    vec3 sampleSpecular = vec3(0.0);

                    // #if LIGHTING_TRACE_FILTER > 0
                        light_GaussianFilter(sampleDiffuse, sampleSpecular, texcoord, depthTransL, texNormal, roughL);
                    // #elif LIGHTING_TRACE_RES == 0
                    //     sampleDiffuse = texelFetch(BUFFER_BLOCK_DIFFUSE, iTex, 0).rgb;

                    //     #if MATERIAL_SPECULAR != SPECULAR_NONE
                    //         sampleSpecular = texelFetch(BUFFER_BLOCK_SPECULAR, iTex, 0).rgb;
                    //     #endif
                    // #else
                    //     sampleDiffuse = textureLod(BUFFER_BLOCK_DIFFUSE, texcoord, 0).rgb;

                    //     #if MATERIAL_SPECULAR != SPECULAR_NONE
                    //         sampleSpecular = textureLod(BUFFER_BLOCK_SPECULAR, texcoord, 0).rgb;
                    //     #endif
                    // #endif
                #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
                    GetFloodfillLighting(diffuseFinal, specularFinal, localPos, localNormal, texNormal, deferredLighting.xy, shadowColor, albedo, metal_f0, roughL, occlusion, sss, tir);
                #endif

                diffuseFinal += emission * MaterialEmissionF;
            #else
                GetVanillaLighting(diffuseFinal, deferredLighting.xy, shadowColor, occlusion);
            #endif

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                SampleHandLight(diffuseFinal, specularFinal, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
                const bool tir = false; // TODO: ?
                bool isUnderWater = isEyeInWater == 1;
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, occlusion, sss, isUnderWater, tir);
            #else
                diffuseFinal += WorldAmbientF * occlusion;
            #endif

            #if MATERIAL_SSS != 0 && defined RENDER_SHADOWS_ENABLED
                vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
                vec3 sssFinal = shadowSSS * MaterialSssStrengthF * skyLightColor;

                vec3 sss_albedo = vec3(1.0);
                #ifdef MATERIAL_SSS_TINT
                    if (any(greaterThan(albedo, vec3(0.0))))
                        sss_albedo = 1.7 * normalize(albedo);

                    sssFinal *= mix(vec3(1.0), sss_albedo, shadowSSS);
                #endif

                float skyLightF = _pow2(deferredLighting.y);

                #ifdef IS_LPV_SKYLIGHT_ENABLED
                    vec3 lpvPos = GetVoxelPosition(localPos);

                    float lpvFade = GetLpvFade(lpvPos);
                    lpvFade = smootherstep(lpvFade);

                    vec4 lpvSample = SampleLpv(lpvPos, localNormal, texNormal);
                    float lpvSkyLight = GetLpvSkyLight(lpvSample);

                    skyLightF = mix(skyLightF, lpvSkyLight, lpvFade);
                #endif

                #if MATERIAL_SSS_AMBIENT > 0
                    vec3 sssSkyAmbientColor = SampleSkyIrradiance(localViewDir);

                    sssFinal += sss_albedo * sssSkyAmbientColor * (MaterialSssAmbientF * skyLightF);
                #endif

                diffuseFinal += sssFinal * occlusion;
            #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                ApplyMetalDarkening(diffuseFinal, specularFinal, albedo, metal_f0, roughL);
            #endif

            //diffuseFinal *= deferredColor.a;

            if (isWater) metal_f0 = 0.02;

            float skyNoVm = max(dot(texNormal, -localViewDir), 0.0);

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                view_F = GetMaterialFresnel(albedo, metal_f0, roughL, skyNoVm, false);
                //view_F *= MaterialReflectionStrength;// * (1.0 - roughL);

                //deferredColor.a = clamp(deferredColor.a, maxOf(view_F), 1.0);
                //albedo *= 1.0 - view_F;
            #endif

//            vec3 albedo_pm = albedo * deferredColor.a;
            #if LIGHTING_MODE == LIGHTING_MODE_TRACED
                diffuseFinal += sampleDiffuse;
                specularFinal += sampleSpecular;
//
//                final.rgb = GetFinalLighting(albedo_pm, diffuseFinal, specularFinal, occlusion);
//            #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
//                final.rgb = GetFinalLighting(albedo_pm, diffuseFinal, specularFinal, occlusion);
//            #else
//                final.rgb = GetFinalLighting(albedo_pm, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
            #endif

            //final.a = min(deferredColor.a + luminance(specularFinal), 1.0);
            final.a = deferredColor.a;

            // #if defined SKY_BORDER_FOG_ENABLED && SKY_TYPE == SKY_TYPE_VANILLA
            //     vec3 fogColorFinal = GetVanillaFogColor(deferredFog.rgb, localViewDir.y);
            //     fogColorFinal = RGBToLinear(fogColorFinal);

            //     final.rgb = mix(final.rgb, fogColorFinal, deferredFog.a);
            //     if (final.a > (1.5/255.0)) final.a = min(final.a + deferredFog.a, 1.0);
            // #endif

            #ifdef MATERIAL_REFRACT_ENABLED
                float refractDist = maxOf(abs(refraction * viewSize));

                if (refractDist >= 1.0) {
                    float dither = InterleavedGradientNoise(gl_FragCoord.xy);
                    
                    int refractSteps = clamp(int(ceil(refractDist)), 2, 16);
                    vec2 step = refraction / refractSteps;
                    //refraction = step * refractSteps;

                    //refraction = vec2(0.0);
                    for (int i = 1; i <= refractSteps; i++) {
                        float o = i + dither;
                        float sampleDepth = textureLod(depthtex1, o * step + texcoord, 0).r;
                        
                        if (sampleDepth < depthTrans) {
                            refraction = max(i - 1, 0) * step;
                            //depthOpaque = sampleDepth;
                            break;
                        }
                    }
                }
            #endif
        }

        depthOpaque = textureLod(depthtex1, texcoord + refraction, 0).r;
        mat4 projectionInv = gbufferProjectionInverse;

        #ifdef DISTANT_HORIZONS
            if (depthOpaque >= 1.0) {
                depthOpaque = textureLod(dhDepthTex1, texcoord, 0).r;
                projectionInv = dhProjectionInverse;
            }
        #endif

        vec3 clipPosOpaque = vec3(texcoord + refraction, depthOpaque) * 2.0 - 1.0;

        #ifdef DISTANT_HORIZONS
            vec3 viewPosOpaque = unproject(projectionInv, clipPosOpaque);
            vec3 localPosOpaque = mul3(gbufferModelViewInverse, viewPosOpaque);
        #else
            #ifndef IRIS_FEATURE_SSBO
                vec3 viewPosOpaque = unproject(gbufferProjectionInverse, clipPosOpaque);
                vec3 localPosOpaque = mul3(gbufferModelViewInverse, viewPosOpaque);
            #else
                vec3 localPosOpaque = unproject(gbufferModelViewProjectionInverse, clipPosOpaque);
            #endif
        #endif

        //float transDepth = isEyeInWater == 1 ? viewDist :
        //    max(length(localPosOpaque) - viewDist, 0.0);
        float opaqueDist = length(localPosOpaque);

        #if defined WORLD_WATER_ENABLED && WATER_DEPTH_LAYERS > 1
            float waterDepth[WATER_DEPTH_LAYERS+1];
            GetAllWaterDepths(waterPixelIndex, waterDepth);
        #endif

        #ifdef EFFECT_BLUR_ENABLED
            float blurDist = 0.0;
            if (depthTransL < depthOpaqueL) {
                // float opaqueDist = length(localPosOpaque);

                // water blur depthTrans
                #if WATER_DEPTH_LAYERS > 1 && defined WORLD_WATER_ENABLED
                    //uvec2 waterScreenUV = uvec2(gl_FragCoord.xy);
                    //uint waterPixelIndex = uint(waterScreenUV.y * viewWidth + waterScreenUV.x);

                    // float waterDepth[WATER_DEPTH_LAYERS+1];
                    // GetAllWaterDepths(waterPixelIndex, viewDist, waterDepth);

                    if (isEyeInWater == 1) {
                        if (waterDepth[1] < opaqueDist)
                            blurDist += max(min(waterDepth[2], opaqueDist) - min(waterDepth[1], opaqueDist), 0.0);

                        #if WATER_DEPTH_LAYERS >= 4
                            if (waterDepth[3] < opaqueDist)
                                blurDist += max(min(waterDepth[4], opaqueDist) - min(waterDepth[3], opaqueDist), 0.0);
                        #endif

                        #if WATER_DEPTH_LAYERS >= 6
                            if (waterDepth[4] < opaqueDist)
                                blurDist += max(min(waterDepth[5], opaqueDist) - min(waterDepth[4], opaqueDist), 0.0);
                        #endif
                    }
                    else {
                        if (waterDepth[0] < opaqueDist)
                            blurDist += max(min(waterDepth[1], opaqueDist) - min(waterDepth[0], opaqueDist), 0.0);

                        #if WATER_DEPTH_LAYERS >= 3
                            if (waterDepth[2] < opaqueDist)
                                blurDist += max(min(waterDepth[3], opaqueDist) - min(waterDepth[2], opaqueDist), 0.0);
                        #endif

                        #if WATER_DEPTH_LAYERS >= 5
                            if (waterDepth[4] < opaqueDist)
                                blurDist += max(min(waterDepth[5], opaqueDist) - min(waterDepth[4], opaqueDist), 0.0);
                        #endif
                    }
                #else
                    blurDist = max(opaqueDist - viewDist, 0.0);
                #endif
            }

            vec3 opaqueFinal = GetBlur(texcoord + refraction, depthOpaqueL, depthTransL, blurDist, isWater && isEyeInWater != 1);
        #else
            vec3 opaqueFinal = textureLod(BUFFER_FINAL, texcoord + refraction, 0).rgb;
        #endif

        #ifdef WORLD_SKY_ENABLED
            //float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
            // vec3 skyColorFinal = GetCustomSkyColor(localSunDirection, vec3(0.0, 1.0, 0.0));
            #if SKY_TYPE == SKY_TYPE_CUSTOM
                vec3 skyColorFinal = GetCustomSkyColor(localSunDirection, vec3(0.0, 1.0, 0.0));// * eyeBrightF;
            #else
                vec3 fogColorL = RGBToLinear(fogColor);
                vec3 skyColorFinal = GetVanillaFogColor(fogColorL, 1.0);
                //skyColorFinal = RGBToLinear(skyColorFinal);// * eyeBrightF;
            #endif
        #endif

        #ifdef SKY_BORDER_FOG_ENABLED
            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 0) {
            #endif
                if (depthTransL < depthOpaqueL) {
                    // vec2 uvSky = DirectionToUV(localViewDir);
                    // vec3 fogColorFinal = textureLod(texSky, uvSky, 0).rgb;

                    #if SKY_TYPE == SKY_TYPE_CUSTOM
                        vec3 fogColorFinal = GetCustomSkyColor(localSunDirection, localViewDir);

                        float fogDist = GetShapedFogDistance(localPos);
                        float fogF = GetCustomFogFactor(fogDist);
                    #elif SKY_TYPE == SKY_TYPE_VANILLA
                        // vec4 deferredFog = unpackUnorm4x8(deferredData.b);
                        vec3 fogColorFinal = vec3(0.0);//RGBToLinear(deferredFog.rgb);
                        // fogColorFinal = GetVanillaFogColor(fogColorFinal, localViewDir.y);

                        float fogF = 0.0;//deferredFog.a;
                    #endif

                    // #if defined WORLD_SKY_ENABLED && LIGHTING_VOLUMETRIC != VOL_TYPE_NONE //&& SKY_CLOUD_TYPE > CLOUDS_VANILLA
                    //     float skyTraceFar = far;
                    //     #ifdef DISTANT_HORIZONS
                    //         skyTraceFar = max(far, dhFarPlane);
                    //     #endif

                    //     vec3 skyScatter = vec3(0.0);
                    //     vec3 skyTransmit = vec3(1.0);

                    //     #if SKY_CLOUD_TYPE <= CLOUDS_VANILLA
                    //         TraceSky(skyScatter, skyTransmit, cameraPosition, localViewDir, viewDist, skyTraceFar, 8);
                    //     #else
                    //         TraceCloudSky(skyScatter, skyTransmit, cameraPosition, localViewDir, viewDist, skyTraceFar, 8, CLOUD_SHADOW_STEPS);
                    //     #endif

                    //     fogColorFinal = fogColorFinal * skyTransmit + skyScatter;
                    // #endif

                    final.rgb = mix(final.rgb, fogColorFinal, fogF);
                    if (final.a > (1.5/255.0)) final.a = min(final.a + fogF, 1.0);
                }
            #ifdef WORLD_WATER_ENABLED
                }
            #endif
        #endif

        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        #endif

        // #ifdef WORLD_WATER_ENABLED
        //     vec3 ambientWaterTint = exp(-12.0 * WaterDensityF * WaterAbsorbF);

        //     if (isWater && isEyeInWater != 1) opaqueFinal *= ambientWaterTint;
        // #endif

        if (isWater) {
            if (tir) final.a = 1.0;
        }
        else {
            vec3 tint = albedo;
            if (any(greaterThan(tint, EPSILON3)))
                tint = normalize(tint) * 1.7;

            tint = mix(tint, vec3(1.0), pow(1.0 - final.a, 3.0));
            opaqueFinal *= tint;
        }

        final.rgb = opaqueFinal;

        if (deferredColor.a > (0.5/255.0) && depthTrans < 1.0) {
            diffuseFinal += Lighting_MinF * occlusion;
            diffuseFinal += emission * MaterialEmissionF;
            diffuseFinal *= albedo;

            final.rgb = mix(opaqueFinal, diffuseFinal, deferredColor.a);
            final.rgb = mix(final.rgb, specularFinal, view_F);

//            #if LIGHTING_MODE == LIGHTING_MODE_TRACED
//                final.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
//            #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
//                final.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
//            #else
//                final.rgb = mix(final.rgb, specularFinal, view_F);
//            #endif
        }


        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater == 1) {
                final.rgb *= exp(-WaterAmbientDepth * WaterDensityF * WaterAbsorbF);
            }
        #endif

        #if defined WORLD_WATER_ENABLED && LIGHTING_VOLUMETRIC == VOL_TYPE_FAST && WATER_DEPTH_LAYERS == 1
            if (isEyeInWater == 1) {
                float waterDist = min(viewDist, far);

                #ifdef WORLD_SKY_ENABLED
                    // float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0;

                    // #ifdef WORLD_SKY_ENABLED
                    //     eyeSkyLightF *= 1.0 - 0.8 * rainStrength;
                    // #endif
                    
                    // eyeSkyLightF += 0.02;

                    //float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
                    // vec3 skyColorFinal = GetCustomSkyColor(localSunDirection, vec3(0.0, 1.0, 0.0));
                    // #if SKY_TYPE == SKY_TYPE_CUSTOM
                    //     vec3 skyColorFinal = GetCustomSkyColor(localSunDirection, vec3(0.0, 1.0, 0.0));// * eyeBrightF;
                    // #else
                    //     vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
                    //     skyColorFinal = RGBToLinear(skyColorFinal);// * eyeBrightF;
                    // #endif

                    float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
                    vec3 skyColorAmbient = WorldSkyAmbientColor * eyeBrightF;

                    vec3 vlLight = phaseIso * WorldSkyLightColor + WaterAmbientF * skyColorAmbient;// * eyeSkyLightF;
                #else
                    vec3 vlLight = vec3(phaseIso + WaterAmbientF);
                #endif

                ApplyScatteringTransmission(final.rgb, waterDist, vlLight, WaterDensityF, WaterScatterF, WaterAbsorbF, 8);
            }
        #endif

        final.a = 1.0;

        // #if defined SKY_BORDER_FOG_ENABLED && defined WORLD_WATER_ENABLED
        //     if (isEyeInWater == 1) {
        //         // water fog

        //         #if SKY_TYPE == SKY_TYPE_CUSTOM
        //             float fogF = GetCustomWaterFogFactor(viewDist);

        //             #if LIGHTING_VOLUMETRIC != VOL_TYPE_NONE
        //                 // final.rgb *= 1.0 - fogF;
        //                 fogF = 1.0;
        //             #else
        //                 // vec3 skyColorFinal = RGBToLinear(skyColor);
        //                 vec3 fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
        //                 final.rgb = mix(final.rgb, fogColorFinal, fogF);
        //             #endif
        //         #else
        //             // TODO
        //         #endif
        //     }
        // #endif

        #if defined WORLD_WATER_ENABLED && LIGHTING_VOLUMETRIC == VOL_TYPE_FAST && WATER_DEPTH_LAYERS > 1
            float farDist = min(viewDist, far);
            float waterDist = 0.0;
            //bool isWater = false;

            if (waterDepth[0] < farDist) {
                waterDist += max(min(farDist, waterDepth[1]) - waterDepth[0], 0.0);
                //isWater = distOpaque > waterDepth[0] && distOpaque < waterDepth[1];
            }

            #if WATER_DEPTH_LAYERS >= 3
                if (waterDepth[2] < farDist) {
                    waterDist += max(min(farDist, waterDepth[3]) - waterDepth[2], 0.0);
                    //isWater = isWater || (distOpaque > min(waterDepth[2], farDist) && distOpaque < min(waterDepth[3], farDist));
                }
            #endif

            #if WATER_DEPTH_LAYERS >= 5
                if (waterDepth[4] < farDist) {
                    waterDist += max(min(farDist, waterDepth[5]) - waterDepth[4], 0.0);
                    //isWater = isWater || (distOpaque > min(waterDepth[4], farDist) && distOpaque < min(waterDepth[5], farDist));
                }
            #endif

            if (waterDist > EPSILON) {
                float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0;

                #ifdef WORLD_SKY_ENABLED
                    eyeSkyLightF *= 1.0 - 0.8 * rainStrength;
                #endif
                
                eyeSkyLightF += 0.02;

                vec3 vlLight = (phaseIso * WorldSkyLightColor + WaterAmbientF) * eyeSkyLightF;
                ApplyScatteringTransmission(final.rgb, waterDist, vlLight, 1.0, WaterScatterF, WaterAbsorbF, 8);
            }

            // vec3 viewDir = normalize(viewPos);
            // float waterSurfaceDist = waterDepth[0] > EPSILON ? waterDepth[0] : waterDepth[1];
            // vec3 waterSurfaceViewPos = viewDir * waterSurfaceDist;

            // vec3 waterSurfaceDX = dFdx(waterSurfaceViewPos);
            // vec3 waterSurfaceDY = dFdy(waterSurfaceViewPos);
            // vec3 waterSurfaceViewNormal = normalize(cross(waterSurfaceDX, waterSurfaceDY));

            // if (waterSurfaceDist < viewDist) {
            //     float waterSurfaceNoL = max(dot(waterSurfaceViewNormal, -viewDir), 0.0);
            //     final.rgb = mix(final.rgb, vec3(1.0), 1.0 - waterSurfaceNoL);
            // }
        #endif

        #ifdef VL_BUFFER_ENABLED
            #if VOLUMETRIC_BLUR_SIZE > 0
                VL_GaussianFilter(final.rgb, texcoord, depthTransL);
            #else
                vec3 vlScatter = textureLod(BUFFER_VL_SCATTER, texcoord, 0).rgb;
                vec3 vlTransmit = textureLod(BUFFER_VL_TRANSMIT, texcoord, 0).rgb;
                final.rgb = final.rgb * vlTransmit + vlScatter;
            #endif
        #endif

        #if LIGHTING_VOLUMETRIC == VOL_TYPE_FAST && defined WORLD_SKY_ENABLED
            if (isEyeInWater == 0) {
                float maxDist = min(viewDist, far);
                float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0;
                vec3 skyColorAmbient = WorldSkyAmbientColor * eyeSkyLightF;

                float airDensityF = GetAirDensity(eyeSkyLightF);
                vec3 vlLight = (phaseIso * WorldSkyLightColor + AirAmbientF * skyColorAmbient);// * eyeSkyLightF;
                ApplyScatteringTransmission(final.rgb, maxDist, vlLight, airDensityF, AirScatterColor, AirExtinctColor, 8);
            }
        #endif

        #if LIGHTING_VOLUMETRIC == VOL_TYPE_FAST && !defined WORLD_SKY_ENABLED
            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 0) {
            #endif

                float maxDist = min(viewDist, far);
                // vec3 _ambient = vec3(AirAmbientF);
                vec3 vlLight = vec3(0.0);

                #ifdef WORLD_SKY_ENABLED
                    vec3 skyLightColor = WorldSkyLightColor * (1.0 - 0.8 * weatherStrength);

                    float skyLightF = eyeBrightnessSmooth.y / 240.0;
                    skyLightF = _pow2(skyLightF);

                    #if LIGHTING_VOLUMETRIC == VOL_TYPE_FAST
                        skyLightColor *= skyLightF;
                    #endif

                    vlLight += phaseAir * skyLightColor;
                    vlLight += AirAmbientF * skyColorFinal;
                #else
                    //const vec3 skyLightColor = vec3(0.0);
                    vlLight += phaseAir;
                    vlLight += AirAmbientF;
                #endif

                //vec3 vlLight = (phaseAir * skyLightColor + _ambient);
                //ApplyScatteringTransmission(final.rgb, maxDist, vlLight, AirDensityF, AirScatterColor, AirExtinctColor, 8);
                vec3 scatterFinal = vec3(0.0);
                vec3 transmitFinal = vec3(1.0);
                vec3 worldPos = localPos + cameraPosition;
                TraceSky(scatterFinal, transmitFinal, worldPos, localViewDir, near, maxDist, 8);
                final.rgb = final.rgb * transmitFinal + scatterFinal;

            #ifdef WORLD_WATER_ENABLED
                }
            #endif
        #endif

        vec4 overlayColor = textureLod(BUFFER_OVERLAY, texcoord, 0);
        // final = mix(final, overlayColor, overlayColor.a);
        final.rgb *= 1.0 - overlayColor.a;
        final.rgb += overlayColor.rgb;
        final.a = max(final.a, overlayColor.a);
        // = mix(final, overlayColor, overlayColor.a);
        
        outFinal = final;
    }
#else
    // Pass-through for world-specific flags not working in shader.properties
    
    void main() {
        outFinal = texture(colortex0, texcoord);
    }
#endif
