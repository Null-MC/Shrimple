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
in vec3 vLocalPos;
in vec2 vLocalCoord;
in vec3 vLocalNormal;
in vec3 vLocalTangent;
in vec3 vBlockLight;
in float vTangentW;
flat in mat2 atlasBounds;

#if MATERIAL_PARALLAX != PARALLAX_NONE
    in vec3 tanViewPos;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
        in vec3 tanLightPos;
    #endif
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

#if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR || MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR
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

uniform int entityId;
uniform vec4 entityColor;
uniform float blindness;
uniform ivec2 atlasSize;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
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

#ifdef IS_IRIS
    uniform int currentRenderedItemId;
    
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    uniform ivec2 eyeBrightnessSmooth;
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
#include "/lib/entities.glsl"
#include "/lib/items.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/utility/tbn.glsl"
    #include "/lib/sampling/atlas.glsl"
#endif

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

#include "/lib/lights.glsl"
#include "/lib/physics_mod/snow.glsl"

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#if (defined DEFERRED_BUFFER_ENABLED && defined RENDER_TRANSLUCENT) || !defined DEFERRED_BUFFER_ENABLED
    #include "/lib/lighting/fresnel.glsl"

    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            #include "/lib/lighting/voxel/mask.glsl"
            #include "/lib/lighting/voxel/blocks.glsl"
        #endif

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            #include "/lib/buffers/collissions.glsl"
            #include "/lib/lighting/voxel/collisions.glsl"
            #include "/lib/lighting/voxel/tinting.glsl"
            #include "/lib/lighting/voxel/tracing.glsl"
        #endif
    #endif
#endif

#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/entities.glsl"
#include "/lib/lighting/voxel/items.glsl"

#if MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"
#include "/lib/material/specular.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE
    #include "/lib/material/normalmap.glsl"
#endif

