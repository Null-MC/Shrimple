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
uniform sampler2D BUFFER_BLOCK_DIFFUSE;
uniform sampler2D BUFFER_OVERLAY;
// uniform sampler2D TEX_LIGHTMAP;

#if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform sampler2D texSkyIrradiance;

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        uniform sampler2D texSky;
    #endif
#endif

#if MATERIAL_SPECULAR != SPECULAR_NONE
    uniform sampler2D BUFFER_BLOCK_SPECULAR;
#endif

#if defined VL_BUFFER_ENABLED || SKY_CLOUD_TYPE > CLOUDS_VANILLA
    uniform sampler2D BUFFER_VL_SCATTER;
    uniform sampler2D BUFFER_VL_TRANSMIT;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform sampler2D texDepthNear;
    //layout(r32f) uniform readonly image2D imgDepthNear;
#endif

#if defined WORLD_SKY_ENABLED && defined IS_IRIS //&& defined MATERIAL_REFLECT_CLOUDS && MATERIAL_REFLECTIONS != REFLECT_NONE
    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS_VANILLA;
    #endif
#endif

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
    uniform vec3 sunPosition;
    uniform vec3 shadowLightPosition;
    uniform float rainStrength;
    uniform float skyRainStrength;
    //uniform float wetness;

    uniform float cloudHeight;
    uniform float cloudTime;

    #ifdef IS_IRIS
        uniform float lightningStrength;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#if LPV_SIZE > 0
    uniform mat4 gbufferPreviousModelView;
#endif

// #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
//     uniform int worldTime;
// #endif

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

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

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
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

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#ifdef WORLD_SKY_ENABLED
    //#if SKY_CLOUD_TYPE != CLOUDS_NONE
        #include "/lib/clouds/cloud_common.glsl"
    //#endif
    
    #include "/lib/world/lightning.glsl"

    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        #include "/lib/clouds/cloud_custom.glsl"
        #include "/lib/clouds/cloud_custom_shadow.glsl"
        #include "/lib/clouds/cloud_custom_trace.glsl"
    #endif
#endif

#include "/lib/lights.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"

// #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
//     #include "/lib/lighting/voxel/sampling.glsl"
// #endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& LIGHTING_MODE != LIGHTING_MODE_NONE
    #include "/lib/buffers/volume.glsl"
    #include "/lib/utility/hsv.glsl"
    
    #include "/lib/lpv/lpv.glsl"
    #include "/lib/lpv/lpv_render.glsl"
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

#if MATERIAL_REFLECTIONS != REFLECT_NONE
    #if defined MATERIAL_REFLECT_CLOUDS && SKY_CLOUD_TYPE == CLOUDS_VANILLA && defined WORLD_SKY_ENABLED && defined IS_IRIS
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
    #include "/lib/lighting/reflections.glsl"
#endif

#if defined RENDER_SHADOWS_ENABLED && SHADOW_BLUR_SIZE > 0
    #include "/lib/sampling/shadow_filter.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/lighting/sky_lighting.glsl"
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

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/basic_hand.glsl"
#endif

