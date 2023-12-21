#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec2 lmcoord;
    vec2 texcoord;
    vec4 color;
    vec3 localPos;
    vec3 localNormal;

    #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        vec3 cloudPos;
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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

#ifdef MATERIAL_PARTICLES
    uniform sampler2D specular;
#endif

#if defined WORLD_SKY_ENABLED && defined SHADOW_CLOUD_ENABLED
    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS;
    #endif
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex1HW;
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

uniform int worldTime;
uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 upPosition;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

uniform float blindnessSmooth;
uniform ivec2 eyeBrightnessSmooth;

#ifndef ANIM_WORLD_TIME
    uniform float frameTimeCounter;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform vec3 skyColor;
    uniform vec3 sunPosition;
    uniform vec3 shadowLightPosition;
    uniform float rainStrength;
    uniform float skyRainStrength;

    #if SKY_CLOUD_TYPE != CLOUDS_NONE && defined IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight = WORLD_CLOUD_HEIGHT;
    #endif

    #ifdef IS_IRIS
        uniform float lightningStrength;
    #endif
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    // uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
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

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || (defined IRIS_FEATURE_SSBO && LIGHTING_MODE != DYN_LIGHT_NONE)
    uniform sampler2D shadowcolor0;
#endif

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
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
#include "/lib/sampling/depth.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#include "/lib/lighting/blackbody.glsl"
#include "/lib/lighting/scatter_transmit.glsl"

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#include "/lib/fog/fog_render.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"

    #if defined SHADOW_CLOUD_ENABLED && SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        #include "/lib/lighting/hg.glsl"
        #include "/lib/clouds/cloud_vars.glsl"
        #include "/lib/clouds/cloud_custom.glsl"
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

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

#include "/lib/material/hcm.glsl"

#ifdef MATERIAL_PARTICLES
    //#include "/lib/material/hcm.glsl"
    #include "/lib/material/emission.glsl"
    #include "/lib/material/subsurface.glsl"
    //#include "/lib/material/specular.glsl"
#endif

#include "/lib/material/specular.glsl"

