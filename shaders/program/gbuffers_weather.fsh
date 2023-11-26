#define RENDER_WEATHER
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vLocalPos;
in vec3 vBlockLight;

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
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SUN_SAMPLES > 0)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if defined WORLD_SKY_ENABLED && (defined SHADOW_CLOUD_ENABLED || defined VL_BUFFER_ENABLED)
    #if WORLD_CLOUD_TYPE == CLOUDS_CUSTOM
        uniform sampler3D TEX_CLOUDS;
    #elif WORLD_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS;
    #endif
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || DYN_LIGHT_MODE != DYN_LIGHT_NONE
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
    
    // #ifdef IS_IRIS
    //     uniform float cloudTime;
    // #endif
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float viewWidth;
uniform vec2 viewSize;
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

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

uniform float blindness;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform vec3 shadowLightPosition;
    uniform float rainStrength;

    #if WORLD_CLOUD_TYPE != CLOUDS_NONE && defined IS_IRIS
        uniform float cloudTime;
    #endif
#endif

uniform float cloudHeight = WORLD_CLOUD_HEIGHT;

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    //uniform vec3 shadowLightPosition;

    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif

    //uniform float cloudHeight = WORLD_CLOUD_HEIGHT;
#else
    //uniform int worldTime;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    //uniform int isEyeInWater;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#if MC_VERSION >= 11700
    uniform ivec2 eyeBrightnessSmooth;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/collisions.glsl"
    #include "/lib/buffers/lighting.glsl"

    #if WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
    #endif
#endif

#include "/lib/anim.glsl"

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/hcm.glsl"
    #include "/lib/material/specular.glsl"
#endif

#include "/lib/lighting/hg.glsl"
#include "/lib/world/sky.glsl"
#include "/lib/clouds/cloud_vars.glsl"

#if defined SHADOW_CLOUD_ENABLED || defined VL_BUFFER_ENABLED
    #if WORLD_CLOUD_TYPE == CLOUDS_CUSTOM
        #include "/lib/clouds/cloud_custom.glsl"
    #elif WORLD_CLOUD_TYPE == CLOUDS_VANILLA
        #include "/lib/clouds/cloud_vanilla.glsl"
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

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || (LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0))
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/buffers/collisions.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lights.glsl"

// #include "/lib/lighting/voxel/block_light_map.glsl"
#include "/lib/lighting/voxel/item_light_map.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"
#include "/lib/lighting/voxel/items.glsl"
#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined DYN_LIGHT_WEATHER
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

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
#elif DYN_LIGHT_MODE == DYN_LIGHT_LPV
    #include "/lib/lighting/floodfill.glsl"
#else
    #include "/lib/lighting/basic.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"

#ifdef VL_BUFFER_ENABLED
    // #if defined RENDER_CLOUD_SHADOWS_ENABLED && defined WORLD_SKY_ENABLED
    //     #include "/lib/shadows/clouds.glsl"
    // #endif

    #include "/lib/world/volumetric_fog.glsl"
#endif


#if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
    /* RENDERTARGETS: 13,15 */
    layout(location = 0) out vec4 outDepth;
    layout(location = 1) out vec4 outFinal;
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;

    #if WORLD_CLOUD_TYPE != CLOUDS_NONE
        #if WORLD_CLOUD_TYPE != CLOUDS_CUSTOM
            const float CloudHeight = 4.0;
        #endif

        float cloudY = smoothstep(0.0, CloudHeight * 0.5, vLocalPos.y + cameraPosition.y - cloudHeight);
        color.a *= 1.0 - cloudY;
    #endif

    if (color.a < (1.5/255.0)) {
        discard;
        return;
    }

    color.a *= WorldRainOpacityF;

    const vec3 normal = vec3(0.0);
    const float occlusion = 1.0;
    const float roughness = 0.4;
    const float metal_f0 = 0.04;
    const float emission = 0.0;
    const float sss = 0.4;

    #ifndef IRIS_FEATURE_SSBO
        vec3 localSkyLightDirection = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
    #endif

    float viewDist = length(vLocalPos);
    vec3 localViewDir = vLocalPos / viewDist;

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        float shadowFade = smoothstep(shadowDistance - 20.0, shadowDistance + 20.0, viewDist);

        #ifdef SHADOW_COLORED
            shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);
        #else
            shadowColor = vec3(GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss));
        #endif
    #endif

    vec3 albedo = RGBToLinear(color.rgb);
    float roughL = _pow2(roughness);

    #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
        vec3 diffuse, specular = vec3(0.0);
        GetVanillaLighting(diffuse, lmcoord, vLocalPos, normal, normal, shadowColor, sss);

        SampleHandLight(diffuse, specular, vLocalPos, normal, normal, albedo, roughL, metal_f0, occlusion, sss);

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            // TODO: weather specular phase
            float VoL = dot(localSkyLightDirection, localViewDir);
            float phase = DHG(VoL, -0.32, 0.85, 0.08);
            //diffuse *= phase * WorldSkyLightColor * 20.0;
            diffuse *= 0.2;
            specular += 1.2 * phase * shadowColor;
        #endif

        color.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
    #elif DYN_LIGHT_MODE == DYN_LIGHT_LPV
        vec3 blockDiffuse = vBlockLight;
        vec3 blockSpecular = vec3(0.0);
        vec3 skyDiffuse = vec3(0.0);
        vec3 skySpecular = vec3(0.0);

        GetFloodfillLighting(blockDiffuse, blockSpecular, vLocalPos, normal, normal, lmcoord, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);
        SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, normal, normal, albedo, roughL, metal_f0, occlusion, sss);

        #ifdef WORLD_SKY_ENABLED
            #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE != SHADOW_TYPE_DISTORTED
                const vec3 shadowPos = vec3(0.0);
            #endif

            //GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, shadowColor, vLocalPos, normal, normal, albedo, lmcoord, roughL, metal_f0, occlusion, sss);
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

        color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, glcolor.a);
    #else
        vec3 blockDiffuse = vBlockLight;
        vec3 blockSpecular = vec3(0.0);
        vec3 skyDiffuse = vec3(0.0);
        vec3 skySpecular = vec3(0.0);

        GetFinalBlockLighting(blockDiffuse, blockSpecular, vLocalPos, normal, normal, albedo, lmcoord, roughL, metal_f0, occlusion, sss);
        SampleHandLight(blockDiffuse, blockSpecular, vLocalPos, normal, normal, albedo, roughL, metal_f0, occlusion, sss);

        #ifdef WORLD_SKY_ENABLED
            #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE != SHADOW_TYPE_DISTORTED
                const vec3 shadowPos = vec3(0.0);
            #endif

            GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, shadowColor, vLocalPos, normal, normal, albedo, lmcoord, roughL, metal_f0, occlusion, sss);
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

        color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, glcolor.a);
    #endif

    #ifndef DH_COMPAT_ENABLED
        ApplyFog(color, vLocalPos, localViewDir);
    #endif

    #ifdef VL_BUFFER_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
        #endif

        vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, min(viewDist - 0.05, far), far);
        color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
    #else
        // TODO: fake VL
    #endif

    #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
        outDepth = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
    #endif

    #ifndef DH_COMPAT_ENABLED
        color.rgb = LinearToRGB(color.rgb);
    #endif

    outFinal = color;
}
