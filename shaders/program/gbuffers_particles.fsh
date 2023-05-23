#define RENDER_PARTICLES
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

#ifdef MATERIAL_PARTICLES
    in vec2 vLocalCoord;
    in vec3 vLocalTangent;
    in float vTangentW;

    flat in mat2 atlasBounds;
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

#if defined MATERIAL_PARTICLES && (MATERIAL_NORMALS == NORMALMAP_OLDPBR || MATERIAL_NORMALS == NORMALMAP_LABPBR || MATERIAL_PARALLAX != PARALLAX_NONE || MATERIAL_OCCLUSION == OCCLUSION_LABPBR)
    uniform sampler2D normals;
#endif

#if defined MATERIAL_PARTICLES && (MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR || MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR || MATERIAL_POROSITY != POROSITY_NONE)
    uniform sampler2D specular;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
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
#endif

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

uniform float blindness;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef MATERIAL_PARTICLES
    uniform ivec2 atlasSize;
#endif

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

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
    uniform int worldTime;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
#endif

#ifdef IRIS_FEATURE_SSBO
    #if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
        uniform sampler2D shadowcolor0;
    #endif
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    uniform ivec2 eyeBrightnessSmooth;
    //uniform int isEyeInWater;
#endif

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/sampling/depth.glsl"
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

#include "/lib/lights.glsl"

#ifdef MATERIAL_PARTICLES
    #include "/lib/sampling/atlas.glsl"
    #include "/lib/utility/tbn.glsl"

    #include "/lib/material/normalmap.glsl"
    #include "/lib/material/emission.glsl"
    #include "/lib/material/subsurface.glsl"
#endif

#include "/lib/material/specular.glsl"

#ifdef IRIS_FEATURE_SSBO
    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
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

#if (defined DEFERRED_BUFFER_ENABLED && defined RENDER_TRANSLUCENT) || !defined DEFERRED_BUFFER_ENABLED
    #if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED)
        #include "/lib/lighting/voxel/sampling.glsl"
    #endif

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"
    #endif

    #if LPV_SIZE > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        #include "/lib/buffers/volume.glsl"
        #include "/lib/lighting/voxel/lpv.glsl"
    #endif

    #include "/lib/lighting/basic_hand.glsl"
    #include "/lib/lighting/basic.glsl"

    #ifdef VL_BUFFER_ENABLED
        // #if LPV_SIZE > 0 && VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_EMIT
        //     #include "/lib/lighting/voxel/lpv.glsl"
        // #endif

        #include "/lib/world/volumetric_fog.glsl"
    #endif
#endif


#if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
    /* RENDERTARGETS: 1,2,3,14 */
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out vec4 outDeferredShadow;
    layout(location = 2) out uvec4 outDeferredData;
    #if MATERIAL_SPECULAR != SPECULAR_NONE
        layout(location = 3) out vec4 outDeferredRough;
    #endif
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
    mat2 dFdXY = mat2(dFdx(texcoord), dFdy(texcoord));

    vec4 color = texture(gtexture, texcoord) * glcolor;

    #ifdef RENDER_TRANSLUCENT
        const float alphaThreshold = (1.5/255.0);
    #else
        float alphaThreshold = alphaTestRef;
    #endif

    if (color.a < alphaThreshold) {
        discard;
        return;
    }
    
    vec3 localViewDir = normalize(vLocalPos);
    
    #ifdef MATERIAL_PARTICLES
        const int particleId = -1;

        float roughness, metal_f0;
        float sss = GetMaterialSSS(particleId, texcoord, dFdXY);
        float emission = GetMaterialEmission(particleId, texcoord, dFdXY);
        GetMaterialSpecular(particleId, texcoord, dFdXY, roughness, metal_f0);
    #else
        const float emission = 0.0;
        const float roughness = 1.0;
        const float metal_f0 = 0.04;
        const float sss = 0.0;
    #endif

    const float occlusion = 1.0;
    const vec3 localNormal = vec3(0.0);
    vec3 texNormal = vec3(0.0);

    #if defined MATERIAL_PARTICLES && MATERIAL_NORMALS != NORMALMAP_NONE
        GetMaterialNormal(texcoord, dFdXY, texNormal);

        vec3 localTangent = normalize(vLocalTangent);
        mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent);
        texNormal = normalize(matLocalTBN * texNormal);
    #endif

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #ifdef SHADOW_COLORED
            shadowColor = GetFinalShadowColor();
        #else
            shadowColor = vec3(GetFinalShadowFactor());
        #endif
    #endif

    #if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        float fogF = GetVanillaFogFactor(vLocalPos);

        if (!all(lessThan(abs(texNormal), EPSILON3)))
            texNormal = texNormal * 0.5 + 0.5;

        color.a = 1.0;
        outDeferredColor = color;
        outDeferredShadow = vec4(shadowColor, 1.0);

        outDeferredData = uvec4(
            packUnorm4x8(vec4(localNormal, sss + dither)),
            packUnorm4x8(vec4(lmcoord, occlusion, emission) + dither),
            packUnorm4x8(vec4(fogColor, fogF + dither)),
            packUnorm4x8(vec4(texNormal, 1.0)));

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outDeferredRough = vec4(roughness + dither, metal_f0 + dither, 0.0, 1.0);
        #endif
    #else
        color.rgb = RGBToLinear(color.rgb);
        float roughL = _pow2(roughness);

        vec3 blockDiffuse = vBlockLight;
        vec3 blockSpecular = vec3(0.0);
        vec3 skyDiffuse = vec3(0.0);
        vec3 skySpecular = vec3(0.0);

        //blockDiffuse += emission * MaterialEmissionF;

        #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, lmcoord.x, roughL, metal_f0, sss);
        #endif

        #ifdef WORLD_SKY_ENABLED
            GetSkyLightingFinal(skyDiffuse, skySpecular, shadowColor, localViewDir, localNormal, texNormal, lmcoord.y, roughL, metal_f0, sss);
        #endif

        vec3 diffuseFinal = blockDiffuse + skyDiffuse;
        vec3 specularFinal = blockSpecular + skySpecular;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            if (metal_f0 >= 0.5) {
                diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                specularFinal *= color.rgb;
            }
        #endif

        color.rgb = GetFinalLighting(color.rgb, vLocalPos, texNormal, diffuseFinal, specularFinal, lmcoord, metal_f0, roughL, occlusion);

        ApplyFog(color, vLocalPos, localViewDir);

        #ifdef VL_BUFFER_ENABLED
            #ifndef IRIS_FEATURE_SSBO
                vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            #endif

            vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, min(length(vPos) - 0.05, far));
            color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        #endif

        outFinal = color;
    #endif
}
