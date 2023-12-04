#define RENDER_OPAQUE_VL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

uniform sampler2D BUFFER_DEFERRED_SHADOW;

#if defined WATER_CAUSTICS && defined WORLD_WATER_ENABLED && defined WORLD_SKY_ENABLED && defined IS_IRIS
    uniform sampler3D texCaustics;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& VOLUMETRIC_BRIGHT_BLOCK > 0 //&& !defined VOLUMETRIC_BLOCK_RT
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if defined WORLD_SKY_ENABLED && (SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || SKY_CLOUD_TYPE == CLOUDS_CUSTOM) //&& defined SHADOW_CLOUD_ENABLED
    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS;
    #endif
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    //#if VOLUMETRIC_BRIGHT_SKY > 0
        uniform sampler2D shadowtex0;
        uniform sampler2D shadowtex1;

        #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex1HW;
        #endif

        #ifdef SHADOW_COLORED
            uniform sampler2D shadowcolor0;
        #endif
    //#endif
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
uniform int fogShape;
uniform float fogEnd;
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
        uniform float lightningStrength;
        uniform float cloudTime;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

#if defined IRIS_FEATURE_SSBO && VOLUMETRIC_BRIGHT_BLOCK > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    uniform bool firstPersonCamera;
#endif

#ifdef IS_IRIS
    uniform vec3 eyePosition;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"

#include "/lib/world/atmosphere.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/scatter_transmit.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    
    // #if WATER_DEPTH_LAYERS > 1
    //     #include "/lib/buffers/water_depths.glsl"
    // #endif

    #if LPV_SIZE > 0 || (VOLUMETRIC_BRIGHT_BLOCK > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE)
        #include "/lib/blocks.glsl"

        #include "/lib/buffers/lighting.glsl"

        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if VOLUMETRIC_BRIGHT_BLOCK > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        #ifdef DYN_LIGHT_FLICKER
            #include "/lib/lighting/blackbody.glsl"
            #include "/lib/lighting/flicker.glsl"
        #endif

        #include "/lib/lights.glsl"
        #include "/lib/lighting/fresnel.glsl"

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined VOLUMETRIC_BLOCK_RT
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

    #if LPV_SIZE > 0
        #include "/lib/lighting/voxel/lpv.glsl"
        #include "/lib/lighting/voxel/lpv_render.glsl"
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"

    #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
        #include "/lib/lighting/caustics.glsl"
    #endif

    #if WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
    #endif
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
    #include "/lib/fog/fog_common.glsl"
    #include "/lib/clouds/cloud_vars.glsl"

    #if SKY_TYPE == SKY_TYPE_CUSTOM
        #include "/lib/fog/fog_custom.glsl"
    #elif SKY_TYPE == SKY_TYPE_VANILLA
        #include "/lib/fog/fog_vanilla.glsl"
    #endif

    #if SKY_CLOUD_TYPE == CLOUDS_CUSTOM
        #include "/lib/clouds/cloud_custom.glsl"
    #endif

    #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
        #if SKY_CLOUD_TYPE == CLOUDS_VANILLA
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
    #endif
#endif

#ifdef VL_BUFFER_ENABLED
    #include "/lib/fog/fog_volume.glsl"
#endif


/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 outVL;

void main() {
    //ivec2 iTex = ivec2(gl_FragCoord.xy / viewSize + 0.5);
    ivec2 iTex = ivec2(texcoord * viewSize);
    float depthOpaque = texelFetch(depthtex1, iTex, 0).r;
    float depthTranslucent = texelFetch(depthtex0, iTex, 0).r;

    vec4 final = vec4(0.0, 0.0, 0.0, 1.0);

    if (depthTranslucent < depthOpaque) {
        vec3 clipPosOpaque = vec3(texcoord, depthOpaque) * 2.0 - 1.0;
        vec3 clipPosTranslucent = vec3(texcoord, depthTranslucent) * 2.0 - 1.0;

        #ifndef IRIS_FEATURE_SSBO
            vec3 viewPosOpaque = unproject(gbufferProjectionInverse * vec4(clipPosOpaque, 1.0));
            vec3 localPosOpaque = (gbufferModelViewInverse * vec4(viewPosOpaque, 1.0)).xyz;

            vec3 viewPosTranslucent = unproject(gbufferProjectionInverse * vec4(clipPosTranslucent, 1.0));
            vec3 localPosTranslucent = (gbufferModelViewInverse * vec4(viewPosTranslucent, 1.0)).xyz;

            vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
        #else
            vec3 localPosOpaque = unproject(gbufferModelViewProjectionInverse * vec4(clipPosOpaque, 1.0));
            vec3 localPosTranslucent = unproject(gbufferModelViewProjectionInverse * vec4(clipPosTranslucent, 1.0));
        #endif

        float distOpaque = length(localPosOpaque);
        float distTranslucent = length(localPosTranslucent);
        vec3 localViewDir = normalize(localPosOpaque);

        //float d = clamp(distOpaque * 0.05, 0.02, 0.5);
        //float endDist = clamp(distOpaque - 0.4 * d, near, far);

        #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
            bool isWater = false;
            #if defined WORLD_WATER_ENABLED
                #if WATER_DEPTH_LAYERS > 1
                    isWater = true;
                #else
                    if (isEyeInWater == 0) {
                        float deferredShadowA = texelFetch(BUFFER_DEFERRED_SHADOW, iTex, 0).a;
                        isWater = deferredShadowA > 0.5;
                    }
                #endif
            #endif

            //float farMax = far;//min(shadowDistance, far) - 0.002;
            float distNear = clamp(distTranslucent, near, far);
            float distFar = clamp(distOpaque, near, far);

            bool hasVl = false;
            #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
                if (isEyeInWater == 1) hasVl = true;
            #endif
            #if WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
                if (isEyeInWater != 1 && isWater) hasVl = true;
            #endif

            if (hasVl) final = GetVolumetricLighting(localViewDir, localSunDirection, distNear, distFar, distTranslucent, isWater);
        #endif

        #if defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE == CLOUDS_CUSTOM && SKY_VOL_FOG_TYPE != VOL_TYPE_FANCY
            if (isEyeInWater == 1) {
                final = TraceCloudVL(cameraPosition, localViewDir, distOpaque, depthOpaque, CLOUD_STEPS, CLOUD_SHADOW_STEPS);
            }
        #endif
    }

    outVL = final;
}
