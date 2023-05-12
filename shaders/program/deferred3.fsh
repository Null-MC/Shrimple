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
uniform sampler2D BUFFER_BLOCK_DIFFUSE;
uniform sampler2D BUFFER_LIGHT_NORMAL;
uniform sampler2D BUFFER_LIGHT_DEPTH;
uniform sampler2D TEX_LIGHTMAP;

#if MATERIAL_SPECULAR != SPECULAR_NONE
    uniform sampler2D BUFFER_ROUGHNESS;
    uniform sampler2D BUFFER_BLOCK_SPECULAR;
    uniform sampler2D BUFFER_TA_SPECULAR;
#endif

#ifdef VL_BUFFER_ENABLED
    uniform sampler2D BUFFER_VL;
#endif

#if DYN_LIGHT_TA > 0
    uniform sampler2D BUFFER_LIGHT_TA;
    uniform sampler2D BUFFER_LIGHT_TA_NORMAL;
    uniform sampler2D BUFFER_LIGHT_TA_DEPTH;
#endif

uniform int frameCounter;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
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

#ifndef IRIS_FEATURE_SSBO
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferPreviousProjection;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform vec3 shadowLightPosition;
    uniform float rainStrength;
    //uniform float wetness;
#endif

#if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
    uniform int worldTime;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
#endif

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/sampling/bilateral_gaussian.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"

#ifdef DYN_LIGHT_FLICKER
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
#endif

#if MATERIAL_SPECULAR != SPECULAR_NONE
    #include "/lib/material/specular.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    //#include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/buffers/collissions.glsl"
    #include "/lib/lighting/voxel/collisions.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

#include "/lib/lighting/voxel/lights.glsl"

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#include "/lib/lighting/voxel/items.glsl"

#include "/lib/lighting/basic_hand.glsl"
#include "/lib/lighting/basic.glsl"

#include "/lib/post/saturation.glsl"
#include "/lib/post/tonemap.glsl"


void BilateralGaussianBlur(out vec3 blockDiffuse, out vec3 blockSpecular, const in vec2 texcoord, const in float linearDepth, const in vec3 normal, const in vec3 g_sigma) {
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    const float lightBufferScale = exp2(DYN_LIGHT_RES);
    const float lightBufferScaleInv = rcp(lightBufferScale);

    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 lightBufferSize = viewSize * lightBufferScaleInv;
    vec2 blendPixelSize = rcp(lightBufferSize);
    vec2 screenPixelSize = rcp(viewSize);

    float total = 0.0;
    vec3 accumDiffuse = vec3(0.0);
    vec3 accumSpecular = vec3(0.0);

    bool hasNormal = any(greaterThan(normal, EPSILON3));
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.y, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);

            vec2 sampleBlendTex = texcoord - vec2(ix, iy) * blendPixelSize;
            vec3 sampleDiffuse = textureLod(BUFFER_BLOCK_DIFFUSE, sampleBlendTex, 0).rgb;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                vec3 sampleSpecular = textureLod(BUFFER_BLOCK_SPECULAR, sampleBlendTex, 0).rgb;
            #endif

            float sampleDepth = textureLod(BUFFER_LIGHT_DEPTH, sampleBlendTex, 0).r;

            sampleDepth = linearizeDepthFast(sampleDepth, near, far);
            
            float normalWeight = 1.0;
            if (hasNormal) {
                vec3 sampleNormal = textureLod(BUFFER_LIGHT_NORMAL, sampleBlendTex, 0).rgb;

                if (any(greaterThan(sampleNormal, EPSILON3))) {
                    sampleNormal = normalize(sampleNormal * 2.0 - 1.0);

                    normalWeight = max(dot(normal, sampleNormal), 0.0);
                }
            }
            
            float fv = Gaussian(g_sigma.z, abs(sampleDepth - linearDepth) + 16.0*(1.0 - normalWeight));
            
            float weight = fx*fy*fv;
            accumDiffuse += weight * sampleDiffuse;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                accumSpecular += weight * sampleSpecular;
            #endif

            total += weight;
        }
    }
    
    total = max(total, EPSILON);
    blockDiffuse = accumDiffuse / total;
    blockSpecular = accumSpecular / total;
}

