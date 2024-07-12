#define RENDER_PARTICLES
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec3 localNormal;

    #ifdef MATERIAL_PARTICLES
        vec2 localCoord;
        vec4 localTangent;

        flat mat2 atlasBounds;
    #endif

    // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
    //     vec3 cloudPos;
    // #endif

    #if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D noisetex;
uniform sampler2D lightmap;

#ifdef WORLD_SKY_ENABLED
    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        uniform sampler2D texSkyIrradiance;
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE && !defined DEFERRED_BUFFER_ENABLED
        uniform sampler2D texSky;
    #endif
#endif

#if defined MATERIAL_PARTICLES && (MATERIAL_NORMALS == NORMALMAP_OLDPBR || MATERIAL_NORMALS == NORMALMAP_LABPBR || defined PARALLAX_ENABLED || MATERIAL_OCCLUSION == OCCLUSION_LABPBR)
    uniform sampler2D normals;
#endif

#if defined MATERIAL_PARTICLES && (MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR || MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR || MATERIAL_POROSITY != POROSITY_NONE)
    uniform sampler2D specular;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#ifdef WORLD_SKY_ENABLED
    //#ifdef SHADOW_CLOUD_ENABLED
        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            uniform sampler3D TEX_CLOUDS;
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
            uniform sampler2D TEX_CLOUDS_VANILLA;
        #endif
    //#endif

    #if defined WATER_CAUSTICS && defined WORLD_WATER_ENABLED && defined IS_IRIS
        uniform sampler3D texCaustics;
    #endif
#elif defined VL_BUFFER_ENABLED
    uniform sampler3D TEX_CLOUDS;
#endif

#if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    // #ifdef SHADOW_CLOUD_ENABLED
    //     uniform sampler2D TEX_CLOUDS;
    // #endif

    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            #ifdef RENDER_TRANSLUCENT
                uniform sampler2DShadow shadowtex0HW;
            #else
                uniform sampler2DShadow shadowtex1HW;
            #endif
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif
    
    // #ifdef IS_IRIS
    //     uniform float cloudTime;
    // #endif
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 upPosition;

uniform float viewWidth;
uniform float near;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform ivec2 eyeBrightnessSmooth;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 skyColor;
    uniform float rainStrength;
    uniform float skyRainStrength;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef MATERIAL_PARTICLES
    uniform ivec2 atlasSize;
#endif

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
    uniform mat4 shadowProjection;
#endif

#ifdef IRIS_FEATURE_SSBO
    #if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || LIGHTING_MODE > LIGHTING_MODE_BASIC
        uniform sampler2D shadowcolor0;
    #endif
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhFarPlane;
#endif

// #if AF_SAMPLES > 1
//     uniform float viewHeight;
//     uniform vec4 spriteBounds;
// #endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#if !(defined DEFERRED_BUFFER_ENABLED && defined DEFERRED_PARTICLES) || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    #ifdef WORLD_SKY_ENABLED
        uniform vec3 sunPosition;
        uniform vec3 shadowLightPosition;
        
        uniform float cloudHeight;

        #if SKY_CLOUD_TYPE != CLOUDS_NONE && defined IS_IRIS
            uniform float cloudTime;
        #endif

        #ifdef IS_IRIS
            uniform float lightningStrength;
        #endif
    #endif

    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    uniform float blindnessSmooth;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/light_static.glsl"
    
    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/lights.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/erp.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/lighting/scatter_transmit.glsl"
#include "/lib/lighting/hg.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

// #if AF_SAMPLES > 1
//     #include "/lib/sampling/anisotropic.glsl"
// #endif

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

#include "/lib/fog/fog_render.glsl"

#if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/render.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/render.glsl"
    #endif
    
    #include "/lib/shadows/render.glsl"
#endif

#ifdef LIGHTING_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#ifdef MATERIAL_PARTICLES
    #include "/lib/sampling/atlas.glsl"
    #include "/lib/utility/tbn.glsl"

    #include "/lib/material/normalmap.glsl"
    #include "/lib/material/emission.glsl"
    #include "/lib/material/subsurface.glsl"
    #include "/lib/material/specular.glsl"
#endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/fresnel.glsl"

#ifdef IRIS_FEATURE_SSBO
    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        #include "/lib/lighting/voxel/tinting.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif
#endif

