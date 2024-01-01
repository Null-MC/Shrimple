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
uniform sampler2D TEX_LIGHTMAP;

#if MATERIAL_SPECULAR != SPECULAR_NONE
    uniform sampler2D BUFFER_ROUGHNESS;
#endif

#if !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE)
    uniform sampler2D shadowcolor0;
#endif

// #if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 && LIGHTING_MODE != DYN_LIGHT_NONE
//     uniform sampler3D texLPV_1;
//     uniform sampler3D texLPV_2;
// #endif

uniform float frameTime;
//uniform float frameTimeCounter;
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
    uniform float skyRainStrength;
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
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/utility/anim.glsl"

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/hcm.glsl"
    #include "/lib/material/specular.glsl"
#endif

#if LIGHTING_MODE == DYN_LIGHT_LPV || LIGHTING_MODE == DYN_LIGHT_TRACED
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #include "/lib/lights.glsl"
    #include "/lib/buffers/collisions.glsl"
    #include "/lib/buffers/lighting.glsl"
    // #include "/lib/lighting/voxel/block_light_map.glsl"
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/light_mask.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/lights_render.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/items.glsl"
#endif

#if LIGHTING_MODE == DYN_LIGHT_TRACED
    // #include "/lib/buffers/collisions.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

// #if LPV_SIZE > 0 && LIGHTING_MODE != DYN_LIGHT_NONE
//     #include "/lib/buffers/volume.glsl"
//     #include "/lib/lighting/voxel/lpv.glsl"
// #endif

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"
//#include "/lib/lighting/basic.glsl"

#include "/lib/utility/temporal_offset.glsl"


/* RENDERTARGETS: 4,11 */
layout(location = 0) out vec4 outDiffuse;
// layout(location = 1) out vec4 outNormal;
// layout(location = 2) out vec4 outDepth;
#if MATERIAL_SPECULAR != SPECULAR_NONE
    layout(location = 3) out vec4 outSpecular;
#endif

void main() {
    //vec2 viewSize = vec2(viewWidth, viewHeight);
    const int resScale = int(exp2(LIGHTING_TRACE_RES));

    vec2 tex2 = texcoord;
    // #if LIGHTING_TRACE_TEMP_ACCUM > 0 //&& LIGHTING_TRACE_PENUMBRA > 0
        #if LIGHTING_TRACE_RES == 2
            tex2 += GetTemporalOffset() * pixelSize * 0.25;
        #elif LIGHTING_TRACE_RES == 1
            tex2 += GetTemporalOffset() * pixelSize * 0.5;
        #endif
    // #endif

    float depth = textureLod(depthtex1, tex2, 0).r;
    //float handClipDepth = textureLod(depthtex2, tex2, 0).r;
    //bool isHand = handClipDepth > depth;
    
    // if (handClipDepth > depth) {
    //     depth = depth * 2.0 - 1.0;
    //     depth /= MC_HAND_DEPTH;
    //     depth = depth * 0.5 + 0.5;
    // }

    // outDepth = vec4(vec3(depth), 1.0);

    if (depth < 1.0) {
        ivec2 iTex = ivec2(tex2 * viewSize);

        vec3 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;

        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
        vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
        vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
        vec4 deferredTexture = unpackUnorm4x8(deferredData.a);

        vec3 albedo = RGBToLinear(deferredColor);

        vec3 localNormal = deferredNormal.xyz;
        if (any(greaterThan(localNormal.xyz, EPSILON3)))
            localNormal = normalize(localNormal * 2.0 - 1.0);

        vec3 texNormal = deferredTexture.xyz;

        if (any(greaterThan(texNormal, EPSILON3)))
            texNormal = normalize(texNormal * 2.0 - 1.0);

        float roughL = 1.0;
        float metal_f0 = 0.04;
        float occlusion = deferredLighting.z;
        float sss = deferredNormal.w;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            vec2 specularMap = texelFetch(BUFFER_ROUGHNESS, iTex, 0).rg;
            float rough = specularMap.r;
            roughL = _pow2(rough);
            metal_f0 = specularMap.g;
        #endif

        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;

        #ifndef IRIS_FEATURE_SSBO
            vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
            vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        #else
            vec3 localPos = unproject(gbufferModelViewProjectionInverse * vec4(clipPos, 1.0));
        #endif

        vec3 blockDiffuse = vec3(0.0);
        vec3 blockSpecular = vec3(0.0);
        //GetFinalBlockLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, sss);
        SampleDynamicLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

        #if defined LIGHT_HAND_SOFT_SHADOW && LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            SampleHandLight(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
        #endif

        #if SKY_TYPE == SKY_VANILLA
            vec4 deferredFog = unpackUnorm4x8(deferredData.b);
            blockDiffuse *= 1.0 - deferredFog.a;
        #endif

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            #if MATERIAL_SPECULAR == SPECULAR_LABPBR
                if (IsMetal(metal_f0))
                    blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, rough);
            #else
                blockDiffuse *= mix(vec3(1.0), albedo, metal_f0 * (1.0 - roughL));
            #endif

            blockSpecular *= GetMetalTint(albedo, metal_f0);
        #endif

        // if (!all(lessThan(abs(texNormal), EPSILON3)))
        //     texNormal = texNormal * 0.5 + 0.5;

        outDiffuse = vec4(blockDiffuse, 1.0);
        // outNormal = vec4(texNormal, 1.0);

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outSpecular = vec4(blockSpecular, roughL);
        #endif
    }
    else {
        outDiffuse = vec4(0.0, 0.0, 0.0, 1.0);
        // outNormal = vec4(0.0, 0.0, 0.0, 1.0);

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outSpecular = vec4(0.0, 0.0, 0.0, 1.0);
        #endif
    }
}
