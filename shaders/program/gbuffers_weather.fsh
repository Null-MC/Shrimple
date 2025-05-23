#define RENDER_WEATHER
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;

    #ifdef RENDER_SHADOWS_ENABLED
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
uniform sampler2D texBlueNoise;

//uniform sampler2D BUFFER_FINAL_PREV;

#if LIGHTING_MODE == LIGHTING_MODE_NONE
    uniform sampler2D lightmap;
#else
    uniform sampler2D texSkyIrradiance;
#endif

#if MATERIAL_REFLECTIONS != REFLECT_NONE //&& !defined DEFERRED_BUFFER_ENABLED
    uniform sampler2D texSky;
#endif

#if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if defined WORLD_SKY_ENABLED && (defined SHADOW_CLOUD_ENABLED || defined VL_BUFFER_ENABLED)
    // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
    //     uniform sampler3D TEX_CLOUDS;
    #if SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS_VANILLA;
    #endif
#endif

uniform sampler3D TEX_CLOUDS;

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || LIGHTING_MODE > LIGHTING_MODE_BASIC
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

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
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

uniform float blindnessSmooth;

uniform int moonPhase;
uniform float sunAngle;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform float rainStrength;
uniform float weatherStrength;

uniform float cloudHeight;
uniform float cloudTime;

#if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
    uniform float weatherCloudStrength;
#endif


#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowProjection;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

uniform bool isSpectator;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform vec3 playerBodyVector;
uniform vec3 eyePosition;

uniform float nightVision;

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhFarPlane;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#if MC_VERSION >= 11700
    uniform ivec2 eyeBrightnessSmooth;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/light_static.glsl"
    
    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif

    #if WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
        #include "/lib/water/water_depths_read.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/erp.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/scatter_transmit.glsl"
#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"
#include "/lib/lighting/blackbody.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/atmosphere_trace.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/sky.glsl"

#include "/lib/fog/fog_common.glsl"
#include "/lib/clouds/cloud_common.glsl"
#include "/lib/world/lightning.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
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

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/hcm.glsl"
    #include "/lib/material/fresnel.glsl"
#endif

#if defined SHADOW_CLOUD_ENABLED || defined VL_BUFFER_ENABLED
    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        #include "/lib/clouds/cloud_custom.glsl"
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        #include "/lib/clouds/cloud_vanilla.glsl"
        #include "/lib/clouds/cloud_vanilla_shadow.glsl"
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

#ifdef LIGHTING_FLICKER
    #include "/lib/lighting/flicker.glsl"
#endif

#if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
    #include "/lib/voxel/voxel_common.glsl"

    #include "/lib/voxel/lights/mask.glsl"
    // #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/voxel/blocks.glsl"
#endif

#if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lights.glsl"

#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/items.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED && defined DYN_LIGHT_WEATHER
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
    #include "/lib/buffers/volume.glsl"
    #include "/lib/utility/hsv.glsl"
    
    #include "/lib/voxel/lpv/lpv.glsl"
    #include "/lib/voxel/lpv/lpv_render.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/sky/sky_trace.glsl"
#endif

#if MATERIAL_REFLECTIONS != REFLECT_NONE
    #include "/lib/lighting/reflections.glsl"
#endif

#if LIGHTING_MODE != LIGHTING_MODE_NONE
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

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/basic_hand.glsl"
#endif

#ifdef VL_BUFFER_ENABLED
    #include "/lib/fog/fog_volume.glsl"
#endif

//#include "/lib/post/exposure.glsl"


#ifdef EFFECT_TAA_ENABLED
    #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
        /* RENDERTARGETS: 15,7 */
    #else
        /* RENDERTARGETS: 0,7 */
    #endif
#else
    #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
        /* RENDERTARGETS: 15 */
    #else
        /* RENDERTARGETS: 0 */
    #endif
#endif
layout(location = 0) out vec4 outFinal;
#ifdef EFFECT_TAA_ENABLED
    layout(location = 1) out vec4 outVelocity;
#endif