#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/items.glsl"
#endif

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#if !(defined DEFERRED_BUFFER_ENABLED && defined DEFERRED_PARTICLES) || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    #ifdef WORLD_SKY_ENABLED
        #include "/lib/clouds/cloud_common.glsl"
        #include "/lib/world/lightning.glsl"

        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            #include "/lib/clouds/cloud_custom.glsl"
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
            #include "/lib/clouds/cloud_vanilla.glsl"
        #endif
    #endif

    // #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
    //     #include "/lib/lighting/voxel/sampling.glsl"
    // #endif

    #ifdef WORLD_WATER_ENABLED
        #if defined WORLD_SKY_ENABLED && defined WORLD_WATER_ENABLED
            #include "/lib/lighting/caustics.glsl"
        #endif

        #if WATER_DEPTH_LAYERS > 1
            #include "/lib/buffers/water_depths.glsl"
        #endif
    #endif

    #if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"

        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_render.glsl"
    #endif

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/sky/sky_trace.glsl"
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        #include "/lib/lighting/reflections.glsl"
    #endif

    #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/sky/sky_lighting.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
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
        #ifndef WORLD_SKY_ENABLED
            #include "/lib/fog/fog_smoke.glsl"
        #endif
    #endif
#endif


#if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
    #ifdef DEFERRED_PARTICLES
        layout(location = 0) out vec4 outDeferredColor;
        layout(location = 1) out vec4 outDeferredShadow;
        layout(location = 2) out uvec4 outDeferredData;
        layout(location = 3) out vec3 outDeferredTexNormal;

        #ifdef EFFECT_TAA_ENABLED
            /* RENDERTARGETS: 1,2,3,9,7 */
            layout(location = 4) out vec4 outVelocity;
        #else
            /* RENDERTARGETS: 1,2,3,9 */
        #endif
    #else
        layout(location = 0) out vec4 outFinal;

        #ifdef EFFECT_TAA_ENABLED
            /* RENDERTARGETS: 15,7 */
            layout(location = 1) out vec4 outVelocity;
        #else
            /* RENDERTARGETS: 15 */
        #endif
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

