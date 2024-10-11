#define RENDER_SHADOW_TRANSLUCENT
#define RENDER_COMPOSITE
#define RENDER_FRAG
#define RENDER_TRANSLUCENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

#ifdef RENDER_SHADOWS_ENABLED
    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;
    uniform sampler2D depthtex2;

    #ifdef DISTANT_HORIZONS
        uniform sampler2D dhDepthTex0;
        uniform sampler2D dhDepthTex1;
    #endif

    uniform usampler2D BUFFER_DEFERRED_DATA;
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    #ifdef SHADOW_COLORED
        uniform sampler2D shadowcolor0;
    #endif

    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex0HW;
        #else
            uniform sampler2DShadow shadow;
        #endif
    #endif

    #if defined WORLD_SKY_ENABLED && ((MATERIAL_REFLECTIONS != REFLECT_NONE && defined MATERIAL_REFLECT_CLOUDS) || defined SHADOW_CLOUD_ENABLED)
        #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
            uniform sampler3D TEX_CLOUDS;
        #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
            uniform sampler2D TEX_CLOUDS_VANILLA;
        #endif
    #endif

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 cameraPosition;
    uniform int frameCounter;

    uniform vec2 viewSize;
    uniform vec2 pixelSize;
    uniform float aspectRatio;
    uniform float farPlane;
    uniform float near;
    uniform float far;

    #ifndef IRIS_FEATURE_SSBO
        uniform vec3 shadowLightPosition;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform mat4 dhProjection;
        uniform mat4 dhProjectionInverse;
        uniform float dhNearPlane;
        uniform float dhFarPlane;
    #endif

    #if defined WORLD_SKY_ENABLED //&& defined SHADOW_CLOUD_ENABLED
        uniform vec3 eyePosition;
        uniform float weatherStrength;
        uniform float cloudHeight;
        uniform float cloudTime;
    #endif

    #include "/lib/sampling/depth.glsl"
    #include "/lib/sampling/ign.glsl"
    #include "/lib/sampling/noise.glsl"

    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/buffers/scene.glsl"
        #include "/lib/buffers/shadow.glsl"
    #endif

    #if defined WORLD_SKY_ENABLED && defined IS_IRIS
        #include "/lib/clouds/cloud_common.glsl"

        #if (defined MATERIAL_REFLECT_CLOUDS && MATERIAL_REFLECTIONS != REFLECT_NONE) || defined RENDER_CLOUD_SHADOWS_ENABLED
            #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                #include "/lib/clouds/cloud_custom.glsl"
                #include "/lib/clouds/cloud_custom_shadow.glsl"
            #elif SKY_CLOUD_TYPE == CLOUDS_VANILLA
                #include "/lib/clouds/cloud_vanilla.glsl"
                #include "/lib/clouds/cloud_vanilla_shadow.glsl"
            #endif
        #endif
    #endif

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/apply.glsl"
        #include "/lib/shadows/cascaded/render.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/apply.glsl"
        #include "/lib/shadows/distorted/render.glsl"
    #endif

    #if MATERIAL_SSS != 0
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #include "/lib/shadows/cascaded/render_sss.glsl"
        #else
            #include "/lib/shadows/distorted/render_sss.glsl"
        #endif
    #endif

    #ifdef EFFECT_TAA_ENABLED
        #include "/lib/effects/taa_jitter.glsl"
    #endif
#endif


/* RENDERTARGETS: 2 */
layout(location = 0) out vec4 outShadow;

uniform bool hideGUI;

