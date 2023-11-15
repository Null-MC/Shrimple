#define RENDER_TRANSLUCENT_FINAL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    const bool colortex0MipmapEnabled = true;
#endif

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
//uniform sampler2D BUFFER_WEATHER_DEPTH;
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

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform sampler2D texDepthNear;
    //layout(r32f) uniform readonly image2D imgDepthNear;
#endif

#if defined MATERIAL_REFLECT_CLOUDS && MATERIAL_REFLECTIONS != REFLECT_NONE && defined WORLD_SKY_ENABLED && defined IS_IRIS
    uniform sampler2D TEX_CLOUDS;
#endif

uniform int worldTime;
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
uniform float aspectRatio;
uniform vec2 viewSize;
uniform vec2 pixelSize;
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

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform mat4 gbufferProjection;
#endif

#ifdef WORLD_SKY_ENABLED
    uniform vec3 sunPosition;
    uniform vec3 shadowLightPosition;
    uniform float rainStrength;
    //uniform float wetness;

    #if defined MATERIAL_REFLECT_CLOUDS && MATERIAL_REFLECTIONS != REFLECT_NONE && defined IS_IRIS
        uniform float cloudTime;
    #endif
#endif

#ifdef WORLD_WATER_ENABLED
    uniform vec3 WaterAbsorbColor;
    uniform vec3 WaterScatterColor;
    uniform float waterDensitySmooth;
#endif

// #if !defined WORLD_SHADOW_ENABLED || SHADOW_TYPE == SHADOW_TYPE_NONE
//     uniform int worldTime;
// #endif

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#ifdef IS_IRIS
    uniform bool isSpectator;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#if DIST_BLUR_MODE == DIST_BLUR_DOF
    uniform float centerDepthSmooth;
#endif

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"
#include "/lib/anim.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"

    #if WATER_DEPTH_LAYERS > 1
        #include "/lib/buffers/water_depths.glsl"
    #endif
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
    #include "/lib/material/hcm.glsl"
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
    #include "/lib/lighting/voxel/tinting.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
#endif

#include "/lib/lighting/fresnel.glsl"
#include "/lib/lighting/sampling.glsl"

#ifdef WORLD_SKY_ENABLED
    #include "/lib/world/sky.glsl"
#endif

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
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

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    #include "/lib/utility/depth_tiles.glsl"
    #include "/lib/lighting/ssr.glsl"
#endif

#if MATERIAL_REFLECTIONS != REFLECT_NONE
    #if defined MATERIAL_REFLECT_CLOUDS && defined WORLD_SKY_ENABLED && defined IS_IRIS
        #include "/lib/shadows/clouds.glsl"
    #endif
    
    #include "/lib/lighting/reflections.glsl"
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_NONE
    #include "/lib/lighting/vanilla.glsl"
#elif DYN_LIGHT_MODE == DYN_LIGHT_LPV
    #include "/lib/lighting/floodfill.glsl"
#else
    #include "/lib/lighting/basic.glsl"
#endif

#include "/lib/lighting/basic_hand.glsl"

#if VOLUMETRIC_BRIGHT_SKY > 0 || VOLUMETRIC_BRIGHT_BLOCK > 0
    #include "/lib/world/volumetric_blur.glsl"
#endif

#if DIST_BLUR_MODE != DIST_BLUR_OFF || defined WATER_BLUR
    #include "/lib/post/depth_blur.glsl"
#endif

// #ifdef DH_COMPAT_ENABLED
//     #include "/lib/post/saturation.glsl"
//     #include "/lib/post/tonemap.glsl"
// #endif


