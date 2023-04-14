#define RENDER_DEFERRED_RT_LIGHT
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform usampler2D BUFFER_DEFERRED_DATA;
uniform sampler2D TEX_LIGHTMAP;

#if MATERIAL_SPECULAR != SPECULAR_NONE
    uniform sampler2D BUFFER_ROUGHNESS;
#endif

#if !(defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE)
    uniform sampler2D shadowcolor0;
#endif

uniform float frameTime;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform bool firstPersonCamera;
uniform vec3 eyePosition;

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/blocks.glsl"

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/specular.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/items.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/collisions.glsl"
    #include "/lib/lighting/tracing.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL || DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/dynamic_lights.glsl"
    #include "/lib/lighting/dynamic_items.glsl"
#endif

#include "/lib/lighting/sampling.glsl"
#include "/lib/lighting/basic_hand.glsl"
#include "/lib/lighting/basic.glsl"


ivec2 GetTemporalOffset(const in int size) {
    ivec2 coord = ivec2(gl_FragCoord.xy) + frameCounter;
    return ivec2(coord.x % size, (coord.y / size) % size);
}


/* RENDERTARGETS: 4,5,6,11 */
layout(location = 0) out vec4 outDiffuse;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outDepth;
#if MATERIAL_SPECULAR != SPECULAR_NONE
    layout(location = 3) out vec4 outSpecular;
#endif

void main() {
    vec2 viewSize = vec2(viewWidth, viewHeight);
    const int resScale = int(exp2(DYN_LIGHT_RES));

    vec2 tex2 = texcoord;
    #if DYN_LIGHT_TA > 0 && DYN_LIGHT_PENUMBRA > 0
        vec2 pixelSize = rcp(viewSize);

        #if DYN_LIGHT_RES == 2
            tex2 += GetTemporalOffset(4) * pixelSize;
        #elif DYN_LIGHT_RES == 1
            tex2 += GetTemporalOffset(2) * pixelSize;
        #endif
    #endif

    float depth = textureLod(depthtex0, tex2, 0).r;
    outDepth = vec4(vec3(depth), 1.0);

    if (depth < 1.0) {
        ivec2 iTex = ivec2(tex2 * viewSize);
        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
        vec4 localNormal = unpackUnorm4x8(deferredData.r);
        vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
        vec4 deferredFog = unpackUnorm4x8(deferredData.b);

        if (any(greaterThan(localNormal.xyz, EPSILON3)))
            localNormal.xyz = normalize(localNormal.xyz * 2.0 - 1.0);

        vec3 texNormal = localNormal.xyz;
        #if MATERIAL_NORMALS != NORMALMAP_NONE
            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            texNormal = deferredTexture.xyz;

            if (any(greaterThan(texNormal, EPSILON3)))
                texNormal = normalize(texNormal * 2.0 - 1.0);
        #endif

        float roughL = 1.0;
        float metal_f0 = 0.04;
        float emission = deferredLighting.a;
        float sss = localNormal.w;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            vec2 specularMap = texelFetch(BUFFER_ROUGHNESS, iTex, 0).rg;
            roughL = max(_pow2(specularMap.r), ROUGH_MIN);
            metal_f0 = specularMap.g;
        #endif

        vec3 clipPos = vec3(tex2, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

        vec3 blockDiffuse = vec3(0.0);
        vec3 blockSpecular = vec3(0.0);
        GetFinalBlockLighting(blockDiffuse, blockSpecular, localPos, localNormal.xyz, texNormal, deferredLighting.x, roughL, metal_f0, emission, sss);
        blockDiffuse *= 1.0 - deferredFog.a;

        outDiffuse = vec4(blockDiffuse, 1.0);

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outSpecular = vec4(blockSpecular, 1.0);
        #endif

        #if MATERIAL_NORMALS != NORMALMAP_NONE
            outNormal = vec4(texNormal * 0.5 + 0.5, 1.0);
        #else
            outNormal = vec4(localNormal.xyz * 0.5 + 0.5, 1.0);
        #endif
    }
    else {
        outDiffuse = vec4(0.0, 0.0, 0.0, 1.0);
        outNormal = vec4(0.0, 0.0, 0.0, 1.0);

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            outSpecular = vec4(0.0, 0.0, 0.0, 1.0);
        #endif
    }
}
