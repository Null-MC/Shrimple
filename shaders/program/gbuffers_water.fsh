#define RENDER_WATER
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
in vec3 vLocalNormal;
in vec3 vLocalTangent;
in vec3 vBlockLight;
in float vTangentW;
flat in int vBlockId;

#if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
    in vec3 physics_localPosition;
    in float physics_localWaviness;
#endif

in vec2 vLocalCoord;
flat in mat2 atlasBounds;

#if MATERIAL_PARALLAX != PARALLAX_NONE || defined WORLD_WATER_ENABLED
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

#if MATERIAL_EMISSION != EMISSION_NONE || MATERIAL_SSS == SSS_LABPBR || MATERIAL_SPECULAR == SPECULAR_OLDPBR || MATERIAL_SPECULAR == SPECULAR_LABPBR || MATERIAL_POROSITY != POROSITY_NONE
    uniform sampler2D specular;
#endif

#if defined IRIS_FEATURE_SSBO && VOLUMETRIC_BLOCK_MODE == VOLUMETRIC_BLOCK_EMIT
    uniform sampler3D texLPV;
#endif

#if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
    uniform sampler3D TEX_RIPPLES;
#endif

#if (defined WORLD_SHADOW_ENABLED && SHADOW_COLORS == 1) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler2D shadowcolor0;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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

uniform ivec2 atlasSize;

uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform int isEyeInWater;
uniform vec3 skyColor;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform float blindness;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform float rainStrength;
    uniform float wetness;

    uniform float skyWetnessSmooth;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#else
    uniform int worldTime;
#endif

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    uniform ivec2 eyeBrightnessSmooth;
    uniform float near;
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

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/atlas.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/foliage.glsl"
#include "/lib/world/fog.glsl"
#include "/lib/utility/tbn.glsl"

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
    #include "/lib/material/porosity.glsl"
    #include "/lib/world/wetness.glsl"
#endif

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
        #include "/lib/shadows/cascaded_render.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/basic.glsl"
        #include "/lib/shadows/basic_render.glsl"
    #endif
    
    #include "/lib/shadows/common_render.glsl"
#endif

#include "/lib/lighting/fresnel.glsl"

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        //#include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/buffers/collissions.glsl"
        #include "/lib/lighting/voxel/collisions.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif
#endif

#include "/lib/lighting/directional.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/items.glsl"
#include "/lib/lighting/sampling.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/lighting/sky.glsl"
#endif

#if MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#include "/lib/material/emission.glsl"
#include "/lib/material/normalmap.glsl"
#include "/lib/material/specular.glsl"
#include "/lib/material/subsurface.glsl"

#ifdef WORLD_WATER_ENABLED
    #ifdef PHYSICS_OCEAN
        #include "/lib/physics_mod/ocean.glsl"
    #elif WORLD_WATER_WAVES != WATER_WAVES_NONE
        #include "/lib/world/water.glsl"
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED)
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"
#include "/lib/lighting/basic.glsl"

#ifdef VL_BUFFER_ENABLED
    #include "/lib/world/volumetric_fog.glsl"
#endif

#include "/lib/post/saturation.glsl"
#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;


