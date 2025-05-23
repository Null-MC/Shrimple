#define RENDER_BLOCK
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

    #ifdef PARALLAX_ENABLED
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

    #if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D noisetex;

#if LIGHTING_MODE == LIGHTING_MODE_NONE
    uniform sampler2D lightmap;
#endif

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform sampler3D texClouds;

    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        uniform sampler2D texSkyIrradiance;
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE && !defined DEFERRED_BUFFER_ENABLED
        uniform sampler2D texSky;
    #endif
#endif

#if MATERIAL_NORMALS != NORMALMAP_NONE || defined PARALLAX_ENABLED
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR || MATERIAL_POROSITY != 0 || MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR
    uniform sampler2D specular;
#endif

#ifdef WORLD_SKY_ENABLED
    #ifdef WORLD_WETNESS_ENABLED
        uniform sampler3D TEX_RIPPLES;
    #endif

    // #ifdef SHADOW_CLOUD_ENABLED
    //     #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
    //         uniform sampler3D TEX_CLOUDS;
    //     #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
    //         uniform sampler2D TEX_CLOUDS_VANILLA;
    //     #endif
    // #endif
#endif

#if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || (defined IRIS_FEATURE_SSBO && LIGHTING_MODE > LIGHTING_MODE_BASIC)
    uniform sampler2D shadowcolor0;
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
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

uniform ivec2 atlasSize;

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform int isEyeInWater;
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

uniform int blockEntityId;
uniform ivec2 eyeBrightnessSmooth;

#ifdef WORLD_SKY_ENABLED
    uniform float sunAngle;
    uniform float rainStrength;
    uniform float weatherStrength;
    uniform float weatherPuddleStrength;
    uniform float skyWetnessSmooth;
    uniform float wetness;
    uniform int moonPhase;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
    uniform vec3 shadowLightPosition;

    #ifdef SHADOW_ENABLED
        uniform mat4 shadowProjection;
    #endif
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    // uniform float near;
#endif

#ifndef DEFERRED_BUFFER_ENABLED
    #ifdef WORLD_SKY_ENABLED
        uniform vec3 sunPosition;

        uniform float cloudTime;
        uniform float cloudHeight;
        //uniform float lightningStrength;
    #endif

    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 playerBodyVector;
    uniform vec3 relativeEyePosition;
    uniform vec3 eyePosition;

    uniform float blindnessSmooth;
#endif

#ifdef DISTANT_HORIZONS
    uniform float farPlane;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

// #if AF_SAMPLES > 1
//     uniform float viewWidth;
//     uniform float viewHeight;
//     uniform vec4 spriteBounds;
// #endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
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
#include "/lib/items.glsl"
#include "/lib/lights.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/erp.glsl"
#include "/lib/sampling/atlas.glsl"

#include "/lib/utility/hsv.glsl"
#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/blackbody.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/common.glsl"
#include "/lib/fog/fog_common.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"

    #ifdef WORLD_WETNESS_ENABLED
        #include "/lib/material/porosity.glsl"
        #include "/lib/world/wetness.glsl"
        #include "/lib/world/wetness_ripples.glsl"
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

#if SKY_TYPE == SKY_TYPE_CUSTOM
    #include "/lib/fog/fog_custom.glsl"
    
    #ifdef WORLD_WATER_ENABLED
        #include "/lib/fog/fog_water_custom.glsl"
    #endif
#elif SKY_TYPE == SKY_TYPE_VANILLA
    #include "/lib/fog/fog_vanilla.glsl"
#endif

#include "/lib/fog/fog_render.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE || defined PARALLAX_ENABLED
    #include "/lib/utility/tbn.glsl"
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
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

#ifdef PARALLAX_ENABLED
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#ifdef LIGHTING_FLICKER
    #include "/lib/lighting/flicker.glsl"
    // #include "/lib/lighting/blackbody.glsl"
#endif

#if !defined DEFERRED_BUFFER_ENABLED && defined IRIS_FEATURE_SSBO
    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/voxel/voxel_common.glsl"
    #endif

    #if defined IS_LPV_ENABLED || defined IS_TRACING_ENABLED
        #include "/lib/voxel/lights/mask.glsl"
        // #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/voxel/blocks.glsl"
    #endif

    #if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        #include "/lib/lighting/voxel/tinting.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif
