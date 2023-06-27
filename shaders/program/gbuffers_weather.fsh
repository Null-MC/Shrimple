#define RENDER_WEATHER
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in float geoNoL;
in vec3 vPos;
in vec3 vLocalPos;
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
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;
    
    uniform sampler2D shadowcolor1;
    
    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex0HW;
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif
    
    #ifdef IS_IRIS
        uniform float cloudTime;
    #endif
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 upPosition;
uniform vec3 skyColor;
uniform float near;
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

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform float rainStrength;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#else
    //uniform int worldTime;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
#endif

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    //uniform int isEyeInWater;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
    uniform ivec2 eyeBrightnessSmooth;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/specular.glsl"
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

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || (LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0))
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/buffers/collissions.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lights.glsl"

#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/items.glsl"
#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined DYN_LIGHT_WEATHER
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    #include "/lib/buffers/volume.glsl"
    #include "/lib/lighting/voxel/lpv.glsl"
    #include "/lib/lighting/voxel/lpv_render.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"
#include "/lib/lighting/basic.glsl"

#ifdef VL_BUFFER_ENABLED
    #include "/lib/world/volumetric_fog.glsl"
#endif


#if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
    /* RENDERTARGETS: 15 */
    layout(location = 0) out vec4 outFinal;
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;

    if (color.a < (1.5/255.0)) {
        discard;
        return;
    }

    color.a *= WorldRainOpacityF;

    const vec3 normal = vec3(0.0);
    const float occlusion = 1.0;
    const float roughness = 0.6;
    const float metal_f0 = 0.04;
    const float emission = 0.0;
    const float sss = 0.4;

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #ifdef SHADOW_COLORED
            shadowColor = GetFinalShadowColor(localSkyLightDirection, sss);
        #else
            shadowColor = vec3(GetFinalShadowFactor(localSkyLightDirection, sss));
        #endif
    #endif

    color.rgb = RGBToLinear(color.rgb);
    float roughL = _pow2(roughness);

    vec3 localViewDir = normalize(vLocalPos);

    vec3 blockDiffuse = vBlockLight;
    vec3 blockSpecular = vec3(0.0);
    vec3 skyDiffuse = vec3(0.0);
    vec3 skySpecular = vec3(0.0);

    GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, normal, normal, lmcoord, roughL, metal_f0, sss);
    SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, normal, normal, roughL, metal_f0, sss);

    #ifdef WORLD_SKY_ENABLED
        #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE != SHADOW_TYPE_DISTORTED
            const vec3 shadowPos = vec3(0.0);
        #endif

        GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, shadowColor, vLocalPos, normal, normal, lmcoord, roughL, metal_f0, occlusion, sss);
    #endif

    vec3 diffuseFinal = blockDiffuse + skyDiffuse;
    vec3 specularFinal = blockSpecular + skySpecular;

    #if MATERIAL_SPECULAR != SPECULAR_NONE
        if (metal_f0 >= 0.5) {
            diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
            specularFinal *= color.rgb;
        }
    #endif

    color.rgb = GetFinalLighting(color.rgb, diffuseFinal, specularFinal, glcolor.a);

    ApplyFog(color, vLocalPos, localViewDir);

    #ifdef VL_BUFFER_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
        #endif

        vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, min(length(vPos) - 0.05, far));
        color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
    #endif

    outFinal = color;
}
