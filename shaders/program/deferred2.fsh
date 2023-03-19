#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform sampler2D BUFFER_DEFERRED_SHADOW;
uniform usampler2D BUFFER_DEFERRED_DATA;
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
uniform vec3 sunPosition;
uniform vec3 upPosition;
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

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
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

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/collisions.glsl"
    #include "/lib/lighting/tracing.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
#endif

#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"
#include "/lib/lighting/basic.glsl"
#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

vec3 BilateralGaussianBlur(const in vec2 texcoord, const in float linearDepth, const in vec3 normal, const in vec3 g_sigma) {
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    const float lightBufferScale = exp2(DYN_LIGHT_RES);
    const float lightBufferScaleInv = rcp(lightBufferScale);

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 lightBufferSize = viewSize * lightBufferScaleInv;
    vec2 blendPixelSize = rcp(lightBufferSize);

    float total = 0.0;
    vec3 accum = vec3(0.0);
    //vec3 defaultColor;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            vec2 sampleTex = vec2(ix, iy);

            vec2 sampleBlendTex = texcoord + sampleTex * blendPixelSize;
            vec3 sampleValue = textureLod(BUFFER_BLOCKLIGHT, sampleBlendTex, 0).rgb;

            //if (abs(iy) < EPSILON && abs(ix) < EPSILON) defaultColor = sampleValue;

            //ivec2 iTexLight = ivec2(texcoord * lightBufferSize + sampleTex);
            vec3 sampleNormal = textureLod(BUFFER_LIGHT_NORMAL, sampleBlendTex, 0).rgb;
            float sampleDepth = textureLod(BUFFER_LIGHT_DEPTH, sampleBlendTex, 0).r;

            // ivec2 iTexLight = ivec2(texcoord * viewSize + sampleTex / lightBufferScale);
            // float handClipDepth = texelFetch(depthtex2, iTexLight, 0).r;
            // if (handClipDepth > sampleDepth) {
            //     sampleDepth = sampleDepth * 2.0 - 1.0;
            //     sampleDepth /= MC_HAND_DEPTH;
            //     sampleDepth = sampleDepth * 0.5 + 0.5;
            // }

            sampleNormal = normalize(sampleNormal * 2.0 - 1.0);
            sampleDepth = linearizeDepthFast(sampleDepth, near, far);
            
            float normalWeight = 1.0 - dot(normal, sampleNormal);
            float fv = Gaussian(g_sigma.z, 10.0*abs(sampleDepth - linearDepth) + normalWeight);
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return vec3(0.0);
    return accum / total;
}

void main() {
    ivec2 iTex = ivec2(gl_FragCoord.xy);
    float depth = texelFetch(depthtex0, iTex, 0).r;
    vec3 final;

    if (depth < 1.0) {
        vec2 viewSize = vec2(viewWidth, viewHeight);

        vec3 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;
        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
        vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
        vec4 deferredFog = unpackUnorm4x8(deferredData.a);

        float linearDepth = linearizeDepthFast(depth, near, far);

        #ifdef SHADOW_BLUR
            float shadowSigma = 3.0 / linearDepth;

            #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
                vec3 deferredShadow = BilateralGaussianDepthBlurRGB_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma);
            #else
                vec3 deferredShadow = vec3(BilateralGaussianDepthBlur_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma));
            #endif
        #else
            vec3 deferredShadow = unpackUnorm4x8(deferredData.b).rgb;
        #endif

        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

        vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
        vec3 localNormal = normalize(deferredNormal.rgb * 2.0 - 1.0);

        float emission = deferredLighting.a;
        float sss = deferredNormal.a;

        #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            #ifdef DYN_LIGHT_BLUR
                const vec3 lightSigma = vec3(1.2, 1.2, 0.2);// / linearDepth;
                vec3 blockLight = BilateralGaussianBlur(texcoord, linearDepth, localNormal, lightSigma);
            #else
                #if DYN_LIGHT_RES == 0
                    vec3 blockLight = texelFetch(BUFFER_BLOCKLIGHT, iTex, 0).rgb;
                #else
                    vec3 blockLight = textureLod(BUFFER_BLOCKLIGHT, texcoord, 0).rgb;
                #endif
            #endif
        #elif defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
            vec3 blockLight = GetFinalBlockLighting(localPos, localNormal, deferredLighting.x, emission, sss);
        #else
            vec3 blockLight = textureLod(TEX_LIGHTMAP, vec2(deferredLighting.x, 1.0/32.0), 0).rgb;
            blockLight = RGBToLinear(blockLight);
        #endif

        vec3 albedo = RGBToLinear(deferredColor);
        final = GetFinalLighting(albedo, blockLight, deferredShadow, deferredLighting.y, deferredLighting.z);

        vec3 fogColorFinal = RGBToLinear(deferredFog.rgb);
        final = mix(final, fogColorFinal, deferredFog.a);

        ApplyPostProcessing(final);
    }
    else {
        #ifdef WORLD_SKY_ENABLED
            final = texelFetch(BUFFER_FINAL, iTex, 0).rgb;
        #else
            final = RGBToLinear(fogColor) * GetWorldBrightnessF();
            ApplyPostProcessing(final);
        #endif
    }

    outFinal = vec4(final, 1.0);
}
