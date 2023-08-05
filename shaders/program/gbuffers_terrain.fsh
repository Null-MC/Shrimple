#define RENDER_TERRAIN
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
in vec3 vBlockLight;
in vec3 vLocalPos;
in vec2 vLocalCoord;
in vec3 vLocalNormal;
in vec3 vLocalTangent;
flat in int vBlockId;
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

#if MATERIAL_NORMALS == NORMALMAP_OLDPBR || MATERIAL_NORMALS == NORMALMAP_LABPBR || MATERIAL_PARALLAX != PARALLAX_NONE || MATERIAL_OCCLUSION == OCCLUSION_LABPBR
    uniform sampler2D normals;
#endif

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR || MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR || MATERIAL_POROSITY != POROSITY_NONE
    uniform sampler2D specular;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
    uniform sampler2D shadowcolor0;
#endif

#ifdef SHADOW_CLOUD_ENABLED
    uniform sampler2D TEX_CLOUDS;
#endif

#if !defined IRIS_FEATURE_SSBO || DYN_LIGHT_MODE != DYN_LIGHT_TRACED
    uniform sampler2D lightmap;
#endif

#if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
    uniform sampler3D TEX_RIPPLES;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex1HW;
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif
//#else
//    uniform int worldTime;
#endif

uniform ivec2 atlasSize;
uniform int renderStage;

uniform int worldTime;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 upPosition;
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
    uniform vec3 sunPosition;
    uniform float rainStrength;
    uniform float wetness;

    uniform float skyWetnessSmooth;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    //uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
#endif

#if !defined IRIS_FEATURE_SSBO || DYN_LIGHT_MODE != DYN_LIGHT_TRACED
    uniform int frameCounter;

    uniform float blindness;

    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    
    #ifdef IS_IRIS
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

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/anim.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/foliage.glsl"
#include "/lib/world/fog.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#include "/lib/lighting/fresnel.glsl"
#include "/lib/sampling/atlas.glsl"
#include "/lib/utility/tbn.glsl"

#if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
    #include "/lib/material/porosity.glsl"
    #include "/lib/world/wetness.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
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

#include "/lib/material/normalmap.glsl"
#include "/lib/lighting/directional.glsl"

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#ifndef DEFERRED_BUFFER_ENABLED
    #include "/lib/lighting/sampling.glsl"

    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE || (LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0)
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif
#endif

#include "/lib/lights.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/items.glsl"

#include "/lib/material/hcm.glsl"
#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"
#include "/lib/material/specular.glsl"

#if MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#ifndef DEFERRED_BUFFER_ENABLED
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/voxel/sampling.glsl"
    #endif

    #if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
        #include "/lib/buffers/volume.glsl"
        #include "/lib/lighting/voxel/lpv.glsl"
        #include "/lib/lighting/voxel/lpv_render.glsl"
    #endif
    
    #if MATERIAL_REFLECTIONS != REFLECT_NONE
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


