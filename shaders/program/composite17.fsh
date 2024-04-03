#define RENDER_TRANSLUCENT_VL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
//uniform sampler2D BUFFER_VL_SCATTER;
//uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform usampler2D BUFFER_DEFERRED_DATA;
//uniform sampler2D BUFFER_DEFERRED_NORMAL_TEX;

#if defined WATER_CAUSTICS && defined WORLD_WATER_ENABLED && defined WORLD_SKY_ENABLED && defined IS_IRIS
    uniform sampler3D texCaustics;
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& VOLUMETRIC_BRIGHT_BLOCK > 0 //&& !defined VOLUMETRIC_BLOCK_RT
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if VOLUMETRIC_BRIGHT_SKY > 0 && defined RENDER_SHADOWS_ENABLED
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
        uniform sampler2DShadow shadowtex0HW;
    #endif

    #ifdef SHADOW_COLORED
        uniform sampler2D shadowcolor0;
    #endif
#endif

#if defined WORLD_SKY_ENABLED && (VOLUMETRIC_BRIGHT_SKY > 0 || SKY_CLOUD_TYPE > CLOUDS_VANILLA) //&& defined SHADOW_CLOUD_ENABLED
    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        uniform sampler3D TEX_CLOUDS;
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        uniform sampler2D TEX_CLOUDS_VANILLA;
    #endif
#elif defined IS_WORLD_SMOKE_ENABLED && defined VL_BUFFER_ENABLED
    uniform sampler3D TEX_CLOUDS;
#endif

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
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

    uniform float cloudHeight;

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

#if defined IRIS_FEATURE_SSBO && VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != LIGHTING_MODE_NONE
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;

    #ifdef IS_IRIS
        uniform bool firstPersonCamera;
        //uniform vec3 eyePosition;
    #endif
#endif

#if LPV_SIZE > 0
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferPreviousModelView;
#endif

// #if defined RENDER_CLOUD_SHADOWS_ENABLED && defined WORLD_SKY_ENABLED
//     uniform vec3 eyePosition;
// #endif

#ifdef DISTANT_HORIZONS
    // uniform mat4 dhModelViewInverse;
    uniform mat4 dhProjectionInverse;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"

    #if LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED && defined VOLUMETRIC_BLOCK_RT
        #include "/lib/buffers/block_static.glsl"
        #include "/lib/buffers/light_voxel.glsl"
    #endif
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/utility/anim.glsl"

#include "/lib/lighting/hg.glsl"
#include "/lib/lighting/scatter_transmit.glsl"

#include "/lib/world/atmosphere.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
    #include "/lib/fog/fog_common.glsl"
    #include "/lib/clouds/cloud_vars.glsl"
    #include "/lib/world/lightning.glsl"
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
    
    #if defined WATER_CAUSTICS && defined WORLD_SKY_ENABLED
        #include "/lib/lighting/caustics.glsl"
    #endif
#endif

#ifdef WORLD_SKY_ENABLED
    //#if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
        #if SKY_TYPE == SKY_TYPE_CUSTOM
            #include "/lib/fog/fog_custom.glsl"
        #elif SKY_TYPE == SKY_TYPE_VANILLA
            #include "/lib/fog/fog_vanilla.glsl"
        #endif
    //#endif

    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        #include "/lib/clouds/cloud_custom.glsl"
        #include "/lib/clouds/cloud_custom_shadow.glsl"
        #include "/lib/clouds/cloud_custom_trace.glsl"
    #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
        #include "/lib/clouds/cloud_vanilla.glsl"
        #include "/lib/clouds/cloud_vanilla_shadow.glsl"
    #endif

    #include "/lib/sky/sky_trace.glsl"
#endif

#ifdef IRIS_FEATURE_SSBO
    // #include "/lib/buffers/scene.glsl"
    
    #if WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
    #endif

    // #if LPV_SIZE > 0 || (VOLUMETRIC_BRIGHT_BLOCK > 0 && LIGHTING_MODE != LIGHTING_MODE_NONE)
    #if LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED || defined VOLUMETRIC_BLOCK_RT
        #include "/lib/blocks.glsl"

        // #include "/lib/buffers/lighting.glsl"

        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        #ifdef LIGHTING_FLICKER
            #include "/lib/lighting/blackbody.glsl"
            #include "/lib/lighting/flicker.glsl"
        #endif

        #include "/lib/lights.glsl"
        #include "/lib/lighting/fresnel.glsl"

        #if LIGHTING_MODE == LIGHTING_MODE_TRACED && defined VOLUMETRIC_BLOCK_RT
            #include "/lib/lighting/voxel/light_mask.glsl"

            //#include "/lib/buffers/block_static.glsl"
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
    
    #if defined IS_LPV_ENABLED && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED) //&& VOLUMETRIC_BRIGHT_BLOCK > 0 //&& !defined VOLUMETRIC_BLOCK_RT
        #include "/lib/utility/hsv.glsl"

        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_render.glsl"
    #endif
#endif

#ifdef RENDER_SHADOWS_ENABLED //&& (SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY)
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
    #if defined IS_WORLD_SMOKE_ENABLED && !defined WORLD_SKY_ENABLED
        #include "/lib/fog/fog_smoke.glsl"
    #endif

    #include "/lib/fog/fog_volume.glsl"
#endif


/* RENDERTARGETS: 8,10 */
layout(location = 0) out vec3 outScatter;
layout(location = 1) out vec3 outTransmit;

// TODO: This might blow up in non-overworld worlds! add bypass?

