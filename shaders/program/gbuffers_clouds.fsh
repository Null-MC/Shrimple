#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec3 vLocalPos;
in vec4 vColor;
// in vec3 vBlockLight;

// #ifdef RENDER_CLOUD_SHADOWS_ENABLED
//     in vec3 cloudPos;
// #endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #else
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

#ifdef RENDER_CLOUD_SHADOWS_ENABLED
    uniform sampler2D TEX_CLOUDS;
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float near;
uniform float far;

uniform int fogShape;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;

uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
uniform float skyRainStrength;
uniform float blindnessSmooth;

//#ifdef WORLD_SKY_ENABLED
    uniform vec3 skyColor;
//#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex0HW;
    #endif
    
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;

        #ifdef RENDER_CLOUD_SHADOWS_ENABLED
            uniform float cloudTime;
        #endif
    #endif
#endif

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform float lightningStrength;
    uniform vec3 eyePosition;
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/collisions.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"

#include "/lib/lighting/blackbody.glsl"

#ifdef SKY_BORDER_FOG_ENABLED
    #include "/lib/fog/fog_common.glsl"

    #ifdef WORLD_SKY_ENABLED
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            #include "/lib/fog/fog_custom.glsl"
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            #include "/lib/fog/fog_vanilla.glsl"
        #endif
    #endif

    #include "/lib/fog/fog_render.glsl"
#endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/specular.glsl"

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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

//#if !(defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED)
    #ifdef DYN_LIGHT_FLICKER
        #include "/lib/lighting/flicker.glsl"
    #endif

    #if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || (LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0))
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            #include "/lib/lighting/voxel/light_mask.glsl"
        #endif
    #endif

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        //#include "/lib/buffers/collisions.glsl"
        #include "/lib/lighting/voxel/tinting.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif

    #include "/lib/lights.glsl"
    // #include "/lib/lighting/voxel/block_light_map.glsl"
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/lights_render.glsl"
    #include "/lib/lighting/voxel/items.glsl"
    #include "/lib/lighting/fresnel.glsl"
    #include "/lib/lighting/sampling.glsl"

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/voxel/sampling.glsl"
    #endif

    #if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
        #include "/lib/buffers/volume.glsl"
        #include "/lib/lighting/voxel/lpv.glsl"
        #include "/lib/lighting/voxel/lpv_render.glsl"
    #endif

    #include "/lib/world/sky.glsl"
    #include "/lib/lighting/basic_hand.glsl"

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/basic.glsl"
    #elif DYN_LIGHT_MODE == DYN_LIGHT_LPV
        #include "/lib/lighting/floodfill.glsl"
    #else
        #include "/lib/lighting/vanilla.glsl"
    #endif

    #ifdef WORLD_WATER_ENABLED
        #include "/lib/world/water.glsl"
    #endif

    #include "/lib/lighting/scatter_transmit.glsl"

    // #ifdef VL_BUFFER_ENABLED
    //     #include "/lib/lighting/hg.glsl"
    //     #include "/lib/fog/fog_volume.glsl"
    // #endif

    #ifdef DH_COMPAT_ENABLED
        #include "/lib/post/saturation.glsl"
        #include "/lib/post/tonemap.glsl"
    #endif
//#endif


layout(location = 0) out vec4 outFinal;
#if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
    /* RENDERTARGETS: 15 */
#else
    /* RENDERTARGETS: 0 */
#endif