void main() {
    mat2 dFdXY = mat2(dFdx(texcoord), dFdy(texcoord));
    vec3 worldPos = vLocalPos + cameraPosition;
    vec3 texNormal = vec3(0.0, 0.0, 1.0);
    float viewDist = length(vPos);
    vec2 atlasCoord = texcoord;
    vec2 localCoord = vLocalCoord;
    bool skipParallax = false;
    vec2 waterUvOffset = vec2(0.0);
    vec2 lmFinal = lmcoord;

    #if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
        if (vBlockId == BLOCK_WATER) {
            if (!gl_FrontFacing && isEyeInWater != 1) {
                discard;
                return;
            }
        }
    #endif

    vec3 localNormal = normalize(vLocalNormal);
    if (!gl_FrontFacing) localNormal = -localNormal;

    #ifdef WORLD_WATER_ENABLED
        float oceanFoam = 0.0;

        if (vBlockId == BLOCK_WATER) {
            skipParallax = true;

            #ifdef PHYSICS_OCEAN
                float waviness = max(physics_localWaviness, 0.02);
                WavePixelData wave = physics_wavePixel(physics_localPosition.xz, waviness, physics_iterationsNormal, physics_gameTime);
                waterUvOffset = wave.worldPos - physics_localPosition.xz;
                texNormal = wave.normal;
                oceanFoam = wave.foam;
            #elif WORLD_WATER_WAVES != WATER_WAVES_NONE
                float skyLight = saturate((lmFinal.y - (0.5/16.0)) / (15.0/16.0));
                texNormal = water_waveNormal(worldPos.xz, skyLight, waterUvOffset);
            #endif

            #if defined PHYSICS_OCEAN || WORLD_WATER_WAVES == WATER_WAVES_FANCY
                localCoord += waterUvOffset;
                atlasCoord = GetAtlasCoord(localCoord);
            #endif
        }
    #endif

    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
        //vec3 worldPos = vLocalPos + cameraPosition;

        float surface_roughness, surface_metal_f0;
        GetMaterialSpecular(vBlockId, texcoord, dFdXY, surface_roughness, surface_metal_f0);

        float porosity = GetMaterialPorosity(texcoord, dFdXY, surface_roughness, surface_metal_f0);
        float skyWetness = GetSkyWetness(worldPos, localNormal, lmFinal);
        float puddleF = GetWetnessPuddleF(skyWetness, porosity);

        #if WORLD_WETNESS_PUDDLES > PUDDLES_BASIC
            vec4 rippleNormalStrength = GetWetnessRipples(worldPos, viewDist, puddleF);
            localCoord += rippleNormalStrength.yx * rippleNormalStrength.w * RIPPLE_STRENGTH;
            atlasCoord = GetAtlasCoord(localCoord);
        #endif
    #endif

    #if MATERIAL_PARALLAX != PARALLAX_NONE
        //bool isMissingNormal = all(lessThan(normalMap.xy, EPSILON2));
        //bool isMissingTangent = any(isnan(vLocalTangent));

        if (vBlockId == BLOCK_LAVA) skipParallax = true;

        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(tanViewPos);

        if (!skipParallax && viewDist < MATERIAL_PARALLAX_DISTANCE) {
            atlasCoord = GetParallaxCoord(localCoord, dFdXY, tanViewDir, viewDist, texDepth, traceCoordDepth);
        }
    #endif

    vec4 color = textureGrad(gtexture, atlasCoord, dFdXY[0], dFdXY[1]);

    color.rgb = RGBToLinear(color.rgb * glcolor.rgb);

    #ifdef WORLD_WATER_ENABLED
        if (vBlockId == BLOCK_WATER)
            color.rgb = mix(color.rgb, vec3(1.0), oceanFoam);
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        color.rgb = vec3(WHITEWORLD_VALUE);
    #endif

    float occlusion = 1.0;
    #ifdef WORLD_AO_ENABLED
        occlusion = RGBToLinear(glcolor.a);
    #endif

    vec3 localViewDir = normalize(vLocalPos);

    float roughness, metal_f0;
    float sss = GetMaterialSSS(vBlockId, atlasCoord, dFdXY);
    float emission = GetMaterialEmission(vBlockId, atlasCoord, dFdXY);
    GetMaterialSpecular(vBlockId, atlasCoord, dFdXY, roughness, metal_f0);

    #ifdef TRANSLUCENT_SSS_ENABLED
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
            #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
                shadowColor = GetFinalShadowColor(sss);
            #else
                shadowColor = vec3(GetFinalShadowFactor(sss));
            #endif
        }
    #endif

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        if (vBlockId != BLOCK_WATER)
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

    #ifdef WORLD_WATER_ENABLED
        if (vBlockId == BLOCK_WATER) {
            roughness = 0.08;
            metal_f0 = 0.02;
        }
    #endif

    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
        //float porosity = GetMaterialPorosity(atlasCoord, dFdXY, roughness, metal_f0);
        //float skyWetness = GetSkyWetness(worldPos, localNormal, lmFinal);
        //float puddleF = GetWetnessPuddleF(skyWetness, porosity);

        #if WORLD_WETNESS_PUDDLES != PUDDLES_NONE
            if (vBlockId != BLOCK_WATER)
                ApplyWetnessPuddles(texNormal, vLocalPos, skyWetness, porosity, puddleF);

            #if WORLD_WETNESS_PUDDLES != PUDDLES_BASIC
                //vec3 waterWorldPos = worldPos;
                //waterWorldPos.xz += waterUvOffset;
                ApplyWetnessRipples(texNormal, rippleNormalStrength);
            #endif
        #endif
    #endif

    vec3 localTangent = normalize(vLocalTangent);
    mat3 matLocalTBN = GetLocalTBN(localNormal, localTangent);

    #if WORLD_WATER_WAVES != WATER_WAVES_NONE || defined PHYSICS_OCEAN
    if (vBlockId != BLOCK_WATER)
    #endif
        texNormal = matLocalTBN * texNormal;

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            float skyTexNoL = max(dot(texNormal, localSkyLightDirection), 0.0);

            #if MATERIAL_SSS != SSS_NONE
                skyTexNoL = mix(skyTexNoL, 1.0, sss);
            #endif

            shadowColor *= 1.2 * pow(skyTexNoL, 0.8);
        #endif
    //#else
    //    shadowColor *= max(vLit, 0.0);
    #endif

    // #if defined WORLD_WATER_ENABLED && defined WORLD_SKY_REFLECTIONS
    //     if (vBlockId == BLOCK_WATER) {
    //         if (!gl_FrontFacing) {
    //             if (isEyeInWater == 1) {
    //                 localNormal = -localNormal;
    //                 texNormal = -texNormal;
    //             }
    //             else {
    //                 discard;
    //                 return;
    //             }
    //         }

    //         vec3 fogColorFinal = RGBToLinear(fogColor);
    //         vec3 reflectDir = reflect(localViewDir, texNormal);
    //         vec3 reflectColor = GetFogColor(fogColorFinal, reflectDir.y) * vec3(0.7, 0.8, 1.0);

    //         float NoV = abs(dot(texNormal, -localViewDir));
    //         float F = 1.0 - NoV;//F_schlick(NoVmax, 0.02, 1.0);

    //         color.rgb = mix(color.rgb, reflectColor, F * (1.0 - color.a));
    //         color.a = max(color.a, F);
    //     }
    //     else {
    // #endif

        if (color.a > (0.5/255.0)) {
            float NoV = abs(dot(texNormal, -localViewDir));

            float F = F_schlick(NoV, metal_f0, 1.0);
            color.a = 1.0 - (1.0 - F) * (1.0 - color.a);
        }

        #if MATERIAL_NORMALS != NORMALMAP_NONE && (!defined IRIS_FEATURE_SSBO || DYN_LIGHT_MODE == DYN_LIGHT_NONE) && defined DIRECTIONAL_LIGHTMAP
            vec3 texViewNormal = mat3(gbufferModelView) * texNormal;
            ApplyDirectionalLightmap(lmFinal.x, vPos, vNormal, texViewNormal);
        #endif

        #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
            ApplySkyWetness(color.rgb, roughness, porosity, skyWetness, puddleF);
        #endif

    // #if defined WORLD_WATER_ENABLED && defined WORLD_SKY_REFLECTIONS
    //     }
    // #endif

    float roughL = max(_pow2(roughness), ROUGH_MIN);

    vec3 blockDiffuse = vBlockLight;
    vec3 blockSpecular = vec3(0.0);

    blockDiffuse += emission * MaterialEmissionF;
    
    GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, lmFinal.x, roughL, metal_f0, sss);

    vec3 skyDiffuse = vec3(0.0);
    vec3 skySpecular = vec3(0.0);

    #ifdef WORLD_SKY_ENABLED
        GetSkyLightingFinal(skyDiffuse, skySpecular, shadowColor, -localViewDir, localNormal, texNormal, lmFinal.y, roughL, metal_f0, sss);
    #endif

    color.rgb = GetFinalLighting(color.rgb, texNormal, blockDiffuse, blockSpecular, skyDiffuse, skySpecular, lmFinal, metal_f0, roughL, occlusion);

    vec3 specular = blockSpecular + skySpecular;
    color.a = min(color.a + luminance(specular), 1.0);

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
}
