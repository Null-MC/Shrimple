#define RENDER_HAND
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vLocalPos;
in vec2 vLocalCoord;
in vec3 vLocalNormal;
in vec3 vLocalTangent;
// in vec3 vBlockLight;
in float vTangentW;

flat in mat2 atlasBounds;

#if MATERIAL_PARALLAX != PARALLAX_NONE
    in vec3 tanViewPos;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
        in vec3 tanLightPos;
    #endif
#endif

#ifdef RENDER_CLOUD_SHADOWS_ENABLED
    in vec3 cloudPos;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        in vec3 shadowPos[4];
        flat in int shadowTile;
    #else
        in vec3 shadowPos;
    #endif
#endif

uniform sampler2D gtexture;
uniform sampler2D noisetex;
uniform sampler2D lightmap;

#if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR || MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR
    uniform sampler2D specular;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
    uniform sampler2D shadowcolor0;
#endif

#if defined WORLD_SKY_ENABLED && defined SHADOW_CLOUD_ENABLED
    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS;
    #endif
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    // #ifdef SHADOW_CLOUD_ENABLED
    //     uniform sampler2D TEX_CLOUDS;
    // #endif

    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            #ifdef RENDER_TRANSLUCENT
                uniform sampler2DShadow shadowtex0HW;
            #else
                uniform sampler2DShadow shadowtex1HW;
            #endif
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif
#endif

uniform ivec2 atlasSize;

uniform int worldTime;
uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 upPosition;
uniform float viewWidth;
uniform vec3 skyColor;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform ivec2 eyeBrightnessSmooth;

#ifndef ANIM_WORLD_TIME
    uniform float frameTimeCounter;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform float rainStrength;
    uniform float skyRainStrength;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    //uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#endif

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#if AF_SAMPLES > 1
    //uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    #ifdef WORLD_SKY_ENABLED
        uniform vec3 sunPosition;
        uniform vec3 shadowLightPosition;

        #if SKY_CLOUD_TYPE != CLOUDS_NONE && defined IS_IRIS
            uniform float cloudTime;
            uniform float cloudHeight = WORLD_CLOUD_HEIGHT;
        #endif

        #ifdef IS_IRIS
            uniform float lightningStrength;
        #endif
    #endif

    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    uniform float blindnessSmooth;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/collisions.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#include "/lib/fog/fog_render.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/sampling/atlas.glsl"
    #include "/lib/utility/tbn.glsl"
#endif

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/render.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/render.glsl"
    #endif

    #include "/lib/shadows/render.glsl"
#endif

#if MATERIAL_NORMALS != NORMALMAP_NONE
    #include "/lib/material/normalmap.glsl"
#endif

#include "/lib/lights.glsl"

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

// #include "/lib/lighting/voxel/block_light_map.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"

#if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"

        #if defined SHADOW_CLOUD_ENABLED && SKY_CLOUD_TYPE == CLOUDS_CUSTOM
            #include "/lib/lighting/hg.glsl"
            #include "/lib/clouds/cloud_vars.glsl"
            #include "/lib/clouds/cloud_custom.glsl"
        #endif
    #endif

    #if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_TRACED || LPV_SIZE > 0)
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            #include "/lib/lighting/voxel/light_mask.glsl"
        #endif
    #endif

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        //#include "/lib/buffers/collisions.glsl"
        #include "/lib/lighting/voxel/tinting.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif

    #include "/lib/lighting/fresnel.glsl"
    #include "/lib/lighting/sampling.glsl"
#endif

#include "/lib/lighting/voxel/items.glsl"

#if MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"
#include "/lib/material/specular.glsl"