#ifdef DEFERRED_BUFFER_ENABLED
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
    float viewDist = length(vPos);
    vec2 atlasCoord = texcoord;
    vec2 localCoord = vLocalCoord;
    vec2 lmFinal = lmcoord;
    
    vec3 localNormal = normalize(vLocalNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    bool skipParallax = false;
    //if (vBlockId == BLOCK_LAVA && localNormal.y < 1.0) skipParallax = true;
    if (vBlockId == BLOCK_LAVA) skipParallax = true;

    float porosity = 0.0;
    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
        float skyWetness = 0.0, puddleF = 0.0;
        vec4 rippleNormalStrength;

        if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT) {
            vec3 worldPos = vLocalPos + cameraPosition;

            float surface_roughness, surface_metal_f0;
            GetMaterialSpecular(vBlockId, texcoord, dFdXY, surface_roughness, surface_metal_f0);

            porosity = GetMaterialPorosity(texcoord, dFdXY, surface_roughness, surface_metal_f0);
            skyWetness = GetSkyWetness(worldPos, localNormal, lmFinal, vBlockId);
            puddleF = GetWetnessPuddleF(skyWetness, porosity);

            #if WORLD_WETNESS_PUDDLES > PUDDLES_BASIC
                rippleNormalStrength = GetWetnessRipples(worldPos, viewDist, puddleF);
                localCoord -= rippleNormalStrength.yx * rippleNormalStrength.w * RIPPLE_STRENGTH;
                if (!skipParallax) atlasCoord = GetAtlasCoord(localCoord);
            #endif
        }
    #endif

    #if MATERIAL_PARALLAX != PARALLAX_NONE
        //bool isMissingNormal = all(lessThan(normalMap.xy, EPSILON2));
        //bool isMissingTangent = any(isnan(vLocalTangent));

        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(tanViewPos);

        if (!skipParallax && viewDist < MATERIAL_PARALLAX_DISTANCE) {
            atlasCoord = GetParallaxCoord(localCoord, dFdXY, tanViewDir, viewDist, texDepth, traceCoordDepth);
        }
    #endif

    vec4 color = textureGrad(gtexture, atlasCoord, dFdXY[0], dFdXY[1]);

    if (color.a < alphaTestRef) {
        discard;
        return;
    }

    color.rgb *= glcolor.rgb;
    color.a = 1.0;

    // if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID) color.rgb = vec3(0.0, 0.0, 1.0);
    // if (renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT) color.rgb = vec3(1.0, 0.0, 0.0);
    // if (renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED) color.rgb = vec3(0.0, 1.0, 0.0);

    // #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
    //     color.rgb = vec3(WHITEWORLD_VALUE);
    // #endif

    //color.rgb = vec3(vLocalCoord, 0.0);

    float occlusion = 1.0;
    float roughness, metal_f0;
    float sss = GetMaterialSSS(vBlockId, atlasCoord, dFdXY);
    float emission = GetMaterialEmission(vBlockId, atlasCoord, dFdXY);
    GetMaterialSpecular(vBlockId, atlasCoord, dFdXY, roughness, metal_f0);

    #ifdef WORLD_AO_ENABLED
        occlusion = RGBToLinear(glcolor.a);
        //occlusion = _pow2(glcolor.a);
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
                shadowColor = GetFinalShadowColor(localSkyLightDirection, sss);
            #else
                float shadowF = GetFinalShadowFactor(localSkyLightDirection, sss);
                shadowColor = vec3(shadowF);
            #endif

            float shadowFade = smoothstep(shadowDistance - 20.0, shadowDistance + 20.0, viewDist);

            //lmFinal.y = (lmFinal.y - (0.5/16.0)) / (15.0/16.0);
            lmFinal.y = mix(lmFinal.y, pow3(lmFinal.y), shadowFade);
            //lmFinal.y = lmFinal.y * (15.0/16.0) + (0.5/16.0);

            if (viewDist < shadowDistance) {
                #ifndef LIGHT_LEAK_FIX
                    float lightF = min(luminance(shadowColor), 1.0) * (1.0 - shadowFade);
                    lmFinal.y = max(lmFinal.y, lightF);
                #endif
            }

            shadowColor = 1.0 - (1.0 - shadowColor) * (1.0 - shadowFade);
        }
    #endif

    vec3 texNormal = vec3(0.0, 0.0, 1.0);
    #if MATERIAL_NORMALS != NORMALMAP_NONE
        if (vBlockId != BLOCK_LAVA)
            GetMaterialNormal(atlasCoord, dFdXY, texNormal);

        #if MATERIAL_PARALLAX != PARALLAX_NONE
            if (!skipParallax) {
                #if MATERIAL_PARALLAX == PARALLAX_SHARP
                    float depthDiff = max(texDepth - traceCoordDepth.z, 0.0);

                    if (depthDiff >= ParallaxSharpThreshold) {
                        texNormal = GetParallaxSlopeNormal(atlasCoord, dFdXY, traceCoordDepth.z, tanViewDir);
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
    #endif

    #if MATERIAL_OCCLUSION == OCCLUSION_LABPBR
        float texOcclusion = textureGrad(normals, atlasCoord, dFdXY[0], dFdXY[1]).b;
        occlusion *= texOcclusion;
    #elif MATERIAL_OCCLUSION == OCCLUSION_DEFAULT
        float texOcclusion = max(texNormal.z, 0.0) * 0.5 + 0.5;
        occlusion *= texOcclusion;
    #endif

    vec3 localTangent = normalize(vLocalTangent);
    mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent);

    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED && WORLD_WETNESS_PUDDLES != PUDDLES_NONE
        if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT) {
            ApplyWetnessPuddles(texNormal, vLocalPos, skyWetness, porosity, puddleF);

            #if WORLD_WETNESS_PUDDLES != PUDDLES_BASIC
                ApplyWetnessRipples(texNormal, rippleNormalStrength);
            #endif
        }
    #endif

    vec3 localViewDir = normalize(vLocalPos);
    texNormal = normalize(matLocalTBN * texNormal);

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        float skyNoL = dot(texNormal, localSkyLightDirection);

        #if MATERIAL_SSS != SSS_NONE
            skyNoL = mix(max(skyNoL, 0.0), abs(skyNoL), sss);
        #else
            skyNoL = max(skyNoL, 0.0);
        #endif

        shadowColor *= 1.2 * pow(skyNoL, 0.8);
    #endif

    #if MATERIAL_NORMALS != NORMALMAP_NONE && (!defined IRIS_FEATURE_SSBO || DYN_LIGHT_MODE == DYN_LIGHT_NONE) && defined DIRECTIONAL_LIGHTMAP
        vec3 texViewNormal = mat3(gbufferModelView) * texNormal;
        ApplyDirectionalLightmap(lmFinal.x, vPos, vNormal, texViewNormal);
    #endif

    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
        ApplySkyWetness(color.rgb, roughness, porosity, skyWetness, puddleF);
    #endif

    #ifdef DEFERRED_BUFFER_ENABLED
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;
        float fogF = GetVanillaFogFactor(vLocalPos);

        // #ifdef DH_COMPAT_ENABLED
        //     float dhFogDist = GetVanillaFogDistance(vLocalPos);
        //     float dhFogF = GetFogFactor(dhFogDist, 0.6 * far, far, 1.0);
        //     color.a *= 1.0 - dhFogF;
        // #endif

        if (!all(lessThan(abs(texNormal), EPSILON3)))
            texNormal = texNormal * 0.5 + 0.5;

        outDeferredColor = color;
        outDeferredShadow = vec4(shadowColor + dither, 1.0);

        uvec4 deferredData;
        deferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss + dither));
        deferredData.g = packUnorm4x8(vec4(lmFinal, occlusion, emission) + dither);
        deferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        deferredData.a = packUnorm4x8(vec4(texNormal, 1.0));
        outDeferredData = deferredData;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outDeferredRough = vec4(roughness, metal_f0, porosity, 1.0) + dither;
        #endif
    #else
        vec3 albedo = RGBToLinear(color.rgb);
        float roughL = _pow2(roughness);
        
        #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
            vec3 diffuse, specular = vec3(0.0);
            GetVanillaLighting(diffuse, lmcoord, vLocalPos, localNormal, shadowColor);

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                specular += GetSkySpecular(vLocalPos, geoNoL, texNormal, albedo, shadowColor, lmcoord, metal_f0, roughL);
            #endif

            SampleHandLight(diffuse, specular, vLocalPos, localNormal, texNormal, albedo, roughL, metal_f0, sss);

            color.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
        #else
            vec3 blockDiffuse = vBlockLight;
            vec3 blockSpecular = vec3(0.0);
            vec3 skyDiffuse = vec3(0.0);
            vec3 skySpecular = vec3(0.0);

            blockDiffuse += emission * MaterialEmissionF;

            //#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_LPV
                GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, albedo, lmFinal, roughL, metal_f0, sss);
                SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, albedo, roughL, metal_f0, sss);
            //#endif

            // #if (!defined IRIS_FEATURE_SSBO || DYN_LIGHT_MODE == DYN_LIGHT_NONE) && !(defined RENDER_CLOUDS || defined RENDER_WEATHER)
            //     SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, albedo, roughL, metal_f0, sss);
            // #endif

            #ifdef WORLD_SKY_ENABLED
                #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
                    const vec3 shadowPos = vec3(0.0);
                #endif

                GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, shadowColor, vLocalPos, localNormal, texNormal, albedo, lmFinal, roughL, metal_f0, occlusion, sss);
            #endif

            vec3 diffuseFinal = blockDiffuse + skyDiffuse;
            vec3 specularFinal = blockSpecular + skySpecular;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                #if MATERIAL_SPECULAR == SPECULAR_LABPBR
                    if (IsMetal(metal_f0))
                        diffuseFinal *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                #else
                    diffuseFinal *= mix(vec3(1.0), albedo, metal_f0 * (1.0 - roughL));
                #endif

                specularFinal *= GetMetalTint(albedo, metal_f0);
            #endif

            color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
        #endif

        #ifdef DH_COMPAT_ENABLED
            float fogDist = GetVanillaFogDistance(vLocalPos);
            float fogF = GetFogFactor(fogDist, 0.6 * far, far, 1.0);
            color.a *= 1.0 - fogF;

            //ApplyPostProcessing(color.rgb);
            color.rgb = LinearToRGB(color.rgb);
        #else
            ApplyFog(color, vLocalPos, localViewDir);
        #endif

        outFinal = color;
    #endif
}
