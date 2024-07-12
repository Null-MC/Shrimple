#define RENDER_GENERIC_DH
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;

    flat uint materialId;
} vIn;

uniform sampler2D noisetex;

// #if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || (defined IRIS_FEATURE_SSBO && LIGHTING_MODE > LIGHTING_MODE_BASIC)
//     uniform sampler2D shadowcolor0;
// #endif

#ifdef WORLD_SKY_ENABLED
    // #ifdef WORLD_WETNESS_ENABLED
    //     uniform sampler3D TEX_RIPPLES;
    // #endif

    // #ifdef SHADOW_CLOUD_ENABLED
    //     #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
    //         uniform sampler3D TEX_CLOUDS;
    //     #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
    //         uniform sampler2D TEX_CLOUDS_VANILLA;
    //     #endif
    // #endif
#endif

uniform sampler2D lightmap;

// #if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
//     uniform sampler3D texLPV_1;
//     uniform sampler3D texLPV_2;
// #endif

// #ifdef RENDER_SHADOWS_ENABLED
//     uniform sampler2D shadowtex0;
//     uniform sampler2D shadowtex1;

//     #ifdef SHADOW_ENABLE_HWCOMP
//         #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
//             uniform sampler2DShadow shadowtex1HW;
//         #else
//             uniform sampler2DShadow shadow;
//         #endif
//     #endif
// #endif

uniform int worldTime;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 upPosition;

uniform float dhFarPlane;
uniform float far;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform ivec2 eyeBrightnessSmooth;
uniform int frameCounter;

#ifndef ANIM_WORLD_TIME
    uniform float frameTimeCounter;
#endif

// #ifdef IS_LPV_ENABLED
//     uniform vec3 previousCameraPosition;
//     uniform mat4 gbufferPreviousModelView;
// #endif

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform float rainStrength;
    uniform float wetness;

    uniform float skyRainStrength;
    uniform float skyWetnessSmooth;

    #ifdef IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
        uniform float lightningStrength;
    #endif
#endif

#ifdef IS_IRIS
    uniform vec3 eyePosition;
#endif

// #ifdef WORLD_SHADOW_ENABLED
//     uniform mat4 shadowModelView;
//     uniform vec3 shadowLightPosition;

//     #ifdef SHADOW_ENABLED
//         uniform mat4 shadowProjection;
//     #endif
// #endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#if !defined IRIS_FEATURE_SSBO || LIGHTING_MODE != LIGHTING_MODE_TRACED
    uniform float blindnessSmooth;

    // uniform int heldItemId;
    // uniform int heldItemId2;
    // uniform int heldBlockLightValue;
    // uniform int heldBlockLightValue2;
    
    // #ifdef IS_IRIS
    //     uniform bool firstPersonCamera;
    //     uniform vec3 eyePosition;
    // #endif
#endif

// #if AF_SAMPLES > 1
//     uniform float viewWidth;
//     uniform float viewHeight;
//     uniform vec4 spriteBounds;
// #endif

// #if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
//     uniform float alphaTestRef;
// #endif

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

#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/noise.glsl"

#include "/lib/utility/hsv.glsl"
#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/fresnel.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"

    #ifdef WORLD_WETNESS_ENABLED
        // #include "/lib/material/porosity.glsl"
        #include "/lib/world/wetness.glsl"
    #endif
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

#ifdef RENDER_SHADOWS_ENABLED
    // #include "/lib/buffers/shadow.glsl"

    // #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    //     #include "/lib/shadows/cascaded/common.glsl"
    //     #include "/lib/shadows/cascaded/render.glsl"
    // #else
    //     #include "/lib/shadows/distorted/common.glsl"
    //     #include "/lib/shadows/distorted/render.glsl"
    // #endif

    // #include "/lib/shadows/render.glsl"
#endif

#ifdef LIGHTING_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#ifndef DEFERRED_BUFFER_ENABLED
    #ifdef WORLD_SKY_ENABLED
        #include "/lib/clouds/cloud_common.glsl"
        #include "/lib/world/lightning.glsl"

        #if defined SHADOW_CLOUD_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
            #include "/lib/clouds/cloud_custom.glsl"
        #endif
    #endif

    #include "/lib/lighting/sampling.glsl"

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

#include "/lib/lighting/voxel/item_light_map.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"
#include "/lib/lighting/voxel/items.glsl"

#include "/lib/material/hcm.glsl"
#include "/lib/material/fresnel.glsl"

