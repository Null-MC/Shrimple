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

#ifdef VL_BUFFER_ENABLED
    uniform sampler2D BUFFER_VL;
#endif

#ifdef DYN_LIGHT_TA
    uniform sampler2D BUFFER_LIGHT_TA;
    uniform sampler2D BUFFER_LIGHT_TA_NORMAL;
    uniform sampler2D BUFFER_LIGHT_TA_DEPTH;
#endif

uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
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

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/dynamic.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/collisions.glsl"
    #include "/lib/lighting/tracing.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/lighting/dynamic_blocks.glsl"
    #include "/lib/lighting/dynamic_items.glsl"
#endif

#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"
#include "/lib/lighting/basic.glsl"
#include "/lib/post/tonemap.glsl"


vec3 BilateralGaussianBlur(const in vec2 texcoord, const in float linearDepth, const in vec3 normal, const in vec3 g_sigma) {
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    const float lightBufferScale = exp2(DYN_LIGHT_RES);
    const float lightBufferScaleInv = rcp(lightBufferScale);

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 lightBufferSize = viewSize * lightBufferScaleInv;
    vec2 blendPixelSize = rcp(lightBufferSize);
    vec2 screenPixelSize = rcp(viewSize);

    float total = 0.0;
    vec3 accum = vec3(0.0);
    //vec3 defaultColor;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);

            //vec2 sampleBlendTex = texcoord - 0.5 * screenPixelSize + (vec2(ix, iy) + 0.5) * blendPixelSize;
            vec2 sampleBlendTex = texcoord - vec2(ix, iy) * blendPixelSize;
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
            
            float normalWeight = max(dot(normal, sampleNormal), 0.0);
            //float fv = Gaussian(g_sigma.z, 10.0*abs(sampleDepth - linearDepth) + 6.0*(1.0 - normalWeight));
            float fv = Gaussian(g_sigma.z, abs(sampleDepth - linearDepth) + 12.0*(1.0 - normalWeight));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return vec3(0.0);
    return accum / total;
}

