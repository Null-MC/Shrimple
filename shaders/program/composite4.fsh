#define RENDER_OPAQUE_POST_VL
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D BUFFER_FINAL;
uniform usampler2D BUFFER_DEFERRED_DATA;

#ifdef VL_BUFFER_ENABLED
    uniform sampler2D BUFFER_VL;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 upPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

uniform ivec2 eyeBrightnessSmooth;

#ifndef IRIS_FEATURE_SSBO
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferPreviousProjection;
#endif

#if MATERIAL_REFLECTIONS == REFLECT_SCREEN
    uniform mat4 gbufferProjection;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/world/common.glsl"

#ifdef WORLD_WATER_ENABLED
    #include "/lib/world/water.glsl"
#endif

#include "/lib/sampling/bilateral_gaussian.glsl"
#include "/lib/world/volumetric_blur.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

#if defined VL_BUFFER_ENABLED && defined DEFERRED_BUFFER_ENABLED
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

        if (depthTranslucent < depthOpaque) {
            vec2 viewSize = vec2(viewWidth, viewHeight);
            
            #ifdef WORLD_WATER_ENABLED
                vec3 clipPosOpaque = vec3(texcoord, depthOpaque) * 2.0 - 1.0;
                vec3 clipPosTranslucent = vec3(texcoord, depthTranslucent) * 2.0 - 1.0;

                #ifndef IRIS_FEATURE_SSBO
                    vec3 viewPosOpaque = unproject(gbufferProjectionInverse * vec4(clipPosOpaque, 1.0));
                    vec3 viewPosTranslucent = unproject(gbufferProjectionInverse * vec4(clipPosTranslucent, 1.0));
                    vec3 localPosOpaque = (gbufferModelViewInverse * vec4(viewPosOpaque, 1.0)).xyz;
                    vec3 localPosTranslucent = (gbufferModelViewInverse * vec4(viewPosTranslucent, 1.0)).xyz;
                #else
                    vec3 localPosOpaque = unproject(gbufferModelViewProjectionInverse * vec4(clipPosOpaque, 1.0));
                    vec3 localPosTranslucent = unproject(gbufferModelViewProjectionInverse * vec4(clipPosTranslucent, 1.0));
                #endif

                uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, iTex, 0);
                vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
                bool isWater = deferredTexture.a < 0.5;

                if (isEyeInWater != 1 && isWater) {
                    float waterDist = length(localPosOpaque - localPosTranslucent);
                    final *= exp(waterDist * -WaterAbsorbColorInv);
                }
            #endif

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