void BilateralGaussianBlur(out vec3 blockDiffuse, out vec3 blockSpecular, const in vec2 texcoord, const in float linearDepth, const in vec3 normal, const in float roughL, const in vec3 g_sigma) {
    const float c_halfSamplesX = 2.0;
    const float c_halfSamplesY = 2.0;

    const float lightBufferScale = exp2(DYN_LIGHT_RES);
    const float lightBufferScaleInv = rcp(lightBufferScale);

    //vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 lightBufferSize = viewSize * lightBufferScaleInv;
    vec2 blendPixelSize = rcp(lightBufferSize);
    //vec2 screenPixelSize = rcp(viewSize);

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
#if defined DEFERRED_BUFFER_ENABLED && (defined DEFER_TRANSLUCENT || defined MATERIAL_REFRACT_ENABLED)
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
        //vec2 viewSize = vec2(viewWidth, viewHeight);

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
        float linearDepthOpaque = linearizeDepthFast(depthOpaque, near, far);

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

        vec3 albedo = RGBToLinear(deferredColor.rgb);

        vec3 fogColorFinal = GetVanillaFogColor(deferredFog.rgb, localViewDir.y);
        fogColorFinal = RGBToLinear(fogColorFinal);

        bool isWater = false;
        float roughness = 1.0;
        float roughL = 1.0;
        vec3 texNormal;

        #if WATER_DEPTH_LAYERS > 1
            uvec2 waterScreenUV = uvec2(gl_FragCoord.xy);
            uint waterPixelIndex = uint(waterScreenUV.y * viewWidth + waterScreenUV.x);
        #endif

        if (deferredColor.a > (0.5/255.0)) {
            vec4 deferredLighting = unpackUnorm4x8(deferredData.g);

            vec4 deferredNormal = unpackUnorm4x8(deferredData.r);
            vec3 localNormal = deferredNormal.rgb;

            if (any(greaterThan(localNormal, EPSILON3)))
                localNormal = normalize(localNormal * 2.0 - 1.0);

            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            texNormal = deferredTexture.rgb;

            if (any(greaterThan(texNormal, EPSILON3)))
                texNormal = normalize(texNormal * 2.0 - 1.0);

            vec4 deferredShadow = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0);

            //#if WATER_DEPTH_LAYERS > 1
            //    isWater = WaterDepths[waterPixelIndex].IsWater;
            //#else
                isWater = deferredShadow.a > 0.5;
            //#endif

            #ifdef MATERIAL_REFRACT_ENABLED
                vec3 texViewNormal = mat3(gbufferModelView) * (texNormal - localNormal);

                const float ior = IOR_WATER;
                float refractEta = (IOR_AIR/ior);//isEyeInWater == 1 ? (ior/IOR_AIR) : (IOR_AIR/ior);
                vec3 refractViewDir = vec3(0.0, 0.0, 1.0);//isEyeInWater == 1 ? normalize(viewPos) : vec3(0.0, 0.0, 1.0);

                vec3 refractDir = refract(refractViewDir, texViewNormal, refractEta);
                linearDepthOpaque = linearizeDepthFast(depthOpaque, near, far);
                float linearDist = linearDepthOpaque - linearDepth;

                vec2 refractMax = vec2(0.2);
                refractMax.x *= viewWidth / viewHeight;
                refraction = clamp(vec2(0.1 * linearDist * RefractionStrengthF), -refractMax, refractMax) * refractDir.xy;

                #ifdef REFRACTION_SNELL
                    if (isEyeInWater == 1) {
                        texViewNormal = mat3(gbufferModelView) * texNormal;

                        refractEta = (IOR_WATER/IOR_AIR);//isEyeInWater == 1 ? (ior/IOR_AIR) : (IOR_AIR/ior);
                        refractViewDir = normalize(viewPos);
                        refractDir = refract(refractViewDir, texViewNormal, refractEta);

                        tir = all(lessThan(abs(refractDir), EPSILON3));
                    }
                #endif
            #endif

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                vec2 deferredRoughMetalF0 = texelFetch(BUFFER_ROUGHNESS, iTex, 0).rg;
                roughness = deferredRoughMetalF0.r;
                float metal_f0 = deferredRoughMetalF0.g;
                roughL = _pow2(roughness);
            #else
                //const float roughness = 1.0;
                //float roughL = 1.0;
                const float metal_f0 = 0.04;
            #endif

            #ifdef SHADOW_BLUR
                #ifdef SHADOW_COLORED
                    const vec3 shadowSigma = vec3(1.2, 1.2, 0.06);
                    deferredShadow.rgb = BilateralGaussianDepthBlurRGB_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma);
                #else
                    float shadowSigma = 3.0 / linearDepth;
                    deferredShadow.rgb = vec3(BilateralGaussianDepthBlur_5x(texcoord, BUFFER_DEFERRED_SHADOW, viewSize, depthtex0, viewSize, linearDepth, shadowSigma));
                #endif
            #else
                //deferredShadow.rgb = textureLod(BUFFER_DEFERRED_SHADOW, texcoord, 0).rgb;
            #endif

            float occlusion = deferredLighting.z;
            float emission = deferredLighting.a;
            float sss = deferredNormal.a;

            //if (isWater) deferredColor.a *= WorldWaterOpacityF;

            #if DYN_LIGHT_MODE == DYN_LIGHT_NONE
                vec3 diffuse, specular = vec3(0.0);
                GetVanillaLighting(diffuse, deferredLighting.xy, localPos, localNormal, texNormal, deferredShadow.rgb, sss);

                #if MATERIAL_SPECULAR != SPECULAR_NONE //&& defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                    float geoNoL = dot(localNormal, localSkyLightDirection);
                    specular += GetSkySpecular(localPos, geoNoL, texNormal, albedo, deferredShadow.rgb, deferredLighting.xy, metal_f0, roughL);
                #endif

                SampleHandLight(diffuse, specular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

                if (isWater) diffuse *= WorldWaterOpacityF;
                //if (isWater) deferredColor.rgb *= WorldWaterOpacityF;

                final.rgb = GetFinalLighting(albedo, diffuse, specular, metal_f0, roughL, emission, occlusion);
                final.a = min(deferredColor.a + luminance(specular), 1.0);
            #else
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
                                const float depthWeightF = 8.0;
                            #else
                                const float depthWeightF = 16.0;
                            #endif

                            float depthWeight = saturate(depthWeightF * abs(depthPrevLinear1 - depthPrevLinear2));

                            float normalWeight = 0.0;
                            vec3 normalPrev = textureLod(BUFFER_LIGHT_TA_NORMAL, uvPrev.xy, 0).rgb;
                            if (any(greaterThan(normalPrev, EPSILON3)) && !all(lessThan(abs(texNormal), EPSILON3))) {
                                normalPrev = normalize(normalPrev * 2.0 - 1.0);
                                normalWeight = 1.0 - dot(normalPrev, texNormal);

                                #if DYN_LIGHT_RES == 2
                                    normalWeight *= 0.25;
                                #endif
                            }

                            if (depthWeight < 1.0 && normalWeight < 1.0) {
                                vec4 diffuseSamplePrev = textureLod(BUFFER_LIGHT_TA, uvPrev.xy, 0);

                                bool hasLightingChanged = false;

                                #ifdef LIGHT_HAND_SOFT_SHADOW
                                    hasLightingChanged =
                                        HandLightType1 != HandLightTypePrevious1 ||
                                        HandLightType2 != HandLightTypePrevious2;
                                #endif

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

                                diffuseCounter *= 1.0 - depthWeight;
                                diffuseCounter *= 1.0 - normalWeight;

                                // if (HandLightType1 > 0 || HandLightType2 > 0) {
                                //     float cameraSpeed = 2.0 * length(cameraOffsetPrevious);// * frameTime;
                                //     float viewDistF = max(1.0 - viewDist/16.0, 0.0);
                                //     diffuseCounter *= max(1.0 - cameraSpeed * viewDistF, 0.0);
                                // }

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

                    #ifndef LIGHT_HAND_SOFT_SHADOW
                        vec3 handDiffuse = vec3(0.0);
                        vec3 handSpecular = vec3(0.0);
                        SampleHandLight(handDiffuse, handSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

                        #if MATERIAL_SPECULAR != SPECULAR_NONE
                            if (metal_f0 >= 0.5) {
                                blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                                blockSpecular *= albedo;
                            }
                        #endif

                        blockDiffuse += handDiffuse;
                        blockSpecular += handSpecular;
                    #endif

                    #if LPV_SIZE > 0
                        blockDiffuse += GetLpvAmbientLighting(localPos, localNormal) * occlusion;
                    #endif

                    //blockDiffuse += emission * MaterialEmissionF;
                #elif DYN_LIGHT_MODE == DYN_LIGHT_LPV
                    GetFloodfillLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, deferredLighting.xy, deferredShadow.rgb, albedo, metal_f0, roughL, sss, tir);

                    SampleHandLight(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

                    #if MATERIAL_SPECULAR != SPECULAR_NONE
                        if (metal_f0 >= 0.5) {
                            blockDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                            blockSpecular *= albedo;
                        }
                    #endif

                    // #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
                    //     blockDiffuse += emission * MaterialEmissionF;
                    // #endif
                #else
                    GetFinalBlockLighting(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, sss);

                    SampleHandLight(blockDiffuse, blockSpecular, localPos, localNormal, texNormal, albedo, roughL, metal_f0, occlusion, sss);

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

                #if defined WORLD_SKY_ENABLED && DYN_LIGHT_MODE != DYN_LIGHT_LPV
                    vec3 shadowPos = vec3(0.0);
                    GetSkyLightingFinal(skyDiffuse, skySpecular, shadowPos, deferredShadow.rgb, localPos, localNormal, texNormal, albedo, deferredLighting.xy, roughL, metal_f0, occlusion, sss, tir);
                #endif

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    if (metal_f0 >= 0.5) {
                        skyDiffuse *= mix(MaterialMetalBrightnessF, 1.0, roughL);
                        skySpecular *= albedo;
                    }
                #endif

                float shadowF = min(luminance(deferredShadow.rgb), 1.0);
                occlusion = max(occlusion, shadowF);

                // #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
                //     if (isWater) albedo = vec3(0.0);
                // #endif

                vec3 diffuseFinal = blockDiffuse + skyDiffuse;
                vec3 specularFinal = blockSpecular + skySpecular;
                final.rgb = GetFinalLighting(albedo, diffuseFinal, specularFinal, occlusion);
                final.a = min(deferredColor.a + luminance(specularFinal), 1.0);
            #endif

            #if WORLD_FOG_MODE == FOG_MODE_VANILLA
                final.rgb = mix(final.rgb, fogColorFinal, deferredFog.a);
                if (final.a > (1.5/255.0)) final.a = min(final.a + deferredFog.a, 1.0);
            #endif

            #ifdef MATERIAL_REFRACT_ENABLED
                float refractDist = maxOf(abs(refraction * viewSize));
                if (refractDist >= 1.0) {
                    int refractSteps = clamp(int(ceil(refractDist)), 2, 16);
                    vec2 step = refraction / refractSteps;
                    //refraction = step * refractSteps;
                    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

                    //refraction = vec2(0.0);
                    for (int i = 1; i <= refractSteps; i++) {
                        float o = i + dither;
                        float sampleDepth = textureLod(depthtex1, texcoord + o * step, 0).r;
                        
                        if (sampleDepth < depth) {
                            refraction = max(i - 1, 0) * step;
                            //depthOpaque = sampleDepth;
                            break;
                        }
                    }
                }
            #endif
        }

        depthOpaque = textureLod(depthtex1, texcoord + refraction, 0).r;
        vec3 clipPosOpaque = vec3(texcoord + refraction, depthOpaque) * 2.0 - 1.0;

        #ifndef IRIS_FEATURE_SSBO
            vec3 viewPosOpaque = unproject(gbufferProjectionInverse * vec4(clipPosOpaque, 1.0));
            vec3 localPosOpaque = (gbufferModelViewInverse * vec4(viewPosOpaque, 1.0)).xyz;
        #else
            vec3 localPosOpaque = unproject(gbufferModelViewProjectionInverse * vec4(clipPosOpaque, 1.0));
        #endif

        //float transDepth = isEyeInWater == 1 ? viewDist :
        //    max(length(localPosOpaque) - viewDist, 0.0);

        #if DIST_BLUR_MODE != DIST_BLUR_OFF || defined WATER_BLUR
            float blurDist = 0.0;
            if (depth < depthOpaque) {
                float opaqueDist = length(localPosOpaque);

                // water blur depth
                #if WATER_DEPTH_LAYERS > 1
                    //uvec2 waterScreenUV = uvec2(gl_FragCoord.xy);
                    //uint waterPixelIndex = uint(waterScreenUV.y * viewWidth + waterScreenUV.x);

                    float waterDepth[WATER_DEPTH_LAYERS+1];
                    GetAllWaterDepths(waterPixelIndex, viewDist, waterDepth);

                    if (isEyeInWater == 1) {
                        if (waterDepth[1] < opaqueDist)
                            blurDist += max(min(waterDepth[2], opaqueDist) - min(waterDepth[1], opaqueDist), 0.0);

                        #if WATER_DEPTH_LAYERS >= 4
                            if (waterDepth[3] < opaqueDist)
                                blurDist += max(min(waterDepth[4], opaqueDist) - min(waterDepth[3], opaqueDist), 0.0);
                        #endif

                        #if WATER_DEPTH_LAYERS >= 6
                            if (waterDepth[4] < opaqueDist)
                                blurDist += max(min(waterDepth[5], opaqueDist) - min(waterDepth[4], opaqueDist), 0.0);
                        #endif
                    }
                    else {
                        if (waterDepth[0] < opaqueDist)
                            blurDist += max(min(waterDepth[1], opaqueDist) - min(waterDepth[0], opaqueDist), 0.0);

                        #if WATER_DEPTH_LAYERS >= 3
                            if (waterDepth[2] < opaqueDist)
                                blurDist += max(min(waterDepth[3], opaqueDist) - min(waterDepth[2], opaqueDist), 0.0);
                        #endif

                        #if WATER_DEPTH_LAYERS >= 5
                            if (waterDepth[4] < opaqueDist)
                                blurDist += max(min(waterDepth[5], opaqueDist) - min(waterDepth[4], opaqueDist), 0.0);
                        #endif
                    }
                #else
                    blurDist = max(opaqueDist - viewDist, 0.0);
                #endif
            }

            vec3 opaqueFinal = GetBlur(depthtex1, texcoord + refraction, linearDepthOpaque, depth, blurDist, isWater && isEyeInWater != 1);
        #else
            //float lodOpaque = 4.0 * float(isWater) * min(transDepth / 20.0, 1.0);
            // float maxLod = clamp(log2(min(viewWidth, viewHeight)) - 1.0, 0.0, 4.0);

            // float lodOpaque = 0.0;
            // #ifdef REFRACTION_BLUR
            //     if (isWater)
            //         lodOpaque = maxLod * min(min(viewDist, transDepth) / 12.0, 1.0);
            //     else if (isEyeInWater != 1)
            //         lodOpaque = maxLod * min(transDepth * roughL / 2.0, 1.0);
            // #endif

            vec3 opaqueFinal = textureLod(BUFFER_FINAL, texcoord + refraction, 0).rgb;
        #endif

        // #ifdef DH_COMPAT_ENABLED
        //     opaqueFinal = RGBToLinear(opaqueFinal);
        // #endif

        #if defined MATERIAL_REFRACT_ENABLED && defined REFRACTION_SNELL
            if (tir) {
                opaqueFinal = GetCustomWaterFogColor(localSunDirection.y);
            }
        #endif

        // #ifdef DH_COMPAT_ENABLED
        //     float fogDist = GetVanillaFogDistance(localPos);
        //     float fogF = GetFogFactor(fogDist, 0.6 * far, far, 1.0);
        //     final.a *= 1.0 - fogF;
        // #endif

        if (isWater) {
            //final.rgb *= final.a;
            final.rgb += opaqueFinal * (1.0 - final.a);
        }
        else {
            vec3 tint = albedo;
            if (any(greaterThan(tint, EPSILON3)))
                tint = normalize(tint) * 1.7;

            tint = mix(tint, vec3(1.0), pow(1.0 - final.a, 3.0));
            final.rgb = mix(opaqueFinal * tint, final.rgb, final.a);
        }

        #if defined WORLD_WATER_ENABLED && !defined VL_BUFFER_ENABLED
            if (isEyeInWater == 1) {
                final.rgb *= exp(viewDist * -WaterAbsorbColorInv);
            }
        #endif

        final.a = 1.0;

        #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
            //float fogF = 0.0;

            #ifdef WORLD_WATER_ENABLED
                if (isEyeInWater == 1) {
                    // water fog

                    #ifndef VL_BUFFER_ENABLED
                        vec3 skyColorFinal = RGBToLinear(skyColor);
                        fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                        float fogF = GetCustomWaterFogFactor(viewDist);
                        final.rgb = mix(final.rgb, fogColorFinal, fogF);
                    #endif
                }
                else {
            #endif
                float fogF;
                float fogDist = GetVanillaFogDistance(localPos);

                if (depth < 1.0) {
                    #ifndef DH_COMPAT_ENABLED
                        #ifdef WORLD_SKY_ENABLED
                            // sky fog

                            vec3 skyColorFinal = RGBToLinear(skyColor);
                            fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                            fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, localViewDir.y);
                        #else
                            // no-sky fog

                            fogColorFinal = RGBToLinear(fogColor);
                            //fogF = GetVanillaFogFactor(localPos);
                        #endif

                        fogF = GetCustomFogFactor(fogDist);
                        final.rgb = mix(final.rgb, fogColorFinal, fogF);
                    #endif
                }

                #ifdef WORLD_SKY_ENABLED
                    fogDist = min(length(localPos), far);
                    ApplyCustomRainFog(final.rgb, fogDist, localSunDirection.y);
                #endif
            #ifdef WORLD_WATER_ENABLED
                }
            #endif

            //final.rgb = mix(final.rgb, fogColorFinal, fogF);
        #endif

        #if defined WORLD_WATER_ENABLED && defined VL_BUFFER_ENABLED
            if (isEyeInWater == 1) {
                final.rgb *= exp(viewDist * -WaterAbsorbColorInv);
            }
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
        //float weatherDepth = textureLod(BUFFER_WEATHER_DEPTH, texcoord, 0).r;
        //weatherColor.a *= step(weatherDepth, depthOpaque);

        final = mix(final, weatherColor, weatherColor.a);
        
        // #ifdef DH_COMPAT_ENABLED
        //     if (deferredColor.a > (0.5/255.0) || weatherColor.a > (0.5/255.0))
        //         ApplyPostProcessing(final.rgb);
        // #endif

        outFinal = final;
    }
#else
    // Pass-through for world-specific flags not working in shader.properties
    
    uniform sampler2D colortex0;


    void main() {
        outFinal = texture(colortex0, texcoord);
    }
#endif
