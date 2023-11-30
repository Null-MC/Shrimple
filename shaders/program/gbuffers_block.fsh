#define RENDER_BLOCK
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

#ifdef WORLD_SKY_ENABLED
    #ifdef WORLD_WETNESS_ENABLED
        uniform sampler3D TEX_RIPPLES;
    #endif

    #ifdef SHADOW_CLOUD_ENABLED
        #if WORLD_CLOUD_TYPE == CLOUDS_CUSTOM
            uniform sampler3D TEX_CLOUDS;
        #elif WORLD_CLOUD_TYPE == CLOUDS_VANILLA
            uniform sampler2D TEX_CLOUDS;
        #endif
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || (defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
    uniform sampler2D shadowcolor0;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
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
    
    // #ifdef IS_IRIS
    //     uniform float cloudTime;
    // #endif
#endif

uniform ivec2 atlasSize;

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform int isEyeInWater;
uniform vec3 upPosition;
uniform vec3 skyColor;
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
    uniform float rainStrength;
    uniform float skyRainStrength;
    uniform float skyWetnessSmooth;
    uniform float wetness;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    //uniform ivec2 eyeBrightnessSmooth;
    uniform float near;
#endif

#if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    #ifdef WORLD_SKY_ENABLED
        uniform vec3 sunPosition;
        // uniform float rainStrength;
        // uniform float wetness;

        #if WORLD_CLOUD_TYPE != CLOUDS_NONE && defined IS_IRIS
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

    #ifdef IS_IRIS
        uniform bool isSpectator;
        uniform bool firstPersonCamera;
        uniform vec3 eyePosition;
    #endif

    uniform float blindness;
#endif

#if AF_SAMPLES > 1
    uniform float viewWidth;
    uniform float viewHeight;
    uniform vec4 spriteBounds;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/collisions.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/anim.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/atlas.glsl"

#include "/lib/world/common.glsl"

//#if WORLD_FOG_MODE != FOG_MODE_NONE
    #include "/lib/fog/fog_common.glsl"

    //#ifdef WORLD_SKY_ENABLED
        #if WORLD_SKY_TYPE == SKY_TYPE_CUSTOM
            #include "/lib/fog/fog_custom.glsl"
        #elif WORLD_SKY_TYPE == SKY_TYPE_VANILLA
            #include "/lib/fog/fog_vanilla.glsl"
        #endif
    //#endif

    #include "/lib/fog/fog_render.glsl"
//#endif

#if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/utility/tbn.glsl"
#endif

#if AF_SAMPLES > 1
    #include "/lib/sampling/anisotropic.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #ifdef WORLD_WETNESS_ENABLED
        #include "/lib/material/porosity.glsl"
        #include "/lib/world/wetness.glsl"
    #endif
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

#if MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/blackbody.glsl"
#endif

#if !defined RENDER_TRANSLUCENT && ((defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED) || (defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && defined SHADOW_BLUR))
    //
#elif defined IRIS_FEATURE_SSBO
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE || (LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0)
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            #include "/lib/lighting/voxel/light_mask.glsl"
        #endif
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        //#include "/lib/buffers/collisions.glsl"
        #include "/lib/lighting/voxel/tinting.glsl"
        #include "/lib/lighting/voxel/tracing.glsl"
    #endif
#endif

#include "/lib/lights.glsl"
// #include "/lib/lighting/voxel/block_light_map.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"

#if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"
        
        // #ifdef WORLD_WETNESS_ENABLED
        //     #include "/lib/material/porosity.glsl"
        //     #include "/lib/world/wetness.glsl"
        // #endif
        
        #if defined SHADOW_CLOUD_ENABLED && WORLD_CLOUD_TYPE == CLOUDS_CUSTOM
            #include "/lib/lighting/hg.glsl"
            #include "/lib/clouds/cloud_vars.glsl"
            #include "/lib/clouds/cloud_custom.glsl"
        #endif
    #endif

    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/items.glsl"
#endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"
#include "/lib/material/specular.glsl"

#if !defined DEFERRED_BUFFER_ENABLED || (defined RENDER_TRANSLUCENT && !defined DEFER_TRANSLUCENT)
    #include "/lib/lighting/fresnel.glsl"
    #include "/lib/lighting/sampling.glsl"
    #include "/lib/lighting/scatter_transmit.glsl"

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/voxel/sampling.glsl"
    #endif

    // #ifdef WORLD_SKY_ENABLED
    //     #include "/lib/world/sky.glsl"
    // #endif

    #ifdef WORLD_WATER_ENABLED
        #include "/lib/world/water.glsl"
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

    #ifdef VL_BUFFER_ENABLED
        #include "/lib/lighting/hg.glsl"
        #include "/lib/world/volumetric_fog.glsl"
    #endif

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
    vec3 localNormal = normalize(vLocalNormal);
    float viewDist = length(vLocalPos);
    vec2 localCoord = vLocalCoord;
    vec2 atlasCoord = texcoord;
    
    if (!gl_FrontFacing) localNormal = -localNormal;

    float porosity = 0.0;
    bool skipParallax = false;
    // #if (defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED) || MATERIAL_PARALLAX != PARALLAX_NONE
    //     vec4 preN = textureGrad(normals, atlasCoord, dFdXY[0], dFdXY[1]);
    //     if (all(lessThan(atlasBounds[1], vec2(1.0/atlasSize)))) skipParallax = true;
    //     if (all(lessThan(abs(vLocalNormal), vec3(0.1)))) skipParallax = true;
    //     skipParallax = true;
    // #endif

    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
        float skyWetness = 0.0, puddleF = 0.0;
        vec4 rippleNormalStrength;

        if (!skipParallax) {
        //if (blockEntityId == BLOCK_CREATE_TRACK) {
            vec3 worldPos = vLocalPos + cameraPosition;

            float surface_roughness, surface_metal_f0;
            GetMaterialSpecular(blockEntityId, texcoord, dFdXY, surface_roughness, surface_metal_f0);

            porosity = GetMaterialPorosity(texcoord, dFdXY, surface_roughness, surface_metal_f0);
            skyWetness = GetSkyWetness(worldPos, localNormal, lmcoord);//, blockEntityId);
            puddleF = GetWetnessPuddleF(skyWetness, porosity);

            #if WORLD_WETNESS_PUDDLES > PUDDLES_BASIC
                rippleNormalStrength = GetWetnessRipples(worldPos, viewDist, puddleF);

                localCoord -= rippleNormalStrength.yx * rippleNormalStrength.w * RIPPLE_STRENGTH;
                //if (!skipParallax) atlasCoord = GetAtlasCoord(localCoord);
                atlasCoord = GetAtlasCoord(localCoord);
            #endif
        //}
        }
    #endif

    #if MATERIAL_PARALLAX != PARALLAX_NONE
        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(tanViewPos);

        if (!skipParallax && viewDist < MATERIAL_PARALLAX_DISTANCE) {
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

    color.rgb *= glcolor.rgb;
    color.a = 1.0;

    float occlusion = 1.0;
    #if defined WORLD_AO_ENABLED && !defined EFFECT_SSAO_ENABLED
        //occlusion = RGBToLinear(glcolor.a);
        occlusion = glcolor.a;
    #endif

    float roughness, metal_f0;
    float sss = GetMaterialSSS(blockEntityId, atlasCoord, dFdXY);
    float emission = GetMaterialEmission(blockEntityId, atlasCoord, dFdXY);
    GetMaterialSpecular(blockEntityId, atlasCoord, dFdXY, roughness, metal_f0);
    
    vec2 lmFinal = lmcoord;

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
                float shadowF = GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss);
                shadowColor = vec3(shadowF);
            #endif
        }
    #endif

    vec3 texNormal = localNormal;
    bool isValidNormal = false;
    float parallaxShadow = 1.0;

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        isValidNormal = GetMaterialNormal(atlasCoord, dFdXY, texNormal);

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
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        float skyTexNoL = 1.0;

        if (isValidNormal) {
            skyTexNoL = dot(texNormal, localSkyLightDirection);
        }

        #if MATERIAL_SSS != SSS_NONE
            skyTexNoL = mix(max(skyTexNoL, 0.0), abs(skyTexNoL), sss);
        #else
            skyTexNoL = max(skyTexNoL, 0.0);
        #endif

        shadowColor *= 1.2 * pow(skyTexNoL, 0.8);
    #endif

    vec3 albedo = RGBToLinear(color.rgb);

    #if defined WORLD_SKY_ENABLED && defined WORLD_WETNESS_ENABLED
        //if (blockEntityId == BLOCK_CREATE_TRACK) {
            #if WORLD_WETNESS_PUDDLES != PUDDLES_NONE
                ApplyWetnessPuddles(texNormal, vLocalPos, skyWetness, porosity, puddleF);

                #if WORLD_WETNESS_PUDDLES != PUDDLES_BASIC
                    ApplyWetnessRipples(texNormal, rippleNormalStrength);
                #endif
            #endif

            ApplySkyWetness(albedo, roughness, porosity, skyWetness, puddleF);
        //}
    #endif

    #if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
        float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        float fogF = 0.0;
        #if WORLD_SKY_TYPE == SKY_TYPE_VANILLA && WORLD_FOG_MODE != FOG_MODE_NONE
            fogF = GetVanillaFogFactor(vLocalPos);
        #endif

        outDeferredColor = vec4(LinearToRGB(albedo), color.a) + dither;
        outDeferredShadow = vec4(shadowColor + dither, 0.0);

        uvec4 deferredData;
        deferredData.r = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, sss + dither));
        deferredData.g = packUnorm4x8(vec4(lmFinal, occlusion, emission) + dither);
        deferredData.b = packUnorm4x8(vec4(fogColor, fogF + dither));
        deferredData.a = packUnorm4x8(vec4(texNormal * 0.5 + 0.5, 1.0));
        outDeferredData = deferredData;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outDeferredRough = vec4(roughness + dither, metal_f0 + dither, 0.0, 1.0);
        #endif
    #else
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

            #if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE == DYN_LIGHT_LPV || DYN_LIGHT_MODE == DYN_LIGHT_TRACED)
                GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, albedo, lmFinal, roughL, metal_f0, sss);
                SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
            #endif

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

        #if !defined DH_COMPAT_ENABLED && WORLD_FOG_MODE != FOG_MODE_NONE
            ApplyFog(color, vLocalPos, localViewDir);
        #endif

        #ifdef VL_BUFFER_ENABLED
            #ifndef IRIS_FEATURE_SSBO
                vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            #endif

            float farMax = min(viewDist - 0.05, far);
            vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, farMax);
            color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        #endif

        #ifdef DH_COMPAT_ENABLED
            color.rgb = LinearToRGB(color.rgb);
        #endif

        outFinal = color;
    #endif
}
