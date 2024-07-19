#define RENDER_OPAQUE_FINAL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform usampler2D BUFFER_DEFERRED_DATA;
uniform sampler2D BUFFER_DEFERRED_NORMAL_TEX;
uniform sampler2D BUFFER_BLOCK_DIFFUSE;

#ifdef RENDER_SHADOWS_ENABLED
    // uniform sampler2D BUFFER_DEFERRED_SHADOW;
    uniform sampler2D texShadowSSS;
#endif

#ifdef EFFECT_SSAO_ENABLED
    uniform sampler2D texSSAO;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform sampler3D texClouds;

    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        uniform sampler2D texSkyIrradiance;

        #if MATERIAL_REFLECTIONS != REFLECT_NONE
            uniform sampler2D texSky;
        #endif
    #endif
#endif

#if defined WATER_CAUSTICS && defined WORLD_WATER_ENABLED && defined WORLD_SKY_ENABLED && defined IS_IRIS
    uniform sampler3D texCaustics;
#endif

#if MATERIAL_SPECULAR != SPECULAR_NONE
    uniform sampler2D BUFFER_BLOCK_SPECULAR;
#endif

#if defined IS_LPV_ENABLED && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE == CLOUDS_VANILLA
    uniform sampler2D TEX_CLOUDS_VANILLA;
#endif

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
    uniform sampler2D dhDepthTex1;
#endif

uniform int frameCounter;
uniform float frameTime;
//uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 upPosition;
uniform float viewWidth;
uniform float viewHeight;
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

uniform int worldTime;
uniform ivec2 eyeBrightnessSmooth;
uniform float blindnessSmooth;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef ANIM_WORLD_TIME
    //uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#ifndef IRIS_FEATURE_SSBO
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferPreviousProjection;
#endif

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform mat4 gbufferProjection;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform vec3 shadowLightPosition;
    uniform float rainStrength;
    uniform float weatherStrength;
    uniform float weatherPuddleStrength;
    uniform float skyWetnessSmooth;
    uniform float wetness;
    
    uniform float cloudHeight;
    uniform float cloudTime;

    #if (MATERIAL_REFLECTIONS != REFLECT_NONE && defined MATERIAL_REFLECT_CLOUDS) || defined SHADOW_CLOUD_ENABLED
        // uniform float cloudTime;
    #endif

    #ifdef IS_IRIS
        uniform float lightningStrength;
    #endif
#endif

#if LPV_SIZE > 0
    uniform mat4 gbufferPreviousModelView;
#endif

#ifdef RENDER_SHADOWS_ENABLED
    #ifndef IRIS_FEATURE_SSBO
        uniform mat4 shadowModelView;
    #endif
#else
    //uniform int worldTime;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef DISTANT_HORIZONS
    uniform mat4 dhModelViewInverse;
    uniform mat4 dhProjectionInverse;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#ifndef IRIS_FEATURE_SSBO
    #ifdef WORLD_SKY_ENABLED
        uniform float lightningPosition;
    #endif

    #if MC_VERSION > 11900
        uniform float darknessFactor;
    #endif
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/light_static.glsl"

    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif
    
    #ifdef WORLD_WATER_ENABLED
        #include "/lib/buffers/water_mask.glsl"
        #include "/lib/water/water_mask_read.glsl"
    #endif

    #if defined WORLD_WATER_ENABLED && WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
        #include "/lib/water/water_depths_read.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lights.glsl"
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/erp.glsl"
#include "/lib/sampling/gaussian.glsl"
// #include "/lib/sampling/bilateral_gaussian.glsl"

#include "/lib/utility/hsv.glsl"
#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"
#include "/lib/utility/temporal_offset.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/blackbody.glsl"
#include "/lib/lighting/sampling.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/flicker.glsl"
    #endif
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
    #include "/lib/world/wetness.glsl"
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"

    #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
        #include "/lib/lighting/caustics.glsl"
    #endif
#endif

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
    
    #ifdef WORLD_WATER_ENABLED
        #include "/lib/fog/fog_water_custom.glsl"
    #endif
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/hcm.glsl"
    #include "/lib/material/fresnel.glsl"
