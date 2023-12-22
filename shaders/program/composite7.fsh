#define RENDER_TRANSLUCENT_VL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
//uniform sampler2D BUFFER_VL;
//uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform usampler2D BUFFER_DEFERRED_DATA;

#if defined WATER_CAUSTICS && defined WORLD_WATER_ENABLED && defined WORLD_SKY_ENABLED && defined IS_IRIS
    uniform sampler3D texCaustics;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& VOLUMETRIC_BRIGHT_BLOCK > 0 //&& !defined VOLUMETRIC_BLOCK_RT
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if VOLUMETRIC_BRIGHT_SKY > 0 && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex0HW;
    #endif

    #ifdef SHADOW_COLORED
        uniform sampler2D shadowcolor0;
    #endif
#endif

#if defined WORLD_SKY_ENABLED && (VOLUMETRIC_BRIGHT_SKY > 0 || SKY_CLOUD_TYPE == CLOUDS_CUSTOM) //&& defined SHADOW_CLOUD_ENABLED
    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS;
    #endif
#endif

uniform int worldTime;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform float near;
uniform float far;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int isEyeInWater;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform ivec2 eyeBrightnessSmooth;

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform float rainStrength;
    uniform float skyRainStrength;

    uniform float cloudHeight = WORLD_CLOUD_HEIGHT;

    #ifdef IS_IRIS
        uniform vec3 eyePosition;
        uniform float lightningStrength;
        uniform float cloudTime;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#if defined IRIS_FEATURE_SSBO && VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != DYN_LIGHT_NONE
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    #ifdef IS_IRIS
        uniform bool firstPersonCamera;
        //uniform vec3 eyePosition;
    #endif
#endif

// #if defined RENDER_CLOUD_SHADOWS_ENABLED && defined WORLD_SKY_ENABLED
//     uniform vec3 eyePosition;
// #endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"

#include "/lib/world/atmosphere.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/scatter_transmit.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
    #include "/lib/fog/fog_common.glsl"
    #include "/lib/clouds/cloud_vars.glsl"

    //#if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            #include "/lib/fog/fog_custom.glsl"
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            #include "/lib/fog/fog_vanilla.glsl"
        #endif
    //#endif

    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        #include "/lib/clouds/cloud_custom.glsl"
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
#endif

#ifdef IRIS_FEATURE_SSBO
    // #include "/lib/buffers/scene.glsl"
    
    #if WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
    #endif

    #if LPV_SIZE > 0 || (VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != DYN_LIGHT_NONE)
        #include "/lib/blocks.glsl"

        #include "/lib/buffers/lighting.glsl"

        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != DYN_LIGHT_NONE
        #ifdef LIGHTING_FLICKER
            #include "/lib/lighting/blackbody.glsl"
            #include "/lib/lighting/flicker.glsl"
        #endif

        #include "/lib/lights.glsl"
        #include "/lib/lighting/fresnel.glsl"

        #if LIGHTING_MODE == DYN_LIGHT_TRACED && defined VOLUMETRIC_BLOCK_RT
            #include "/lib/lighting/voxel/light_mask.glsl"

            #include "/lib/buffers/collisions.glsl"
            #include "/lib/lighting/voxel/tinting.glsl"
            #include "/lib/lighting/voxel/tracing.glsl"

            #include "/lib/lighting/voxel/lights.glsl"
            #include "/lib/lighting/voxel/lights_render.glsl"
        #endif

        #ifdef VOLUMETRIC_HANDLIGHT
            #include "/lib/items.glsl"
            #include "/lib/lighting/voxel/items.glsl"
        #endif

        #include "/lib/lighting/sampling.glsl"
    #endif
    
    #if LPV_SIZE > 0 //&& VOLUMETRIC_BRIGHT_BLOCK > 0 //&& !defined VOLUMETRIC_BLOCK_RT
        #include "/lib/utility/hsv.glsl"

        #include "/lib/lighting/voxel/lpv.glsl"
        #include "/lib/lighting/voxel/lpv_render.glsl"
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
    
    #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
        #include "/lib/lighting/caustics.glsl"
    #endif
