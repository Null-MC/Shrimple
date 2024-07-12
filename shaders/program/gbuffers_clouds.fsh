#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
    vec3 localNormal;

    #ifdef DISTANT_HORIZONS
        float viewPosZ;
    #endif

    #ifdef RENDER_SHADOWS_ENABLED
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform sampler2D texSkyIrradiance;
#endif

#if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || LIGHTING_MODE > LIGHTING_MODE_BASIC
    uniform sampler2D shadowcolor0;
#endif

// #ifdef RENDER_CLOUD_SHADOWS_ENABLED
//     uniform sampler2D TEX_CLOUDS_VANILLA;
// #endif

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
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

uniform vec3 skyColor;

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

    #ifdef SHADOW_ENABLED
        uniform mat4 shadowProjection;
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
    uniform float cloudHeight;
    uniform float cloudTime;
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/light_static.glsl"
    // #include "/lib/buffers/lighting.glsl"

    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif
    
    // #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    //     #include "/lib/buffers/block_static.glsl"
    // #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/erp.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/blackbody.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"

#include "/lib/clouds/cloud_common.glsl"
#include "/lib/world/sky.glsl"
#include "/lib/world/lightning.glsl"

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

// #ifdef SKY_BORDER_FOG_ENABLED
    #include "/lib/fog/fog_common.glsl"

    #ifdef WORLD_SKY_ENABLED
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            #include "/lib/fog/fog_custom.glsl"
            
            #ifdef WORLD_WATER_ENABLED
                #include "/lib/fog/fog_water_custom.glsl"
            #endif
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            #include "/lib/fog/fog_vanilla.glsl"
        #endif
    #endif

    #include "/lib/fog/fog_render.glsl"
// #endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/fresnel.glsl"

#ifdef RENDER_SHADOWS_ENABLED
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
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/flicker.glsl"
    #endif

    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"

        // #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        //     #include "/lib/lighting/voxel/light_mask.glsl"
        // #endif
    #endif

    #if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        #include "/lib/lighting/voxel/tinting.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif

    #include "/lib/lights.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/lights_render.glsl"

    #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
        #include "/lib/lighting/voxel/item_light_map.glsl"
        #include "/lib/lighting/voxel/items.glsl"
    #endif

    #include "/lib/lighting/fresnel.glsl"
    #include "/lib/lighting/sampling.glsl"

    // #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
    //     #include "/lib/lighting/voxel/sampling.glsl"
    // #endif

    #if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"

        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_render.glsl"
    #endif

    #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
        #include "/lib/lighting/basic_hand.glsl"
    #endif

    #include "/lib/lighting/scatter_transmit.glsl"

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
//#endif


#ifdef EFFECT_TAA_ENABLED
    #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
        /* RENDERTARGETS: 7,15 */
        layout(location = 0) out vec4 outVelocity;
        layout(location = 1) out vec4 outFinal;
    #else
        /* RENDERTARGETS: 0,7 */
        layout(location = 0) out vec4 outFinal;
        layout(location = 1) out vec4 outVelocity;
    #endif
#else
    layout(location = 0) out vec4 outFinal;
    #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
        /* RENDERTARGETS: 15 */
    #else
        /* RENDERTARGETS: 0 */
    #endif
#endif

