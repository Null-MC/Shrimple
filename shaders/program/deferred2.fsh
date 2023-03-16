#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D BUFFER_FINAL;
uniform usampler2D BUFFER_DEFERRED_PRE;
uniform usampler2D BUFFER_DEFERRED_POST;
uniform sampler2D BUFFER_BLOCKLIGHT;
uniform sampler2D BUFFER_LIGHT_NORMAL;
uniform sampler2D BUFFER_LIGHT_DEPTH;
uniform sampler2D TEX_LIGHTMAP;

uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

uniform float blindness;

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif
#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/bilateral_gaussian.glsl"

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/buffers/lighting.glsl"
#include "/lib/lighting/blackbody.glsl"
#include "/lib/lighting/dynamic.glsl"
#include "/lib/lighting/collisions.glsl"
#include "/lib/lighting/tracing.glsl"
#include "/lib/lighting/dynamic_blocks.glsl"

#include "/lib/world/fog.glsl"
#include "/lib/lighting/basic.glsl"
#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

vec3 BilateralGaussianBlur(const in vec2 texcoord, const in float linearDepth, const in vec3 normal, const in vec3 g_sigma) {
    const float c_halfSamplesX = 3.0;
    const float c_halfSamplesY = 3.0;

    const float lightBufferScale = rcp(exp2(DYN_LIGHT_RES));

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 lightBufferSize = viewSize * lightBufferScale;
    vec2 blendPixelSize = rcp(lightBufferSize);

    float total = 0.0;
    vec3 accum = vec3(0.0);
    vec3 defaultColor;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            vec2 sampleTex = vec2(ix, iy);

            vec2 sampleBlendTex = texcoord + sampleTex * blendPixelSize;
            vec3 sampleValue = textureLod(BUFFER_BLOCKLIGHT, sampleBlendTex, 0).rgb;

            if (abs(iy) < EPSILON && abs(ix) < EPSILON) defaultColor = sampleValue;

            ivec2 iTexLight = ivec2(texcoord * lightBufferSize + sampleTex);
            vec3 sampleNormal = texelFetch(BUFFER_LIGHT_NORMAL, iTexLight, 0).rgb;
            float sampleDepth = texelFetch(BUFFER_LIGHT_DEPTH, iTexLight, 0).r;

            iTexLight = ivec2(texcoord * viewSize + sampleTex / lightBufferScale);
            float handClipDepth = texelFetch(depthtex2, iTexLight, 0).r;
            if (handClipDepth > sampleDepth) {
                sampleDepth = sampleDepth * 2.0 - 1.0;
                sampleDepth /= MC_HAND_DEPTH;
                sampleDepth = sampleDepth * 0.5 + 0.5;
            }

            sampleNormal = normalize(sampleNormal * 2.0 - 1.0);
            sampleDepth = linearizeDepthFast(sampleDepth, near, far);
            
            float normalWeight = 1.0 - dot(normal, sampleNormal);
            float fv = Gaussian(g_sigma.z, abs(sampleDepth - linearDepth) + 100.0*normalWeight);
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return defaultColor;
    return accum / total;
}

void main() {
    ivec2 iTex = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex0, iTex, 0).r;
    vec3 final;

    if (depth < 1.0) {
        vec2 viewSize = vec2(viewWidth, viewHeight);

        uvec3 deferredPre = texelFetch(BUFFER_DEFERRED_PRE, iTex, 0).rgb;
        vec3 deferredColor = unpackUnorm4x8(deferredPre.r).rgb;
        vec3 deferredNormal = unpackUnorm4x8(deferredPre.g).rgb;
        vec3 deferredLighting = unpackUnorm4x8(deferredPre.b).rgb;

        uvec2 deferredPost = texelFetch(BUFFER_DEFERRED_POST, iTex, 0).rg;
        vec3 deferredShadow = unpackUnorm4x8(deferredPost.r).rgb;
        vec4 deferredFog = unpackUnorm4x8(deferredPost.g);

        float linearDepth = linearizeDepthFast(depth, near, far);
        const vec3 sigma = vec3(3.0, 3.0, 0.002) / linearDepth;

        deferredNormal = normalize(deferredNormal * 2.0 - 1.0);

        #ifdef DYN_LIGHT_BLUR
            vec3 blockLight = BilateralGaussianBlur(texcoord, linearDepth, deferredNormal, sigma);
        #else
            #if DYN_LIGHT_RES == 0
                vec3 blockLight = texelFetch(BUFFER_BLOCKLIGHT, iTex, 0).rgb;
            #else
                vec3 blockLight = textureLod(BUFFER_BLOCKLIGHT, texcoord, 0).rgb;
            #endif
        #endif

        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

        vec3 albedo = RGBToLinear(deferredColor);
        final = GetFinalLighting(albedo, blockLight, deferredShadow, viewPos, deferredLighting.xy, deferredLighting.z);

        vec3 fogColorFinal = RGBToLinear(deferredFog.rgb);
        final = mix(final, fogColorFinal, deferredFog.a);

        ApplyPostProcessing(final);
    }
    else {
        #ifdef WORLD_SKY_ENABLED
            final = texelFetch(BUFFER_FINAL, iTex, 0).rgb;
        #else
            final = RGBToLinear(fogColor) * WorldBrightnessF;
            ApplyPostProcessing(final);
        #endif
    }

    outFinal = vec4(final, 1.0);
}
