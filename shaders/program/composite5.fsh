#define RENDER_OPAQUE_POST_VL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    const bool colortex0MipmapEnabled = true;
#endif

in vec2 texcoord;

#ifdef DEFERRED_BUFFER_ENABLED
    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;
    uniform sampler2D depthtex2;
    uniform sampler2D BUFFER_FINAL;
    uniform sampler2D BUFFER_DEFERRED_SHADOW;

    #if MATERIAL_REFLECTIONS == REFLECT_SCREEN
        uniform sampler2D BUFFER_DEFERRED_COLOR;
        uniform usampler2D BUFFER_DEFERRED_DATA;
        uniform sampler2D texDepthNear;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            uniform sampler2D BUFFER_ROUGHNESS;
        #endif
    #endif

    #ifdef VL_BUFFER_ENABLED
        uniform sampler2D BUFFER_VL;
    #endif

    #if defined MATERIAL_REFLECT_CLOUDS && MATERIAL_REFLECTIONS != REFLECT_NONE && defined WORLD_SKY_ENABLED && defined IS_IRIS
        #if WORLD_CLOUD_TYPE == CLOUDS_CUSTOM
            uniform sampler3D TEX_CLOUDS;
        #elif WORLD_CLOUD_TYPE == CLOUDS_VANILLA
            uniform sampler2D TEX_CLOUDS;
        #endif
    #endif

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferProjectionInverse;
    uniform vec3 upPosition;
    uniform float viewWidth;
    uniform float viewHeight;
    uniform float aspectRatio;
    uniform vec2 viewSize;
    uniform vec2 pixelSize;
    uniform float near;
    uniform float far;

    uniform int fogShape;
    uniform vec3 fogColor;
    uniform float fogStart;
    uniform float fogEnd;

    uniform int worldTime;
    uniform ivec2 eyeBrightnessSmooth;

    #ifndef IRIS_FEATURE_SSBO
        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;
    #endif

    #if MATERIAL_REFLECTIONS == REFLECT_SCREEN
        uniform mat4 gbufferProjection;
    #endif

    #ifdef WORLD_SKY_ENABLED
        uniform vec3 skyColor;
        uniform float rainStrength;

        #ifndef IRIS_FEATURE_SSBO
            uniform vec3 sunPosition;
        #endif

        #if defined MATERIAL_REFLECT_CLOUDS && MATERIAL_REFLECTIONS != REFLECT_NONE && defined IS_IRIS
            uniform vec3 cameraPosition;
            uniform vec3 eyePosition;
            uniform float cloudTime;
            uniform float cloudHeight = WORLD_CLOUD_HEIGHT;
        #endif
    #endif

    #ifdef WORLD_WATER_ENABLED
        uniform int isEyeInWater;
        uniform vec3 WaterAbsorbColor;
        uniform vec3 WaterScatterColor;
        uniform float waterDensitySmooth;
    #endif

    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/buffers/scene.glsl"

        #if defined WORLD_WATER_ENABLED && WATER_DEPTH_LAYERS > 1
            #include "/lib/buffers/water_depths.glsl"
        #endif
    #endif

    #include "/lib/sampling/depth.glsl"
    #include "/lib/sampling/noise.glsl"
    #include "/lib/sampling/bayer.glsl"
    #include "/lib/sampling/ign.glsl"

    #include "/lib/world/common.glsl"
    #include "/lib/world/fog.glsl"

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"

        #if WORLD_CLOUD_TYPE == CLOUDS_CUSTOM
            #include "/lib/world/clouds.glsl"
        #endif
    #endif

    #ifdef WORLD_WATER_ENABLED
        #include "/lib/world/water.glsl"
    #endif

    #if MATERIAL_REFLECTIONS == REFLECT_SCREEN
        #if MATERIAL_SPECULAR != SPECULAR_NONE
            #include "/lib/blocks.glsl"
            #include "/lib/items.glsl"
            #include "/lib/material/hcm.glsl"
            #include "/lib/material/specular.glsl"
        #endif

        #if defined MATERIAL_REFLECT_CLOUDS && WORLD_CLOUD_TYPE == CLOUDS_VANILLA && defined WORLD_SKY_ENABLED && defined IS_IRIS
            #include "/lib/shadows/clouds.glsl"

            //#include "/lib/world/clouds.glsl"
        #endif

        #include "/lib/utility/depth_tiles.glsl"
        #include "/lib/lighting/ssr.glsl"
        #include "/lib/lighting/fresnel.glsl"
        #include "/lib/lighting/reflections.glsl"
    #endif

    //#include "/lib/sampling/bilateral_gaussian.glsl"
    //#include "/lib/world/volumetric_blur.glsl"

    #ifdef VL_BUFFER_ENABLED
        #ifdef VOLUMETRIC_BLUR
            #include "/lib/sampling/bilateral_gaussian.glsl"
            #include "/lib/world/volumetric_blur.glsl"
        #endif
    #else
        //#include "/lib/world/clouds.glsl"
    #endif
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