vec4 BilateralGaussianDepthBlur_VL(const in vec2 texcoord, const in sampler2D blendSampler, const in vec2 blendTexSize, const in sampler2D depthSampler, const in vec2 depthTexSize, const in float depth, const in vec2 g_sigma) {
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    float total = 0.0;
    vec4 accum = vec4(0.0);

    vec2 blendPixelSize = rcp(blendTexSize);
    vec2 depthPixelSize = rcp(depthTexSize);
    vec2 depthTexcoord = texcoord * depthTexSize;
    
    for (float iy = -c_halfSamplesY; iy <= c_halfSamplesY; iy++) {
        float fy = Gaussian(g_sigma.x, iy);

        for (float ix = -c_halfSamplesX; ix <= c_halfSamplesX; ix++) {
            float fx = Gaussian(g_sigma.x, ix);
            
            vec2 sampleTex = vec2(ix, iy);

            vec2 texBlend = texcoord + sampleTex * blendPixelSize;
            vec4 sampleValue = textureLod(blendSampler, texBlend, 0);

            vec2 texDepth = texcoord + sampleTex * depthPixelSize;
            float sampleDepth = textureLod(depthSampler, texDepth, 0).r;
                        
            float fv = Gaussian(g_sigma.y, abs(sampleDepth - depth));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    return accum / max(total, EPSILON);
}

ivec2 GetTemporalOffset(const in int size) {
    ivec2 coord = ivec2(gl_FragCoord.xy) + frameCounter;
    return ivec2(coord.x % size, (coord.y / size) % size);
}


layout(location = 0) out vec4 outFinal;
#ifdef DEFERRED_BUFFER_ENABLED
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED && DYN_LIGHT_TA > 0
        /* RENDERTARGETS: 0,7,8,9,12 */
        layout(location = 1) out vec4 outTA;
        layout(location = 2) out vec4 outTA_Normal;
        layout(location = 3) out vec4 outTA_Depth;
        #if MATERIAL_SPECULAR != SPECULAR_NONE
            layout(location = 4) out vec4 outSpecularTA;
        #endif
    #else
        /* RENDERTARGETS: 0 */
    #endif

    void main() {
        ivec2 iTex = ivec2(gl_FragCoord.xy);
        vec2 viewSize = vec2(viewWidth, viewHeight);

        //float depth = texelFetch(depthtex0, iTex, 0).r;
        //float handClipDepth = texelFetch(depthtex2, iTex, 0).r;
        float depth = textureLod(depthtex0, texcoord, 0).r;
        float handClipDepth = textureLod(depthtex2, texcoord, 0).r;
        bool isHand = handClipDepth > depth;

        // if (isHand) {
        //     depth = depth * 2.0 - 1.0;
        //     depth /= MC_HAND_DEPTH;
        //     depth = depth * 0.5 + 0.5;
        // }

        float linearDepth = linearizeDepthFast(depth, near, far);
        vec3 final;

        if (depth < 1.0) {
            vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;

            #ifndef IRIS_FEATURE_SSBO
                vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));
                vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
            #else
                vec3 localPos = unproject(gbufferModelViewProjectionInverse * vec4(clipPos, 1.0));
            #endif

            vec3 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0).rgb;

            uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
            vec4 deferredLighting = unpackUnorm4x8(deferredData.g);

            vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
            vec3 localNormal = deferredNormal.rgb;

            if (any(greaterThan(localNormal, EPSILON3)))
                localNormal = normalize(localNormal * 2.0 - 1.0);

            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            vec3 texNormal = deferredTexture.rgb;

            if (any(greaterThan(texNormal, EPSILON3)))
                texNormal = normalize(texNormal * 2.0 - 1.0);

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                vec2 deferredRoughMetalF0 = texelFetch(BUFFER_ROUGHNESS, iTex, 0).rg;
                float roughL = max(_pow2(deferredRoughMetalF0.r), ROUGH_MIN);
                float metal_f0 = deferredRoughMetalF0.g;
            #else
                const float roughL = 1.0;
                const float metal_f0 = 0.04;
            #endif

            #ifdef SHADOW_BLUR
                #if SHADOW_COLORS == SHADOW_COLOR_ENABLED
                    const vec3 shadowSigma = vec3(1.2, 1.2, 0.06);
                    vec3 deferredShadow = BilateralGaussianDepthBlurRGB_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma);
                #else
                    float shadowSigma = 3.0 / linearDepth;
                    vec3 deferredShadow = vec3(BilateralGaussianDepthBlur_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma));
                #endif
            #else
                //vec3 deferredShadow = unpackUnorm4x8(deferredData.b).rgb;
                vec3 deferredShadow = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0).rgb;
            #endif

            float occlusion = deferredLighting.z;
            float emission = deferredLighting.a;
            float sss = deferredNormal.a;

            vec3 blockDiffuse = vec3(0.0);
            vec3 blockSpecular = vec3(0.0);

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                #ifdef DYN_LIGHT_BLUR
                    const vec3 lightSigma = vec3(1.2, 1.2, 0.2);
                    BilateralGaussianBlur(blockDiffuse, blockSpecular, texcoord, linearDepth, texNormal, lightSigma);
                #elif DYN_LIGHT_RES == 0
                    blockDiffuse = texelFetch(BUFFER_BLOCK_DIFFUSE, iTex, 0).rgb;

                    #if MATERIAL_SPECULAR != SPECULAR_NONE
                        blockSpecular = texelFetch(BUFFER_BLOCK_SPECULAR, iTex, 0).rgb;
                    #endif
                #else
                    blockDiffuse = textureLod(BUFFER_BLOCK_DIFFUSE, texcoord, 0).rgb;

                    #if MATERIAL_SPECULAR != SPECULAR_NONE
                        blockSpecular = textureLod(BUFFER_BLOCK_SPECULAR, texcoord, 0).rgb;
                    #endif
                #endif

                #if DYN_LIGHT_TA > 0
                    vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;

                    #ifdef IRIS_FEATURE_SSBO
                        vec3 clipPosPrev = unproject(gbufferPreviousModelViewProjection * vec4(localPosPrev, 1.0));
                    #else
                        vec3 viewPosPrev = (gbufferPreviousModelView * vec4(localPosPrev, 1.0)).xyz;
                        vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));
                    #endif

                    vec3 uvPrev = clipPosPrev * 0.5 + 0.5;

                    float diffuseCounter = 40.0;

                    if (all(greaterThanEqual(uvPrev.xy, vec2(0.0))) && all(lessThan(uvPrev.xy, vec2(1.0)))) {
                        float depthPrev = textureLod(BUFFER_LIGHT_TA_DEPTH, uvPrev.xy, 0).r;
                        float depthPrevLinear1 = linearizeDepthFast(uvPrev.z, near, far);
                        float depthPrevLinear2 = linearizeDepthFast(depthPrev, near, far);

                        float depthWeight = 1.0 - saturate(16.0 * abs(depthPrevLinear1 - depthPrevLinear2));

                        float normalWeight = 1.0;
                        vec3 normalPrev = textureLod(BUFFER_LIGHT_TA_NORMAL, uvPrev.xy, 0).rgb;
                        if (any(greaterThan(normalPrev, EPSILON3)) && !all(lessThan(abs(texNormal), EPSILON3))) {
                            normalPrev = normalize(normalPrev * 2.0 - 1.0);
                            normalWeight = dot(normalPrev, texNormal) * 0.5 + 0.5;
                        }

                        if (depthWeight > 0.0 && normalWeight > 0.0) {
                            vec4 diffuseSamplePrev = textureLod(BUFFER_LIGHT_TA, uvPrev.xy, 0);
                            vec3 blockDiffusePrev = diffuseSamplePrev.rgb;
                            diffuseCounter = min(diffuseSamplePrev.a, 256.0);

                            diffuseCounter *= depthWeight;
                            diffuseCounter *= normalWeight;

                            float diffuseWeightMin = 1.0 + DynamicLightTemporalStrength;
                            float diffuseWeight = rcp(diffuseWeightMin + diffuseCounter*DynamicLightTemporalStrength);
                            blockDiffuse = mix(blockDiffusePrev, blockDiffuse, diffuseWeight);

                            #if MATERIAL_SPECULAR != SPECULAR_NONE
                                vec3 blockSpecularPrev = textureLod(BUFFER_TA_SPECULAR, uvPrev.xy, 0).rgb;

                                //lum = log(luminance(blockSpecular) + EPSILON);
                                //lumPrev = log(luminance(blockSpecularPrev) + EPSILON);

                                //lumDiff = min(abs(lum - lumPrev), 0.6);
                                //lumWeight = 1.0 - lumDiff * mix(0.6, 0.16, DynamicLightTemporalStrength);
                                //float lumWeight = 0.8 * (_pow3(lumDiff) + 0.16 * lumDiff);

                                //minWeight = mix(0.04, 0.006, DynamicLightTemporalStrength);
                                //float weightSpecular = max(1.0 - depthWeight * normalWeight * lumWeight, minWeight);

                                float specularWeightMin = 2.0;// + DynamicLightTemporalStrength;
                                float specularWeight = rcp(diffuseWeightMin + 0.75*diffuseCounter*DynamicLightTemporalStrength);
                                blockSpecular = mix(blockSpecularPrev, blockSpecular, specularWeight);
                            #endif
                        }
                    }

                    outTA = vec4(blockDiffuse, diffuseCounter + 1.0);
                    outTA_Normal = vec4(localNormal * 0.5 + 0.5, 1.0);
                    outTA_Depth = vec4(depth, 0.0, 0.0, 1.0);

                    #if MATERIAL_SPECULAR != SPECULAR_NONE
                        outSpecularTA = vec4(blockSpecular, 1.0);
                    #endif
                #endif

                //blockDiffuse += emission * MaterialEmissionF;
            #else
                GetFinalBlockLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, deferredLighting.x, roughL, metal_f0, sss);

                // #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                //     blockDiffuse += emission * MaterialEmissionF;
                // #endif
            #endif

            blockDiffuse += emission * MaterialEmissionF;

            vec3 skyDiffuse = vec3(0.0);
            vec3 skySpecular = vec3(0.0);

            vec3 localViewDir = normalize(localPos);

            #ifdef WORLD_SKY_ENABLED
                GetSkyLightingFinal(skyDiffuse, skySpecular, deferredShadow, -localViewDir, localNormal, texNormal, deferredLighting.y, roughL, metal_f0, sss);
            #endif

            float shadowF = min(luminance(deferredShadow), 1.0);
            occlusion = max(occlusion, shadowF);

            vec3 albedo = RGBToLinear(deferredColor);
            //final = GetFinalLighting(albedo, blockDiffuse, blockSpecular, deferredShadow, deferredLighting.xy, roughL, deferredLighting.z);
            final = GetFinalLighting(albedo, texNormal, blockDiffuse, blockSpecular, skyDiffuse, skySpecular, deferredLighting.xy, metal_f0, roughL, occlusion);

            vec4 deferredFog = unpackUnorm4x8(deferredData.b);
            //vec3 fogColorFinal = RGBToLinear(deferredFog.rgb);
            vec3 fogColorFinal = GetFogColor(deferredFog.rgb, localViewDir.y);
            fogColorFinal = RGBToLinear(fogColorFinal);

            final = mix(final, fogColorFinal, deferredFog.a);
        }
        else {
            #ifdef WORLD_SKY_ENABLED
                final = texelFetch(BUFFER_FINAL, iTex, 0).rgb;
            #else
                final = fogColor * WorldSkyBrightnessF;
                final = RGBToLinear(final);
            #endif
        }

        #ifdef VL_BUFFER_ENABLED
            #ifdef VOLUMETRIC_BLUR
                const float bufferScale = rcp(exp2(VOLUMETRIC_RES));

                #if VOLUMETRIC_RES == 2
                    const vec2 vlSigma = vec2(1.0, 0.00001);
                #elif VOLUMETRIC_RES == 1
                    const vec2 vlSigma = vec2(2.0, 0.00002);
                #else
                    const vec2 vlSigma = vec2(1.2, 0.00002);
                #endif

                vec4 vlScatterTransmit = BilateralGaussianDepthBlur_VL(texcoord, BUFFER_VL, viewSize * bufferScale, depthtex0, viewSize, depth, vlSigma);
            #else
                vec4 vlScatterTransmit = textureLod(BUFFER_VL, texcoord, 0);
            #endif

            final = final * vlScatterTransmit.a + vlScatterTransmit.rgb;
        #endif

        outFinal = vec4(final, 1.0);
    }
#else
    // Pass-through for world-specific flags not working in shader.properties
    
    uniform sampler2D colortex0;


    void main() {
        outFinal = texture(colortex0, texcoord);
    }
#endif
