#define RENDER_ENTITIES
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat mat2 atlasBounds;

    #if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

    // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
    //     vec3 cloudPos;
    // #endif

    #if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#if MATERIAL_NORMALS != NORMALMAP_NONE || defined PARALLAX_ENABLED
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR || MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR
    uniform sampler2D specular;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if defined WORLD_SKY_ENABLED && defined SHADOW_CLOUD_ENABLED
    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS_VANILLA;
    #endif
#endif

#ifdef RENDER_SHADOWS_ENABLED
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

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

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
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
uniform ivec2 atlasSize;

uniform ivec2 eyeBrightnessSmooth;

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

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || LIGHTING_MODE > LIGHTING_MODE_BASIC
    uniform sampler2D shadowcolor0;
#endif

#ifdef RENDER_SHADOWS_ENABLED
    uniform mat4 shadowProjection;
#endif

#ifdef IS_IRIS
    uniform int currentRenderedItemId;
    
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhFarPlane;
#endif

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    #ifdef WORLD_SKY_ENABLED
        uniform vec3 sunPosition;
        uniform vec3 shadowLightPosition;

        #ifdef IS_IRIS
            uniform float cloudTime;
            uniform float cloudHeight;
            uniform float lightningStrength;
        #endif
    #endif

    #ifdef VL_BUFFER_ENABLED
        uniform mat4 shadowModelView;
    #endif

    uniform float blindnessSmooth;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/light_static.glsl"

    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/entities.glsl"
#include "/lib/items.glsl"
#include "/lib/lights.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/lighting/hg.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#include "/lib/fog/fog_render.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE || defined PARALLAX_ENABLED
    #include "/lib/utility/tbn.glsl"
    #include "/lib/sampling/atlas.glsl"
#endif

#if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
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

#include "/lib/physics_mod/snow.glsl"

#ifdef LIGHTING_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

// #if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
#ifndef DEFERRED_BUFFER_ENABLED
    #ifdef WORLD_SKY_ENABLED
        #include "/lib/clouds/cloud_common.glsl"
        #include "/lib/world/lightning.glsl"

        #if defined SHADOW_CLOUD_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
            #include "/lib/clouds/cloud_custom.glsl"
        #endif
    #endif

    #include "/lib/lighting/fresnel.glsl"

    #ifdef IS_LPV_ENABLED
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        #include "/lib/lighting/voxel/tinting.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif
#endif

#include "/lib/lighting/voxel/item_light_map.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"
#include "/lib/lighting/voxel/entities.glsl"
#include "/lib/lighting/voxel/items.glsl"

#if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/fresnel.glsl"
#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"
#include "/lib/material/specular.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE
    #include "/lib/material/normalmap.glsl"
#endif

// #if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
#ifndef DEFERRED_BUFFER_ENABLED
    #include "/lib/lighting/sampling.glsl"
    #include "/lib/lighting/scatter_transmit.glsl"

    // #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
    //     #include "/lib/lighting/voxel/sampling.glsl"
    // #endif

    #ifdef IS_LPV_ENABLED
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"
        
        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_render.glsl"
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        #include "/lib/lighting/reflections.glsl"
    #endif

    #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/lighting/sky_lighting.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/traced.glsl"
    #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        #include "/lib/lighting/floodfill.glsl"
    #else
        #include "/lib/lighting/vanilla.glsl"
    #endif

    #include "/lib/lighting/basic_hand.glsl"

    #ifdef VL_BUFFER_ENABLED
        #include "/lib/lighting/hg.glsl"
        #include "/lib/fog/fog_volume.glsl"
    #endif
#endif


#if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out vec4 outDeferredShadow;
    layout(location = 2) out uvec4 outDeferredData;
    layout(location = 3) out vec4 outDeferredTexNormal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 1,2,3,9,7 */
        layout(location = 4) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 1,2,3,9 */
    #endif
#else
    layout(location = 0) out vec4 outFinal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 0,7 */
        layout(location = 1) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 0 */
    #endif
#endif

