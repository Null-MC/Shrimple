#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec3 vPos;
in vec3 vLocalPos;
in vec4 vColor;
in float vLit;
in float geoNoL;
in vec3 vBlockLight;

#ifdef WORLD_SHADOW_ENABLED
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D lightmap;

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D noisetex;
#endif

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float far;

uniform float fogStart;
uniform float fogEnd;

uniform float blindness;

#ifdef WORLD_SHADOW_ENABLED
    uniform sampler2D shadowtex0;

    #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
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

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

// #if MC_VERSION >= 11700
//     uniform float alphaTestRef;
// #endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"
//#include "/lib/world/fog.glsl"

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
        #include "/lib/shadows/cascaded_render.glsl"
    #else
        #include "/lib/shadows/basic.glsl"
        #include "/lib/shadows/basic_render.glsl"
    #endif

    #include "/lib/shadows/common.glsl"
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/blocks.glsl"
    #include "/lib/items.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/dynamic.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/collisions.glsl"
    #include "/lib/lighting/tracing.glsl"
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/lighting/dynamic_blocks.glsl"
#endif

#include "/lib/lighting/basic.glsl"
#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

float linear_fog_fade(const in float vertexDistance, const in float fogStart, const in float fogEnd) {
    if (vertexDistance <= fogStart) return 1.0;
    else if (vertexDistance >= fogEnd) return 0.0;

    return smoothstep(fogEnd, fogStart, vertexDistance);
}

void main() {
    vec4 final = vColor;

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
        final.rgb += SampleDynamicLighting(vLocalPos, normal, normal, 0.0, vec3(0.0));
        final.rgb += SampleHandLight(vLocalPos, normal, normal, 0.0);
    #endif

    float viewDist = length(vLocalPos);
    float newWidth = (fogEnd - fogStart) * 4.0;
    float fade = linear_fog_fade(viewDist, fogStart, fogStart + newWidth);
    final.a *= fade;

    ApplyPostProcessing(final.rgb);
    outFinal = final;
}
