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

#if defined IRIS_FEATURE_SSBO && VOLUMETRIC_BRIGHT_BLOCK > 0 && LPV_SIZE > 0 //&& !defined VOLUMETRIC_BLOCK_RT
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if VOLUMETRIC_BRIGHT_SKY > 0
        uniform sampler2D shadowtex0;
        uniform sampler2D shadowtex1;

        #if defined SHADOW_ENABLE_HWCOMP && defined IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex1HW;
        #endif

        #ifdef SHADOW_COLORED
            uniform sampler2D shadowcolor0;
        #endif
    #endif
    
    #ifdef SHADOW_CLOUD_ENABLED
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
    uniform float cloudTime;
    uniform vec3 eyePosition;
#endif

#include "/lib/anim.glsl"

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"

    #if VOLUMETRIC_BRIGHT_BLOCK > 0 && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        #include "/lib/blocks.glsl"

        #ifdef DYN_LIGHT_FLICKER
            #include "/lib/lighting/blackbody.glsl"
            #include "/lib/lighting/flicker.glsl"
        #endif

        #include "/lib/lights.glsl"
        #include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/fresnel.glsl"
        #include "/lib/lighting/voxel/mask.glsl"
        #include "/lib/lighting/voxel/block_mask.glsl"
        #include "/lib/lighting/voxel/blocks.glsl"

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined VOLUMETRIC_BLOCK_RT
            #include "/lib/lighting/voxel/light_mask.glsl"

            #include "/lib/buffers/collissions.glsl"
            #include "/lib/lighting/voxel/tinting.glsl"
            #include "/lib/lighting/voxel/tracing.glsl"
        #endif

        #include "/lib/lighting/voxel/lights.glsl"

        #ifdef VOLUMETRIC_HANDLIGHT
            #include "/lib/items.glsl"
            #include "/lib/lighting/voxel/items.glsl"
        #endif

        #include "/lib/lighting/sampling.glsl"

        #if VOLUMETRIC_BRIGHT_BLOCK > 0 && LPV_SIZE > 0
            #include "/lib/lighting/voxel/lpv.glsl"
            #include "/lib/lighting/voxel/lpv_render.glsl"
        #endif
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

#if VOLUMETRIC_BRIGHT_SKY > 0 && defined WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
    #include "/lib/world/fog.glsl"

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/buffers/shadow.glsl"

        #ifdef RENDER_CLOUD_SHADOWS_ENABLED
            #include "/lib/shadows/clouds.glsl"
        #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #include "/lib/shadows/cascaded.glsl"
            #include "/lib/shadows/cascaded_render.glsl"
        #else
            #include "/lib/shadows/basic.glsl"
            #include "/lib/shadows/basic_render.glsl"
        #endif
    #endif
#endif

#include "/lib/lighting/hg.glsl"
#include "/lib/world/volumetric_fog.glsl"


/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 outVL;

void main() {
    float depthOpaque = textureLod(depthtex1, texcoord, 0).r;
    float depthTranslucent = textureLod(depthtex0, texcoord, 0).r;

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

        vec3 localViewDir = normalize(localPosOpaque);
        float distOpaque = clamp(length(localPosOpaque), near, far);
        float distTranslucent = clamp(length(localPosTranslucent), near, far);
        VolumetricPhaseFactors phaseF;


        bool isWater = false;
        #ifdef WORLD_WATER_ENABLED
            if (isEyeInWater != 1) {
                float deferredShadowA = texelFetch(BUFFER_DEFERRED_SHADOW, ivec2(gl_FragCoord.xy), 0).a;
                isWater = deferredShadowA < 0.5;
            }

            phaseF = isWater ? WaterPhaseF : GetVolumetricPhaseFactors();
        #else
            phaseF = GetVolumetricPhaseFactors();
        #endif

        float d = clamp(distOpaque * 0.05, 0.02, 0.5);
        vec3 endPos = localPosOpaque;// + localNormal * d;
        float endDist = clamp(length(endPos) - 0.4 * d, near, far);

        final = GetVolumetricLighting(phaseF, localViewDir, localSunDirection, distTranslucent, endDist, isWater);
    }

    outVL = final;
}
