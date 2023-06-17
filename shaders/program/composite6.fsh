#define RENDER_TRANSLUCENT_FINAL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D BUFFER_FINAL;
uniform sampler2D BUFFER_DEFERRED_COLOR;
uniform sampler2D BUFFER_DEFERRED_SHADOW;
uniform usampler2D BUFFER_DEFERRED_DATA;
uniform sampler2D BUFFER_BLOCK_DIFFUSE;
uniform sampler2D BUFFER_LIGHT_NORMAL;
uniform sampler2D BUFFER_LIGHT_DEPTH;
uniform sampler2D BUFFER_WEATHER;
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

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform sampler3D texLPV_1;
    uniform sampler3D texLPV_2;
#endif

uniform int frameCounter;
uniform float frameTime;
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
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;

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

#if defined IRIS_FEATURE_SSBO && (DYN_LIGHT_MODE != DYN_LIGHT_NONE || LPV_SIZE > 0)
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"

    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        #include "/lib/lighting/voxel/light_mask.glsl"
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/buffers/collissions.glsl"
    #include "/lib/lighting/voxel/collisions.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

#include "/lib/lights.glsl"
#include "/lib/lighting/voxel/lights.glsl"

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/lighting/voxel/sampling.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && LPV_SIZE > 0 //&& DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/buffers/volume.glsl"
    #include "/lib/lighting/voxel/lpv.glsl"
    #include "/lib/lighting/voxel/lpv_render.glsl"
#endif

#include "/lib/lighting/voxel/items.glsl"

#include "/lib/lighting/basic.glsl"
#include "/lib/lighting/basic_hand.glsl"

#if VOLUMETRIC_BRIGHT_SKY > 0 || VOLUMETRIC_BRIGHT_BLOCK > 0
    #include "/lib/world/volumetric_blur.glsl"
#endif


void BilateralGaussianBlur(out vec3 blockDiffuse, out vec3 blockSpecular, const in vec2 texcoord, const in float linearDepth, const in vec3 normal, const in float roughL, const in vec3 g_sigma) {
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
                vec4 sampleSpecular = textureLod(BUFFER_BLOCK_SPECULAR, sampleBlendTex, 0);
                sampleSpecular.rgb *= 1.0 - min(4.0 * abs(sampleSpecular.a - roughL), 1.0);
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
                accumSpecular += weight * sampleSpecular.rgb;
            #endif

            total += weight;
        }
    }
    
    total = max(total, EPSILON);
    blockDiffuse = accumDiffuse / total;
    blockSpecular = accumSpecular / total;
}