vec4 BilateralGaussianDepthBlur_VL(const in vec2 texcoord, const in sampler2D blendSampler, const in vec2 blendTexSize, const in sampler2D depthSampler, const in vec2 depthTexSize, const in float linearDepth, const in vec3 g_sigma) {
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    float total = 0.0;
    vec4 accum = vec4(0.0);

    vec2 blendPixelSize = rcp(blendTexSize);
    //vec2 blendTexcoord = texcoord * blendTexSize;
    vec2 depthTexcoord = texcoord * depthTexSize;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            
            vec2 sampleTex = vec2(ix, iy);

            vec2 texBlend = texcoord + sampleTex * blendPixelSize;
            vec4 sampleValue = textureLod(blendSampler, texBlend, 0);

            ivec2 iTexDepth = ivec2(depthTexcoord + sampleTex);
            float sampleDepth = texelFetch(depthSampler, iTexDepth, 0).r;
            float sampleLinearDepth = linearizeDepthFast(sampleDepth, near, far);
                        
            float fv = Gaussian(g_sigma.z, abs(sampleLinearDepth - linearDepth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    //if (total <= EPSILON) return vec4(0.0);
    return accum / max(total, EPSILON);
}

ivec2 GetTemporalOffset(const in int size) {
    ivec2 coord = ivec2(gl_FragCoord.xy) + frameCounter;
    return ivec2(coord.x % size, (coord.y / size) % size);
}


#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    /* RENDERTARGETS: 0,7,8,9 */
    layout(location = 0) out vec4 outFinal;
    layout(location = 1) out vec4 outTA;
    layout(location = 2) out vec4 outTA_Normal;
    layout(location = 3) out vec4 outTA_Depth;
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
    ivec2 iTex = ivec2(gl_FragCoord.xy);
    vec2 viewSize = vec2(viewWidth, viewHeight);

    float depth = texelFetch(depthtex0, iTex, 0).r;
    float linearDepth = linearizeDepthFast(depth, near, far);
    vec3 final;

    vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));

    if (depth < 1.0) {
        vec3 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;
        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
        vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
        vec4 deferredFog = unpackUnorm4x8(deferredData.b);

        vec3 texNormal = vec3(0.0);
        #if MATERIAL_NORMALS != NORMALMAP_NONE
            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            texNormal = deferredTexture.rgb;

            if (any(greaterThan(texNormal, EPSILON3)))
                texNormal = normalize(texNormal * 2.0 - 1.0);
        #endif

        #ifdef SHADOW_BLUR
            #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
                const vec3 shadowSigma = vec3(1.2, 1.2, 0.06);// / linearDepth;
                vec3 deferredShadow = BilateralGaussianDepthBlurRGB_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma);
            #else
                float shadowSigma = 3.0 / linearDepth;
                vec3 deferredShadow = vec3(BilateralGaussianDepthBlur_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma));
            #endif
        #else
            vec3 deferredShadow = unpackUnorm4x8(deferredData.b).rgb;
        #endif

        vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

        vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
        vec3 localNormal = deferredNormal.rgb;

        if (any(greaterThan(localNormal, EPSILON3)))
            localNormal = normalize(localNormal * 2.0 - 1.0);

        float emission = deferredLighting.a;
        float sss = deferredNormal.a;

        #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            float depthLinear = linearizeDepthFast(depth, near, far);

            #ifdef DYN_LIGHT_BLUR
                const vec3 lightSigma = vec3(1.2, 1.2, 0.2);// / depthLinear;
                #if MATERIAL_NORMALS != NORMALMAP_NONE
                    vec3 blockLight = BilateralGaussianBlur(texcoord, depthLinear, texNormal, lightSigma);
                #else
                    vec3 blockLight = BilateralGaussianBlur(texcoord, depthLinear, localNormal, lightSigma);
                #endif
            #elif DYN_LIGHT_RES == 0
                vec3 blockLight = texelFetch(BUFFER_BLOCKLIGHT, iTex, 0).rgb;
            #else
                vec3 blockLight = textureLod(BUFFER_BLOCKLIGHT, texcoord, 0).rgb;
            #endif

            #ifdef DYN_LIGHT_TA
                // Use prev value if downscale depth/normal doesnt match
                #if DYN_LIGHT_RES > 0
                    // TODO
                #endif

                vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;
                vec3 viewPosPrev = (gbufferPreviousModelView * vec4(localPosPrev, 1.0)).xyz;
                vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));
                vec3 uvPrev = clipPosPrev * 0.5 + 0.5;

                if (all(greaterThanEqual(uvPrev.xy, vec2(0.0))) && all(lessThan(uvPrev.xy, vec2(1.0)))) {
                    float depthPrev = textureLod(BUFFER_LIGHT_TA_DEPTH, uvPrev.xy, 0).r;
                    float depthPrevLinear1 = linearizeDepthFast(uvPrev.z, near, far);
                    float depthPrevLinear2 = linearizeDepthFast(depthPrev, near, far);

                    if (abs(depthPrevLinear1 - depthPrevLinear2) < 0.06) {// && normalWeight < 0.06) {
                        vec3 blockLightPrev = textureLod(BUFFER_LIGHT_TA, uvPrev.xy, 0).rgb;

                        float lum = log(luminance(blockLight));
                        float lumPrev = log(luminance(blockLightPrev));

                        float lumDiff = saturate(abs(lum - lumPrev));
                        float weight = smoothstep(0.0, 0.8, lumDiff)*0.25 + 0.02;

                        blockLight = mix(blockLightPrev, blockLight, weight);
                    }
                }

                outTA = vec4(blockLight, 1.0);
                outTA_Normal = vec4(localNormal * 0.5 + 0.5, 1.0);
                outTA_Depth = vec4(depth, 0.0, 0.0, 1.0);
            #endif
        #elif defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
            vec3 blockLight = GetFinalBlockLighting(localPos, localNormal, texNormal, deferredLighting.x, emission, sss);
        #else
            vec3 blockLight = textureLod(TEX_LIGHTMAP, vec2(deferredLighting.x, 1.0/32.0), 0).rgb;
            blockLight = RGBToLinear(blockLight);
        #endif

        vec3 albedo = RGBToLinear(deferredColor);
        final = GetFinalLighting(albedo, blockLight, deferredShadow, deferredLighting.xy, deferredLighting.z);

        vec3 fogColorFinal = RGBToLinear(deferredFog.rgb);
        final = mix(final, fogColorFinal, deferredFog.a);
    }
    else {
        #ifdef WORLD_SKY_ENABLED
            final = texelFetch(BUFFER_FINAL, iTex, 0).rgb;
            final = RGBToLinear(final);
        #else
            final = RGBToLinear(fogColor) * GetWorldBrightnessF();
        #endif
    }

    #ifdef VL_BUFFER_ENABLED
        //vec4 vlScatterTransmit = textureLod(BUFFER_VL, texcoord, 0);

        #if VOLUMETRIC_RES == 2
            const vec3 vlSigma = vec3(0.5, 0.5, 48.0);
        #elif VOLUMETRIC_RES == 1
            const vec3 vlSigma = vec3(1.8, 1.8, 24.0);
        #else
            const vec3 vlSigma = vec3(0.5, 0.5, 48.0);
        #endif

        const float bufferScale = rcp(exp2(VOLUMETRIC_RES));

        float maxDist = min(far, length(viewPos));
        vec4 vlScatterTransmit = BilateralGaussianDepthBlur_VL(texcoord, BUFFER_VL, viewSize * bufferScale, depthtex0, viewSize, maxDist, vlSigma);
        final = final * vlScatterTransmit.a + vlScatterTransmit.rgb;
    #endif

    ApplyPostProcessing(final);

    final.rgb += InterleavedGradientNoise(gl_FragCoord.xy) / 255.0;

    outFinal = vec4(final, 1.0);
}