void main() {
	vec4 color = texture(gtexture, vIn.texcoord) * vIn.color;

    // #if SKY_CLOUD_TYPE != CLOUDS_NONE
    //     #if SKY_CLOUD_TYPE <= CLOUDS_VANILLA
    //         const float CloudHeight = 4.0;
    //     #endif

    //     float cloudY = smoothstep(0.0, CloudHeight * 0.5, vIn.localPos.y + cameraPosition.y - cloudHeight);
    //     color.a *= 1.0 - cloudY;

    //     #if SKY_CLOUD_TYPE > CLOUDS_VANILLA && defined SKY_WEATHER_CLOUD_ONLY
    //         const vec3 worldUp = vec3(0.0, 1.0, 0.0);
    //         float cloudUnder = 1.0 - TraceCloudShadow(cameraPosition + vIn.localPos, worldUp, CLOUD_GROUND_SHADOW_STEPS);
    //         color.a *= _pow2(cloudUnder);
    //     #endif
    // #endif

    if (color.a < (1.5/255.0)) {
        discard;
        return;
    }

    color.a *= Sky_RainOpacityF;

    //color.rgb = texelFetch(BUFFER_FINAL_PREV, ivec2(gl_FragCoord.xy), 0).rgb;
    //color.a = 1.0;

    //float exposure = GetPostExposure();
    //color.rgb /= exposure;

    const vec3 normal = vec3(0.0);
    const float occlusion = 1.0;
    const float roughness = 0.4;
    const float metal_f0 = 0.04;
    const float emission = 0.0;
    const float sss = 0.0;

    #ifndef IRIS_FEATURE_SSBO
        vec3 localSkyLightDirection = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
    #endif

    float viewDist = length(vIn.localPos);
    vec3 localViewDir = vIn.localPos / viewDist;

    vec3 shadowColor = vec3(1.0);
    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        float shadowFade = smoothstep(shadowDistance - 20.0, shadowDistance + 20.0, viewDist);

        #ifdef SHADOW_COLORED
            shadowColor = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);
        #else
            shadowColor = vec3(GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss));
        #endif
    #endif

    // #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
    //     float cloudShadow = TraceCloudShadow(cameraPosition + vIn.localPos, localSkyLightDirection, CLOUD_GROUND_SHADOW_STEPS);
    //     shadowColor *= 1.0 - (1.0 - cloudShadow) * 0.8;
    // #endif

    vec3 albedo = RGBToLinear(color.rgb);
    float roughL = _pow2(roughness);

    vec3 diffuseFinal = vec3(0.0);
    vec3 specularFinal = vec3(0.0);

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        GetFinalBlockLighting(diffuseFinal, specularFinal, vIn.localPos, normal, normal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss);
    #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        GetFloodfillLighting(diffuseFinal, specularFinal, vIn.localPos, normal, normal, vIn.lmcoord, shadowColor, albedo, metal_f0, roughL, occlusion, sss, false);
    #else
        GetVanillaLighting(diffuseFinal, vIn.lmcoord, shadowColor, occlusion);
    #endif

    #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
        SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, normal, normal, albedo, roughL, metal_f0, occlusion, sss);
    #endif

    // #if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
    //     const bool tir = false;
    //     const bool isUnderWater = false;
    //     GetSkyLightingFinal(diffuseFinal, specularFinal, shadowColor, vIn.localPos, normal, normal, albedo, vIn.lmcoord, roughL, metal_f0, occlusion, sss, isUnderWater, tir);
    // #endif

    float eyeSkyLightF = eyeBrightnessSmooth.y / 240.0;

    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        float VoL = dot(localSkyLightDirection, localViewDir);
        float phase = DHG(VoL, -0.35, 0.65, 0.3);

        // #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA
        //     phase *= cloudShadow;
        // #endif

        vec3 skyLightShadowColor = shadowColor * CalculateSkyLightWeatherColor(WorldSkyLightColor);

        vec3 skyAmbient = 0.1 * SampleSkyIrradiance(localViewDir) * eyeSkyLightF;
        vec3 skyLight = 10.0 * phase * skyLightShadowColor + skyAmbient;
        diffuseFinal += skyLight;
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, vIn.color.a);
    #elif LIGHTING_MODE == LIGHTING_MODE_FLOODFILL
        color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
    #else
        color.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
    #endif

    #ifdef SKY_BORDER_FOG_ENABLED
        ApplyFog(color, vIn.localPos, localViewDir);
    #endif

    #if defined VL_BUFFER_ENABLED && defined VL_PARTICLES_ENABLED
        #ifndef IRIS_FEATURE_SSBO
            vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
        #endif

        vec4 vlScatterTransmit = GetVolumetricLighting(localViewDir, localSunDirection, near, min(viewDist - 0.05, far), far);
        color.rgb = color.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
    #else
        float maxDist = min(viewDist, far);
        // TODO: limit to < cloudNear

        float airDensityF = GetAirDensity(eyeSkyLightF);
        vec3 vlLight = (phaseAir + AirAmbientF) * WorldSkyLightColor;
        ApplyScatteringTransmission(color.rgb, maxDist, vlLight, airDensityF, AirScatterColor, AirExtinctColor, 8);
    #endif

    // #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
    //     outDepth = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
    // #endif

    outFinal = color;

    #ifdef EFFECT_TAA_ENABLED
        outVelocity = vec4(vec3(0.0), 1.0);
    #endif
}
