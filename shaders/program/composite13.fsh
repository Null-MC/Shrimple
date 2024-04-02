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

#if defined WORLD_SKY_ENABLED //&& (SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || SKY_CLOUD_TYPE > CLOUDS_VANILLA) //&& defined SHADOW_CLOUD_ENABLED
    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS_VANILLA;
    #endif
#elif defined IS_WORLD_SMOKE_ENABLED && defined VL_BUFFER_ENABLED
    uniform sampler3D TEX_CLOUDS;
#endif

#ifdef RENDER_SHADOWS_ENABLED
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

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
    uniform sampler2D dhDepthTex1;
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
uniform float farPlane;

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

    uniform float cloudHeight;

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

#if defined IRIS_FEATURE_SSBO && VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    uniform bool firstPersonCamera;
#endif

#if LPV_SIZE > 0
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferPreviousModelView;
#endif

#ifdef IS_IRIS
    uniform vec3 eyePosition;
#endif

#ifdef DISTANT_HORIZONS
    uniform mat4 dhProjectionInverse;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/scatter_transmit.glsl"

#include "/lib/world/atmosphere.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"

    #if LPV_SIZE > 0 || (VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != LIGHTING_MODE_NONE)
        #include "/lib/buffers/block_voxel.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED && defined VOLUMETRIC_BLOCK_RT
        #include "/lib/buffers/block_static.glsl"
        #include "/lib/buffers/light_voxel.glsl"
    #endif
    
    // #if WATER_DEPTH_LAYERS > 1
    //     #include "/lib/buffers/water_depths.glsl"
    // #endif

    #if LPV_SIZE > 0 || (VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != LIGHTING_MODE_NONE)
        #include "/lib/blocks.glsl"

        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != LIGHTING_MODE_NONE
        #ifdef LIGHTING_FLICKER
            #include "/lib/lighting/blackbody.glsl"
            #include "/lib/lighting/flicker.glsl"
        #endif

        #include "/lib/lights.glsl"
        #include "/lib/lighting/fresnel.glsl"

        #if LIGHTING_MODE == LIGHTING_MODE_TRACED && defined VOLUMETRIC_BLOCK_RT
            #include "/lib/lighting/voxel/light_mask.glsl"

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
        #include "/lib/utility/hsv.glsl"
        
        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_render.glsl"
    #endif
#endif

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
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
    #include "/lib/world/lightning.glsl"

    #if SKY_TYPE == SKY_TYPE_CUSTOM
        #include "/lib/fog/fog_custom.glsl"
    #elif SKY_TYPE == SKY_TYPE_VANILLA
        #include "/lib/fog/fog_vanilla.glsl"
    #endif

    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        #include "/lib/clouds/cloud_custom.glsl"
        #include "/lib/clouds/cloud_custom_shadow.glsl"
        #include "/lib/clouds/cloud_custom_trace.glsl"
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        #include "/lib/clouds/cloud_vanilla.glsl"
        #include "/lib/clouds/cloud_vanilla_shadow.glsl"
    #endif

    #ifdef RENDER_SHADOWS_ENABLED
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
    #if defined IS_WORLD_SMOKE_ENABLED && !defined WORLD_SKY_ENABLED
        #include "/lib/fog/fog_smoke.glsl"
    #endif

    #include "/lib/fog/fog_volume.glsl"
#endif


/* RENDERTARGETS: 8,10 */
layout(location = 0) out vec3 outScatter;
layout(location = 1) out vec3 outTransmit;