void main() {
    mat2 dFdXY = mat2(dFdx(vIn.texcoord), dFdy(vIn.texcoord));
    vec2 atlasCoord = vIn.texcoord;

    #if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(vIn.viewPos_T);

        bool skipParallax = false;
        vec4 preN = textureGrad(normals, atlasCoord, dFdXY[0], dFdXY[1]);
        if (preN.a < EPSILON) skipParallax = true;

        if (entityId == ENTITY_SHADOW) skipParallax = true;
    #endif

    float viewDist = length(vIn.localPos);

    vec4 color = vec4(0.0);
    if (entityId == ENTITY_PHYSICSMOD_SNOW) {
        color.rgb = GetSnowColor(vIn.localPos + cameraPosition) * vIn.color.rgb;
        color.a = 1.0;
    }
    // else if (entityId == ENTITY_LIGHTNING_BOLT) {
    //     color = vec4(1.0, 0.0, 0.0, 1.0);
    // }
    // else if (entityId == ENTITY_SHADOW) {
    //     color = vec4(1.0, 0.0, 0.0, 1.0);
    // }
    else {
        #if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
            if (!skipParallax && viewDist < MATERIAL_DISPLACE_MAX_DIST) {
                atlasCoord = GetParallaxCoord(vIn.localCoord, dFdXY, tanViewDir, viewDist, texDepth, traceCoordDepth);
            }

        #endif

        color = textureGrad(gtexture, atlasCoord, dFdXY[0], dFdXY[1]);

        #ifdef RENDER_TRANSLUCENT
            float alphaThreshold = (1.5/255.0);
        #elif defined ALPHATESTREF_ENABLED
            float alphaThreshold = alphaTestRef;
        #else
            const float alphaThreshold = 0.1;
        #endif

        //if (entityId == ENTITY_BOAT) alphaThreshold = -1.0;

        // if (entityId == ENTITY_BOAT) color = vec4(1.0, 0.0, 0.0, 1.0);
        if (color.a <= alphaThreshold && entityId != ENTITY_BOAT) {
            discard;
            return;
        }

        // #ifndef RENDER_TRANSLUCENT
        //     color.a = 1.0;
        // #endif

        color *= vIn.color;
        color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
    }

    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        color.rgb = vec3(WHITEWORLD_VALUE);
    #endif

    vec3 localNormal = normalize(vIn.localNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    vec3 localViewDir = normalize(vIn.localPos);

    // int materialId = entityId;
    // if (currentRenderedItemId > 0) {
    //     materialId = currentRenderedItemId;
    //     //color.rgb = vec3(1.0, 0.0, 0.0);
    // }

    vec2 lmFinal = vIn.lmcoord;
    float roughness, metal_f0, sss, emission;
    sss = GetMaterialSSS(entityId, atlasCoord, dFdXY);
    emission = GetMaterialEmission(entityId, atlasCoord, dFdXY);
    GetMaterialSpecular(-1, atlasCoord, dFdXY, roughness, metal_f0);
    vec3 shadowColor = vec3(1.0);

    float occlusion = 1.0;
    #if defined WORLD_AO_ENABLED //&& !defined EFFECT_SSAO_ENABLED
        occlusion = _pow2(vIn.color.a);
    #endif

    #if defined RENDER_TRANSLUCENT && defined TRANSLUCENT_SSS_ENABLED
        sss = max(sss, 1.0 - color.a);
    #endif

    #if defined RENDER_ENTITIES_GLOWING && LIGHTING_MODE > LIGHTING_MODE_BASIC
        emission = 1.0;
        //color.rgb = vec3(1.0, 0.0, 0.0);
    #endif

    if (entityId == ENTITY_LIGHTNING_BOLT) {
        roughness = 1.0;
        metal_f0 = 0.0;
        emission = 1.0;
    }
    else if (entityId == ENTITY_SHADOW) {
        shadowColor = vec3(0.0);
        occlusion = 0.0;
    }

    #if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
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

            #ifndef LIGHT_LEAK_FIX
                float lightF = min(luminance(shadowColor), 1.0);
                lmFinal.y = clamp(lmFinal.y, lightF, 1.0);
            #endif
        }
    #endif

    vec3 texNormal = localNormal;
    #if MATERIAL_NORMALS != NORMALMAP_NONE
        bool isValidNormal = false;

        if (entityId != ENTITY_PHYSICSMOD_SNOW)
            isValidNormal = GetMaterialNormal(atlasCoord, dFdXY, texNormal);

        #if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
            if (!skipParallax) {
                #if DISPLACE_MODE == DISPLACE_POM_SHARP
                    float depthDiff = max(texDepth - traceCoordDepth.z, 0.0);

                    if (depthDiff >= ParallaxSharpThreshold) {
                        texNormal = GetParallaxSlopeNormal(atlasCoord, dFdXY, traceCoordDepth.z, tanViewDir);
                        isValidNormal = true;
                    }
                #endif

                #if defined WORLD_SKY_ENABLED && MATERIAL_PARALLAX_SHADOW_SAMPLES > 0
                    if (traceCoordDepth.z + EPSILON < 1.0) {
                        vec3 tanLightDir = normalize(vIn.lightPos_T);
                        shadowColor *= GetParallaxShadow(traceCoordDepth, dFdXY, tanLightDir);
                    }
                #endif
            }
        #endif

        if (isValidNormal) {
            vec3 localTangent = normalize(vIn.localTangent.xyz);
            mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent, vIn.localTangent.w);
            // texNormal = matLocalTBN * texNormal;

            vec3 newNormal = matLocalTBN * texNormal;

            if (any(greaterThan(abs(newNormal), EPSILON3)))
                texNormal = newNormal;
            else
                isValidNormal = false;
        }

        // fallback for PhysicsMod making invalid breaking particle normals
        if (!isValidNormal) texNormal = localNormal;

        // #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        //     float skyTexNoL = dot(texNormal, localSkyLightDirection);

        //     #if MATERIAL_SSS != SSS_NONE
        //         skyTexNoL = mix(max(skyTexNoL, 0.0), abs(skyTexNoL), sss);
        //     #else
        //         skyTexNoL = max(skyTexNoL, 0.0);
        //     #endif

        //     shadowColor *= 1.2 * pow(max(skyTexNoL, 0.0), 0.8);
        // #endif
    #endif

    #if MATERIAL_OCCLUSION == OCCLUSION_LABPBR
        float texOcclusion = textureGrad(normals, atlasCoord, dFdXY[0], dFdXY[1]).b;
        occlusion *= texOcclusion;
    #elif MATERIAL_OCCLUSION == OCCLUSION_DEFAULT
        float texOcclusion = max(texNormal.z, 0.0) * 0.5 + 0.5;
        occlusion *= texOcclusion;
    #endif

    #if LIGHTING_MODE != LIGHTING_MODE_NONE && defined RENDER_SHADOWS_ENABLED
        occlusion = max(occlusion, luminance(shadowColor));
    #endif

    #if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        
        float fogF = 0.0;
        #if SKY_TYPE == SKY_TYPE_VANILLA && defined SKY_BORDER_FOG_ENABLED
            fogF = GetVanillaFogFactor(vIn.localPos);
        #endif

        #ifndef RENDER_TRANSLUCENT
            color.a = 1.0;
        #endif

        outDeferredColor = color + dither;
        outDeferredShadow = vec4(shadowColor + dither, 0.0);
        outDeferredTexNormal = vec4(texNormal * 0.5 + 0.5, 1.0);

        outDeferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(lmFinal, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        outDeferredData.a = packUnorm4x8(vec4(roughness + dither, metal_f0 + dither, 0.0, 1.0));

        #ifdef EFFECT_TAA_ENABLED
            outVelocity = vec4(vec3(0.0), 1.0);
        #endif
    #else
        vec3 albedo = RGBToLinear(color.rgb);
        float roughL = _pow2(roughness);

        vec3 diffuseFinal = vec3(0.0), specularFinal = vec3(0.0);
        #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
            GetFloodfillLighting(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, lmFinal, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);

            #ifdef WORLD_SKY_ENABLED
                const bool tir = false; // TODO: ?
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, localNormal, texNormal, albedo, lmFinal, roughL, metal_f0, occlusion, sss, tir);
            #else
                diffuseFinal += WorldAmbientF;
            #endif

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                if (metal_f0 >= 0.5) {
                    diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                    specularFinal *= albedo;
                }
            #endif

            diffuseFinal += emission * MaterialEmissionF;

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
        #elif LIGHTING_MODE < LIGHTING_MODE_FLOODFILL
            GetVanillaLighting(diffuseFinal, lmFinal);

            #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
                GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, localNormal, texNormal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, false);
            #endif

            #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
                SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
        #endif

        #ifdef SKY_BORDER_FOG_ENABLED
            ApplyFog(color, vIn.localPos, localViewDir);
        #endif

        // #ifdef VL_BUFFER_ENABLED
        //     #ifndef IRIS_FEATURE_SSBO
        //         vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
        //     #endif

        //     float farMax = min(viewDist - 0.05, far);
        //     vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, farMax);
        //     color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        // #endif

        outFinal = color;

        #ifdef EFFECT_TAA_ENABLED
            outVelocity = vec4(vec3(0.0), 1.0);
        #endif
    #endif
}
