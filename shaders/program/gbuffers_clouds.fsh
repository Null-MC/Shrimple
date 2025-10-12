#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_FRAG

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
    vec3 localNormal;

    #ifdef DISTANT_HORIZONS
        float viewPosZ;
    #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;
uniform sampler2D texBlueNoise;

#if defined WORLD_SKY_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform sampler2D texSkyIrradiance;
#endif

#if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if (defined WORLD_SHADOW_ENABLED && defined SHADOW_COLORED) || LIGHTING_MODE > LIGHTING_MODE_BASIC
    uniform sampler2D shadowcolor0;
#endif

// #ifdef RENDER_CLOUD_SHADOWS_ENABLED
    uniform sampler2D TEX_CLOUDS_VANILLA;
// #endif

#ifdef VOLUMETRIC_NOISE_ENABLED
    uniform sampler3D TEX_CLOUDS;
#endif

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float near;
uniform float far;

uniform int fogShape;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;

uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
uniform float weatherStrength;
uniform float blindnessSmooth;

uniform int moonPhase;
uniform float sunAngle;
uniform vec3 skyColor;

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

uniform bool isSpectator;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform vec3 playerBodyVector;
uniform vec3 eyePosition;

//uniform float lightningStrength;
uniform float cloudHeight;
uniform float cloudTime;

#ifdef VL_BUFFER_ENABLED
    uniform mat4 shadowModelView;
#endif

#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

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

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/erp.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/oklab.glsl"
#include "/lib/utility/lightmap.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/blackbody.glsl"
#include "/lib/lighting/fresnel.glsl"

#include "/lib/world/atmosphere.glsl"
#include "/lib/world/atmosphere_trace.glsl"
#include "/lib/world/common.glsl"

#include "/lib/clouds/cloud_common.glsl"
#include "/lib/clouds/cloud_vanilla.glsl"
#include "/lib/world/sky.glsl"
#include "/lib/world/lightning.glsl"

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

// #ifdef SKY_BORDER_FOG_ENABLED
    #include "/lib/fog/fog_common.glsl"

    #ifdef WORLD_SKY_ENABLED
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            #include "/lib/fog/fog_custom.glsl"
            
            #ifdef WORLD_WATER_ENABLED
                #include "/lib/fog/fog_water_custom.glsl"
            #endif
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            #include "/lib/fog/fog_vanilla.glsl"
        #endif
    #endif

    #include "/lib/sky/sky_render.glsl"
    #include "/lib/fog/fog_render.glsl"
// #endif

#include "/lib/material/hcm.glsl"
#include "/lib/material/fresnel.glsl"

//#if !(defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED)
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/flicker.glsl"
    #endif

    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/voxel/voxel_common.glsl"

        #include "/lib/voxel/lights/mask.glsl"
        // #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/voxel/blocks.glsl"

        // #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        //     #include "/lib/voxel/lights/light_mask.glsl"
        // #endif
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

    #include "/lib/lighting/sampling.glsl"

    #if defined IS_LPV_ENABLED && (LIGHTING_MODE > LIGHTING_MODE_BASIC || defined IS_LPV_SKYLIGHT_ENABLED)
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"

        #include "/lib/voxel/lpv/lpv.glsl"
        #include "/lib/voxel/lpv/lpv_render.glsl"
    #endif

    #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
        #include "/lib/lighting/basic_hand.glsl"
    #endif

    #include "/lib/lighting/scatter_transmit.glsl"

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
//#endif


#ifdef EFFECT_TAA_ENABLED
    #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
        /* RENDERTARGETS: 7,15 */
        layout(location = 0) out vec4 outVelocity;
        layout(location = 1) out vec4 outFinal;
    #else
        /* RENDERTARGETS: 0,7 */
        layout(location = 0) out vec4 outFinal;
        layout(location = 1) out vec4 outVelocity;
    #endif