#ifdef DEFERRED_BUFFER_ENABLED
    void main() {
        ivec2 iTex = ivec2(gl_FragCoord.xy);

        //float depth = texelFetch(depthtex1, iTex, 0).r;
        //float handClipDepth = texelFetch(depthtex2, iTex, 0).r;
        float depthOpaque = texelFetch(depthtex1, iTex, 0).r;
        float depthTranslucent = texelFetch(depthtex0, iTex, 0).r;
        //float handClipDepth = textureLod(depthtex2, texcoord, 0).r;
        //bool isHand = handClipDepth > depthOpaque;

        // if (isHand) {
        //     depth = depth * 2.0 - 1.0;
        //     depth /= MC_HAND_DEPTH;
        //     depth = depth * 0.5 + 0.5;
        // }

        vec3 final = texelFetch(BUFFER_FINAL, iTex, 0).rgb;

        //vec2 viewSize = vec2(viewWidth, viewHeight);

        vec3 clipPosOpaque = vec3(texcoord, depthOpaque) * 2.0 - 1.0;
        vec3 clipPosTranslucent = vec3(texcoord, depthTranslucent) * 2.0 - 1.0;

        #ifndef IRIS_FEATURE_SSBO
            vec3 viewPosOpaque = unproject(gbufferProjectionInverse * vec4(clipPosOpaque, 1.0));
            vec3 viewPosTranslucent = unproject(gbufferProjectionInverse * vec4(clipPosTranslucent, 1.0));
            vec3 localPosOpaque = (gbufferModelViewInverse * vec4(viewPosOpaque, 1.0)).xyz;
            vec3 localPosTranslucent = (gbufferModelViewInverse * vec4(viewPosTranslucent, 1.0)).xyz;
        #else
            vec3 viewPosOpaque = unproject(gbufferProjectionInverse * vec4(clipPosOpaque, 1.0));
            vec3 localPosOpaque = (gbufferModelViewInverse * vec4(viewPosOpaque, 1.0)).xyz;
            vec3 localPosTranslucent = unproject(gbufferModelViewProjectionInverse * vec4(clipPosTranslucent, 1.0));
        #endif
        
        vec3 localViewDir = normalize(localPosOpaque);

        #if MATERIAL_REFLECTIONS == REFLECT_SCREEN && MATERIAL_SPECULAR != SPECULAR_NONE
            vec2 deferredRoughMetalF0 = texelFetch(BUFFER_ROUGHNESS, iTex, 0).rg;
            float roughness = deferredRoughMetalF0.r;
            float metal_f0 = deferredRoughMetalF0.g;
            float roughL = _pow2(roughness);

            vec4 deferredColor = texelFetch(BUFFER_DEFERRED_COLOR, iTex, 0);
            uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
            vec4 deferredLighting = unpackUnorm4x8(deferredData.g);
            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            vec3 texNormal = deferredTexture.xyz;

            float skyNoVm = 1.0;
            if (any(greaterThan(texNormal, EPSILON3))) {
                texNormal = normalize(texNormal * 2.0 - 1.0);
                skyNoVm = max(dot(texNormal, -localViewDir), 0.0);
            }

            vec3 albedo = RGBToLinear(deferredColor.rgb);
            vec3 f0 = GetMaterialF0(albedo, metal_f0);
            
            vec3 skyReflectF = GetReflectiveness(skyNoVm, f0, roughL);
            vec3 texViewNormal = mat3(gbufferModelView) * texNormal;
            vec3 specular = ApplyReflections(localPosOpaque, viewPosOpaque, texViewNormal, deferredLighting.y, roughness) * skyReflectF;

            specular *= GetMetalTint(albedo, metal_f0);

            final += specular;
        #endif

        if (depthTranslucent < depthOpaque) {
            #ifdef WORLD_WATER_ENABLED
                //uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
                //vec4 deferredTexture = unpackUnorm4x8(deferredData.a);

                #if WATER_DEPTH_LAYERS > 1
                    uvec2 waterScreenUV = uvec2(gl_FragCoord.xy);
                    uint waterPixelIndex = uint(waterScreenUV.y * viewWidth + waterScreenUV.x);
                    bool isWater = WaterDepths[waterPixelIndex].IsWater;
                #else
                    float deferredShadowA = texelFetch(BUFFER_DEFERRED_SHADOW, iTex, 0).a;
                    bool isWater = deferredShadowA > 0.5;
                #endif

                float distOpaque = length(localPosOpaque);
                float distTranslucent = length(localPosTranslucent);
                float waterDepthFinal = 0.0;
                float waterDepthAirFinal = 0.0;

                if (isWater) {
                    #if WATER_DEPTH_LAYERS > 1
                        float waterDepth[WATER_DEPTH_LAYERS+1];
                        GetAllWaterDepths(waterPixelIndex, distTranslucent, waterDepth);

                        if (isEyeInWater == 1) {
                            if (waterDepth[1] < distOpaque) {
                                waterDepthFinal += max(min(waterDepth[2], distOpaque) - min(waterDepth[1], distOpaque), 0.0);
                            }

                            #if WATER_DEPTH_LAYERS >= 4
                                if (waterDepth[3] < distOpaque)
                                    waterDepthFinal += max(min(waterDepth[4], distOpaque) - min(waterDepth[3], distOpaque), 0.0);
                            #endif
                        }
                        else {
                            waterDepthFinal = max(min(waterDepth[1], distOpaque) - min(waterDepth[0], distOpaque), 0.0);

                            #if WATER_DEPTH_LAYERS >= 3
                                if (waterDepth[2] < distOpaque)
                                    waterDepthFinal += max(min(waterDepth[3], distOpaque) - min(waterDepth[2], distOpaque), 0.0);
                            #endif

                            #if WATER_DEPTH_LAYERS >= 5
                                if (waterDepth[4] < distOpaque)
                                    waterDepthFinal += max(min(waterDepth[5], distOpaque) - min(waterDepth[4], distOpaque), 0.0);
                            #endif
                        }
                    #else
                        if (isEyeInWater != 1) {
                            waterDepthFinal = distOpaque - distTranslucent;
                        }
                    #endif

                    //final *= exp(waterDepthFinal * -WaterAbsorbColorInv);
                }
            #endif

            #if defined WORLD_WATER_ENABLED && !defined VL_BUFFER_ENABLED
                if (isWater) {
                    final *= exp(waterDepthFinal * -WaterAbsorbColorInv);
                }
            #endif

            #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
                float fogDist  = GetVanillaFogDistance(localPosOpaque);

                #if !defined IRIS_FEATURE_SSBO && defined WORLD_SKY_ENABLED
                    vec3 localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
                #endif

                #ifndef DH_COMPAT_ENABLED
                    if (depthOpaque < 1.0) {
                        vec3 fogColorFinal = vec3(0.0);
                        float fogF = 0.0;

                        #ifdef WORLD_SKY_ENABLED
                            // sky fog

                            vec3 skyColorFinal = RGBToLinear(skyColor);
                            fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                            fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, localViewDir.y);

                            //float fogDist  = GetVanillaFogDistance(localPosOpaque);
                            fogF = GetCustomFogFactor(fogDist);
                        #else
                            // no-sky fog

                            fogColorFinal = RGBToLinear(fogColor);
                            //fogF = GetVanillaFogFactor(localPosOpaque);

                            //float fogDist  = GetVanillaFogDistance(localPosOpaque);
                            fogF = GetCustomFogFactor(fogDist);
                        #endif

                        final = mix(final, fogColorFinal, fogF);
                    }
                #endif

                #ifdef WORLD_SKY_ENABLED
                    fogDist = length(localPosOpaque);
                    ApplyCustomRainFog(final, fogDist, localSunDirection.y);
                #endif

                #if defined WORLD_WATER_ENABLED && !defined VL_BUFFER_ENABLED
                    if (isWater) {
                        // water fog from outside water

                        float fogDist = max(waterDepthFinal, 0.0);
                        float fogF = GetCustomWaterFogFactor(fogDist);

                        #ifdef WORLD_SKY_ENABLED
                            vec3 fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                        #else
                            vec3 fogColorFinal = GetCustomWaterFogColor(0.0);
                        #endif

                        final = mix(final, fogColorFinal, fogF);
                    }
                #endif
            #endif

            #if defined WORLD_WATER_ENABLED && defined VL_BUFFER_ENABLED
                if (isWater) {
                    final *= exp(waterDepthFinal * -WaterAbsorbColorInv);
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

                    vec4 vlScatterTransmit = BilateralGaussianDepthBlur_VL(texcoord, BUFFER_VL, viewSize * bufferScale, depthtex1, viewSize, depthOpaque, vlSigma);
                #else
                    vec4 vlScatterTransmit = textureLod(BUFFER_VL, texcoord, 0);
                #endif

                final = final * vlScatterTransmit.a + vlScatterTransmit.rgb;
            #elif WORLD_CLOUD_TYPE == CLOUDS_CUSTOM
                if (isEyeInWater == 1) {
                    float viewDist = length(localPosOpaque);
                    vec2 cloudAbsorbScatter = SampleClouds2(cameraPosition, localViewDir, viewDist, depthOpaque);
                    final = final * cloudAbsorbScatter.x + WorldSkyLightColor * cloudAbsorbScatter.y;
                }
            #endif
        }

        outFinal = vec4(final, 1.0);
    }
#else
    // Pass-through for world-specific flags not working in shader.properties
    
    uniform sampler2D BUFFER_FINAL;


    void main() {
        outFinal = texelFetch(BUFFER_FINAL, ivec2(gl_FragCoord.xy), 0);
    }
#endif