#if (defined DEFERRED_BUFFER_ENABLED && defined RENDER_TRANSLUCENT) || !defined DEFERRED_BUFFER_ENABLED
    #include "/lib/lighting/sampling.glsl"

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
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
    vec2 atlasCoord = texcoord;

    #if MATERIAL_PARALLAX != PARALLAX_NONE
        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(tanViewPos);
        bool skipParallax = false;
    #endif

    vec4 color = vec4(0.0);
    if (entityId == ENTITY_PHYSICSMOD_SNOW) {
        color.rgb = GetSnowColor(vLocalPos + cameraPosition) * glcolor.rgb;
        color.a = 1.0;
    }
    else {
        #if MATERIAL_PARALLAX != PARALLAX_NONE
            float viewDist = length(vPos);

            if (!skipParallax && viewDist < MATERIAL_PARALLAX_DISTANCE) {
                atlasCoord = GetParallaxCoord(vLocalCoord, dFdXY, tanViewDir, viewDist, texDepth, traceCoordDepth);
            }

        #endif

        color = textureGrad(gtexture, atlasCoord, dFdXY[0], dFdXY[1]);

        #ifdef RENDER_TRANSLUCENT
            const float alphaThreshold = (1.5/255.0);
        #else
            float alphaThreshold = alphaTestRef;
        #endif

        if (color.a < alphaThreshold) {
            discard;
            return;
        }

        #ifndef RENDER_TRANSLUCENT
            color.a = 1.0;
        #endif

        color.rgb = mix(color.rgb * glcolor.rgb, entityColor.rgb, entityColor.a);
    }

    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        color.rgb = vec3(WHITEWORLD_VALUE);
    #endif

    vec3 localNormal = normalize(vLocalNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    vec3 localViewDir = normalize(vLocalPos);

    // int materialId = entityId;
    // if (currentRenderedItemId > 0) {
    //     materialId = currentRenderedItemId;
    //     //color.rgb = vec3(1.0, 0.0, 0.0);
    // }

    float occlusion = 1.0;
    float roughness, metal_f0, sss, emission;
    sss = GetMaterialSSS(entityId, atlasCoord, dFdXY);
    emission = GetMaterialEmission(entityId, atlasCoord, dFdXY);
    GetMaterialSpecular(-1, atlasCoord, dFdXY, roughness, metal_f0);

    #ifdef WORLD_AO_ENABLED
        occlusion = RGBToLinear(glcolor.a);
    #endif

    #if defined RENDER_TRANSLUCENT && defined TRANSLUCENT_SSS_ENABLED
        sss = max(sss, 1.0 - color.a);
    #endif

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSkyLightDirection = normalize((gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz);
        #endif

        float skyGeoNoL = dot(localNormal, localSkyLightDirection);

        if (skyGeoNoL < EPSILON && sss < EPSILON) {
            shadowColor = vec3(0.0);
        }
        else {
            #ifdef SHADOW_COLORED
                shadowColor = GetFinalShadowColor(sss);
            #else
                shadowColor = vec3(GetFinalShadowFactor(sss));
            #endif
        }
    #endif

    vec3 texNormal = localNormal;
    #if MATERIAL_NORMALS != NORMALMAP_NONE
        bool isValidNormal = false;

        if (entityId != ENTITY_PHYSICSMOD_SNOW)
            isValidNormal = GetMaterialNormal(atlasCoord, dFdXY, texNormal);

        #if MATERIAL_PARALLAX != PARALLAX_NONE
            if (!skipParallax) {
                #if MATERIAL_PARALLAX == PARALLAX_SHARP
                    float depthDiff = max(texDepth - traceCoordDepth.z, 0.0);

                    if (depthDiff >= ParallaxSharpThreshold) {
                        texNormal = GetParallaxSlopeNormal(atlasCoord, dFdXY, traceCoordDepth.z, tanViewDir);
                        isValidNormal = true;
                    }
                #endif

                #if defined WORLD_SKY_ENABLED && MATERIAL_PARALLAX_SHADOW_SAMPLES > 0
                    if (traceCoordDepth.z + EPSILON < 1.0) {
                        vec3 tanLightDir = normalize(tanLightPos);
                        shadowColor *= GetParallaxShadow(traceCoordDepth, dFdXY, tanLightDir);
                    }
                #endif
            }
        #endif

        if (isValidNormal) {
            vec3 localTangent = normalize(vLocalTangent);
            mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent);
            texNormal = matLocalTBN * texNormal;
        }

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            float skyTexNoL = dot(texNormal, localSkyLightDirection);

            #if MATERIAL_SSS != SSS_NONE
                skyTexNoL = mix(max(skyTexNoL, 0.0), abs(skyTexNoL), sss);
            #else
                skyTexNoL = max(skyTexNoL, 0.0);
            #endif

            shadowColor *= 1.2 * pow(max(skyTexNoL, 0.0), 0.8);
        #endif
    #endif

    #if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        float fogF = GetVanillaFogFactor(vLocalPos);

        #ifndef RENDER_TRANSLUCENT
            color.a = 1.0;
        #endif

        outDeferredColor = color;
        outDeferredShadow = vec4(shadowColor + dither, 1.0);

        uvec4 deferredData;
        deferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss + dither));
        deferredData.g = packUnorm4x8(vec4(lmcoord, occlusion, emission) + dither);
        deferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        deferredData.a = packUnorm4x8(vec4(texNormal * 0.5 + 0.5, 1.0));
        outDeferredData = deferredData;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outDeferredRough = vec4(roughness + dither, metal_f0 + dither, 0.0, 1.0);
        #endif
    #else
        color.rgb = RGBToLinear(color.rgb);
        float roughL = max(_pow2(roughness), ROUGH_MIN);

        #ifdef RENDER_TRANSLUCENT
            if (color.a > (0.5/255.0)) {
                float NoV = abs(dot(texNormal, -localViewDir));

                float F = F_schlick(NoV, metal_f0, 1.0);
                color.a += (1.0 - color.a) * F;
            }
        #endif

        vec3 blockDiffuse = vBlockLight;
        vec3 blockSpecular = vec3(0.0);
        vec3 skyDiffuse = vec3(0.0);
        vec3 skySpecular = vec3(0.0);

        blockDiffuse += emission * MaterialEmissionF;

        GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, lmcoord.x, roughL, metal_f0, sss);

        #ifdef WORLD_SKY_ENABLED
            GetSkyLightingFinal(skyDiffuse, skySpecular, shadowColor, -localViewDir, localNormal, texNormal, lmcoord.y, roughL, metal_f0, sss);
        #endif

        vec3 diffuseFinal = blockDiffuse + skyDiffuse;
        vec3 specularFinal = blockSpecular + skySpecular;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            if (metal_f0 >= 0.5) {
                diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                specularFinal *= color.rgb;
            }
        #endif

        color.rgb = GetFinalLighting(color.rgb, vLocalPos, localNormal, diffuseFinal, specularFinal, lmcoord, metal_f0, roughL, occlusion);

        ApplyFog(color, vLocalPos, localViewDir);

        #ifdef VL_BUFFER_ENABLED
            #ifndef IRIS_FEATURE_SSBO
                vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            #endif

            float farMax = min(length(vPos) - 0.05, far);
            vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, farMax);
            color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        #endif

        outFinal = color;
    #endif
}