void main() {
    vec4 albedo = texture(gtexture, vIn.texcoord) * vIn.color;

    if (albedo.a < 0.2) {
        discard;
        return;
    }

    // albedo.a = sqrt(albedo.a);
    albedo.a = min(albedo.a * SkyCloudOpacityF, 1.0);

    float viewDist = length(vIn.localPos);

    #ifdef DISTANT_HORIZONS
        float depthDh = texelFetch(dhDepthTex, ivec2(gl_FragCoord.xy), 0).r;
        float depthDhL = linearizeDepthFast(depthDh, dhNearPlane, dhFarPlane);

        if (vIn.viewPosZ >= depthDhL) {
            discard;
            return;
        }
    #endif

    const float roughness = 0.9;
    const vec3 normal = normalize(vIn.localNormal);
    const float metal_f0 = 0.04;
    const float occlusion = 1.0;
    const float emission = 0.0;
    const float sss = 1.0;

    vec3 shadowColor = vec3(1.0);
    #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
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
        float fogDist = 0.5 * GetShapedFogDistance(vIn.localPos);

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
        //const vec2 lmcoord = vec2(0.0, 1.0);

        // #if LIGHTING_MODE > LIGHTING_MODE_BASIC
        //     vec3 diffuseFinal = vec3(0.0);
        //     vec3 specularFinal = vec3(0.0);

        //     #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        //         GetFinalBlockLighting(diffuseFinal, specularFinal, vIn.localPos, normal, normal, albedo.rgb, lmcoord, roughL, metal_f0, occlusion, sss);
        //         GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, normal, normal, albedo.rgb, lmcoord, roughL, metal_f0, occlusion, sss, false);
        //     #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        //         GetFloodfillLighting(diffuseFinal, specularFinal, vIn.localPos, normal, normal, lmcoord, shadowColor, albedo.rgb, metal_f0, roughL, occlusion, sss, false);
        //     #endif

        //     #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
        //         SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, normal, normal, albedo.rgb, roughL, metal_f0, occlusion, sss);
        //     #endif

        //     final.rgb = GetFinalLighting(albedo.rgb, diffuseFinal, specularFinal, occlusion);
        // #else

        vec3 diffuseFinal = vec3(0.0);
        vec3 specularFinal = vec3(0.0);

        float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * Sky_BrightnessF * eyeBrightF;
        #else
            vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
            skyColorFinal = RGBToLinear(skyColorFinal) * eyeBrightF;
        #endif

        #if LIGHTING_MODE == LIGHTING_MODE_NONE
            diffuseFinal += albedo.rgb * (1.0 + fogColor);
        #else
            diffuseFinal += albedo.rgb * (shadowColor * WorldSkyLightColor + skyColorFinal);
        #endif

        #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE && LIGHTING_MODE <= LIGHTING_MODE_FLOODFILL
            SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, normal, normal, albedo.rgb, roughL, metal_f0, occlusion, sss);
        #endif

        #if LIGHTING_MODE >= LIGHTING_MODE_FLOODFILL
            final.rgb = GetFinalLighting(albedo.rgb, diffuseFinal, specularFinal, occlusion);
        // #elif LIGHTING_MODE < LIGHTING_MODE_FLOODFILL
        #else
            final.rgb = GetFinalLighting(albedo.rgb, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
        #endif

        // #ifdef VL_BUFFER_ENABLED
        //     #ifndef IRIS_FEATURE_SSBO
        //         vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
        //     #endif

        //     vec3 localViewDir = normalize(vIn.localPos);
        //     vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, min(viewDist, far));
        //     final.rgb = final.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        // #else

        #if SKY_VOL_FOG_TYPE != VOL_TYPE_NONE
            #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                float weatherF = 1.0 - 0.5 * _pow2(skyRainStrength);
            #else
                float weatherF = 1.0 - 0.8 * _pow2(skyRainStrength);
            #endif
        
            vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;

            // float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
            // vec3 skyColorFinal = GetCustomSkyColor(localSunDirection.y, 1.0) * Sky_BrightnessF * eyeBrightF;

            vec3 vlLight = phaseAir * skyLightColor + AirAmbientF * skyColorFinal;
            ApplyScatteringTransmission(final.rgb, min(viewDist, far), vlLight, AirDensityF, AirScatterColor, AirExtinctColor, 8);
        #endif
        
        outFinal = final;
    //#endif

    #ifdef EFFECT_TAA_ENABLED
        // TODO: get vanilla cloud velocity
        outVelocity = vec4(vec3(0.0), 0.0);
    #endif
}