#endif

#include "/lib/lighting/voxel/lights_render.glsl"

#ifndef DEFERRED_BUFFER_ENABLED
    #ifdef WORLD_SKY_ENABLED
        #include "/lib/clouds/cloud_common.glsl"
        #include "/lib/world/lightning.glsl"

        // #if defined SHADOW_CLOUD_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
        //     #include "/lib/clouds/cloud_custom.glsl"
        // #endif
    #endif

    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/items.glsl"
#endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/fresnel.glsl"
#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"
#include "/lib/material/specular.glsl"

#ifndef DEFERRED_BUFFER_ENABLED
    #include "/lib/lighting/sampling.glsl"
    #include "/lib/lighting/scatter_transmit.glsl"

    // #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
    //     #include "/lib/lighting/voxel/sampling.glsl"
    // #endif

    #ifdef IS_LPV_ENABLED
        #include "/lib/buffers/volume.glsl"

        #include "/lib/voxel/lpv/lpv.glsl"
        #include "/lib/voxel/lpv/lpv_render.glsl"
    #endif

    #if MATERIAL_REFLECTIONS != REFLECT_NONE
        #if defined(WORLD_SKY_ENABLED) && defined(MATERIAL_REFLECT_CLOUDS)
            #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
                #include "/lib/clouds/cloud_custom.glsl"
            #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
                #include "/lib/clouds/cloud_vanilla.glsl"
            #endif
        #endif

        #include "/lib/lighting/reflections.glsl"
    #endif

    #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/sky/irradiance.glsl"
        #include "/lib/sky/sky_lighting.glsl"
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


#ifdef DEFERRED_BUFFER_ENABLED
    layout(location = 0) out vec4 outDeferredColor;
    layout(location = 1) out uvec4 outDeferredData;
    layout(location = 2) out vec3 outDeferredTexNormal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 1,3,9,7 */
        layout(location = 3) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 1,3,9 */
    #endif
#else
    layout(location = 0) out vec4 outFinal;
    layout(location = 1) out vec3 outDeferredTexNormal;

    #ifdef EFFECT_TAA_ENABLED
        /* RENDERTARGETS: 0,9,7 */
        layout(location = 2) out vec4 outVelocity;
    #else
        /* RENDERTARGETS: 0,9 */
    #endif
#endif