#ifndef DEFERRED_BUFFER_ENABLED
    #include "/lib/lighting/scatter_transmit.glsl"

    #ifdef IS_LPV_ENABLED
        #include "/lib/buffers/volume.glsl"

        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_render.glsl"
    #endif
    
    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        #if MATERIAL_REFLECTIONS != REFLECT_NONE
            #include "/lib/lighting/reflections.glsl"
        #endif

        #ifdef WORLD_SKY_ENABLED
            #include "/lib/sky/sky_lighting.glsl"
        #endif
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/traced.glsl"
    #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        #include "/lib/lighting/floodfill.glsl"
    #else
        #include "/lib/lighting/vanilla.glsl"
    #endif

    // #include "/lib/lighting/basic_hand.glsl"
#endif


#ifdef DEFERRED_BUFFER_ENABLED
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
        /* RENDERTARGETS: 0,7 */
        layout(location = 1) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 0 */
    #endif
#endif

void main() {
    float viewDist = length(vIn.localPos);
    if (viewDist < dh_clipDistF * far) {
        discard;
        return;
    }
    
    vec2 lmFinal = vIn.lmcoord;
    
    vec3 localNormal = normalize(vIn.localNormal);

    float porosity = 0.0;
    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
        float skyWetness = 0.0, puddleF = 0.0;
        //vec4 rippleNormalStrength = vec4(0.0);

        // if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT) {
            // #if DISPLACE_MODE == DISPLACE_TESSELATION
            //     vec3 worldPos = vIn.surfacePos + cameraPosition;
            // #else
                vec3 worldPos = vIn.localPos + cameraPosition;
            // #endif

            float surface_roughness, surface_metal_f0;
            //GetMaterialSpecular(vIn.blockId, vIn.texcoord, dFdXY, surface_roughness, surface_metal_f0);
            surface_roughness = 0.95;
            surface_metal_f0 = 0.04;

            // porosity = GetMaterialPorosity(vIn.texcoord, dFdXY, surface_roughness, surface_metal_f0);
            porosity = 0.75;
            skyWetness = GetSkyWetness(worldPos, localNormal, lmFinal);//, vBlockId);
            puddleF = GetWetnessPuddleF(skyWetness, porosity);

            #if WORLD_WETNESS_PUDDLES > PUDDLES_BASIC
                //rippleNormalStrength = GetWetnessRipples(worldPos, viewDist, puddleF);
                //localCoord -= rippleNormalStrength.yx * rippleNormalStrength.w * RIPPLE_STRENGTH;
                // if (!skipParallax) atlasCoord = GetAtlasCoord(localCoord, vIn.atlasBounds);
            #endif
        // }
    #endif

    vec3 viewPos = mul3(gbufferModelView, vIn.localPos);

    vec4 color = vIn.color;

    vec3 albedo = RGBToLinear(color.rgb);
    color.a = 1.0;

    float occlusion = 1.0;
    float roughness, metal_f0;
    // float sss = GetMaterialSSS(vIn.blockId, atlasCoord, dFdXY);
    // float emission = GetMaterialEmission(vIn.blockId, atlasCoord, dFdXY);
    float emission = 0.0;
    float sss = 0.0;
    // GetMaterialSpecular(vIn.blockId, atlasCoord, dFdXY, roughness, metal_f0);
    roughness = 0.95;
    metal_f0 = 0.04;

    if (vIn.materialId == DH_BLOCK_LEAVES) sss = 0.8;
    if (vIn.materialId == DH_BLOCK_SNOW) sss = 0.6;
    if (vIn.materialId == DH_BLOCK_LAVA) emission = 1.0;
    if (vIn.materialId == DH_BLOCK_ILLUMINATED) emission = 1.0;
    
    vec3 shadowColor = vec3(1.0);
    #ifdef RENDER_SHADOWS_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
        #endif

        float skyGeoNoL = dot(localNormal, localSkyLightDirection);

        if (skyGeoNoL < EPSILON && sss < EPSILON) {
            shadowColor = vec3(0.0);
        }
        else {
            // #ifdef DISTANT_HORIZONS
            //     float shadowDistFar = min(shadowDistance, 0.5*dhFarPlane);
            // #else
            //     float shadowDistFar = min(shadowDistance, far);
            // #endif

            // vec3 shadowViewPos = mul3(shadowModelView, vIn.localPos);
            // float shadowViewDist = length(shadowViewPos.xy);
            // float shadowFade = 1.0 - smoothstep(shadowDistFar - 20.0, shadowDistFar, shadowViewDist);

            // #if SHADOW_TYPE != SHADOW_TYPE_CASCADED
            //     shadowFade *= step(-1.0, vIn.shadowPos.z);
            //     shadowFade *= step(vIn.shadowPos.z, 1.0);
            // #endif

            // shadowFade = 1.0 - shadowFade;

            // #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            //     float shadowFade = 0.0;
            //     float lmShadow = 1.0;
            // #else
            //     float shadowFade = float(vIn.shadowPos != clamp(vIn.shadowPos, -1.0, 1.0));

            //     float lmShadow = pow(lmFinal.y, 9);
            //     if (vIn.shadowPos == clamp(vIn.shadowPos, -0.85, 0.85)) lmShadow = 1.0;
            // #endif

            // #ifdef SHADOW_COLORED
            //     // if (vIn.shadowPos == clamp(vIn.shadowPos, -1.0, 1.0))
            //     if (shadowFade < 1.0)
            //         shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);

            //     shadowColor = min(shadowColor, vec3(lmShadow));
            // #else
            //     float shadowF = 1.0;
            //     // if (vIn.shadowPos == clamp(vIn.shadowPos, -1.0, 1.0))
            //     if (shadowFade < 1.0)
            //         shadowF = GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss);
                
            //     shadowF = min(shadowF, lmShadow);
            //     shadowColor = vec3(shadowF);
            // #endif

            // lmFinal.y = mix(lmFinal.y, pow3(lmFinal.y), shadowFade);

            // if (viewDist < shadowDistance) {
            //     #ifndef LIGHT_LEAK_FIX
            //         float lightF = min(luminance(shadowColor), 1.0) * (1.0 - shadowFade);
            //         lmFinal.y = max(lmFinal.y, lightF);
            //     #endif
            // }

            //shadowColor = 1.0 - (1.0 - shadowColor) * (1.0 - shadowFade);

            // #if defined WATER_CAUSTICS
            //     float causticLight = SampleWaterCaustics(vLocalPos);
            //     causticLight = 6.0 * pow(causticLight, 1.0 + 1.0 * Water_WaveStrength);

            //     float causticStrength = Water_CausticStrength;
            //     //causticStrength *= min(waterDepth*0.5, 1.0);
            //     //causticStrength *= max(1.0 - waterDepth/waterDensitySmooth, 0.0);
                
            //     // TODO: get shadow depth!
            //     float texDepthTrans = textureLod(shadowtex0, shadowPos.xy, 0).r;
            //     float waterDepth = ;

            //     shadowColor *= 1.0 + 1.0*causticLight * causticStrength;
            // #endif
        }
    #endif

    vec3 texNormal = localNormal;

    vec3 localViewDir = normalize(vIn.localPos);

    #ifdef DEFERRED_BUFFER_ENABLED
        #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
            ApplySkyWetness(roughness, porosity, skyWetness, puddleF);
        #endif

        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vIn.localPos);
        #endif

        color.rgb = LinearToRGB(albedo);

        if (!all(lessThan(abs(texNormal), EPSILON3)))
            texNormal = texNormal * 0.5 + 0.5;

        outDeferredColor = color + dither;
        outDeferredShadow = vec4(shadowColor + dither, 0.0);
        outDeferredTexNormal = texNormal;

        outDeferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(lmFinal, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(fogColor, fogF) + dither);
        outDeferredData.a = packUnorm4x8(vec4(roughness, metal_f0, porosity, 1.0) + dither);
    #else
        float roughL = _pow2(roughness);
        
        #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
            float cloudShadow = TraceCloudShadow(cameraPosition + localPos, localSkyLightDirection, CLOUD_GROUND_SHADOW_STEPS);
            deferredShadow.rgb *= 1.0 - (1.0 - cloudShadow) * (1.0 - Shadow_CloudBrightnessF);
        #endif
        
        #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
            ApplySkyWetness(albedo, roughness, porosity, skyWetness, puddleF);
        #endif

        vec3 diffuseFinal = vec3(0.0), specularFinal = vec3(0.0);
        #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
            // GetFloodfillLighting(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, lmFinal, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);

            #ifdef WORLD_SKY_ENABLED
                const bool tir = false; // TODO: ?
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, localNormal, texNormal, albedo, lmFinal, roughL, metal_f0, occlusion, sss, tir);
            #else
                diffuseFinal += WorldAmbientF;
            #endif

            // #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            //     SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            // #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                if (metal_f0 >= 0.5) {
                    diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                    specularFinal *= albedo;
                }
            #endif

            diffuseFinal += emission * MaterialEmissionF;

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
        #elif LIGHTING_MODE < LIGHTING_MODE_FLOODFILL
            GetVanillaLighting(diffuseFinal, vIn.lmcoord, occlusion);

            #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, localNormal, texNormal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, false);
            #endif

            // #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            //     SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            // #endif

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
        #endif

        color.a = 1.0;

        #ifdef SKY_BORDER_FOG_ENABLED
            ApplyFog(color, vIn.localPos, localViewDir);
        #endif

        #if defined WORLD_SKY_ENABLED && SKY_VOL_FOG_TYPE != VOL_TYPE_NONE //&& SKY_CLOUD_TYPE <= CLOUDS_VANILLA
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