void main() {
    //ivec2 iTex = ivec2(gl_FragCoord.xy / viewSize + 0.5);
    ivec2 iTex = ivec2(texcoord * viewSize);
    float depthOpaque = texelFetch(depthtex1, iTex, 0).r;
    float depthTrans = texelFetch(depthtex0, iTex, 0).r;

    float depthOpaqueL = linearizeDepth(depthOpaque, near, farPlane);
    float depthTransL = linearizeDepth(depthTrans, near, farPlane);

    #ifdef DISTANT_HORIZONS
        float dhDepthTrans = texelFetch(dhDepthTex, iTex, 0).r;
        float dhDepthTransL = linearizeDepth(dhDepthTrans, dhNearPlane, dhFarPlane);
        mat4 projectionInvTrans = gbufferProjectionInverse;

        if (dhDepthTransL < depthTransL || depthTrans >= 1.0) {
            depthTrans = dhDepthTrans;
            depthTransL = dhDepthTransL;
            projectionInvTrans = dhProjectionInverse;
        }

        float dhDepthOpaque = texelFetch(dhDepthTex1, iTex, 0).r;
        float dhDepthOpaqueL = linearizeDepth(dhDepthOpaque, dhNearPlane, dhFarPlane);
        mat4 projectionInvOpaque = gbufferProjectionInverse;

        if (dhDepthOpaqueL < depthOpaqueL || depthOpaque >= 1.0) {
            depthOpaque = dhDepthOpaque;
            depthOpaqueL = dhDepthOpaqueL;
            projectionInvOpaque = dhProjectionInverse;
        }
    #endif

    vec3 scatterFinal = vec3(0.0);
    vec3 transmitFinal = vec3(1.0);

    if (depthTransL < depthOpaqueL) {
        vec3 clipPosOpaque = vec3(texcoord, depthOpaque) * 2.0 - 1.0;
        vec3 clipPosTranslucent = vec3(texcoord, depthTrans) * 2.0 - 1.0;

        #ifdef DISTANT_HORIZONS
            vec3 viewPosOpaque = unproject(projectionInvOpaque, clipPosOpaque);
            vec3 localPosOpaque = mul3(gbufferModelViewInverse, viewPosOpaque);

            vec3 viewPosTranslucent = unproject(projectionInvTrans, clipPosTranslucent);
            vec3 localPosTranslucent = mul3(gbufferModelViewInverse, viewPosTranslucent);
        #else
            #ifndef IRIS_FEATURE_SSBO
                vec3 viewPosOpaque = unproject(gbufferProjectionInverse, clipPosOpaque);
                vec3 localPosOpaque = mul3(gbufferModelViewInverse, viewPosOpaque);

                vec3 viewPosTranslucent = unproject(gbufferProjectionInverse, clipPosTranslucent);
                vec3 localPosTranslucent = mul3(gbufferModelViewInverse, viewPosTranslucent);
            #else
                vec3 localPosOpaque = unproject(gbufferModelViewProjectionInverse, clipPosOpaque);
                vec3 localPosTranslucent = unproject(gbufferModelViewProjectionInverse, clipPosTranslucent);
            #endif
        #endif

        // #ifndef IRIS_FEATURE_SSBO
        //     vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
        // #endif

        float distOpaque = length(localPosOpaque);
        float distTranslucent = length(localPosTranslucent);
        vec3 localViewDir = localPosOpaque / distOpaque;

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
            float farMax = far;
            #ifdef DISTANT_HORIZONS
                farMax = 0.5*dhFarPlane;
            #endif
            
            farMax -= 0.002 * distOpaque;

            float distNear = clamp(distTranslucent, near, farMax);
            float distFar = clamp(distOpaque, near, farMax);

            bool hasVl = false;
            #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
                if (isEyeInWater == 1) hasVl = true;
            #endif
            #if WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
                if (isEyeInWater != 1 && isWater) hasVl = true;
            #endif

            if (hasVl) ApplyVolumetricLighting(scatterFinal, transmitFinal, localViewDir, distNear, distFar, distTranslucent, isWater);
        #endif

        #if defined WORLD_SKY_ENABLED && SKY_CLOUD_TYPE > CLOUDS_VANILLA && SKY_VOL_FOG_TYPE != VOL_TYPE_FANCY
            if (isEyeInWater == 1) {
                // vec4 scatterTransmit = TraceCloudVL(cameraPosition, localViewDir, distOpaque, depthOpaque, CLOUD_STEPS, CLOUD_SHADOW_STEPS);
                // scatterFinal += scatterTransmit.rgb * transmitFinal;
                // transmitFinal *= scatterTransmit.a;

                vec3 cloudNear, cloudFar;
                GetCloudNearFar(cameraPosition, localViewDir, cloudNear, cloudFar);
                
                //float cloudDistNear = length(cloudNear);
                float cloudDistFar = length(cloudFar);

                #if SKY_VOL_FOG_TYPE == VOL_TYPE_FAST
                    float cloudDistNear = distTranslucent;

                    if (depthOpaque >= 1.0)
                        cloudDistFar = SkyFar;
                #else
                    float cloudDistNear = max(length(cloudNear), distTranslucent);
                #endif

                // if (cloudDistNear < distOpaque || depthOpaque >= 0.9999)
                //     cloudDistFar = min(cloudDistFar, min(distOpaque, far));
                // else {
                //     cloudDistNear = 0.0;
                //     cloudDistFar = 0.0;
                // }

                if (depthOpaque < 1.0)
                    cloudDistFar = min(cloudDistFar, distOpaque);

                //float farMax = min(distOpaque, far);

                // _TraceCloudVL(scatterFinal, transmitFinal, cameraPosition, localViewDir, cloudDistNear, cloudDistFar, CLOUD_STEPS, CLOUD_SHADOW_STEPS);
                if (cloudDistFar > cloudDistNear)
                    _TraceClouds(scatterFinal, transmitFinal, cameraPosition, localViewDir, cloudDistNear, cloudDistFar, VOLUMETRIC_SAMPLES, CLOUD_SHADOW_STEPS);
            }
        #endif
    }

    outScatter = scatterFinal;
    outTransmit = transmitFinal;
}