#endif

#if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE //&& (SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY)
    #include "/lib/buffers/shadow.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/render.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/render.glsl"
    #endif
#endif

#ifdef VL_BUFFER_ENABLED
    #include "/lib/fog/fog_volume.glsl"
#endif


/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 outVL;

// TODO: This might blow up in non-overworld worlds! add bypass?

void main() {
    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy * exp2(VOLUMETRIC_RES) + 0.5), 0).r;
    vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;

    #ifndef IRIS_FEATURE_SSBO
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

        vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    #else
        vec3 localPos = unproject(gbufferModelViewProjectionInverse * vec4(clipPos, 1.0));
    #endif

    vec3 localViewDir = normalize(localPos);

    #ifdef WORLD_WATER_ENABLED
        bool isWater = isEyeInWater == 1;
    #else
        const bool isWater = false;
    #endif

    ivec2 iTex = ivec2(texcoord * viewSize);
    uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
    vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
    vec3 localNormal = deferredNormal.rgb;

    if (any(greaterThan(localNormal, EPSILON3)))
        localNormal = normalize(localNormal * 2.0 - 1.0);

    float viewDist = length(localPos);

    //float d = clamp(viewDist * 0.05, 0.02, 0.5);
    //vec3 endPos = localPos + localNormal * d;
    //float endDist = clamp(length(endPos) - 0.4 * d, near, far);

    //float farMax = far;//min(shadowDistance, far);
    float farDist = clamp(viewDist, near, far - 0.002);

    vec4 final = vec4(0.0, 0.0, 0.0, 1.0);

    #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
        #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
            // if (depth >= 0.9999) {
            //     // vec3 cloudNear, cloudFar;
            //     // GetCloudNearFar(cameraPosition, localViewDir, cloudNear, cloudFar);

            //     // farDist = length(cloudFar);
            //     // if (farDist < EPSILON) farDist = CloudFar;
            //     // else farDist = min(farDist, CloudFar);
            //     farDist = CloudFar;
            // }
        #endif
    
        bool hasVl = false;
        // #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        //     hasVl = true;
        // #endif
        #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
            if (isEyeInWater != 1) hasVl = true;
        #endif
        #if WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
            if (isEyeInWater == 1) hasVl = true;
        #endif

        if (hasVl) final = GetVolumetricLighting(localViewDir, localSunDirection, near, farDist, viewDist, isWater);
    #endif

    #if defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE == CLOUDS_CUSTOM //&& SKY_VOL_FOG_TYPE != VOL_TYPE_FANCY
        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater != 1) {
        #endif

            vec3 cloudNear, cloudFar;
            GetCloudNearFar(cameraPosition, localViewDir, cloudNear, cloudFar);
            
            float cloudDistNear = length(cloudNear);
            float cloudDistFar = length(cloudFar);

            #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
                cloudDistNear = max(cloudDistNear, far);
            #endif

            cloudDistFar = min(cloudDistFar, 2000.0);

            if (depth < 1.0) {
                cloudDistFar = min(cloudDistFar, viewDist);

                if (cloudDistNear >= viewDist) {
                    cloudDistNear = 0.0;
                    cloudDistFar = 0.0;
                }
            }

            if (cloudDistFar > cloudDistNear) {
                #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
                    vec4 scatterTransmit = _TraceClouds(cameraPosition, localViewDir, cloudDistNear, cloudDistFar, CLOUD_STEPS, CLOUD_SHADOW_STEPS);
                #else
                    vec4 scatterTransmit = _TraceCloudVL(cameraPosition, localViewDir, cloudDistNear, cloudDistFar, CLOUD_STEPS, CLOUD_SHADOW_STEPS);
                #endif

                final.rgb += scatterTransmit.rgb * final.a;
                final.a *= scatterTransmit.a;
            }

            //final = TraceCloudVL(cameraPosition, localViewDir, viewDist, depth, CLOUD_STEPS, CLOUD_SHADOW_STEPS);

        #ifdef WORLD_WATER_ENABLED
            }
        #endif
    #endif

    outVL = final;
}