#if defined VL_BUFFER_ENABLED || SKY_CLOUD_TYPE > CLOUDS_VANILLA
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
        vec4 deferredFog = unpackUnorm4x8(deferredData.b);

        vec3 albedo = RGBToLinear(deferredColor.rgb);

        // vec3 fogColorFinal = GetVanillaFogColor(deferredFog.rgb, localViewDir.y);
        // fogColorFinal = RGBToLinear(fogColorFinal);

        bool isWater = false;
        float roughness = 1.0;
        float roughL = 1.0;
        vec3 texNormal;

        #if WATER_DEPTH_LAYERS > 1
            uvec2 waterScreenUV = uvec2(gl_FragCoord.xy);
            uint waterPixelIndex = uint(waterScreenUV.y * viewWidth + waterScreenUV.x);
        #endif

        if (deferredColor.a > (0.5/255.0) && depthTrans < 1.0) {
            vec4 deferredLighting = unpackUnorm4x8(deferredData.g);

            vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
            vec3 localNormal = deferredNormal.rgb;

            if (any(greaterThan(localNormal, EPSILON3)))
                localNormal = normalize(localNormal * 2.0 - 1.0);

            // vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            // texNormal = deferredTexture.rgb;

            vec3 texNormal = texelFetch(BUFFER_DEFERRED_NORMAL_TEX, iTex, 0).rgb;

            if (any(greaterThan(texNormal, EPSILON3)))
                texNormal = normalize(texNormal * 2.0 - 1.0);

            // vec4 deferredShadow = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0);

            //#if WATER_DEPTH_LAYERS > 1
            //    isWater = WaterDepths[waterPixelIndex].IsWater;
            //#else
                float deferredWater = unpackUnorm4x8(deferredData.b).r;
                isWater = deferredWater > 0.5;
            //#endif

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
                const float metal_f0 = 0.04;
            #endif

            vec3 deferredShadow = vec3(1.0);
            #if defined RENDER_SHADOWS_ENABLED && SHADOW_BLUR_SIZE > 0 && !defined EFFECT_TAA_ENABLED
                #ifdef SHADOW_COLORED
                    deferredShadow = shadow_GaussianFilterRGB(texcoord, depthTransL);
                #else
                    deferredShadow = vec3(shadow_GaussianFilter(texcoord, depthTransL));
                #endif
            #else
                deferredShadow = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0).rgb;
            #endif

            #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED
                #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                    deferredShadow *= TraceCloudShadow(cameraPosition + localPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
                // #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
                //     shadow *= SampleCloudShadow(localSkyLightDirection, cloudPos);
                #endif
            #endif

            float occlusion = deferredLighting.z;
            float emission = deferredLighting.a;
            float sss = deferredNormal.a;

            //if (isWater) deferredColor.a *= Water_OpacityF;

            #if LIGHTING_MODE > LIGHTING_MODE_BASIC
                vec3 blockDiffuse = vec3(0.0);
                vec3 blockSpecular = vec3(0.0);

                #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
                    #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                        SampleHandLight(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
                    #endif

                    #if LPV_SIZE > 0
                        blockDiffuse += GetLpvAmbientLighting(localPos, localNormal, texNormal) * occlusion;
                    #endif

                    #if MATERIAL_SPECULAR != SPECULAR_NONE
                        if (metal_f0 >= 0.5) {
                            blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                            blockSpecular *= albedo;
                        }
                    #endif

                    vec3 sampleDiffuse = vec3(0.0);
                    vec3 sampleSpecular = vec3(0.0);

                    #if LIGHTING_TRACE_FILTER > 0
                        light_GaussianFilter(sampleDiffuse, sampleSpecular, texcoord, depthTransL, texNormal, roughL);
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
                    
                    blockDiffuse += sampleDiffuse;
                    blockSpecular += sampleSpecular;

                    // #if LIGHTING_MODE_HAND == HAND_LIGHT_SIMPLE
                    //     vec3 handDiffuse = vec3(0.0);
                    //     vec3 handSpecular = vec3(0.0);
                    //     SampleHandLight(handDiffuse, handSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

                    //     #if MATERIAL_SPECULAR != SPECULAR_NONE
                    //         if (metal_f0 >= 0.5) {
                    //             blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                    //             blockSpecular *= albedo;
                    //         }
                    //     #endif

                    //     blockDiffuse += handDiffuse;
                    //     blockSpecular += handSpecular;
                    // #endif

                    //blockDiffuse += emission * MaterialEmissionF;
                #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
                    GetFloodfillLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, deferredLighting.xy, deferredShadow, albedo, metal_f0, roughL, occlusion, sss, tir);

                    #ifdef WORLD_SKY_ENABLED
                        GetSkyLightingFinal(blockDiffuse, blockSpecular, deferredShadow, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, occlusion, sss, tir);
                    #else
                        blockDiffuse += WorldAmbientF;
                    #endif

                    #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                        SampleHandLight(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
                    #endif

                    #if MATERIAL_SPECULAR != SPECULAR_NONE
                        if (metal_f0 >= 0.5) {
                            blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                            blockSpecular *= albedo;
                        }
                    #endif
                #endif

                blockDiffuse += emission * MaterialEmissionF;

                vec3 skyDiffuse = vec3(0.0);
                vec3 skySpecular = vec3(0.0);

                #if LIGHTING_MODE != LIGHTING_MODE_FLOODFILL
                    #ifdef WORLD_SKY_ENABLED
                        GetSkyLightingFinal(skyDiffuse, skySpecular, deferredShadow, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, occlusion, sss, tir);
                    #else
                        blockDiffuse += WorldAmbientF;
                    #endif
                #endif

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    if (metal_f0 >= 0.5) {
                        skyDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                        skySpecular *= albedo;
                    }
                #endif

                float shadowF = min(luminance(deferredShadow), 1.0);
                occlusion = max(occlusion, shadowF);

                vec3 diffuseFinal = blockDiffuse + skyDiffuse;
                vec3 specularFinal = blockSpecular + skySpecular;
                final.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
                final.a = min(deferredColor.a + luminance(specularFinal), 1.0);
            #else
                vec3 diffuse, specular = vec3(0.0);
                GetVanillaLighting(diffuse, deferredLighting.xy);

                #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
                    GetSkyLightingFinal(diffuse, specular, deferredShadow, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, occlusion, sss, tir);
                #endif

                #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                    SampleHandLight(diffuse, specular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
                #endif

                //if (isWater) diffuse *= Water_OpacityF;
                //if (isWater) deferredColor.rgb *= Water_OpacityF;

                final.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
                final.a = min(deferredColor.a + luminance(specular), 1.0);
            #endif

            #if defined SKY_BORDER_FOG_ENABLED && SKY_TYPE == SKY_TYPE_VANILLA
                vec3 fogColorFinal = GetVanillaFogColor(deferredFog.rgb, localViewDir.y);
                fogColorFinal = RGBToLinear(fogColorFinal);

                final.rgb = mix(final.rgb, fogColorFinal, deferredFog.a);
                if (final.a > (1.5/255.0)) final.a = min(final.a + deferredFog.a, 1.0);
            #endif

            #ifdef MATERIAL_REFRACT_ENABLED
                float refractDist = maxOf(abs(refraction * viewSize));
                if (refractDist >= 1.0) {
                    int refractSteps = clamp(int(ceil(refractDist)), 2, 16);
                    vec2 step = refraction / refractSteps;
                    //refraction = step * refractSteps;
                    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

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
            // vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * Sky_BrightnessF;
            #if SKY_TYPE == SKY_TYPE_CUSTOM
                vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * Sky_BrightnessF;// * eyeBrightF;
            #else
                vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
                skyColorFinal = RGBToLinear(skyColorFinal);// * eyeBrightF;
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
                        vec3 fogColorFinal = GetCustomSkyColor(localSunDirection.y, localViewDir.y);// * Sky_BrightnessF;

                        float fogDist = GetShapedFogDistance(localPos);
                        float fogF = GetCustomFogFactor(fogDist);
                    #elif SKY_TYPE == SKY_TYPE_VANILLA
                        vec4 deferredFog = unpackUnorm4x8(deferredData.b);
                        vec3 fogColorFinal = RGBToLinear(deferredFog.rgb);
                        fogColorFinal = GetVanillaFogColor(fogColorFinal, localViewDir.y);

                        float fogF = deferredFog.a;
                    #endif

                    fogColorFinal *= Sky_BrightnessF;

                    #if defined WORLD_SKY_ENABLED && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE //&& SKY_CLOUD_TYPE > CLOUDS_VANILLA
                        float skyTraceFar = far;
                        #ifdef DISTANT_HORIZONS
                            skyTraceFar = max(far, dhFarPlane);
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

        if (isWater) {
            if (tir) final.a = 1.0;
        }
        // else {
        //     vec3 tint = albedo;
        //     if (any(greaterThan(tint, EPSILON3)))
        //         tint = normalize(tint) * 1.7;

        //     tint = mix(tint, vec3(1.0), pow(1.0 - final.a, 3.0));
        //     opaqueFinal *= tint;
        // }

        final.rgb += opaqueFinal * (1.0 - final.a);

        #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FAST && WATER_DEPTH_LAYERS == 1
            if (isEyeInWater == 1) {
                float waterDist = min(viewDist, far);

                #ifdef WORLD_SKY_ENABLED
                    float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0;

                    #ifdef WORLD_SKY_ENABLED
                        eyeSkyLightF *= 1.0 - 0.8 * rainStrength;
                    #endif
                    
                    eyeSkyLightF += 0.02;

                    //float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
                    // vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * Sky_BrightnessF;
                    // #if SKY_TYPE == SKY_TYPE_CUSTOM
                    //     vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * Sky_BrightnessF;// * eyeBrightF;
                    // #else
                    //     vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
                    //     skyColorFinal = RGBToLinear(skyColorFinal);// * eyeBrightF;
                    // #endif

                    vec3 vlLight = (phaseIso * WorldSkyLightColor + WaterAmbientF * skyColorFinal) * eyeSkyLightF;
                #else
                    vec3 vlLight = vec3(phaseIso + WaterAmbientF);
                #endif

                ApplyScatteringTransmission(final.rgb, waterDist, vlLight, WaterDensityF, WaterScatterF, WaterAbsorbF, VOLUMETRIC_SAMPLES);
            }
        #endif

        final.a = 1.0;

        #if defined SKY_BORDER_FOG_ENABLED && defined WORLD_WATER_ENABLED
            if (isEyeInWater == 1) {
                // water fog

                #if SKY_TYPE == SKY_TYPE_CUSTOM
                    float fogF = GetCustomWaterFogFactor(viewDist);

                    #if SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
                        // final.rgb *= 1.0 - fogF;
                        fogF = 1.0;
                    #else
                        // vec3 skyColorFinal = RGBToLinear(skyColor);
                        vec3 fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                        final.rgb = mix(final.rgb, fogColorFinal, fogF);
                    #endif
                #else
                    // TODO
                #endif
            }
        #endif

        #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FAST && WATER_DEPTH_LAYERS > 1
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
        #else
            #if SKY_VOL_FOG_TYPE == VOL_TYPE_FAST && (!defined WORLD_SKY_ENABLED || SKY_CLOUD_TYPE <= CLOUDS_VANILLA)
                #ifdef WORLD_WATER_ENABLED
                    if (isEyeInWater == 0) {
                #endif

                    float maxDist = min(viewDist, far);
                    // vec3 _ambient = vec3(AirAmbientF);
                    vec3 vlLight = vec3(0.0);

                    #ifdef WORLD_SKY_ENABLED
                        vec3 skyLightColor = WorldSkyLightColor * (1.0 - 0.8 * skyRainStrength);

                        float skyLightF = eyeBrightnessSmooth.y / 240.0;
                        skyLightF = _pow2(skyLightF);

                        #if SKY_VOL_FOG_TYPE == VOL_TYPE_FAST
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
                    ApplyScatteringTransmission(final.rgb, maxDist, vlLight, AirDensityF, AirScatterColor, AirExtinctColor, 8);

                #ifdef WORLD_WATER_ENABLED
                    }
                #endif
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
