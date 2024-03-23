#define RENDER_SCREEN_SHADOWS
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform int frameCounter;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float aspectRatio;
uniform float farPlane;
uniform float near;
uniform float far;

// uniform vec3 fogColor;
// uniform float fogStart;
// uniform float fogEnd;
// uniform int fogShape;

// #ifdef WORLD_SKY_ENABLED
//     uniform vec3 skyColor;

//     uniform float rainStrength;
//     uniform float skyRainStrength;
//     uniform ivec2 eyeBrightnessSmooth;
// #endif

#ifdef DISTANT_HORIZONS
    uniform mat4 dhProjection;
    uniform mat4 dhProjectionInverse;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif


/* RENDERTARGETS: 2 */
layout(location = 0) out vec4 outShadow;

void main() {
    ivec2 iTexDepth = ivec2(texcoord * viewSize);
    float depth = texelFetch(depthtex1, iTexDepth, 0).r;

    #ifdef DISTANT_HORIZONS
        float dhDepth = texelFetch(dhDepthTex, iTexDepth, 0).r;
        float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);
        float depthL = linearizeDepth(depth, near, farPlane);
        mat4 projectionInv = gbufferProjectionInverse;

        if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
            projectionInv = dhProjectionInverse;
            depthL = dhDepthL;
            depth = dhDepth;
        }
    #endif

    float occlusion = 1.0;

    if (depth < 1.0) {
        #ifdef EFFECT_TAA_ENABLED
            float dither = InterleavedGradientNoiseTime();
        #else
            float dither = InterleavedGradientNoise();
        #endif

        vec3 clipPosStart = vec3(texcoord, depth);
        vec3 clipPos = clipPosStart * 2.0 - 1.0;

        #ifdef DISTANT_HORIZONS
            vec3 viewPos = unproject(projectionInv, clipPos);
            //vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
        #else
            // #ifndef IRIS_FEATURE_SSBO
            //     vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
            //     vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
            // #else
            //     vec3 localPos = unproject(gbufferModelViewProjectionInverse, clipPos);
            // #endif
            vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
        #endif

        float viewDist = length(viewPos);
        vec3 lightViewDir = mat3(gbufferModelView) * localSkyLightDirection;
        vec3 endViewPos = lightViewDir * viewDist * 0.1 + viewPos;

        #ifdef DISTANT_HORIZONS
            vec3 clipPosEnd = unproject(dhProjectionFull, endViewPos) * 0.5 + 0.5;

            clipPosStart = unproject(dhProjectionFull, viewPos) * 0.5 + 0.5;
        #else
            vec3 clipPosEnd = unproject(gbufferProjection, endViewPos) * 0.5 + 0.5;
        #endif

        vec3 traceScreenDir = normalize(clipPosEnd - clipPosStart);

        vec3 traceScreenStep = traceScreenDir * pixelSize.y;
        vec2 traceScreenDirAbs = abs(traceScreenDir.xy);
        traceScreenStep /= (traceScreenDirAbs.y > 0.5 * aspectRatio ? traceScreenDirAbs.y : traceScreenDirAbs.x);

        vec3 traceScreenPos = clipPosStart;
        traceScreenStep *= 1.0 + dither;

        // TODO: get deferred SSS

        for (uint i = 0; i < SHADOW_SCREEN_STEPS; i++) {
            traceScreenPos += traceScreenStep;

            if (saturate(traceScreenPos) != traceScreenPos) break;

            ivec2 sampleUV = ivec2(traceScreenPos.xy * viewSize);
            float sampleDepth = texelFetch(depthtex1, sampleUV, 0).r;

            #ifdef DISTANT_HORIZONS
                float sampleDepthL = linearizeDepth(sampleDepth, near, farPlane);

                float dhSampleDepth = texelFetch(dhDepthTex, sampleUV, 0).r;
                float dhSampleDepthL = linearizeDepth(dhSampleDepth, dhNearPlane, dhFarPlane);

                if (sampleDepth >= 1.0 || (dhSampleDepthL < sampleDepthL && dhSampleDepth > 0.0)) {
                    sampleDepthL = dhSampleDepthL;
                    sampleDepth = dhSampleDepth;
                }

                float traceDepthL = linearizeDepth(traceScreenPos.z, near, dhFarPlane);
            #else
                float traceDepthL = linearizeDepth(traceScreenPos.z, near, farPlane);
            #endif

            float sampleDiff = traceDepthL - sampleDepthL;
            if (sampleDiff > 0.0) {
                // occlusion *= 1.0 - rcp(sampleDiff + 1.0);
                // break;
                vec3 traceViewPos = unproject(dhProjectionFullInv, traceScreenPos * 2.0 - 1.0);

                float traceDist = length(traceViewPos - viewPos);

                // occlusion *= 1.0 - saturate(sampleDiff/traceDist);
                occlusion *= step(traceDist, sampleDiff);
                //break;
            }

            if (occlusion < EPSILON) break;
        }
    }

    outShadow = vec4(vec3(occlusion), 1.0);
}