void main() {
    vec4 albedo = texture(gtexture, texcoord) * vColor;

    if (albedo.a < 0.2) {
        discard;
        return;
    }

    const float roughness = 0.9;
    const vec3 normal = vec3(0.0);
    const float metal_f0 = 0.04;
    const float occlusion = 1.0;
    const float emission = 0.0;
    const float sss = 0.6;

    float viewDist = length(vLocalPos);

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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

    float fogF = 0.0;
    #ifdef SKY_BORDER_FOG_ENABLED
        float fogDist = 0.5 * GetShapedFogDistance(vLocalPos);

        #if SKY_TYPE == SKY_TYPE_CUSTOM
            fogF = GetCustomFogFactor(fogDist);
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            fogF = GetFogFactor(fogDist, fogStart, fogEnd, 1.0);
        #endif

        albedo.a *= 1.0 - fogF;
    #endif

    albedo.rgb = RGBToLinear(albedo.rgb);
    //albedo.rgb *= 1.0 - 0.7 * rainStrength;

    // #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
    //     float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

    //     outDeferredColor = vec4(LinearToRGB(albedo.rgb), albedo.a);
    //     outDeferredShadow = vec4(shadowColor + dither, 0.0);

    //     const vec2 lmcoord = vec2((0.5/16.0), (15.5/16.0));

    //     uvec4 deferredData;
    //     deferredData.r = packUnorm4x8(vec4(normal, sss + dither));
    //     deferredData.g = packUnorm4x8(vec4(lmcoord, occlusion, emission) + dither);
    //     deferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
    //     deferredData.a = packUnorm4x8(vec4(normal, 1.0));
    //     outDeferredData = deferredData;

    //     #if MATERIAL_SPECULAR != SPECULAR_NONE
    //         outDeferredRough = vec4(roughness, metal_f0, 0.0, 1.0) + dither;
    //     #endif
    // #else
        float roughL = _pow2(roughness);
        vec4 final = albedo;

        // TODO: do clouds have lightmap coords?
        const vec2 lmcoord = vec2(0.0, 1.0);

        #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
            vec3 diffuse = vec3(0.0), specular = vec3(0.0);
            GetVanillaLighting(diffuse, lmcoord, vLocalPos, normal, normal, shadowColor, sss);

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                    float geoNoL = dot(normal, localSkyLightDirection);
                #else
                    float geoNoL = 1.0;
                #endif

                specular += GetSkySpecular(vLocalPos, geoNoL, normal, albedo.rgb, shadowColor, lmcoord, metal_f0, roughL);
            #endif

            SampleHandLight(diffuse, specular, vLocalPos, normal, normal, albedo.rgb, roughL, metal_f0, occlusion, sss);

            final.rgb = GetFinalLighting(albedo.rgb, diffuse, specular, metal_f0, roughL, emission, occlusion);
        #elif defined IRIS_FEATURE_SSBO
            vec3 diffuseFinal = vec3(0.0);
            vec3 specularFinal = vec3(0.0);

            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                    const vec3 shadowPos = vec3(0.0);
                #endif

                // float shadowFade = getShadowFade(shadowPos);

                GetFinalBlockLighting(diffuseFinal, specularFinal, vLocalPos, normal, normal, albedo.rgb, lmcoord, roughL, metal_f0, occlusion, sss);
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vLocalPos, normal, normal, albedo.rgb, lmcoord, roughL, metal_f0, occlusion, sss, false);
            #elif DYN_LIGHT_MODE == DYN_LIGHT_LPV
                GetFloodfillLighting(diffuseFinal, specularFinal, vLocalPos, normal, normal, lmcoord, shadowColor, albedo.rgb, metal_f0, roughL, occlusion, sss, false);
                
                //SampleHandLight(diffuseFinal, specularFinal, vLocalPos, normal, normal, albedo.rgb, roughL, metal_f0, occlusion, sss);
            #endif

            SampleHandLight(diffuseFinal, specularFinal, vLocalPos, normal, normal, albedo.rgb, roughL, metal_f0, occlusion, sss);

            final.rgb = GetFinalLighting(albedo.rgb, diffuseFinal, specularFinal, occlusion);
        #endif

        // #ifdef VL_BUFFER_ENABLED
        //     #ifndef IRIS_FEATURE_SSBO
        //         vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
        //     #endif

        //     vec3 localViewDir = normalize(vLocalPos);
        //     vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, min(viewDist, far));
        //     final.rgb = final.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        // #else

        #if SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
            vec3 vlLight = (phaseAir + AirAmbientF) * WorldSkyLightColor;
            vec4 scatterTransmit = ApplyScatteringTransmission(min(viewDist, far), vlLight, AirScatterF, AirExtinctF);
            final.rgb = final.rgb * scatterTransmit.a + scatterTransmit.rgb;
        #endif

        #ifdef DH_COMPAT_ENABLED
            final.rgb = LinearToRGB(final.rgb);
        #endif
        
        outFinal = final;
    //#endif
}