#else
    layout(location = 0) out vec4 outFinal;
    #if defined DEFER_TRANSLUCENT && defined DEFERRED_BUFFER_ENABLED
        /* RENDERTARGETS: 15 */
    #else
        /* RENDERTARGETS: 0 */
    #endif
#endif

void main() {
    vec4 albedo = vec4(1.0);//texture(gtexture, vIn.texcoord);

    #if SKY_CLOUD_TYPE == CLOUDS_SOFT
        albedo *= 0.8;
    #else
        albedo *= vIn.color;
    #endif

//    if (albedo.a < 0.2) {
//        discard;
//        return;
//    }

    // albedo.a = sqrt(albedo.a);
    // albedo.a = min(albedo.a * SkyCloudOpacityF, 1.0);

    float viewDist = length(vIn.localPos);
    vec3 localViewDir = vIn.localPos / viewDist;

    #ifdef DISTANT_HORIZONS
        float depthDh = texelFetch(dhDepthTex, ivec2(gl_FragCoord.xy), 0).r;
        float depthDhL = linearizeDepthFast(depthDh, dhNearPlane, dhFarPlane);

        if (vIn.viewPosZ >= depthDhL) {
            discard;
            return;
        }
    #endif

    const float roughness = 0.9;
    const vec3 normal = normalize(vIn.localNormal);
    const float metal_f0 = 0.04;
    const float occlusion = 1.0;
    const float emission = 0.0;
    const float sss = 1.0;

    vec3 shadowColor = vec3(1.0);

//    float fogF = 0.0;
//    #ifdef SKY_BORDER_FOG_ENABLED
//        float fogDist = 0.5 * GetShapedFogDistance(vIn.localPos);
//
//        #if SKY_TYPE == SKY_TYPE_CUSTOM
//            fogF = GetCustomFogFactor(fogDist);
//        #elif SKY_TYPE == SKY_TYPE_VANILLA
//            fogF = GetFogFactor(fogDist, fogStart, fogEnd, 1.0);
//        #endif
//
//        albedo.a *= 1.0 - fogF;
//    #endif

    albedo.rgb = RGBToLinear(albedo.rgb);
    //albedo.rgb *= 1.0 - 0.7 * rainStrength;

    float roughL = _pow2(roughness);
    vec4 final = albedo;

    vec3 diffuseFinal = vec3(0.0);
    vec3 specularFinal = vec3(0.0);

//    float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
//    #if SKY_TYPE == SKY_TYPE_CUSTOM
//        vec3 skyColorFinal = GetCustomSkyColor(localSunDirection, vec3(0.0, 1.0, 0.0)) * eyeBrightF;
//    #else
//        vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
//        skyColorFinal = RGBToLinear(skyColorFinal) * eyeBrightF;
//    #endif
//
//    #if LIGHTING_MODE == LIGHTING_MODE_NONE
//        diffuseFinal += albedo.rgb * (1.0 + fogColor);
//    #else
//        diffuseFinal += albedo.rgb * (shadowColor * WorldSkyLightColor + 0.3*skyColorFinal);
//    #endif
//
//    #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE && LIGHTING_MODE <= LIGHTING_MODE_FLOODFILL
//        SampleHandLight(diffuseFinal, specularFinal, vIn.localPos, normal, normal, albedo.rgb, roughL, metal_f0, occlusion, sss);
//    #endif
//
//    #if LIGHTING_MODE >= LIGHTING_MODE_FLOODFILL
//        final.rgb = GetFinalLighting(albedo.rgb, diffuseFinal, specularFinal, occlusion);
//    #else
//        final.rgb = GetFinalLighting(albedo.rgb, diffuseFinal, specularFinal, metal_f0, roughL, emission, occlusion);
//    #endif

    #if SKY_CLOUD_TYPE == CLOUDS_SOFT
        vec3 worldPos = vIn.localPos + cameraPosition;// - fract(cameraPosition/12.0)*12.0;

        vec2 cloudOffset = GetCloudOffset();
        vec3 cloudTexcoord = GetCloudTexcoord(worldPos, cloudOffset) * vec2(256.0, 1.0).xyx;

        vec3 direction = localViewDir;

        direction.y /= (4.5/12.0);

        vec3 stepDir = sign(direction);
        vec3 stepSizes = rcp(abs(direction));
        vec3 nextDist = (stepDir * 0.5 + 0.5 - fract(cloudTexcoord)) / direction;

        vec3 currPos = cloudTexcoord;

        final.a = 1.0;

        for (int i = 0; i < 8; i++) {
            float closestDist = minOf(nextDist);
            vec3 sampleStep = direction*closestDist;

            ivec3 samplePos = ivec3(floor(currPos + 0.5*sampleStep));
            if (samplePos.y != 0) break;

            // TODO: shadow trace?

            vec3 stepAxis = vec3(lessThanEqual(nextDist, vec3(closestDist)));

            nextDist -= closestDist;
            nextDist += stepSizes * stepAxis;
            currPos += sampleStep;

            float density = 1.0 * texelFetch(TEX_CLOUDS_VANILLA, samplePos.xz, 0).r;
            final.a *= exp(-closestDist * density);
        }

        final.a = 1.0 - final.a;
    #endif

    //float fogF = 0.0;
    #ifdef SKY_BORDER_FOG_ENABLED
        ApplyBorderFog(final.rgb, vIn.localPos, localViewDir, fogEnd);



//        float fogDist = 0.25 * GetShapedFogDistance(vIn.localPos);
//
//        #if SKY_TYPE == SKY_TYPE_CUSTOM
//            // TODO: switch for in-water?
//            vec3 fogColorFinal = GetCustomSkyColor(localSunDirection, localViewDir);
//            float fogF = GetCustomFogFactor(fogDist);
//        #elif SKY_TYPE == SKY_TYPE_VANILLA
//            vec3 fogColorL = RGBToLinear(fogColor);
//            vec3 fogColorFinal = GetVanillaFogColor(fogColorL, localViewDir.y);
//            float fogF = GetVanillaFogFactor(fogDist);
//        #endif
//
//        //albedo.a *= 1.0 - fogF;
//        final.rgb = mix(final.rgb, fogColorFinal, fogF);
    #endif

//    #if LIGHTING_VOLUMETRIC != VOL_TYPE_NONE
//        float eyeBrightF = eyeBrightnessSmooth.y / 240.0;
//        #if SKY_TYPE == SKY_TYPE_CUSTOM
//            vec3 skyColorFinal = GetCustomSkyColor(localSunDirection, vec3(0.0, 1.0, 0.0)) * eyeBrightF;
//        #else
//            vec3 skyColorFinal = GetVanillaFogColor(fogColor, 1.0);
//            skyColorFinal = RGBToLinear(skyColorFinal) * eyeBrightF;
//        #endif
//
//        // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
//        //     float weatherF = 1.0 - 0.5 * _pow2(weatherStrength);
//        // #else
//            float weatherF = 1.0 - 0.8 * _pow2(weatherStrength);
//        // #endif
//
//        vec3 skyLightColor = WorldSkyLightColor * weatherF * VolumetricBrightnessSky;
//
//        //float skyLightF = eyeBrightnessSmooth.y / 240.0;
//        float airDensityF = GetAirDensity(eyeBrightF);
//        vec3 vlLight = phaseAir * skyLightColor + AirAmbientF * skyColorFinal;
//        ApplyScatteringTransmission(final.rgb, min(viewDist, far), vlLight, airDensityF, AirScatterColor, AirExtinctColor, 8);
//    #endif

    outFinal = final;

    #ifdef EFFECT_TAA_ENABLED
        // TODO: get vanilla cloud velocity
        outVelocity = vec4(vec3(0.0), 0.0);
    #endif
}
