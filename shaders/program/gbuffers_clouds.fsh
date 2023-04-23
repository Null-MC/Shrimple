#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec3 vPos;
in vec3 vLocalPos;
in vec4 vColor;
in float geoNoL;
in vec3 vBlockLight;

#ifndef IS_IRIS
    in vec2 texcoord;
#endif

#ifdef WORLD_SHADOW_ENABLED
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D lightmap;
uniform sampler2D noisetex;

#ifndef IS_IRIS
    uniform sampler2D gtexture;
#endif

#if defined IRIS_FEATURE_SSBO && VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_EMIT
    uniform sampler3D texLPV;
#endif

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float near;
uniform float far;

uniform int fogShape;
uniform float fogStart;
uniform float fogEnd;

uniform float rainStrength;
uniform float blindness;

#ifdef WORLD_SHADOW_ENABLED
    uniform sampler2D shadowtex0;

    #if SHADOW_COLORS != SHADOW_COLOR_DISABLED
        uniform sampler2D shadowtex1;
    #endif

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex0HW;
    #endif
    
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#endif

//#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    #ifdef IS_IRIS
        uniform bool firstPersonCamera;
        uniform vec3 eyePosition;
    #endif
//#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    uniform ivec2 eyeBrightnessSmooth;
    //uniform float rainStrength;
    uniform int isEyeInWater;
    uniform vec3 skyColor;
    uniform vec3 fogColor;
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#else
    #include "/lib/post/saturation.glsl"
#endif

#include "/lib/material/specular.glsl"

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

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/collisions.glsl"
        #include "/lib/lighting/tracing.glsl"
    #endif
#endif

#include "/lib/lighting/dynamic_lights.glsl"
#include "/lib/lighting/dynamic_items.glsl"
#include "/lib/lighting/sampling.glsl"

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/lighting/dynamic/sampling.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"
#include "/lib/lighting/basic.glsl"

#ifdef VL_BUFFER_ENABLED
    #include "/lib/world/volumetric_fog.glsl"
#endif

#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

float linear_fog_fade(const in float vertexDistance, const in float fogStart, const in float fogEnd) {
    if (vertexDistance <= fogStart) return 1.0;
    else if (vertexDistance >= fogEnd) return 0.0;

    return smoothstep(fogEnd, fogStart, vertexDistance);
}

void main() {
    #ifndef IS_IRIS
        vec4 final = texture(gtexture, texcoord) * vColor;

        if (final.a < 0.2) {
            discard;
            return;
        }
    #else
        vec4 final = vColor;
    #endif

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
            shadowColor = GetFinalShadowColor();
        #else
            shadowColor = vec3(GetFinalShadowFactor());
        #endif
    #endif

    final.rgb *= mix(vec3(1.0), shadowColor, ShadowBrightnessF);

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        const vec3 normal = vec3(0.0);
        const float roughL = 0.9;
        const float metal_f0 = 0.04;
        const float sss = 0.0;

        // TODO: Is this right?
        const vec3 blockLightDefault = vec3(0.0);

        vec3 blockDiffuse = vec3(0.0);
        vec3 blockSpecular = vec3(0.0);

        SampleDynamicLighting(blockDiffuse, blockSpecular, vLocalPos, normal, normal, roughL, metal_f0, sss, blockLightDefault);
        SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, normal, normal, roughL, metal_f0, sss);
        
        final.rgb += blockDiffuse * vColor.rgb + blockSpecular;
    #endif

    vec3 fogPos = vLocalPos;
    if (fogShape == 1) fogPos.y = 0.0;

    float viewDist = length(fogPos);
    float newWidth = (fogEnd - fogStart) * 4.0;
    float fade = linear_fog_fade(viewDist, fogStart, fogStart + newWidth);
    final.a *= fade;

    #ifdef VL_BUFFER_ENABLED
        vec3 localViewDir = normalize(vLocalPos);
        vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, near, min(length(vPos), far));
        final.rgb = final.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
    #endif

    //ApplyPostProcessing(final.rgb);
    outFinal = final;
}
