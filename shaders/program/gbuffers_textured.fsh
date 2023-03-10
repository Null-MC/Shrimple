#define RENDER_TEXTURED
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vPos;
in vec3 vNormal;
in float geoNoL;
in float vLit;
in vec3 vBlockLight;

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    in vec3 vLocalPos;
    in vec3 vLocalNormal;
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

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && DYN_LIGHT_TEMPORAL > 0
    uniform sampler2D BUFFER_BLOCKLIGHT_PREV;
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    uniform sampler2D noisetex;
#endif

uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float far;

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#ifndef SHADOW_BLUR
    #ifdef IRIS_FEATURE_CUSTOM_TEXTURE_NAME
        uniform sampler2D texLightMap;
    #else
        uniform sampler2D lightmap;
    #endif

    uniform vec3 upPosition;
    uniform vec3 skyColor;
    //uniform float far;
    
    uniform vec3 fogColor;
    uniform float fogDensity;
    uniform float fogStart;
    uniform float fogEnd;
    uniform int fogShape;
    uniform int fogMode;

    uniform float blindness;
#endif

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
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

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    uniform int frameCounter;

    #if DYN_LIGHT_TEMPORAL > 0
        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;
        uniform vec3 previousCameraPosition;
        uniform float viewWidth;
        uniform float viewHeight;
    #endif
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
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
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/blocks.glsl"
    #include "/lib/items.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/collisions.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
#endif

#ifdef TONEMAP_ENABLED
    #include "/lib/post/tonemap.glsl"
#endif

#include "/lib/lighting/basic.glsl"


/* RENDERTARGETS: 0,1,2,4 */
layout(location = 0) out vec4 outColor0;
#ifdef SHADOW_BLUR
    layout(location = 1) out vec4 outColor1;
    layout(location = 2) out vec4 outColor2;
#endif
#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && DYN_LIGHT_TEMPORAL > 0
    layout(location = 3) out vec3 outColor3;
#endif

void main() {
    vec4 color = GetColor() * glcolor;

    #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
        vec3 lightColor = GetFinalShadowColor();
    #else
        vec3 lightColor = vec3(GetFinalShadowFactor());
    #endif

    #ifdef SHADOW_BLUR
        outColor0 = color;
        outColor1 = vec4(lightColor, 1.0);
        outColor2 = vec4(lmcoord, 1.0, 1.0);
    #else
        vec3 blockLightColor = GetFinalBlockLighting(lmcoord.x);

        outColor0 = GetFinalLighting(color, blockLightColor, lightColor, vPos, lmcoord, glcolor.a);
        
        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && DYN_LIGHT_TEMPORAL > 0
            outColor3 = blockLightColor;
        #endif
    #endif
}