void main() {
    mat2 dFdXY = mat2(dFdx(vIn.texcoord), dFdy(vIn.texcoord));

    vec4 color = texture(gtexture, vIn.texcoord) * vIn.color;

    #ifdef RENDER_TRANSLUCENT
        const float alphaThreshold = (1.5/255.0);
    #else
        float alphaThreshold = alphaTestRef;
    #endif

    if (color.a < alphaThreshold) {
        discard;
        return;
    }
    
    float viewDist = length(vIn.localPos);
    vec3 localViewDir = vIn.localPos / viewDist;
    
    #ifdef MATERIAL_PARTICLES
        const int particleId = -1;

        float roughness, metal_f0;
        float sss = GetMaterialSSS(particleId, vIn.texcoord, dFdXY);
        float emission = GetMaterialEmission(particleId, vIn.texcoord, dFdXY);
        GetMaterialSpecular(particleId, vIn.texcoord, dFdXY, roughness, metal_f0);
    #else
        const float emission = 0.0;
        const float roughness = 1.0;
        const float metal_f0 = 0.04;
        const float sss = 0.0;
    #endif

    const float occlusion = 1.0;
    const vec3 localNormal = vec3(0.0);
    vec3 texNormal = vec3(0.0);

    #if defined MATERIAL_PARTICLES && MATERIAL_NORMALS != NORMALMAP_NONE
        GetMaterialNormal(vIn.texcoord, dFdXY, texNormal);
        texNormal = mat3(gbufferModelViewInverse) * texNormal;

        // vec3 localNormal2 = -normalize(vIn.localPos);

        // vec3 localTangent = normalize(vIn.localTangent.xyz);
        // mat3 matLocalTBN = GetLocalTBN(localNormal2, localTangent, vIn.localTangent.w);
        // texNormal = normalize(matLocalTBN * texNormal);
    #endif

    vec3 shadowColor = vec3(1.0);
    #if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
        #endif

        float shadowFade = smoothstep(shadowDistance - 20.0, shadowDistance + 20.0, viewDist);
    
        #ifdef SHADOW_COLORED
            shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);
        #else
            shadowColor = vec3(GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss));
        #endif
    #endif

    #ifndef RENDER_TRANSLUCENT
        color.a = 1.0;
    #endif

    #if defined DEFERRED_BUFFER_ENABLED && defined DEFERRED_PARTICLES && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        
        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vIn.localPos);
        #endif

        if (!all(lessThan(abs(texNormal), EPSILON3)))
            texNormal = texNormal * 0.5 + 0.5;

        outDeferredColor = 1.5 * color + dither;
        outDeferredShadow = vec4(shadowColor + dither, 0.0);
        outDeferredTexNormal = texNormal;

        outDeferredData.r = packUnorm4x8(vec4(localNormal, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(vIn.lmcoord, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        outDeferredData.a = packUnorm4x8(vec4(roughness + dither, metal_f0 + dither, 0.0, 1.0));
    #else
        vec3 albedo = RGBToLinear(color.rgb);
        float roughL = _pow2(roughness);

        #if LIGHTING_MODE > LIGHTING_MODE_BASIC
            vec3 blockDiffuse = vec3(0.0);
            vec3 blockSpecular = vec3(0.0);

            #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
                GetFloodfillLighting(blockDiffuse, blockSpecular, vIn.localPos, localNormal, texNormal, vIn.lmcoord, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);
                
                #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                    SampleHandLight(blockDiffuse, blockSpecular, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
                #endif

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    if (metal_f0 >= 0.5) {
                        blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                        blockSpecular *= albedo;
                    }
                #endif
            #else
                GetFinalBlockLighting(blockDiffuse, blockSpecular, vIn.localPos, localNormal, texNormal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss);

                #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                    SampleHandLight(blockDiffuse, blockSpecular, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
                #endif

                vec3 skyDiffuse = vec3(0.0);
                vec3 skySpecular = vec3(0.0);

                #ifdef WORLD_SKY_ENABLED
                    #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                        const vec3 shadowPos = vec3(0.0);
                    #endif

                    // float shadowFade = getShadowFade(shadowPos);
                    GetSkyLightingFinal(skyDiffuse, skySpecular, shadowColor, vIn.localPos, localNormal, texNormal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, false);
                #endif

                blockDiffuse += skyDiffuse;
                blockSpecular += skySpecular;

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    if (metal_f0 >= 0.5) {
                        blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                        blockSpecular *= albedo;
                    }
                #endif
            #endif

            color.rgb = GetFinalLighting(albedo, blockDiffuse, blockSpecular, occlusion);
        #else
            vec3 diffuse, specular = vec3(0.0);
            GetVanillaLighting(diffuse, vIn.lmcoord, occlusion);

            #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
                const bool tir = false; // TODO: ?
                GetSkyLightingFinal(diffuse, specular, shadowColor, vIn.localPos, localNormal, texNormal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, tir);
            #endif

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                SampleHandLight(diffuse, specular, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            color.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
        #endif

        //ApplyFog(color, vLocalPos, localViewDir);
        #ifdef SKY_BORDER_FOG_ENABLED
            ApplyFog(color, vIn.localPos, localViewDir);

            // TODO: manually apply fog so you can inverse fogF as alpha

            #if SKY_TYPE == SKY_TYPE_CUSTOM
                float fogDist = GetShapedFogDistance(vIn.localPos);
                float fogF = GetCustomFogFactor(fogDist);
                color.a *= 1.0 - fogF;
            #elif SKY_TYPE == SKY_TYPE_VANILLA
                // TODO
            #endif
        #endif

        // #ifdef VL_BUFFER_ENABLED
        //     #ifndef IRIS_FEATURE_SSBO
        //         vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
        //     #endif

        //     bool isWater = isEyeInWater == 1;
        //     vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, min(viewDist - 0.05, far), far, isWater);
        //     color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        // #endif

        #if defined WORLD_SKY_ENABLED && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE //&& SKY_CLOUD_TYPE <= CLOUDS_VANILLA
            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 0) {
            #endif

                float maxDist = min(viewDist, far);

                // TODO: apply water VL when in water

                vec3 vlLight = (phaseAir + AirAmbientF) * WorldSkyLightColor;
                ApplyScatteringTransmission(color.rgb, maxDist, vlLight, AirDensityF, AirScatterColor, AirExtinctColor, 8);

                // TODO: removed this during refactor but might want to keep
                //color.a *= scatterTransmit.a;

            #ifdef WORLD_WATER_ENABLED
                }
            #endif
        #endif

        outFinal = color;
    #endif

    #ifdef EFFECT_TAA_ENABLED
        outVelocity = vec4(vec3(0.0), 1.0);
    #endif
}