#if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    #include "/lib/lighting/scatter_transmit.glsl"

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/voxel/sampling.glsl"
    #endif

    // #ifdef WORLD_SKY_ENABLED
    //     #include "/lib/world/sky.glsl"
    // #endif

    #if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
        #include "/lib/buffers/volume.glsl"
        #include "/lib/lighting/voxel/lpv.glsl"
        #include "/lib/lighting/voxel/lpv_render.glsl"
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        #ifdef WORLD_WATER_ENABLED
            #include "/lib/world/water.glsl"
        #endif
    
        #include "/lib/lighting/reflections.glsl"
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
        #include "/lib/lighting/vanilla.glsl"
    #else
        #include "/lib/lighting/basic.glsl"
    #endif

    #include "/lib/lighting/basic_hand.glsl"

    #ifdef DH_COMPAT_ENABLED
        #include "/lib/post/saturation.glsl"
        #include "/lib/post/tonemap.glsl"
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

    float viewDist = length(vLocalPos);
    
    #if MATERIAL_PARALLAX != PARALLAX_NONE
        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(tanViewPos);

        if (viewDist < MATERIAL_PARALLAX_DISTANCE) {
            atlasCoord = GetParallaxCoord(vLocalCoord, dFdXY, tanViewDir, viewDist, texDepth, traceCoordDepth);
        }
    #endif

    vec4 color = textureGrad(gtexture, atlasCoord, dFdXY[0], dFdXY[1]);

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

    color.rgb *= glcolor.rgb;
    
    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        color.rgb = vec3(WHITEWORLD_VALUE);
    #endif

    const float occlusion = 1.0; // glcolor.a

    vec3 localNormal = normalize(vLocalNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    #ifdef IS_IRIS
        int itemId = currentRenderedItemId;
    #else
        int itemId = (gl_FragCoord.x > viewWidth / 2) ? heldItemId : heldItemId2;
    #endif

    float roughness, metal_f0, emission, sss;
    sss = GetMaterialSSS(itemId, atlasCoord, dFdXY);
    emission = GetMaterialEmission(itemId, atlasCoord, dFdXY);
    GetMaterialSpecular(itemId, atlasCoord, dFdXY, roughness, metal_f0);

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
            float shadowFade = smoothstep(shadowDistance - 20.0, shadowDistance + 20.0, viewDist);

            #ifdef SHADOW_COLORED
                shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);
            #else
                shadowColor = vec3(GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss));
            #endif
        }
    #endif

    vec3 texNormal = localNormal;
    #if MATERIAL_NORMALS != NORMALMAP_NONE
        bool isValidNormal = GetMaterialNormal(atlasCoord, dFdXY, texNormal);

        #if MATERIAL_PARALLAX != PARALLAX_NONE
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

            shadowColor *= 1.2 * pow(skyTexNoL, 0.8);
        #endif
    #endif

    #if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        
        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vLocalPos);
        #endif

        outDeferredColor = color + dither;
        outDeferredShadow = vec4(shadowColor + dither, 0.0);

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
        vec3 albedo = RGBToLinear(color.rgb);
        float roughL = _pow2(roughness);

        vec3 localViewDir = normalize(vLocalPos);

        #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
            vec3 diffuse, specular = vec3(0.0);
            GetVanillaLighting(diffuse, lmcoord, vLocalPos, localNormal, texNormal, shadowColor, sss);

            #if MATERIAL_SPECULAR != SPECULAR_NONE && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                    float geoNoL = dot(localNormal, localSkyLightDirection);
                #else
                    float geoNoL = 1.0;
                #endif

                specular += GetSkySpecular(vLocalPos, geoNoL, texNormal, albedo, shadowColor, lmcoord, metal_f0, roughL);
            #endif

            SampleHandLight(diffuse, specular, vLocalPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

            color.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
        #else
            vec3 blockDiffuse = vec3(0.0);
            vec3 blockSpecular = vec3(0.0);
            vec3 skyDiffuse = vec3(0.0);
            vec3 skySpecular = vec3(0.0);

            blockDiffuse += emission * MaterialEmissionF;

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_LPV
                GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, albedo, lmcoord, roughL, metal_f0, sss);
                SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            #ifdef WORLD_SKY_ENABLED
                #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                        vec3 shadowPos[4];
                    #else
                        vec3 shadowPos;
                    #endif
                #endif

                // #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                //     float shadowFade = getShadowFade(shadowPos[shadowTile]);
                // #else
                //     float shadowFade = getShadowFade(shadowPos);
                // #endif

                GetSkyLightingFinal(skyDiffuse, skySpecular, shadowColor, vLocalPos, localNormal, texNormal, albedo, lmcoord, roughL, metal_f0, occlusion, sss, false);
            #endif

            vec3 diffuseFinal = blockDiffuse + skyDiffuse;
            vec3 specularFinal = blockSpecular + skySpecular;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                if (metal_f0 >= 0.5) {
                    diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                    specularFinal *= albedo;
                }
            #endif

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
        #endif

        #ifdef DH_COMPAT_ENABLED
            color.rgb = LinearToRGB(color.rgb);
        #elif defined SKY_BORDER_FOG_ENABLED
            ApplyFog(color, vLocalPos, localViewDir);
        #endif

        outFinal = color;
    #endif
}
