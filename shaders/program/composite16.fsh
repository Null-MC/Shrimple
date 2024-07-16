#define RENDER_TRANSLUCENT_RT_LIGHT
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform usampler2D BUFFER_DEFERRED_DATA;
uniform sampler2D BUFFER_DEFERRED_NORMAL_TEX;
uniform sampler2D TEX_LIGHTMAP;

// #if MATERIAL_SPECULAR != SPECULAR_NONE
//     uniform sampler2D BUFFER_ROUGHNESS;
// #endif

#ifndef RENDER_SHADOWS_ENABLED
    uniform sampler2D shadowcolor0;
#endif

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

    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/buffers/block_static.glsl"
        #include "/lib/buffers/block_voxel.glsl"
        //#include "/lib/buffers/lighting.glsl"
        #include "/lib/buffers/light_voxel.glsl"
    #endif
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
    #include "/lib/material/fresnel.glsl"
#endif

#if LIGHTING_MODE != LIGHTING_MODE_NONE
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #include "/lib/lights.glsl"
    
    // #include "/lib/lighting/voxel/block_light_map.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/light_mask.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/lights_render.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
    
    // #include "/lib/lighting/voxel/item_light_map.glsl"
    // #include "/lib/lighting/voxel/items.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_TRACED
    //#include "/lib/buffers/collisions.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

//#include "/lib/lighting/basic_hand.glsl"
//#include "/lib/lighting/traced.glsl"

#if LIGHTING_TRACE_RES != 0
    #include "/lib/utility/temporal_offset.glsl"
#endif


#if LIGHTING_TRACE_RES != 0
    ivec2 GetTemporalOffset(const in int size) {
        int i = int(frameCounter + gl_FragCoord.x + size*gl_FragCoord.y);
        return offsetList[i % _pow2(size)];
    }
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

    float depth = texelFetch(depthtex0, iTex, 0).r;
    //float handClipDepth = textureLod(depthtex2, tex2, 0).r;
    //bool isHand = handClipDepth > depth;
    
    // if (handClipDepth > depth) {
    //     depth = depth * 2.0 - 1.0;
    //     depth /= MC_HAND_DEPTH;
    //     depth = depth * 0.5 + 0.5;
    // }

    vec4 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0);
    //float opacity = textureLod(BUFFER_DEFERRED_COLOR, tex2, 0).a;

    if (deferredColor.a > (0.5/255.0)) {
        float depthOpaque = texelFetch(depthtex1, iTex, 0).r;

        //vec3 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;

        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
        vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
        vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
        //vec4 deferredFog = unpackUnorm4x8(deferredData.b);

        vec3 albedo = RGBToLinear(deferredColor.rgb);

        vec3 localNormal = deferredNormal.xyz;
        if (any(greaterThan(localNormal.xyz, EPSILON3)))
            localNormal = normalize(localNormal * 2.0 - 1.0);

        // vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
        // vec3 texNormal = deferredTexture.xyz;
        vec3 texNormal = texelFetch(BUFFER_DEFERRED_NORMAL_TEX, iTex, 0).rgb;

        if (any(greaterThan(texNormal, EPSILON3)))
            texNormal = normalize(texNormal * 2.0 - 1.0);

        float occlusion = deferredLighting.z;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            vec3 deferredRoughMetalF0Porosity = unpackUnorm4x8(deferredData.a).rgb;
            float roughness = _pow2(deferredRoughMetalF0Porosity.r);
            float metal_f0 = deferredRoughMetalF0Porosity.g;
            // float porosity = deferredRoughMetalF0Porosity.b;

            float sss = deferredNormal.w;
            float roughL = _pow2(roughness);
        #else
            const float roughL = 1.0;
            const float metal_f0 = 0.04;
            const float sss = 0.0;
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

        vec3 blockDiffuse = vec3(0.0);
        vec3 blockSpecular = vec3(0.0);
        //GetFinalBlockLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, sss);
        SampleDynamicLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
        //blockDiffuse *= 1.0 - deferredFog.a;

        // #if LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        //     SampleHandLight(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);
        // #endif

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            ApplyMetalDarkening(blockDiffuse, blockSpecular, albedo, metal_f0, roughL);

            // if (metal_f0 >= 0.5) {
            //     //vec3 deferredAlbedo = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;
            //     blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
            //     blockSpecular *= albedo;
            // }
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
