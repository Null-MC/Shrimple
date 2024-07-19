#define RENDER_OPAQUE_RT_LIGHT
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform usampler2D BUFFER_DEFERRED_DATA;
uniform sampler2D BUFFER_DEFERRED_NORMAL_TEX;
uniform sampler2D TEX_LIGHTMAP;

#ifndef RENDER_SHADOWS_ENABLED
    uniform sampler2D shadowcolor0;
#endif

uniform float frameTime;
uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float near;
uniform float far;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform bool firstPersonCamera;
uniform vec3 eyePosition;
uniform vec3 upPosition;
uniform vec3 fogColor;

uniform float blindnessSmooth;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform float rainStrength;
    uniform float weatherStrength;
    uniform vec3 skyColor;
#endif

#if defined WORLD_SHADOW_ENABLED
    uniform vec3 shadowLightPosition;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
#endif

#ifdef IS_IRIS
    uniform bool isSpectator;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"
    #include "/lib/buffers/block_voxel.glsl"
    #include "/lib/buffers/light_static.glsl"
    #include "/lib/buffers/light_voxel.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/lights.glsl"

#include "/lib/utility/anim.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/hcm.glsl"
    #include "/lib/material/fresnel.glsl"
#endif

#ifdef LIGHTING_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#include "/lib/lighting/voxel/mask.glsl"
#include "/lib/lighting/voxel/block_mask.glsl"
#include "/lib/lighting/voxel/light_mask.glsl"
#include "/lib/lighting/voxel/lights.glsl"
#include "/lib/lighting/voxel/lights_render.glsl"
#include "/lib/lighting/voxel/blocks.glsl"

#include "/lib/lighting/voxel/tinting.glsl"
#include "/lib/lighting/voxel/tracing.glsl"

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/items.glsl"
    
    #include "/lib/lighting/basic_hand.glsl"
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

#include "/lib/utility/temporal_offset.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


layout(location = 0) out vec4 outDiffuse;
#if MATERIAL_SPECULAR != SPECULAR_NONE
    /* RENDERTARGETS: 4,11 */
    layout(location = 1) out vec4 outSpecular;
#else
    /* RENDERTARGETS: 4 */
#endif

void main() {
    const int resScale = int(exp2(LIGHTING_TRACE_RES));

    vec2 tex2 = texcoord;
    tex2 += 0.5 * pixelSize;

    #if LIGHTING_TRACE_RES == 2
        tex2 += GetTemporalOffset() * pixelSize * 0.25;
        tex2 -= 2.0*pixelSize;
    #elif LIGHTING_TRACE_RES == 1
        tex2 += GetTemporalOffset() * pixelSize * 0.5;
        tex2 -= pixelSize;
    #endif

    ivec2 iTex = ivec2(tex2 * viewSize);

    #ifdef EFFECT_TAA_ENABLED
        tex2 -= getJitterOffset(frameCounter);
    #endif

    // float depth = textureLod(depthtex1, tex2, 0).r;
    float depth = texelFetch(depthtex1, iTex, 0).r;
    //float handClipDepth = textureLod(depthtex2, tex2, 0).r;
    //bool isHand = handClipDepth > depth;
    
    // if (handClipDepth > depth) {
    //     depth = depth * 2.0 - 1.0;
    //     depth /= MC_HAND_DEPTH;
    //     depth = depth * 0.5 + 0.5;
    // }

    if (depth < 1.0) {
        vec3 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;
        vec3 texNormal = texelFetch(BUFFER_DEFERRED_NORMAL_TEX, iTex, 0).rgb;

        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
        vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
        vec4 deferredLighting = unpackUnorm4x8(deferredData.g);

        vec3 albedo = RGBToLinear(deferredColor);

        vec3 localNormal = deferredNormal.xyz;
        if (any(greaterThan(localNormal.xyz, EPSILON3)))
            localNormal = normalize(localNormal * 2.0 - 1.0);

        if (any(greaterThan(texNormal, EPSILON3)))
            texNormal = normalize(texNormal * 2.0 - 1.0);

        float roughL = 1.0;
        float metal_f0 = 0.04;
        float occlusion = deferredLighting.z;
        float sss = deferredNormal.w;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            vec3 deferredRoughMetalF0Porosity = unpackUnorm4x8(deferredData.a).rgb;
            float rough = deferredRoughMetalF0Porosity.r;
            metal_f0 = deferredRoughMetalF0Porosity.g;

            roughL = _pow2(rough);
        #endif

        vec3 clipPos = vec3(tex2, depth) * 2.0 - 1.0;

        #ifndef IRIS_FEATURE_SSBO
            vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
            vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
        #else
            vec3 localPos = unproject(gbufferModelViewProjectionInverse, clipPos);
        #endif

        float viewDist = length(localPos);
        float bias = GetBias_RT(viewDist);
        localPos = localNormal * bias + localPos;

        vec3 diffuseFinal = vec3(0.0);
        vec3 specularFinal = vec3(0.0);

        SampleDynamicLighting(diffuseFinal, specularFinal, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

        // #if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        //     SampleHandLight(diffuseFinal, specularFinal, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
        // #endif

        #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            SampleHandLight(diffuseFinal, specularFinal, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
        #endif

        #if SKY_TYPE == SKY_VANILLA
            vec4 deferredFog = unpackUnorm4x8(deferredData.b);
            diffuseFinal *= 1.0 - deferredFog.a;
        #endif

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            ApplyMetalDarkening(diffuseFinal, specularFinal, albedo, metal_f0, roughL);
        #endif

        outDiffuse = vec4(diffuseFinal, 1.0);

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outSpecular = vec4(specularFinal, roughL);
        #endif
    }
    else {
        outDiffuse = vec4(0.0, 0.0, 0.0, 1.0);

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outSpecular = vec4(0.0, 0.0, 0.0, 1.0);
        #endif
    }
}