void main() {
    float viewDist = length(vIn.localPos);
    vec2 localCoord = vIn.localCoord;
    vec2 atlasCoord = vIn.texcoord;

    float mip = textureQueryLod(gtexture, atlasCoord).y;

    vec3 localNormal = normalize(vIn.localNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    #ifdef DISTANT_HORIZONS
        float dhDepth = texelFetch(dhDepthTex, ivec2(gl_FragCoord.xy), 0).r;
        float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);
        float depthL = linearizeDepthFast(gl_FragCoord.z, near, farPlane);
        if (depthL > dhDepthL && dhDepth < 1.0) {discard; return;}
    #endif

    float porosity = 0.0;

    #ifdef PARALLAX_ENABLED
        // bool skipParallax = any(lessThan(vIn.atlasBounds[1], vec2(1.0)));

        bool a = any(isnan(vIn.atlasBounds[0])) || any(isinf(vIn.atlasBounds[0]))
            || any(isnan(vIn.atlasBounds[1])) || any(isinf(vIn.atlasBounds[1]));
        
        bool b = any(lessThan(vIn.atlasBounds[1], vec2(1.0e-8)))
            || any(greaterThan(vIn.atlasBounds[1], vec2(1.0)));

        bool skipParallax = a || b;

        // bool skipParallax = any(greaterThan(vIn.atlasBounds[1], vec2(1.0)));
    #else
        const bool skipParallax = true;
    #endif
    // #if (defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED) || defined PARALLAX_ENABLED
    //     vec4 preN = textureLod(normals, atlasCoord, mip);
    //     if (all(lessThan(atlasBounds[1], vec2(1.0/atlasSize)))) skipParallax = true;
    //     if (all(lessThan(abs(vLocalNormal), vec3(0.1)))) skipParallax = true;
    //     skipParallax = true;
    // #endif

    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
        float skyWetness = 0.0, puddleF = 0.0;
        // vec4 rippleNormalStrength;

        if (!skipParallax) {
        //if (blockEntityId == BLOCK_CREATE_TRACK) {
            vec3 worldPos = vIn.localPos + cameraPosition;

            float surface_roughness, surface_metal_f0;
            GetMaterialSpecular(blockEntityId, vIn.texcoord, mip, surface_roughness, surface_metal_f0);

            porosity = GetMaterialPorosity(vIn.texcoord, mip, surface_roughness, surface_metal_f0);
            skyWetness = GetSkyWetness(worldPos, localNormal, vIn.lmcoord);//, blockEntityId);
            puddleF = GetWetnessPuddleF(skyWetness, porosity);

            // #if WORLD_WETNESS_PUDDLES > PUDDLES_BASIC
            //     rippleNormalStrength = GetWetnessRipples(worldPos, viewDist, puddleF);

            //     localCoord -= rippleNormalStrength.yx * rippleNormalStrength.w * RIPPLE_STRENGTH;
            //     //if (!skipParallax) atlasCoord = GetAtlasCoord(localCoord);
            //     atlasCoord = GetAtlasCoord(localCoord, vIn.atlasBounds);
            // #endif
        //}
        }
    #endif

    #ifdef PARALLAX_ENABLED
        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(vIn.viewPos_T);

        if (!skipParallax && viewDist < MATERIAL_DISPLACE_MAX_DIST) {
            atlasCoord = GetParallaxCoord(vIn.localCoord, mip, tanViewDir, viewDist, texDepth, traceCoordDepth);
        }
    #endif

    vec4 color = textureLod(gtexture, atlasCoord, mip);

    #ifdef RENDER_TRANSLUCENT
        const float alphaThreshold = (1.5/255.0);
    #else
        float alphaThreshold = alphaTestRef;
    #endif

    if (color.a < alphaThreshold) {
        discard;
        return;
    }

    color.rgb *= vIn.color.rgb;

    #ifndef RENDER_TRANSLUCENT
        color.a = 1.0;
    #endif

    float occlusion = 1.0;
    #if defined WORLD_AO_ENABLED //&& !defined EFFECT_SSAO_ENABLED
        //occlusion = RGBToLinear(glcolor.a);
        occlusion = vIn.color.a;
    #endif

    float roughness, metal_f0;
    float sss = GetMaterialSSS(blockEntityId, atlasCoord, mip);
    float emission = GetMaterialEmission(blockEntityId, atlasCoord, mip);
    GetMaterialSpecular(blockEntityId, atlasCoord, mip, roughness, metal_f0);
    
    vec3 albedo = RGBToLinear(color.rgb);
    vec3 texNormal = localNormal;
    bool isValidNormal = false;
    float parallaxShadow = 1.0;

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        isValidNormal = GetMaterialNormal(atlasCoord, mip, texNormal);

        #ifdef PARALLAX_ENABLED
            #if DISPLACE_MODE == DISPLACE_POM_SHARP
                float depthDiff = max(texDepth - traceCoordDepth.z, 0.0);

                if (depthDiff >= ParallaxSharpThreshold) {
                    texNormal = GetParallaxSlopeNormal(atlasCoord, mip, traceCoordDepth.z, tanViewDir);
                    isValidNormal = true;
                }
            #endif

            #if defined WORLD_SKY_ENABLED && MATERIAL_PARALLAX_SHADOW_SAMPLES > 0
                if (traceCoordDepth.z + EPSILON < 1.0) {
                    vec3 tanLightDir = normalize(vIn.lightPos_T);
                    parallaxShadow = GetParallaxShadow(traceCoordDepth, mip, tanLightDir);
                }
            #endif
        #endif

        if (isValidNormal) {
            #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
                //if (blockEntityId == BLOCK_CREATE_TRACK) {
                    #if WORLD_WETNESS_PUDDLES != PUDDLES_NONE
                        ApplyWetnessPuddles(texNormal, vIn.localPos, skyWetness, porosity, puddleF);

                        // #if WORLD_WETNESS_PUDDLES != PUDDLES_BASIC
                        //     ApplyWetnessRipples(texNormal, rippleNormalStrength);
                        // #endif
                    #endif

                    ApplySkyWetness(albedo, roughness, porosity, skyWetness, puddleF);
                //}
            #endif

            vec3 localTangent = normalize(vIn.localTangent.xyz);
            mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent, vIn.localTangent.w);
            texNormal = matLocalTBN * texNormal;
        }
    #endif

    // #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    //     float skyTexNoL = 1.0;

    //     if (isValidNormal) {
    //         skyTexNoL = dot(texNormal, localSkyLightDirection);
    //     }

    //     #if MATERIAL_SSS != SSS_NONE
    //         skyTexNoL = mix(max(skyTexNoL, 0.0), abs(skyTexNoL), sss);
    //     #else
    //         skyTexNoL = max(skyTexNoL, 0.0);
    //     #endif

    //     shadowColor *= 1.2 * pow(skyTexNoL, 0.8);
    // #endif
    
    outDeferredTexNormal = texNormal * 0.5 + 0.5;

    // albedo.rgb = vec3(1.0, 0.0, 0.0);

    #if defined LIGHTING_FULLBRIGHT_FIX && LIGHTING_MODE >= LIGHTING_MODE_FLOODFILL
        if (vIn.lmcoord.x > 0.999)
            emission = 0.04;
    #endif

    #ifdef DEFERRED_BUFFER_ENABLED
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        const float isWater = 0.0;

        color.rgb = LinearToRGB(albedo);
        outDeferredColor = color + dither;

        outDeferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss + dither));
        outDeferredData.g = packUnorm4x8(vec4(vIn.lmcoord, occlusion, emission) + dither);
        outDeferredData.b = packUnorm4x8(vec4(isWater, parallaxShadow, 0.0, 0.0) + dither);
        outDeferredData.a = packUnorm4x8(vec4(roughness + dither, metal_f0 + dither, 0.0, 1.0));
    #else
        float roughL = _pow2(roughness);
        
        vec3 localViewDir = normalize(vIn.localPos);
        
        vec3 shadowColor = vec3(1.0);
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
                    float shadowF = GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss);
                    shadowColor = vec3(shadowF);
                #endif
            }
        #endif

        vec3 diffuseFinal = vec3(0.0);
        vec3 specularFinal = vec3(0.0);

        #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
            GetFloodfillLighting(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, vIn.lmcoord, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);

            diffuseFinal += emission * MaterialEmissionF;
        #elif LIGHTING_MODE < LIGHTING_MODE_FLOODFILL
            GetVanillaLighting(diffuseFinal, vIn.lmcoord, shadowColor, occlusion);
        #endif

        #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
        #endif

        #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
            const bool tir = false;
            const bool isUnderWater = false;
            GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, localNormal, texNormal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, isUnderWater, tir);
        #else
            diffuseFinal += WorldAmbientF;
        #endif
        
        #if MATERIAL_SPECULAR != SPECULAR_NONE && LIGHTING_MODE != LIGHTING_MODE_NONE
            ApplyMetalDarkening(diffuseFinal, specularFinal, albedo, metal_f0, roughL);
        #endif

        #if LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
        #elif LIGHTING_MODE < LIGHTING_MODE_FLOODFILL
            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
        #endif

        #ifdef SKY_BORDER_FOG_ENABLED
            ApplyFog(color, vIn.localPos, localViewDir);
        #endif

        #ifdef VL_BUFFER_ENABLED
            #ifndef IRIS_FEATURE_SSBO
                vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            #endif

            float farMax = min(viewDist - 0.05, far);
            vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, farMax);
            color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        #endif

        outFinal = color;
    #endif

    #ifdef EFFECT_TAA_ENABLED
        outVelocity = vec4(0.0);
    #endif
}