#endif

#if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
#endif

#if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/lights_render.glsl"
#endif

#if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
    #include "/lib/buffers/volume.glsl"
    
    #include "/lib/lpv/lpv.glsl"
    #include "/lib/lpv/lpv_render.glsl"
#endif

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/items.glsl"
#endif

#include "/lib/lighting/scatter_transmit.glsl"

#if defined WORLD_SKY_ENABLED && defined IS_IRIS
    #include "/lib/clouds/cloud_common.glsl"
    #include "/lib/world/lightning.glsl"

    //#if (defined MATERIAL_REFLECT_CLOUDS && MATERIAL_REFLECTIONS != REFLECT_NONE) || defined RENDER_CLOUD_SHADOWS_ENABLED
        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            #include "/lib/clouds/cloud_custom.glsl"
            #include "/lib/clouds/cloud_custom_shadow.glsl"
            #include "/lib/clouds/cloud_custom_trace.glsl"
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
            #include "/lib/clouds/cloud_vanilla.glsl"
        #endif
    //#endif
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/sky/sky_trace.glsl"
#endif

#if MATERIAL_REFLECTIONS != REFLECT_NONE
    //#include "/lib/utility/depth_tiles.glsl"
    #include "/lib/lighting/reflections.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/sky/sky_lighting.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_TRACED
    #if LIGHTING_TRACE_FILTER > 0
        #include "/lib/sampling/light_filter.glsl"
    #endif
    
    #include "/lib/lighting/traced.glsl"
#elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
    #include "/lib/lighting/floodfill.glsl"
#else
    #include "/lib/lighting/vanilla.glsl"
#endif

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE && LIGHTING_MODE != LIGHTING_MODE_TRACED
    #include "/lib/lighting/basic_hand.glsl"
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