void main() {
    #ifdef RENDER_SHADOWS_ENABLED
        vec2 coord = texcoord;

        #ifdef EFFECT_TAA_ENABLED
            vec2 jitterOffset = getJitterOffset(frameCounter);
            coord -= jitterOffset;
        #endif

        float depthTrans = textureLod(depthtex0, texcoord, 0).r;
        float depthOpaque = textureLod(depthtex1, texcoord, 0).r;
        float depthHand = textureLod(depthtex2, texcoord, 0).r;
        bool isHand = false;//depthHand > depthTrans + EPSILON;

        if (isHand) {
            depthTrans = depthTrans * 2.0 - 1.0;
            depthTrans /= MC_HAND_DEPTH;
            depthTrans = depthTrans * 0.5 + 0.5;

            depthOpaque = depthOpaque * 2.0 - 1.0;
            depthOpaque /= MC_HAND_DEPTH;
            depthOpaque = depthOpaque * 0.5 + 0.5;
        }

        float depthTransL = linearizeDepth(depthTrans, near, farPlane);
        float depthOpaqueL = linearizeDepth(depthOpaque, near, farPlane);
        mat4 projectionInv = gbufferProjectionInverse;

        #ifdef DISTANT_HORIZONS
            float dhDepthTrans = textureLod(dhDepthTex0, texcoord, 0).r;
            float dhDepthTransL = linearizeDepth(dhDepthTrans, dhNearPlane, dhFarPlane);

            if (depthTrans >= 1.0 || (dhDepthTransL < depthTransL && dhDepthTrans > 0.0)) {
                projectionInv = dhProjectionInverse;
                depthTransL = dhDepthTransL;
                depthTrans = dhDepthTrans;
            }

            float dhDepthOpaque = textureLod(dhDepthTex1, texcoord, 0).r;
            float dhDepthOpaqueL = linearizeDepth(dhDepthOpaque, dhNearPlane, dhFarPlane);

            if (depthOpaque >= 1.0 || (dhDepthOpaqueL < depthOpaqueL && dhDepthOpaque > 0.0)) {
                // projectionInv = dhProjectionInverse;
                depthOpaqueL = dhDepthOpaqueL;
                //depthOpaque = dhDepthOpaque;
            }
        #endif

        vec3 shadowFinal = vec3(1.0);
        float sssFinal = 0.0;

        if (depthTransL < depthOpaqueL) {
            #ifdef EFFECT_TAA_ENABLED
                float dither = InterleavedGradientNoiseTime();
            #else
                float dither = InterleavedGradientNoise();
            #endif

            vec3 clipPosStart = vec3(coord, depthTrans);

            #ifdef DISTANT_HORIZONS
                vec3 viewPos = unproject(projectionInv, clipPosStart * 2.0 - 1.0);
            #else
                vec3 viewPos = unproject(gbufferProjectionInverse, clipPosStart * 2.0 - 1.0);
            #endif

            // float sss = 0.0;
            ivec2 uv = ivec2(texcoord * viewSize);
            uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, uv, 0);
            vec3 localNormal = unpackUnorm4x8(deferredData.r).rgb;
            // #if MATERIAL_SSS != 0
            //     sss = unpackUnorm4x8(deferredData.r).w;
            // #endif

            if (any(greaterThan(localNormal, EPSILON3)))
                localNormal = normalize(localNormal * 2.0 - 1.0);

            #ifndef IRIS_FEATURE_SSBO
                vec3 localSkyLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
            #endif

            vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
            float geoNoL = dot(localNormal, localSkyLightDirection);

            #if SHADOW_PIXELATE > 0
                vec3 worldPos = localPos + cameraPosition;
                vec3 f = floor(fract(worldPos) * SHADOW_PIXELATE) / SHADOW_PIXELATE;
                localPos = floor(worldPos) - cameraPosition + f;
            #endif

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                int shadowTile;
                vec3 shadowPos[4];
                ApplyShadows(localPos, localNormal, geoNoL, shadowPos, shadowTile);

                float shadowFade = 0.0; // TODO

                int cascadeIndex = GetShadowCascade(shadowPos, Shadow_MaxPcfSize);
                float zRange = -2.0 / cascadeProjection[cascadeIndex][2][2];
            #else
                vec3 shadowPos = ApplyShadows(localPos, localNormal, geoNoL);

                float shadowFade = float(shadowPos != clamp(shadowPos, -1.0, 1.0));

                // float lmShadow = pow(lmFinal.y, 9);
                // if (shadowPos == clamp(shadowPos, -0.85, 0.85)) lmShadow = 1.0;

                float offsetBias = GetShadowOffsetBias(shadowPos, geoNoL);
                float zRange = GetShadowRange();
            #endif

            #if MATERIAL_SSS != 0
                float sss = unpackUnorm4x8(deferredData.r).w;

                #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                    if (cascadeIndex >= 0) {
                        sssFinal = GetSssFactor(shadowPos[cascadeIndex], cascadeIndex, sss);
                    }
                #else
                    sssFinal = GetSssFactor(shadowPos, offsetBias, sss);
                #endif

                // sssFinal *= step(geoNoL, 0.0);
                sssFinal *= 1.0 - 0.5*(1.0 - max(geoNoL, 0.0));
            #endif

            if (geoNoL > 0.0) {
                // #ifdef SHADOW_COLORED
                //     if (shadowFade < 1.0)
                //         shadowFinal = GetFinalShadowColor(localSkyLightDirection, shadowFade, sss);

                //     // shadowFinal = min(shadowFinal, vec3(lmShadow));
                // #else
                //     float shadowF = 1.0;
                //     if (shadowFade < 1.0)
                //         shadowF = GetFinalShadowFactor(localSkyLightDirection, shadowFade, sss);
                    
                //     //shadowF = min(shadowF, lmShadow);
                //     shadowFinal = vec3(shadowF);
                // #endif

                // vec2 sssOffset = hash22(vec2(dither, 0.0)) - 0.5;
                // sssOffset *= sss * _pow2(dither) * MATERIAL_SSS_SCATTER;

                vec3 shadowSample = vec3(1.0);
                #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                    if (cascadeIndex >= 0) {
                        #ifdef SHADOW_COLORED
                            shadowSample = GetShadowColor(shadowPos[cascadeIndex], cascadeIndex);
                        #else
                            shadowSample = vec3(GetShadowFactor(shadowPos[cascadeIndex], cascadeIndex));
                        #endif
                    }
                #else
                    #ifdef SHADOW_COLORED
                        shadowSample = GetShadowColor(shadowPos, offsetBias);
                    #else
                        shadowSample = vec3(GetShadowFactor(shadowPos, offsetBias));
                    #endif
                #endif

                // shadowSample = vec3(1.0, 0.0, 0.0);

                // shadowFinal *= mix(step(0.0, geoNoL), 1.0, sss);
                // shadowFinal *= step(0.0, geoNoL);
                shadowFinal *= mix(shadowSample, vec3(step(0.0, geoNoL)), shadowFade);
                // shadowFinal = shadowSample;

                #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED
                    float cloudShadow = 1.0;

                    #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                        vec3 worldPos = cameraPosition + localPos;
                        cloudShadow = TraceCloudShadow(worldPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
                    #else
                        vec2 cloudOffset = GetCloudOffset();
                        vec3 camOffset = GetCloudCameraOffset();
                        //vec3 worldPos = cameraPosition + localPos;
                        //float cloudShadow = TraceCloudShadow(worldPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
                        cloudShadow = SampleCloudShadow(localPos, localSkyLightDirection, cloudOffset, camOffset, 0.5);
                    #endif

                    shadowFinal *= cloudShadow * 0.5 + 0.5;
                #endif

                #ifdef SHADOW_SCREEN
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
                    
                    #ifdef EFFECT_TAA_ENABLED
                        clipPosStart.xy += jitterOffset;
                    #endif

                    vec3 traceScreenStep = traceScreenDir * pixelSize.y;
                    vec2 traceScreenDirAbs = abs(traceScreenDir.xy);
                    // traceScreenStep /= (traceScreenDirAbs.y > 0.5 * aspectRatio ? traceScreenDirAbs.y : traceScreenDirAbs.x);
                    traceScreenStep /= mix(traceScreenDirAbs.x, traceScreenDirAbs.y, traceScreenDirAbs.y);

                    vec3 traceScreenPos = clipPosStart;
                    traceScreenStep *= 1.0 + dither;

                    float traceDist = 0.0;
                    float shadowTrace = 1.0;
                    for (uint i = 0; i < SHADOW_SCREEN_STEPS; i++) {
                        if (shadowTrace < EPSILON) break;
                        // if (all(lessThan(shadowTrace * shadowFinal, EPSILON3))) break;

                        traceScreenPos += traceScreenStep;

                        if (saturate(traceScreenPos) != traceScreenPos) break;

                        ivec2 sampleUV = ivec2(traceScreenPos.xy * viewSize);
                        float sampleDepth = texelFetch(depthtex0, sampleUV, 0).r;
                        float sampleDepthHand = texelFetch(depthtex2, sampleUV, 0).r;
                        bool isSampleHand = sampleDepthHand > sampleDepth + EPSILON;

                        if (isSampleHand && !isHand) continue;

                        if (sampleDepthHand > sampleDepth + EPSILON) {
                            sampleDepth = sampleDepth * 2.0 - 1.0;
                            sampleDepth /= MC_HAND_DEPTH;
                            sampleDepth = sampleDepth * 0.5 + 0.5;
                        }

                        float sampleDepthL = linearizeDepth(sampleDepth, near, farPlane);

                        #ifdef DISTANT_HORIZONS
                            float dhSampleDepth = texelFetch(dhDepthTex0, sampleUV, 0).r;
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
                        if (sampleDiff > 0.001 * viewDist) {
                            #ifdef DISTANT_HORIZONS
                                vec3 traceViewPos = unproject(dhProjectionFullInv, traceScreenPos * 2.0 - 1.0);
                            #else
                                vec3 traceViewPos = unproject(gbufferProjectionInverse, traceScreenPos * 2.0 - 1.0);
                            #endif

                            traceDist = length(traceViewPos - viewPos);
                            shadowTrace *= step(traceDist, sampleDiff * ShadowScreenSlope);
                        }
                    }

                    if (traceDist > 0.0) {
                        //float sss_offset = 0.5 * dither * sss * saturate(1.0 - traceDist / MATERIAL_SSS_MAXDIST);
                        shadowFinal *= shadowTrace;// * (1.0 - sss_offset) + sss_offset;
                    }
                #endif
            }
            else {
                shadowFinal = vec3(0.0);
            }
        }

        outShadow = vec4(shadowFinal, sssFinal);
    #else
        outShadow = vec4(1.0);
    #endif
}