layout(location = 0) out vec4 outFinal;
#if defined DEFERRED_BUFFER_ENABLED && defined DEFER_TRANSLUCENT
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
        float depthOpaque = textureLod(depthtex1, texcoord, 0).r;
        float handClipDepth = textureLod(depthtex2, texcoord, 0).r;
        bool isHand = handClipDepth > depth;

        // if (isHand) {
        //     depth = depth * 2.0 - 1.0;
        //     depth /= MC_HAND_DEPTH;
        //     depth = depth * 0.5 + 0.5;
        // }

        float linearDepth = linearizeDepthFast(depth, near, far);

        vec2 refraction = vec2(0.0);
        vec4 final = vec4(0.0);
        bool tir = false;

        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));

        #ifndef IRIS_FEATURE_SSBO
            vec3 localPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        #else
            vec3 localPos = unproject(gbufferModelViewProjectionInverse * vec4(clipPos, 1.0));
        #endif

        vec3 localViewDir = normalize(localPos);
        float viewDist = length(localPos);

        vec4 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0);
        uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
        vec4 deferredFog = unpackUnorm4x8(deferredData.b);

        vec3 fogColorFinal = GetVanillaFogColor(deferredFog.rgb, localViewDir.y);
        fogColorFinal = RGBToLinear(fogColorFinal);

        bool isWater = false;

        if (deferredColor.a > (0.5/255.0)) {
            vec4 deferredLighting = unpackUnorm4x8(deferredData.g);

            vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
            vec3 localNormal = deferredNormal.rgb;

            if (any(greaterThan(localNormal, EPSILON3)))
                localNormal = normalize(localNormal * 2.0 - 1.0);

            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            vec3 texNormal = deferredTexture.rgb;

            if (any(greaterThan(texNormal, EPSILON3)))
                texNormal = normalize(texNormal * 2.0 - 1.0);

            isWater = deferredTexture.a < 0.5;

            #if REFRACTION_STRENGTH > 0
                vec3 texViewNormal = mat3(gbufferModelView) * (texNormal - localNormal);

                const float ior = IOR_WATER;
                float refractEta = (IOR_AIR/ior);//isEyeInWater == 1 ? (ior/IOR_AIR) : (IOR_AIR/ior);
                vec3 viewDir = vec3(0.0, 0.0, 1.0);//isEyeInWater == 1 ? normalize(viewPos) : vec3(0.0, 0.0, 1.0);

                vec3 refractDir = refract(viewDir, texViewNormal, refractEta);
                float linearDepthOpaque = linearizeDepthFast(depthOpaque, near, far);
                float linearDist = linearDepthOpaque - linearDepth;

                vec2 refractMax = vec2(0.1);
                refractMax.x *= viewWidth / viewHeight;
                refraction = clamp(vec2(0.06 * linearDist * RefractionStrengthF), -refractMax, refractMax) * refractDir.xy;

                #ifdef REFRACTION_SNELL_ENABLED
                    tir = all(lessThan(abs(refractDir), EPSILON3));
                #endif
            #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                vec2 deferredRoughMetalF0 = texelFetch(BUFFER_ROUGHNESS, iTex, 0).rg;
                float roughL = max(_pow2(deferredRoughMetalF0.r), ROUGH_MIN);
                float metal_f0 = deferredRoughMetalF0.g;
            #else
                const float roughL = 1.0;
                const float metal_f0 = 0.04;
            #endif

            #ifdef SHADOW_BLUR
                #ifdef SHADOW_COLORED
                    const vec3 shadowSigma = vec3(1.2, 1.2, 0.06);
                    vec3 deferredShadow = BilateralGaussianDepthBlurRGB_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma);
                #else
                    float shadowSigma = 3.0 / linearDepth;
                    vec3 deferredShadow = vec3(BilateralGaussianDepthBlur_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma));
                #endif
            #else
                vec3 deferredShadow = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0).rgb;
            #endif

            vec3 albedo = RGBToLinear(deferredColor.rgb);
            float occlusion = deferredLighting.z;
            float emission = deferredLighting.a;
            float sss = deferredNormal.a;

            vec3 blockDiffuse = vec3(0.0);
            vec3 blockSpecular = vec3(0.0);

            #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                #ifdef DYN_LIGHT_BLUR
                    const vec3 lightSigma = vec3(1.2, 1.2, 0.2);
                    BilateralGaussianBlur(blockDiffuse, blockSpecular, texcoord, linearDepth, texNormal, roughL, lightSigma);
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
                    vec3 cameraOffsetPrevious = cameraPosition - previousCameraPosition;
                    vec3 localPosPrev = localPos + cameraOffsetPrevious;

                    #ifdef IRIS_FEATURE_SSBO
                        vec3 clipPosPrev = unproject(gbufferPreviousModelViewProjection * vec4(localPosPrev, 1.0));
                    #else
                        vec3 viewPosPrev = (gbufferPreviousModelView * vec4(localPosPrev, 1.0)).xyz;
                        vec3 clipPosPrev = unproject(gbufferPreviousProjection * vec4(viewPosPrev, 1.0));
                    #endif

                    vec3 uvPrev = clipPosPrev * 0.5 + 0.5;

                    float diffuseCounter = 0.0;

                    if (all(greaterThanEqual(uvPrev.xy, vec2(0.0))) && all(lessThan(uvPrev.xy, vec2(1.0)))) {
                        float depthPrev = textureLod(BUFFER_LIGHT_TA_DEPTH, uvPrev.xy, 0).r;
                        float depthPrevLinear1 = linearizeDepthFast(uvPrev.z, near, far);
                        float depthPrevLinear2 = linearizeDepthFast(depthPrev, near, far);

                        #if DYN_LIGHT_RES == 2
                            const float depthWeightF = 16.0;
                        #else
                            const float depthWeightF = 16.0;
                        #endif

                        float depthWeight = 1.0 - saturate(depthWeightF * abs(depthPrevLinear1 - depthPrevLinear2));

                        float normalWeight = 0.0;
                        vec3 normalPrev = textureLod(BUFFER_LIGHT_TA_NORMAL, uvPrev.xy, 0).rgb;
                        if (any(greaterThan(normalPrev, EPSILON3)) && !all(lessThan(abs(texNormal), EPSILON3))) {
                            normalPrev = normalize(normalPrev * 2.0 - 1.0);
                            normalWeight = 0.25 - dot(normalPrev, texNormal) * 0.25;

                            #if DYN_LIGHT_RES == 2
                                normalWeight *= 0.25;
                            #endif
                        }

                        if (depthWeight > 0.0 && normalWeight < 1.0) {
                            vec4 diffuseSamplePrev = textureLod(BUFFER_LIGHT_TA, uvPrev.xy, 0);

                            bool hasLightingChanged =
                                HandLightType1 != HandLightTypePrevious1 ||
                                HandLightType2 != HandLightTypePrevious2;

                            ivec3 gridCell, gridCellPrevious, blockCell;
                            vec3 gridPos = GetVoxelBlockPosition(localPos);
                            vec3 gridPosPrevious = GetPreviousVoxelBlockPosition(localPosPrev);

                            if (GetVoxelGridCell(gridPos, gridCell, blockCell) && GetVoxelGridCell(gridPosPrevious, gridCellPrevious, blockCell)) {
                                uint gridIndex = GetVoxelGridCellIndex(gridCell);
                                LightCellData cellData = SceneLightMaps[gridIndex];

                                uint gridIndexPrevious = GetVoxelGridCellIndex(gridCellPrevious);
                                LightCellData cellDataPrevious = SceneLightMaps[gridIndexPrevious];

                                if (cellDataPrevious.LightPreviousCount != cellData.LightCount + cellData.LightNeighborCount)
                                    hasLightingChanged = true;
                            }

                            diffuseCounter = min(diffuseSamplePrev.a, 256.0);

                            diffuseCounter *= depthWeight;
                            diffuseCounter *= 1.0 - normalWeight;

                            if (HandLightType1 > 0 || HandLightType2 > 0) {
                                float cameraSpeed = 2.0 * length(cameraOffsetPrevious);// * frameTime;
                                float viewDistF = max(1.0 - viewDist/16.0, 0.0);
                                diffuseCounter *= max(1.0 - cameraSpeed * viewDistF, 0.0);
                            }

                            if (hasLightingChanged) diffuseCounter = min(diffuseCounter, 4.0);

                            float diffuseWeightMin = 1.0 + DynamicLightTemporalStrength;
                            float diffuseWeight = rcp(diffuseWeightMin + diffuseCounter*DynamicLightTemporalStrength);
                            blockDiffuse = mix(diffuseSamplePrev.rgb, blockDiffuse, diffuseWeight);

                            #if MATERIAL_SPECULAR != SPECULAR_NONE
                                vec3 blockSpecularPrev = textureLod(BUFFER_TA_SPECULAR, uvPrev.xy, 0).rgb;
                                //vec3 blockSpecularPrev = specularSamplePrev.rgb;
                                //float metal_f0_prev = specularSamplePrev.a;

                                //float specularWeightMin = 2.0;// + DynamicLightTemporalStrength;
                                float specularWeight = rcp(1.0 + 0.25*diffuseCounter*DynamicLightTemporalStrength);

                                blockSpecular = mix(blockSpecularPrev, blockSpecular, specularWeight);

                                //if (abs(roughL - metal_f0_prev) > (0.5/255.0)) blockSpecular = vec3(0.0);
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

                SampleHandLight(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, roughL, metal_f0, sss);

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    if (metal_f0 >= 0.5) {
                        blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                        blockSpecular *= albedo;
                    }
                #endif

                // #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                //     blockDiffuse += emission * MaterialEmissionF;
                // #endif
            #endif

            blockDiffuse += emission * MaterialEmissionF;

            vec3 skyDiffuse = vec3(0.0);
            vec3 skySpecular = vec3(0.0);

            #ifdef WORLD_SKY_ENABLED
                vec3 shadowPos = vec3(0.0);
                GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, deferredShadow, localPos, localNormal, texNormal, deferredLighting.xy, roughL, metal_f0, occlusion, sss);
            #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                if (metal_f0 >= 0.5) {
                    skyDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                    skySpecular *= albedo;
                }
            #endif

            float shadowF = min(luminance(deferredShadow), 1.0);
            occlusion = max(occlusion, shadowF);

            vec3 diffuseFinal = blockDiffuse + skyDiffuse;
            vec3 specularFinal = blockSpecular + skySpecular;
            final.rgb = GetFinalLighting(albedo, localPos, localNormal, diffuseFinal, specularFinal, deferredLighting.xy, metal_f0, roughL, occlusion, sss);
            final.a = min(deferredColor.a + luminance(specularFinal), 1.0);

            #if WORLD_FOG_MODE == FOG_MODE_VANILLA
                final.rgb = mix(final.rgb, fogColorFinal, deferredFog.a);
                if (final.a > (1.5/255.0)) final.a = min(final.a + deferredFog.a, 1.0);
            #endif

            #if REFRACTION_STRENGTH > 0
                float refractDist = maxOf(abs(refraction * viewSize));
                int refractSteps = int(ceil(refractDist));

                for (int i = 1; i <= min(refractSteps, 16); i++) {
                    vec2 p = refraction * (i / refractSteps);
                    float d = textureLod(depthtex1, texcoord + p, 0).r;
                    
                    if (d < depth) {
                        refraction *= max(i - 1.5, 0.0) / refractSteps;
                        break;
                    }
                }
            #endif
        }

        vec3 opaqueFinal = textureLod(BUFFER_FINAL, texcoord + refraction, 0).rgb;

        #if REFRACTION_STRENGTH > 0 && defined REFRACTION_SNELL_ENABLED
            if (tir) opaqueFinal = fogColorFinal;
        #endif

        #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
            if (depth < depthOpaque) {
                float fogF = 0.0;

                #ifdef WORLD_WATER_ENABLED
                    if (isWater && isEyeInWater != 1) {
                        // water fog from outside water

                        #ifndef VL_BUFFER_ENABLED
                            vec3 clipPosOpaque = vec3(texcoord, depthOpaque) * 2.0 - 1.0;

                            #ifndef IRIS_FEATURE_SSBO
                                vec3 viewPosOpaque = unproject(gbufferProjectionInverse * vec4(clipPosOpaque, 1.0));
                                vec3 localPosOpaque = (gbufferModelViewInverse * vec4(viewPosOpaque, 1.0)).xyz;
                            #else
                                vec3 localPosOpaque = unproject(gbufferModelViewProjectionInverse * vec4(clipPosOpaque, 1.0));
                            #endif

                            float fogDist = max(length(localPosOpaque) - viewDist, 0.0);
                            fogF = GetCustomWaterFogFactor(fogDist);

                            fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                        #endif
                    }
                    else {
                #endif
                    #ifdef WORLD_SKY_ENABLED
                        // sky fog

                        vec3 skyColorFinal = RGBToLinear(skyColor);
                        fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                        fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, localViewDir.y);

                        float fogDist  = GetVanillaFogDistance(localPos);
                        fogF = GetCustomSkyFogFactor(fogDist);
                    #else
                        // no-sky fog

                        fogColorFinal = RGBToLinear(fogColor);
                        fogF = GetVanillaFogFactor(localPos);
                    #endif
                #ifdef WORLD_WATER_ENABLED
                    }
                #endif

                opaqueFinal = mix(opaqueFinal, fogColorFinal, fogF);
            }
        #endif

        if (isWater) {
            final.rgb = mix(opaqueFinal, final.rgb, final.a);
        }
        else {
            // multiplicative tinting for transparent pixels
            final.rgb *= mix(opaqueFinal * 3.0, vec3(1.0), pow(final.a, 3.0));

            // remove background for opaque pixels
            opaqueFinal *= 1.0 - pow(final.a, 3.0);

            // mix background and multiplied foreground
            final.rgb = mix(opaqueFinal, final.rgb, pow(final.a, 0.2));
        }

        final.a = 1.0;

        #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
            float fogF = 0.0;

            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 1) {
                    // water fog

                    #ifndef VL_BUFFER_ENABLED
                        vec3 skyColorFinal = RGBToLinear(skyColor);
                        fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);

                        fogF = GetCustomWaterFogFactor(viewDist);
                    #endif
                }
                else {
            #endif
                if (depth >= 1.0) fogF = 0.0;
                else {
                    #ifdef WORLD_SKY_ENABLED
                        // sky fog

                        vec3 skyColorFinal = RGBToLinear(skyColor);
                        fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                        fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, localViewDir.y);

                        float fogDist = GetVanillaFogDistance(localPos);
                        fogF = GetCustomSkyFogFactor(fogDist);
                    #else
                        // no-sky fog

                        fogColorFinal = RGBToLinear(fogColor);
                        fogF = GetVanillaFogFactor(localPos);
                    #endif
                }
            #ifdef WORLD_WATER_ENABLED
                }
            #endif

            final.rgb = mix(final.rgb, fogColorFinal, fogF);
        #endif

        #ifdef VL_BUFFER_ENABLED
            #ifdef VOLUMETRIC_BLUR
                const float bufferScale = rcp(exp2(VOLUMETRIC_RES));

                #if VOLUMETRIC_RES == 2
                    const vec2 vlSigma = vec2(1.0, 0.00001);
                #elif VOLUMETRIC_RES == 1
                    const vec2 vlSigma = vec2(1.0, 0.00001);
                #else
                    const vec2 vlSigma = vec2(1.2, 0.00002);
                #endif

                vec4 vlScatterTransmit = BilateralGaussianDepthBlur_VL(texcoord, BUFFER_VL, viewSize * bufferScale, depthtex0, viewSize, depth, vlSigma);
            #else
                vec4 vlScatterTransmit = textureLod(BUFFER_VL, texcoord, 0);
            #endif

            final.rgb = final.rgb * vlScatterTransmit.a + vlScatterTransmit.rgb;
        #endif

        vec4 weatherColor = textureLod(BUFFER_WEATHER, texcoord, 0);
        final.rgb = mix(final.rgb, weatherColor.rgb, weatherColor.a);

        outFinal = final;
    }
#else
    // Pass-through for world-specific flags not working in shader.properties
    
    uniform sampler2D colortex0;


    void main() {
        outFinal = texture(colortex0, texcoord);
    }
#endif
