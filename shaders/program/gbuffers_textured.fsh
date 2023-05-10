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

#ifdef WORLD_SHADOW_ENABLED
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D gtexture;
uniform sampler2D noisetex;
uniform sampler2D lightmap;

#ifdef WORLD_SHADOW_ENABLED
    uniform sampler2D shadowtex0;

    #if SHADOW_COLORS != SHADOW_COLOR_DISABLED
        uniform sampler2D shadowtex1;
    #endif

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex0HW;
    #endif
#endif

uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
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

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
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

#include "/lib/material/specular.glsl"

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#ifdef IRIS_FEATURE_SSBO
    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        //#include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/buffers/collissions.glsl"
        #include "/lib/lighting/voxel/collisions.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif
#endif

#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/items.glsl"

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/lighting/sky.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED)
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"
#include "/lib/lighting/basic.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;

    if (color.a < alphaTestRef) {
        discard;
        return;
    }

    color.rgb = RGBToLinear(color.rgb);
    
    vec3 shadowColor = vec3(1.0);
    vec3 blockDiffuse = vBlockLight;
    vec3 blockSpecular = vec3(0.0);
    vec3 skyDiffuse = vec3(0.0);
    vec3 skySpecular = vec3(0.0);
    vec3 localViewDir = normalize(vLocalPos);

    const vec3 normal = vec3(0.0);
    const float roughL = 1.0;
    const float metal_f0 = 0.04;
    const float sss = 0.0;

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
            shadowColor = GetFinalShadowColor();
        #else
            shadowColor = vec3(GetFinalShadowFactor());
        #endif
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, normal, normal, lmcoord.x, roughL, metal_f0, sss);
    #endif

    #ifdef WORLD_SKY_ENABLED
        GetSkyLightingFinal(skyDiffuse, skySpecular, shadowColor, localViewDir, normal, normal, lmcoord.y, roughL, metal_f0, sss);
    #endif

    color.rgb = GetFinalLighting(color.rgb, normal, blockDiffuse, blockSpecular, skyDiffuse, skySpecular, lmcoord, metal_f0, roughL, glcolor.a);

    ApplyFog(color, vLocalPos, localViewDir);

    outFinal = color;
}
