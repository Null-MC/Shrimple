#define RENDER_HAND
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

#if MATERIAL_NORMALS != NORMALMAP_NONE
    in vec3 vLocalTangent;
    in float vTangentW;
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
uniform sampler2D noisetex;
uniform sampler2D lightmap;

#if MATERIAL_NORMALS != NORMALMAP_NONE
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR
    uniform sampler2D specular;
#endif

#ifdef IRIS_FEATURE_SSBO
    #if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
        uniform sampler2D shadowcolor0;
    #endif
#endif

uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
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

uniform float viewWidth;
uniform float blindness;

uniform int heldItemId;
uniform int heldItemId2;

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

#ifdef IRIS_FEATURE_SSBO
    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        uniform int heldBlockLightValue;
        uniform int heldBlockLightValue2;
        uniform bool firstPersonCamera;
        uniform vec3 eyePosition;
    #endif
#endif

#ifdef VL_BUFFER_ENABLED
    uniform float rainStrength;
#endif

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
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

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#ifdef IRIS_FEATURE_SSBO
    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/dynamic.glsl"
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/collisions.glsl"
        #include "/lib/lighting/tracing.glsl"
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
    //#include "/lib/lighting/dynamic_blocks.glsl"
    #include "/lib/lighting/dynamic_items.glsl"
#endif

#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE
    #include "/lib/material/normalmap.glsl"
#endif

#include "/lib/lighting/basic.glsl"
#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    vec4 color = GetColor();
    color.rgb = RGBToLinear(color.rgb);

    vec3 localNormal = normalize(vLocalNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    float sss, emission;
    if (gl_FragCoord.x > viewWidth / 2) {
        sss = GetMaterialSSS(heldItemId2, texcoord);
        emission = GetMaterialEmission(heldItemId2, texcoord);
    }
    else {
        sss = GetMaterialSSS(heldItemId, texcoord);
        emission = GetMaterialEmission(heldItemId, texcoord);
    }

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
        texNormal = GetMaterialNormal(texcoord);

        vec3 localTangent = normalize(vLocalTangent);
        mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent);
        texNormal *= matLocalTBN;

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            float skyTexNoL = dot(texNormal, localLightDir);

            #if MATERIAL_SSS != SSS_NONE
                skyTexNoL = mix(max(skyTexNoL, 0.0), abs(skyTexNoL), sss);
            #else
                skyTexNoL = max(skyTexNoL, 0.0);
            #endif

            shadowColor *= 1.2 * pow(skyTexNoL, 0.8);
        #endif
    #else
        shadowColor *= max(vLit, 0.0);
    #endif

    vec3 blockLightColor = vBlockLight + GetFinalBlockLighting(vLocalPos, localNormal, texNormal, lmcoord.x, emission, sss);
    color.rgb = GetFinalLighting(color.rgb, blockLightColor, shadowColor, lmcoord, glcolor.a);
    
    ApplyFog(color, vLocalPos);

    ApplyPostProcessing(color.rgb);
    outFinal = color;
}
