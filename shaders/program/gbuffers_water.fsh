#define RENDER_WATER
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vPos;
in vec3 vNormal;
in float geoNoL;
in float vLit;
in vec3 vLocalPos;
in vec3 vLocalNormal;
in vec3 vBlockLight;
flat in int vBlockId;

#if MATERIAL_NORMALS != NORMALMAP_NONE
    in vec3 vLocalTangent;
    in float vTangentW;
#endif

#if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
    in vec3 physics_localPosition;
    in float physics_localWaviness;
#endif

#ifdef WORLD_SHADOW_ENABLED
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#if MATERIAL_NORMALS != NORMALMAP_NONE
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR
    uniform sampler2D specular;
#endif

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int isEyeInWater;
uniform vec3 skyColor;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform float blindness;

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;
    
    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex0HW;
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif
    
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    uniform ivec2 eyeBrightnessSmooth;
    uniform float rainStrength;
    uniform float near;
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"
#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
        #include "/lib/shadows/cascaded_render.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/basic.glsl"
        #include "/lib/shadows/basic_render.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"
#endif

#include "/lib/lighting/fresnel.glsl"

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/dynamic.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/collisions.glsl"
    #include "/lib/lighting/tracing.glsl"
#endif

//#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
    #include "/lib/lighting/dynamic_items.glsl"
//#endif

#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE
    #include "/lib/material/normalmap.glsl"
#endif

#if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
    #include "/lib/world/physicsmod_ocean.glsl"
#endif

#include "/lib/lighting/basic.glsl"

#ifdef VL_BUFFER_ENABLED
    #include "/lib/world/volumetric_fog.glsl"
#endif

#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;


void main() {
    #if AF_SAMPLES > 1 && defined IRIS_ANISOTROPIC_FILTERING_ENABLED
        vec4 color = textureAnisotropic(gtexture, texcoord);
    #else
        vec4 color = texture(gtexture, texcoord);
    #endif

    color.rgb = RGBToLinear(color.rgb * glcolor.rgb);

    vec3 localNormal = normalize(vLocalNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    float sss = GetMaterialSSS(vBlockId, texcoord);
    float emission = GetMaterialEmission(vBlockId, texcoord);

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        vec3 localLightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

        float skyGeoNoL = max(dot(localNormal, localLightDir), 0.0);

        if (skyGeoNoL < EPSILON && sss < EPSILON) {
            shadowColor = vec3(0.0);
        }
        else {
            #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
                shadowColor = GetFinalShadowColor(sss);
            #else
                shadowColor = vec3(GetFinalShadowFactor(sss));
            #endif
        }
    #endif

    vec3 texNormal = vec3(0.0);
    #if MATERIAL_NORMALS != NORMALMAP_NONE
        vec3 localTangent = normalize(vLocalTangent);
        texNormal = GetMaterialNormal(texcoord, localNormal, localTangent);

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            float skyTexNoL = max(dot(texNormal, localLightDir), 0.0);

            #if MATERIAL_SSS != SSS_NONE
                skyTexNoL = mix(skyTexNoL, 1.0, sss);
            #endif

            shadowColor *= 1.2 * pow(skyTexNoL, 0.8);
        #endif
    #else
        shadowColor *= max(vLit, 0.0);
    #endif

    #ifdef WORLD_WATER_ENABLED
        if (vBlockId == BLOCK_WATER) {
            #ifdef PHYSICS_OCEAN
                texNormal = physics_waveNormal(physics_localPosition.xz, physics_localWaviness, physics_gameTime);
            #else
                texNormal = localNormal;
            #endif
        }
    #endif

    #if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
        if (vBlockId == BLOCK_WATER) {
            if (!gl_FrontFacing && isEyeInWater != 1) {
                discard;
                return;
            }
        }
    #endif

    vec3 localViewDir = normalize(vLocalPos);

    #if defined WORLD_WATER_ENABLED && defined WATER_REFLECTIONS_ENABLED
        if (vBlockId == BLOCK_WATER) {
            if (!gl_FrontFacing) {
                if (isEyeInWater == 1) {
                    localNormal = -localNormal;
                    texNormal = -texNormal;
                }
                else {
                    discard;
                    return;
                }
            }

            vec3 reflectDir = reflect(localViewDir, texNormal);
            vec3 reflectColor = GetFogColor(reflectDir.y) * vec3(0.7, 0.8, 1.0);

            float NoVmax = max(dot(texNormal, -localViewDir), 0.0);
            float F = 1.0 - NoVmax;//F_schlick(NoVmax, 0.02, 1.0);

            color.rgb = mix(color.rgb, reflectColor, F * (1.0 - color.a));
            color.a = max(color.a, F);
        }
        else {
            #if MATERIAL_NORMALS != NORMALMAP_NONE
                float NoVmax = max(dot(texNormal, -localViewDir), 0.0);
            #else
                float NoVmax = max(dot(localNormal, -localViewDir), 0.0);
            #endif

            float F = F_schlick(NoVmax, 0.04, 1.0);
            color.a = 1.0 - (1.0 - F) * (1.0 - color.a);
        }
    #else
        #if MATERIAL_NORMALS != NORMALMAP_NONE
            float NoVmax = max(dot(texNormal, -localViewDir), 0.0);
        #else
            float NoVmax = max(dot(localNormal, -localViewDir), 0.0);
        #endif

        float F = F_schlick(NoVmax, 0.04, 1.0);
        color.a = 1.0 - (1.0 - F) * (1.0 - color.a);
    #endif

    // #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    //     float emission = GetSceneBlockEmission(vBlockId);
    //     float sss = GetBlockSSS(vBlockId);
    // #else
    //     const float emission = 0.0;
    //     const float sss = 0.0;
    // #endif

    vec3 blockLightColor = vBlockLight + GetFinalBlockLighting(vLocalPos, localNormal, texNormal, lmcoord.x, emission, sss);
    color.rgb = GetFinalLighting(color.rgb, blockLightColor, shadowColor, lmcoord, glcolor.a);

    ApplyFog(color, vLocalPos);

    #ifdef VL_BUFFER_ENABLED
        vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, near, min(length(vPos) - 0.05, far));
        color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
    #endif

    ApplyPostProcessing(color.rgb);
    outFinal = color;
}