void main() {
    const int bufferScale = int(exp2(VOLUMETRIC_RES));
    ivec2 depthCoord = ivec2(gl_FragCoord.xy * bufferScale);// + int(0.5 * bufferScale);
    // ivec2 depthCoord = ivec2(texcoord * viewSize);// + int(0.5 * bufferScale);
    float depthTrans = texelFetch(depthtex0, depthCoord, 0).r;

    #ifdef DISTANT_HORIZONS
        float depthTransL = linearizeDepth(depthTrans, near, farPlane);
        mat4 projectionInvTrans = gbufferProjectionInverse;

        float dhDepthTrans = textureLod(dhDepthTex, texcoord, 0).r;
        float dhDepthTransL = linearizeDepth(dhDepthTrans, dhNearPlane, dhFarPlane);

        if (depthTrans >= 1.0 || (dhDepthTransL < depthTransL && dhDepthTrans > 0.0)) {
            depthTrans = dhDepthTrans;
            //depthTransL = dhDepthTransL;
            projectionInvTrans = dhProjectionInverse;
        }
    #endif

    vec3 clipPos = vec3(depthCoord / viewSize, depthTrans) * 2.0 - 1.0;

    #ifdef DISTANT_HORIZONS
        vec3 viewPos = unproject(projectionInvTrans, clipPos);
        vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
    #else
        #ifndef IRIS_FEATURE_SSBO
            vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
            vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
        #else
            vec3 localPos = unproject(gbufferModelViewProjectionInverse, clipPos);
        #endif
    #endif

    // #ifndef IRIS_FEATURE_SSBO
    //     vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    // #endif

    float viewDist = length(localPos);
    vec3 localViewDir = localPos / viewDist;

    float farMax = far;// - 0.002;
    #ifdef DISTANT_HORIZONS
        farMax = 0.5*dhFarPlane;// - 0.1;
    #endif

    farMax -= 0.002 * viewDist;

    #ifdef WORLD_WATER_ENABLED
        bool isWater = isEyeInWater == 1;
        // if (isWater) farMax = 32.0;
    #else
        const bool isWater = false;
    #endif

    ivec2 iTex = ivec2(texcoord * viewSize);
    uvec3 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0).rgb;
    vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
    vec3 localNormal = deferredNormal.rgb;

    if (any(greaterThan(localNormal, EPSILON3)))
        localNormal = normalize(localNormal * 2.0 - 1.0);


    float farDist = clamp(viewDist, near, farMax);

    vec3 scatterFinal = vec3(0.0);
    vec3 transmitFinal = vec3(1.0);

    #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY || WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
        bool hasVl = false;
        // #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
        //     hasVl = true;
        // #endif
        #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
            if (isEyeInWater != 1) hasVl = true;
        #endif
        #if defined WORLD_WATER_ENABLED && WATER_VOL_FOG_TYPE == VOL_TYPE_FANCY
            if (isEyeInWater == 1) hasVl = true;
        #endif

        if (hasVl) ApplyVolumetricLighting(scatterFinal, transmitFinal, localViewDir, near, farDist, viewDist, isWater);
    #endif

    #ifdef WORLD_SKY_ENABLED //&& SKY_CLOUD_TYPE > CLOUDS_VANILLA //&& SKY_VOL_FOG_TYPE != VOL_TYPE_FANCY
        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater != 1) {
        #endif

            #if SKY_CLOUD_TYPE <= CLOUDS_VANILLA
                // #ifdef DISTANT_HORIZONS
                //     float _far = max(SkyFar, dhFarPlane);
                // #else
                //     float _far = SkyFar;
                // #endif
                float _far = SkyFar;

                if (depthTrans < 1.0)
                    _far = min(_far, viewDist);

                if (_far > farDist)
                    TraceSky(scatterFinal, transmitFinal, cameraPosition, localViewDir, farDist, _far, 16);
            #else
                #if SKY_VOL_FOG_TYPE == VOL_TYPE_FANCY
                    // const int traceStepCount = CLOUD_STEPS;

                    float cloudDistNear = farMax;

                    // #ifdef DISTANT_HORIZONS
                    //     float cloudDistFar = max(SkyFar, dhFarPlane);
                    // #else
                    //     float cloudDistFar = SkyFar;
                    // #endif
                    float cloudDistFar = SkyFar;

                    if (depthTrans < 1.0) {
                        cloudDistNear = 0.0;
                        cloudDistFar = 0.0;
                    }
                #elif SKY_VOL_FOG_TYPE == VOL_TYPE_FAST
                    // const int traceStepCount = VOLUMETRIC_SAMPLES;

                    const float cloudDistNear = 0.0;
                    float cloudDistFar = depthTrans < 1.0 ? viewDist : SkyFar;
                #else
                    // const int traceStepCount = CLOUD_STEPS;
                    // const int traceStepCount = VOLUMETRIC_SAMPLES;

                    vec3 cloudNear, cloudFar;
                    GetCloudNearFar(cameraPosition, localViewDir, cloudNear, cloudFar);
                    
                    float cloudDistNear = length(cloudNear);
                    float cloudDistFar = min(length(cloudFar), SkyFar);

                    // if (cloudDistNear > 0.0 || cloudDistFar > 0.0)
                    //     cloudDistFar = depthTrans < 1.0 ? min(cloudDistFar, viewDist) : SkyFar;
                    
                    if (depthTrans < 1.0)
                        cloudDistFar = min(cloudDistFar, viewDist);
                #endif

                if (cloudDistFar > cloudDistNear)
                    _TraceClouds(scatterFinal, transmitFinal, cameraPosition, localViewDir, cloudDistNear, cloudDistFar, 64, CLOUD_SHADOW_STEPS);
            #endif

        #ifdef WORLD_WATER_ENABLED
            }
        #endif
    #endif

    outScatter = scatterFinal;
    outTransmit = transmitFinal;
}
