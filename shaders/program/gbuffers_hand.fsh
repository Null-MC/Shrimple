#define RENDER_HAND
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

#if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
    uniform sampler2D lightmap;

    #if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
        uniform sampler2D shadowcolor0;
    #endif

    uniform int frameCounter;
    uniform float frameTimeCounter;
    //uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;
    uniform vec3 cameraPosition;
    //uniform float far;

    uniform float blindness;

    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
        uniform int heldItemId;
        uniform int heldItemId2;
        uniform int heldBlockLightValue;
        uniform int heldBlockLightValue2;
        uniform bool firstPersonCamera;
        uniform vec3 eyePosition;
    #endif
#endif

uniform mat4 gbufferModelView;
uniform vec3 skyColor;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

//#include "/lib/sampling/ign.glsl"

#include "/lib/world/fog.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#include "/lib/sampling/depth.glsl"
//#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

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

#if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
        #include "/lib/blocks.glsl"
        #include "/lib/items.glsl"
        #include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/dynamic.glsl"
        #include "/lib/lighting/dynamic_blocks.glsl"
    #endif

    #include "/lib/lighting/basic.glsl"

    #ifdef TONEMAP_ENABLED
        #include "/lib/post/tonemap.glsl"
    #endif
#endif


#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    /* RENDERTARGETS: 1,2 */
    layout(location = 0) out uvec3 outDeferredPre;
    layout(location = 1) out uvec2 outDeferredPost;
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
    vec4 color = texture(gtexture, texcoord);

    if (color.a < alphaTestRef) {
        discard;
        return;
    }

    color.a = 1.0;
    color.rgb *= glcolor.rgb;
    vec3 localNormal = normalize(vLocalNormal);

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
            shadowColor = GetFinalShadowColor();
        #else
            shadowColor = vec3(GetFinalShadowFactor());
        #endif
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        float fogF = GetVanillaFogFactor(vLocalPos);
        vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
        fogColorFinal = LinearToRGB(fogColorFinal);

        const float lightLevel = 0.0;

        uvec3 deferredPre;
        deferredPre.r = packUnorm4x8(color);
        deferredPre.g = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, 1.0));
        deferredPre.b = packUnorm4x8(vec4(lmcoord, glcolor.a, lightLevel));

        uvec2 deferredPost;
        deferredPost.r = packUnorm4x8(vec4(shadowColor, 1.0));
        deferredPost.g = packUnorm4x8(vec4(fogColorFinal, fogF));

        outDeferredPre = deferredPre;
        outDeferredPost = deferredPost;
    #else
        vec3 blockLight = vBlockLight;
        #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
            blockLight += GetFinalBlockLighting(vLocalPos, localNormal, lmcoord.x);
        #endif

        color.rgb = RGBToLinear(color.rgb);
        color.rgb = GetFinalLighting(color.rgb, blockLight, shadowColor, vPos, lmcoord, glcolor.a);

        ApplyFog(color, vLocalPos);

        #ifdef TONEMAP_ENABLED
            color.rgb = tonemap_Tech(color.rgb);
        #endif

        outFinal = vec4(LinearToRGB(color.rgb), 1.0);
    #endif
}