layout(location = 0) out vec4 outFinal;
#ifdef DEFERRED_BUFFER_ENABLED
    /* RENDERTARGETS: 0 */

    void main() {
        ivec2 iTex = ivec2(gl_FragCoord.xy);
        vec2 viewSize = vec2(viewWidth, viewHeight);

        //float depth = texelFetch(depthtex1, iTex, 0).r;
        //float handClipDepth = texelFetch(depthtex2, iTex, 0).r;
        float depthTrans = textureLod(depthtex0, texcoord, 0).r;
        float depthOpaque = textureLod(depthtex1, texcoord, 0).r;
        float handClipDepth = textureLod(depthtex2, texcoord, 0).r;
        bool isHand = handClipDepth > depthOpaque;

        // if (isHand) {
        //     depthOpaque = depthOpaque * 2.0 - 1.0;
        //     depthOpaque /= MC_HAND_DEPTH;
        //     depthOpaque = depthOpaque * 0.5 + 0.5;
        // }

        float depthOpaqueL = linearizeDepthFast(depthOpaque, near, farPlane);
        float depthTransL = linearizeDepthFast(depthTrans, near, farPlane);

        #ifdef DISTANT_HORIZONS
            float dhDepthTrans = textureLod(dhDepthTex, texcoord, 0).r;
            float dhDepthTransL = linearizeDepthFast(dhDepthTrans, dhNearPlane, dhFarPlane);
            mat4 projectionInvOpaque = gbufferProjectionInverse;

            if (depthTrans >= 1.0 || (dhDepthTransL < depthTransL && dhDepthTrans > 0.0)) {
                //depthTrans = dhDepthTrans;
                depthTransL = dhDepthTransL;
            }

            float dhDepthOpaque = textureLod(dhDepthTex1, texcoord, 0).r;
            float dhDepthOpaqueL = linearizeDepthFast(dhDepthOpaque, dhNearPlane, dhFarPlane);

            if (depthOpaque >= 1.0 || (dhDepthOpaqueL < depthOpaqueL && dhDepthOpaque > 0.0)) {
                depthOpaque = dhDepthOpaque;
                depthOpaqueL = dhDepthOpaqueL;
                projectionInvOpaque = dhProjectionInverse;
            }
        #endif

        vec3 final;

        if (depthOpaque < 1.0) {
            vec2 texJ = texcoord;
            #ifdef EFFECT_TAA_ENABLED
                texJ -= getJitterOffset(frameCounter);
            #endif

            vec3 clipPos = vec3(texJ, depthOpaque) * 2.0 - 1.0;

            #ifdef DISTANT_HORIZONS
                vec3 viewPos = unproject(projectionInvOpaque, clipPos);
                vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
            #else
                #ifndef IRIS_FEATURE_SSBO
                    vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
                    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
                #else
                    vec3 localPos = unproject(gbufferModelViewProjectionInverse, clipPos);
                #endif
            #endif

            vec3 localViewDir = normalize(localPos);

            vec3 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;

            uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
            vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
            vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
            vec4 deferredWaterShadow = unpackUnorm4x8(deferredData.b);

            vec3 localNormal = deferredNormal.rgb;
            float occlusion = deferredLighting.z;

            #ifdef EFFECT_SSAO_ENABLED
                float deferredOcclusion = textureLod(texSSAO, texcoord, 0).r;
                // occlusion = min(occlusion, deferredOcclusion);
                occlusion *= deferredOcclusion;
            #endif

            if (any(greaterThan(localNormal, EPSILON3)))
                localNormal = normalize(localNormal * 2.0 - 1.0);

            vec3 texNormal = texelFetch(BUFFER_DEFERRED_NORMAL_TEX, iTex, 0).rgb;

            if (any(greaterThan(texNormal, EPSILON3)))
                texNormal = normalize(texNormal * 2.0 - 1.0);

            float viewDist = length(localPos);

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                vec3 deferredRoughMetalF0Porosity = unpackUnorm4x8(deferredData.a).rgb;
                float roughL = _pow2(deferredRoughMetalF0Porosity.r);
                float metal_f0 = deferredRoughMetalF0Porosity.g;
                float porosity = deferredRoughMetalF0Porosity.b;
            #else
                const float roughL = 1.0;
                const float metal_f0 = 0.04;
                const float porosity = 0.0;
            #endif

            vec3 shadowColor = vec3(1.0);
            float shadowSSS = 0.0;

            #ifdef RENDER_SHADOWS_ENABLED
                // #if SHADOW_BLUR_SIZE > 0 //&& !defined EFFECT_TAA_ENABLED
                //     #ifdef SHADOW_COLORED
                //         shadowColor = shadow_GaussianFilterRGB(texcoord, depthOpaqueL);
                //     #else
                //         shadowColor = vec3(shadow_GaussianFilter(texcoord, depthOpaqueL));
                //     #endif

                //     shadowSSS = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0).a;
                // #else
                    // vec4 deferredShadowSSS = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0);
                    vec4 deferredShadowSSS = textureLod(texShadowSSS, texcoord, 0);
                    shadowColor = deferredShadowSSS.rgb;
                    shadowSSS = deferredShadowSSS.a;
                // #endif

                //occlusion = max(occlusion, luminance(shadowColor));
            #endif

            // apply parallax shadows
            shadowColor *= deferredWaterShadow.g;

            vec3 worldPos = cameraPosition + localPos;

            vec3 albedo = RGBToLinear(deferredColor);
            float emission = deferredLighting.a;
            float sss = deferredNormal.a;

            float skyWetness = 0.0, puddleF = 0.0;
            #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
                skyWetness = GetSkyWetness(worldPos, localNormal, deferredLighting.xy);

                #if WORLD_WETNESS_PUDDLES != PUDDLES_NONE
                    puddleF = GetWetnessPuddleF(skyWetness, porosity);
                #endif
            #endif

            #ifdef WORLD_WATER_ENABLED
                bool isWater = GetWaterMask(ivec2(gl_FragCoord.xy));

                #if WATER_DEPTH_LAYERS > 1
                    uvec2 waterScreenUV = uvec2(gl_FragCoord.xy);
                    uint waterPixelIndex = uint(waterScreenUV.y * viewWidth + waterScreenUV.x);
                    bool hasWaterDepth = false;

                    vec3 clipPosTrans = vec3(texcoord, depthTrans) * 2.0 - 1.0;
                    vec3 localPosTrans = unproject(gbufferModelViewProjectionInverse, clipPosTrans);
                    float distTrans = length(localPosTrans);

                    float waterDepth[WATER_DEPTH_LAYERS+1];
                    GetAllWaterDepths(waterPixelIndex, waterDepth);

                    hasWaterDepth = viewDist > waterDepth[0] && viewDist < waterDepth[1];

                    #if WATER_DEPTH_LAYERS >= 3
                        hasWaterDepth = hasWaterDepth || (viewDist > waterDepth[2] && viewDist < waterDepth[3]);
                    #endif

                    #if WATER_DEPTH_LAYERS >= 5
                        hasWaterDepth = hasWaterDepth || (viewDist > waterDepth[4] && viewDist < waterDepth[5]);
                    #endif
                #else
                    bool hasWaterDepth = isEyeInWater == 1
                        ? depthOpaqueL <= depthTransL
                        : (depthTransL < depthOpaqueL && isWater);
                #endif

                if (hasWaterDepth) {
                    #ifdef WORLD_SKY_ENABLED
                        puddleF = 1.0;
                    #endif

                    #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
                        const float shadowDepth = 8.0; // TODO
                        float causticLight = SampleWaterCaustics(localPos, shadowDepth, deferredLighting.y);
                        shadowColor *= causticLight;
                    #endif
                }
            #endif

            //#if (defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED) || defined WORLD_WATER_ENABLED
            #if defined WORLD_SKY_ENABLED && (defined WORLD_WETNESS_ENABLED || defined WORLD_WATER_ENABLED)
                ApplySkyWetness(albedo, porosity, skyWetness, puddleF);
                ApplySkyWetness(roughL, porosity, skyWetness, puddleF);
            #endif

            vec3 diffuseFinal = vec3(0.0);
            vec3 specularFinal = vec3(0.0);

            #if LIGHTING_MODE > LIGHTING_MODE_BASIC
                #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
                    #if LPV_SIZE > 0
                        diffuseFinal += GetLpvAmbientLighting(localPos, localNormal, texNormal) * occlusion;
                    #endif

                    vec3 sampleDiffuse = vec3(0.0);
                    vec3 sampleSpecular = vec3(0.0);

                    #if LIGHTING_TRACE_FILTER > 0
                        light_GaussianFilter(sampleDiffuse, sampleSpecular, texcoord, depthOpaqueL, texNormal, roughL);
                    #elif LIGHTING_TRACE_RES == 0
                        sampleDiffuse = texelFetch(BUFFER_BLOCK_DIFFUSE, iTex, 0).rgb;

                        #if MATERIAL_SPECULAR != SPECULAR_NONE
                            sampleSpecular = texelFetch(BUFFER_BLOCK_SPECULAR, iTex, 0).rgb;
                        #endif
                    #else
                        sampleDiffuse = textureLod(BUFFER_BLOCK_DIFFUSE, texcoord, 0).rgb;

                        #if MATERIAL_SPECULAR != SPECULAR_NONE
                            sampleSpecular = textureLod(BUFFER_BLOCK_SPECULAR, texcoord, 0).rgb;
                        #endif
                    #endif
                #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
                    GetFloodfillLighting(diffuseFinal, specularFinal, localPos, localNormal, texNormal, deferredLighting.xy, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);
                #endif

                diffuseFinal += emission * MaterialEmissionF;
            #else
                GetVanillaLighting(diffuseFinal, deferredLighting.xy, shadowColor, occlusion);
            #endif

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE && LIGHTING_MODE != LIGHTING_MODE_TRACED
                SampleHandLight(diffuseFinal, specularFinal, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
                const bool tir = false;
                bool isUnderWater = hasWaterDepth;
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, occlusion, sss, isUnderWater, tir);
            #else
                diffuseFinal += WorldAmbientF * occlusion;
            #endif

            #if MATERIAL_SSS != 0 && defined RENDER_SHADOWS_ENABLED
                vec3 skyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
                vec3 sssFinal = shadowSSS * MaterialSssStrengthF * skyLightColor;

                vec2 uvSky = DirectionToUV(localViewDir);
                float sssSkyLight = 0.1 * _pow3(deferredLighting.y);
                vec3 sssSkyColor = textureLod(texSkyIrradiance, uvSky, 0).rgb;
                sssFinal += sssSkyColor * (sss * occlusion * sssSkyLight * Sky_BrightnessF);

                // vec3 sssColor = vec3(1.0);
                // if (any(greaterThan(albedo, EPSILON3)))
                //     sssColor = normalize(albedo);
                // sssFinal *= sssColor;

                diffuseFinal += sssFinal;
            #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                ApplyMetalDarkening(diffuseFinal, specularFinal, albedo, metal_f0, roughL);
            #endif

            #if LIGHTING_MODE == LIGHTING_MODE_TRACED
                diffuseFinal += sampleDiffuse;
                specularFinal += sampleSpecular;

                final = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
            #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
                final = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
            #else
                final = GetFinalLighting(albedo, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
            #endif

            #ifdef WORLD_WATER_ENABLED
                if (isWater && isEyeInWater != 1) {
                    final *= exp(-WaterAmbientDepth * WaterDensityF * WaterAbsorbF);
                }
            #endif


            // #ifdef DISTANT_HORIZONS
            //     float fogDist = GetShapedFogDistance(localPos);
            //     float fogF = GetFogFactor(fogDist, 0.6 * far, far, 1.0);
            //     final = mix(final, skyFinal, fogF);
            // #endif

            #ifdef SKY_BORDER_FOG_ENABLED
                // vec2 uvSky = DirectionToUV(localViewDir);
                // vec3 fogColorFinal = textureLod(texSky, uvSky, 0).rgb;

                #if SKY_TYPE == SKY_TYPE_CUSTOM
                    // #ifndef IRIS_FEATURE_SSBO
                    //     vec3 localSunDirection = normalize(mat3(gbufferModelViewInverse) * sunPosition);
                    // #endif

                    vec3 fogColorFinal = GetCustomSkyColor(localSunDirection.y, localViewDir.y);

                    float fogDist = GetShapedFogDistance(localPos);
                    float fogF = GetCustomFogFactor(fogDist);
                #else
                    vec4 deferredFog = unpackUnorm4x8(deferredData.b);
                    
                    vec3 fogColorFinal = GetVanillaFogColor(deferredFog.rgb, localViewDir.y);
                    fogColorFinal = RGBToLinear(fogColorFinal);

                    float fogF = deferredFog.a;
                #endif

                fogColorFinal *= Sky_BrightnessF;

                #if defined WORLD_SKY_ENABLED && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE //&& SKY_CLOUD_TYPE > CLOUDS_VANILLA
                    #ifdef DISTANT_HORIZONS
                        float skyTraceFar = max(far, dhFarPlane);
                    #else
                        float skyTraceFar = far;
                    #endif

                    vec3 skyScatter = vec3(0.0);
                    vec3 skyTransmit = vec3(1.0);

                    #if SKY_CLOUD_TYPE <= CLOUDS_VANILLA
                        TraceSky(skyScatter, skyTransmit, cameraPosition, localViewDir, viewDist, skyTraceFar, 8);
                    #else
                        TraceCloudSky(skyScatter, skyTransmit, cameraPosition, localViewDir, viewDist, skyTraceFar, 8, CLOUD_SHADOW_STEPS);
                    #endif

                    fogColorFinal = fogColorFinal * skyTransmit + skyScatter;
                #endif

                final = mix(final, fogColorFinal, fogF);
            #endif
        }
        else {
            #ifdef WORLD_NETHER
                final = RGBToLinear(fogColor) * Sky_BrightnessF;
            #else
                final = texelFetch(BUFFER_FINAL, iTex, 0).rgb;
            #endif
        }

        outFinal = vec4(final, 1.0);
    }
#else
    // Pass-through for world-specific flags not working in shader.properties
    
    void main() {
        outFinal = texture(colortex0, texcoord);
    }
#endif