#ifdef LIGHTING_FLICKER
    #include "/lib/lighting/flicker.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && (LIGHTING_MODE != DYN_LIGHT_NONE || (LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0))
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"

    #if LIGHTING_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/voxel/light_mask.glsl"
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != DYN_LIGHT_NONE
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lights.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"
#include "/lib/lighting/voxel/item_light_map.glsl"
#include "/lib/lighting/voxel/items.glsl"

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (LIGHTING_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    #include "/lib/buffers/volume.glsl"
    #include "/lib/utility/hsv.glsl"
    
    #include "/lib/lighting/voxel/lpv.glsl"
    #include "/lib/lighting/voxel/lpv_render.glsl"
#endif

#if MATERIAL_REFLECTIONS != REFLECT_NONE
    #include "/lib/lighting/reflections.glsl"
#endif

#if LIGHTING_MODE == DYN_LIGHT_NONE
    #include "/lib/lighting/vanilla.glsl"
#elif LIGHTING_MODE == DYN_LIGHT_LPV
    #include "/lib/lighting/floodfill.glsl"
#else
    #include "/lib/lighting/basic.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    vec4 color = texture(gtexture, vIn.texcoord) * vIn.color;

    if (color.a < alphaTestRef) {
        discard;
        return;
    }

    vec3 albedo = RGBToLinear(color.rgb);
    
    vec3 shadowColor = vec3(1.0);
    vec3 blockDiffuse = vec3(0.0);
    vec3 blockSpecular = vec3(0.0);
    vec3 skyDiffuse = vec3(0.0);
    vec3 skySpecular = vec3(0.0);
    vec3 localViewDir = normalize(vIn.localPos);

    const vec3 normal = vec3(0.0);
    float roughL = 1.0;
    float metal_f0 = 0.04;
    float occlusion = 1.0;//vIn.color.a;
    float emission = 0.0;
    float sss = 0.0;

    #ifdef MATERIAL_PARTICLES
        mat2 dFdXY = mat2(dFdx(vIn.texcoord), dFdy(vIn.texcoord));
        float roughness;

        sss = GetMaterialSSS(-1, vIn.texcoord, dFdXY);
        emission = GetMaterialEmission(-1, vIn.texcoord, dFdXY);
        GetMaterialSpecular(-1, vIn.texcoord, dFdXY, roughness, metal_f0);

        roughL = _pow2(roughness);
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
        #endif

        float viewDist = length(vIn.localPos);
        float shadowFade = smoothstep(shadowDistance - 20.0, shadowDistance + 20.0, viewDist);

        #ifdef SHADOW_COLORED
            shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);
        #else
            shadowColor = vec3(GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss));
        #endif
    #endif

    #if LIGHTING_MODE == DYN_LIGHT_NONE
        vec3 diffuse, specular = vec3(0.0);
        GetVanillaLighting(diffuse, vIn.lmcoord, vIn.localPos, normal, normal, shadowColor, sss);

        #if MATERIAL_SPECULAR != SPECULAR_NONE && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            const float geoNoL = 1.0;
            specular += GetSkySpecular(vIn.localPos, geoNoL, normal, albedo, shadowColor, vIn.lmcoord, metal_f0, roughL);
        #endif

        #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            SampleHandLight(diffuse, specular, vIn.localPos, normal, normal, albedo, roughL, metal_f0, occlusion, sss);
        #endif

        color.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
    #elif LIGHTING_MODE == DYN_LIGHT_LPV
        GetFloodfillLighting(blockDiffuse, blockSpecular, vIn.localPos, normal, normal, vIn.lmcoord, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);

        #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            SampleHandLight(blockDiffuse, blockSpecular, vIn.localPos, normal, normal, albedo, roughL, metal_f0, occlusion, sss);
        #endif

        // #ifdef WORLD_SKY_ENABLED
        //     #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
        //         const vec3 shadowPos = vec3(0.0);
        //     #endif

        //     // #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        //     //     GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos[shadowTile], shadowColor, vLocalPos, normal, normal, albedo, lmcoord, roughL, metal_f0, occlusion, sss);
        //     // #else
        //     //     GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, shadowColor, vLocalPos, normal, normal, albedo, lmcoord, roughL, metal_f0, occlusion, sss);
        //     // #endif
        // #endif

        vec3 diffuseFinal = blockDiffuse + skyDiffuse;
        vec3 specularFinal = blockSpecular + skySpecular;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            if (metal_f0 >= 0.5) {
                diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                specularFinal *= albedo;
            }
        #endif

        color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
    #else
        GetFinalBlockLighting(blockDiffuse, blockSpecular, vIn.localPos, normal, normal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss);

        #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            SampleHandLight(blockDiffuse, blockSpecular, vIn.localPos, normal, normal, albedo, roughL, metal_f0, occlusion, sss);
        #endif

        #ifdef WORLD_SKY_ENABLED
            // #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
            //     const vec3 shadowPos = vec3(0.0);
            // #endif

            // #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            //     float shadowFade2 = getShadowFade(shadowPos[shadowTile]);
            // #else
            //     float shadowFade2 = getShadowFade(shadowPos);
            // #endif

            GetSkyLightingFinal(skyDiffuse, skySpecular, shadowColor, vIn.localPos, normal, normal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, false);
        #endif

        vec3 diffuseFinal = blockDiffuse + skyDiffuse;
        vec3 specularFinal = blockSpecular + skySpecular;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            if (metal_f0 >= 0.5) {
                diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                specularFinal *= albedo;
            }
        #endif

        color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
    #endif

    #ifdef DH_COMPAT_ENABLED
        color.rgb = LinearToRGB(color.rgb);
    #elif defined SKY_BORDER_FOG_ENABLED
        ApplyFog(color, vIn.localPos, localViewDir);
    #endif

    outFinal = color;
}
