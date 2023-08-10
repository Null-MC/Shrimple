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

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferProjectionInverse;
    uniform vec3 upPosition;
    uniform float viewWidth;
    uniform float viewHeight;
    uniform ivec2 viewSize;
    uniform vec2 pixelSize;
    uniform float near;
    uniform float far;

    uniform vec3 fogColor;
    uniform float fogStart;
    uniform float fogEnd;

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
    #endif

    #ifdef WORLD_WATER_ENABLED
        uniform int isEyeInWater;
        uniform vec3 WaterAbsorbColor;
        uniform vec3 WaterScatterColor;
    #endif

    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/buffers/scene.glsl"
    #endif

    #include "/lib/sampling/depth.glsl"
    #include "/lib/sampling/noise.glsl"
    #include "/lib/sampling/bayer.glsl"
    #include "/lib/sampling/ign.glsl"

    #include "/lib/world/common.glsl"
    #include "/lib/world/fog.glsl"

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"
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

        #include "/lib/lighting/ssr.glsl"
        #include "/lib/lighting/fresnel.glsl"
        #include "/lib/lighting/reflections.glsl"
    #endif

    #include "/lib/sampling/bilateral_gaussian.glsl"
    #include "/lib/world/volumetric_blur.glsl"
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

        vec2 viewSize = vec2(viewWidth, viewHeight);

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
            vec3 specular = ApplyReflections(viewPosOpaque, texViewNormal, deferredLighting.y, roughness) * skyReflectF;

            specular *= GetMetalTint(albedo, metal_f0);

            final += specular;
        #endif

        if (depthTranslucent < depthOpaque) {
            #ifdef WORLD_WATER_ENABLED
                //uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
                //vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
                float deferredShadowA = texelFetch(BUFFER_DEFERRED_SHADOW, iTex, 0).a;
                bool isWater = deferredShadowA < 0.5;

                float distOpaque = length(localPosOpaque);
                float distTranslucent = length(localPosTranslucent);

                if (isWater && isEyeInWater != 1) {
                    final *= exp((distOpaque - distTranslucent) * -WaterAbsorbColorInv);
                }
            #endif

            #if WORLD_FOG_MODE == FOG_MODE_CUSTOM
                vec3 fogColorFinal = vec3(0.0);
                float fogF = 0.0;

                #ifdef WORLD_WATER_ENABLED
                    if (isWater && isEyeInWater != 1) {
                        // water fog from outside water

                        #ifndef VL_BUFFER_ENABLED
                            float fogDist = max(distOpaque - distTranslucent, 0.0);
                            fogF = GetCustomWaterFogFactor(fogDist);

                            fogColorFinal = GetCustomWaterFogColor(localSunDirection.y);
                        #endif
                    }
                    else {
                #endif
                    #ifndef DH_COMPAT_ENABLED
                        #ifdef WORLD_SKY_ENABLED
                            // sky fog

                            if (depthOpaque < 1.0) {
                                vec3 skyColorFinal = RGBToLinear(skyColor);
                                fogColorFinal = GetCustomSkyFogColor(localSunDirection.y);
                                fogColorFinal = GetSkyFogColor(skyColorFinal, fogColorFinal, localViewDir.y);

                                float fogDist  = GetVanillaFogDistance(localPosOpaque);
                                fogF = GetCustomFogFactor(fogDist);
                            }
                        #else
                            // no-sky fog

                            fogColorFinal = RGBToLinear(fogColor);
                            //fogF = GetVanillaFogFactor(localPosOpaque);

                            float fogDist  = GetVanillaFogDistance(localPosOpaque);
                            fogF = GetCustomFogFactor(fogDist);
                        #endif
                    #endif
                #ifdef WORLD_WATER_ENABLED
                    }
                #endif

                final = mix(final, fogColorFinal, fogF);
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
