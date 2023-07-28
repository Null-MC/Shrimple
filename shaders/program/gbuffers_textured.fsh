#define RENDER_TEXTURED
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vPos;
in vec3 vNormal;
in float geoNoL;
in vec3 vLocalPos;
in vec3 vLocalNormal;
in vec3 vBlockLight;

#ifdef RENDER_CLOUD_SHADOWS_ENABLED
    in vec3 cloudPos;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #else
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D gtexture;
uniform sampler2D noisetex;
uniform sampler2D lightmap;

#ifdef WORLD_SHADOW_ENABLED
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    // #ifdef SHADOW_COLORED
    //     uniform sampler2D shadowtex0;
    // #endif

    #ifdef SHADOW_CLOUD_ENABLED
        uniform sampler2D TEX_CLOUDS;
    #endif

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex1HW;
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

uniform int frameCounter;
uniform float frameTimeCounter;
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

uniform float blindness;
uniform ivec2 eyeBrightnessSmooth;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 skyColor;
    uniform vec3 sunPosition;
    uniform float rainStrength;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#else
    uniform int worldTime;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
#endif

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
    uniform sampler2D shadowcolor0;
#endif

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
        #include "/lib/shadows/cascaded_render.glsl"
    #else
        #include "/lib/shadows/basic.glsl"
        #include "/lib/shadows/basic_render.glsl"
    #endif
    
    #include "/lib/shadows/common_render.glsl"
#endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/specular.glsl"

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
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

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/buffers/collissions.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lights.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/items.glsl"

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    #include "/lib/buffers/volume.glsl"
    #include "/lib/lighting/voxel/lpv.glsl"
    #include "/lib/lighting/voxel/lpv_render.glsl"
#endif

#if MATERIAL_REFLECTIONS != REFLECT_NONE
    #include "/lib/lighting/reflections.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_NONE
    #include "/lib/lighting/vanilla.glsl"
#else
    #include "/lib/lighting/basic.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;

    if (color.a < alphaTestRef) {
        discard;
        return;
    }

    vec3 albedo = RGBToLinear(color.rgb);
    
    vec3 shadowColor = vec3(1.0);
    vec3 blockDiffuse = vBlockLight;
    vec3 blockSpecular = vec3(0.0);
    vec3 skyDiffuse = vec3(0.0);
    vec3 skySpecular = vec3(0.0);
    vec3 localViewDir = normalize(vLocalPos);

    const vec3 normal = vec3(0.0);
    const float roughL = 1.0;
    const float metal_f0 = 0.04;
    float occlusion = glcolor.a;
    const float sss = 0.0;

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #ifdef SHADOW_COLORED
            shadowColor = GetFinalShadowColor(localSkyLightDirection, sss);
        #else
            shadowColor = vec3(GetFinalShadowFactor(localSkyLightDirection, sss));
        #endif
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
        vec3 diffuse, specular = vec3(0.0);
        GetVanillaLighting(diffuse, lmcoord, vLocalPos, normal, shadowColor);

        const float geoNoL = 1.0; //dot(localNormal, localSkyLightDirection);
        specular += GetSkySpecular(vLocalPos, geoNoL, normal, albedo, shadowColor, lmcoord, metal_f0, roughL);

        SampleHandLight(diffuse, specular, vLocalPos, normal, normal, albedo, roughL, metal_f0, sss);

        const float emission = 0.0;
        color.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
    #else
        GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, normal, normal, albedo, lmcoord, roughL, metal_f0, sss);
        SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, normal, normal, albedo, roughL, metal_f0, sss);

        #ifdef WORLD_SKY_ENABLED
            #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                const vec3 shadowPos = vec3(0.0);
            #endif

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos[shadowTile], shadowColor, vLocalPos, normal, normal, albedo, lmcoord, roughL, metal_f0, occlusion, sss);
            #else
                GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, shadowColor, vLocalPos, normal, normal, albedo, lmcoord, roughL, metal_f0, occlusion, sss);
            #endif
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

    ApplyFog(color, vLocalPos, localViewDir);

    outFinal = color;
}
