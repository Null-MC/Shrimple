#define RENDER_ENTITIES
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

#if MATERIAL_NORMALS != NORMALMAP_NONE
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE
    uniform sampler2D specular;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 skyColor;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform vec4 entityColor;
uniform int entityId;

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
    uniform sampler2D shadowcolor0;
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
    uniform sampler2D lightmap;

    uniform int frameCounter;
    uniform float frameTimeCounter;
    //uniform mat4 gbufferModelView;
    //uniform mat4 gbufferModelViewInverse;
    uniform vec3 cameraPosition;
    //uniform float far;

    uniform float blindness;

    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        uniform int heldItemId;
        uniform int heldItemId2;
        uniform int heldBlockLightValue;
        uniform int heldBlockLightValue2;
        uniform bool firstPersonCamera;
        uniform vec3 eyePosition;
    #endif
#endif

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

    #include "/lib/shadows/common.glsl"
#endif

#include "/lib/entities.glsl"
#include "/lib/lighting/dynamic_entities.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE
    #include "/lib/lighting/normalmap.glsl"
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
    #include "/lib/sampling/depth.glsl"
    //#include "/lib/sampling/noise.glsl"
    #include "/lib/blocks.glsl"
    #include "/lib/items.glsl"

    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
        #include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/dynamic.glsl"
        #include "/lib/lighting/dynamic_blocks.glsl"
    #endif

    #include "/lib/lighting/basic.glsl"
    #include "/lib/post/tonemap.glsl"
#endif


#if (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR)
    /* RENDERTARGETS: 1,2,3 */
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out vec4 outDeferredShadow;
    layout(location = 2) out uvec4 outDeferredData;
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
    color.rgb = mix(color.rgb * glcolor.rgb, entityColor.rgb, entityColor.a);

    vec3 localNormal = normalize(vLocalNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    vec3 localLightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        float skyGeoNoL = max(dot(localNormal, localLightDir), 0.0);

        if (skyGeoNoL < EPSILON) shadowColor = vec3(0.0);
        else {
            #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
                shadowColor = GetFinalShadowColor();
            #else
                shadowColor = vec3(GetFinalShadowFactor());
            #endif
        }
    #endif

    vec3 texNormal = vec3(0.0);
    #if MATERIAL_NORMALS != NORMALMAP_NONE
        vec3 localTangent = normalize(vLocalTangent);
        texNormal = ApplyNormalMap(texcoord, localNormal, localTangent);

        float skyTexNoL = max(dot(texNormal, localLightDir), 0.0);
        shadowColor *= 1.5 * pow(skyTexNoL, 0.6);
    #endif

    float emission = 0.0;
    #if MATERIAL_EMISSION == EMISSION_OLDPBR
        emission = texture(specular, texcoord).b;
    #elif MATERIAL_EMISSION == EMISSION_LABPBR
        emission = texture(specular, texcoord).a;
        if (emission > (254.5/255.0)) emission = 0.0;
    #elif DYN_LIGHT_MODE != DYN_LIGHT_NONE
        emission = GetSceneEntityLightColor(entityId).a / 15.0;
    #endif

    const float sss = 0.0;

    #if (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR)
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        float fogF = GetVanillaFogFactor(vLocalPos);
        vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
        fogColorFinal = LinearToRGB(fogColorFinal);

        color.a = 1.0;
        outDeferredColor = color;
        outDeferredShadow = vec4(shadowColor, 1.0);

        uvec4 deferredData = uvec4(0);
        deferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss));
        deferredData.g = packUnorm4x8(vec4(lmcoord + dither, glcolor.a + dither, emission));
        deferredData.b = packUnorm4x8(vec4(fogColorFinal, fogF + dither));

        #if MATERIAL_NORMALS != NORMALMAP_NONE
            deferredData.a = packUnorm4x8(vec4(texNormal * 0.5 + 0.5, 1.0));
        #endif

        outDeferredData = deferredData;
    #else
        vec3 blockLight = vBlockLight;
        #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
            blockLight += GetFinalBlockLighting(vLocalPos, localNormal, texNormal, lmcoord.x, emission, sss);
        #endif

        color.rgb = RGBToLinear(color.rgb);
        color.rgb = GetFinalLighting(color.rgb, blockLight, shadowColor, lmcoord.y, glcolor.a);

        ApplyFog(color, vLocalPos);

        ApplyPostProcessing(color.rgb);
        outFinal = color;
    #endif
}
