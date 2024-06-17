#define RENDER_SCREEN_SHADOWS
#define RENDER_DEFERRED
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

#ifdef RENDER_SHADOWS_ENABLED
    uniform sampler2D depthtex1;
    uniform sampler2D depthtex2;

    #ifdef DISTANT_HORIZONS
        uniform sampler2D dhDepthTex;
    #endif

    uniform usampler2D BUFFER_DEFERRED_DATA;
    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;

    #ifdef SHADOW_COLORED
        uniform sampler2D shadowcolor0;
    #endif

    #ifdef SHADOW_ENABLE_HWCOMP
        #ifdef IRIS_FEATURE_SEPARATE_HARDWARE_SAMPLERS
            uniform sampler2DShadow shadowtex1HW;
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
        uniform float skyRainStrength;
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
#endif


/* RENDERTARGETS: 2 */
layout(location = 0) out vec4 outShadow;

void main() {
    #ifdef RENDER_SHADOWS_ENABLED
        ivec2 uv = ivec2(texcoord * viewSize);
        float depth = textureLod(depthtex1, texcoord, 0).r;
        float depthHand = textureLod(depthtex2, texcoord, 0).r;
        bool isHand = depthHand > depth + EPSILON;

        if (isHand) {
            depth = depth * 2.0 - 1.0;
            depth /= MC_HAND_DEPTH;
            depth = depth * 0.5 + 0.5;
        }

        #ifdef DISTANT_HORIZONS
            float dhDepth = textureLod(dhDepthTex, texcoord, 0).r;
            float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);
            float depthL = linearizeDepth(depth, near, farPlane);
            mat4 projectionInv = gbufferProjectionInverse;

            if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
                projectionInv = dhProjectionInverse;
                depthL = dhDepthL;
                depth = dhDepth;
            }
        #endif

        vec3 shadowFinal = vec3(1.0);

        if (depth < 1.0) {
            #ifdef EFFECT_TAA_ENABLED
                float dither = InterleavedGradientNoiseTime();
            #else
                float dither = InterleavedGradientNoise();
            #endif

            vec3 clipPosStart = vec3(texcoord, depth);

            #ifdef DISTANT_HORIZONS
                vec3 viewPos = unproject(projectionInv, clipPosStart * 2.0 - 1.0);
            #else
                vec3 viewPos = unproject(gbufferProjectionInverse, clipPosStart * 2.0 - 1.0);
            #endif

            uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, uv, 0);
            vec3 localNormal = unpackUnorm4x8(deferredData.r).rgb;
            float sss = unpackUnorm4x8(deferredData.r).w;

            if (any(greaterThan(localNormal, EPSILON3)))
                localNormal = normalize(localNormal * 2.0 - 1.0);

            #ifndef IRIS_FEATURE_SSBO
                vec3 localSkyLightDirection = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
            #endif

            vec3 localPos = mul3(gbufferModelViewInverse, viewPos);
            float geoNoL = dot(localNormal, localSkyLightDirection);

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

                float zRange = GetShadowRange();
            #endif

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
            
            float sssBias = sss * _pow3(dither) * MATERIAL_SSS_MAXDIST / zRange;

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                vec3 shadowSample = vec3(1.0);

                if (cascadeIndex >= 0) {
                    #ifdef SHADOW_COLORED
                        shadowSample = GetShadowColor(shadowPos[cascadeIndex], cascadeIndex, sssBias);
                    #else
                        shadowSample = vec3(GetShadowFactor(shadowPos[cascadeIndex], cascadeIndex, sssBias));
                    #endif
                }
            #else
                float offsetBias = GetShadowOffsetBias(shadowPos, geoNoL);

                #ifdef SHADOW_COLORED
                    vec3 shadowSample = GetShadowColor(shadowPos, offsetBias, sssBias);
                #else
                    vec3 shadowSample = vec3(GetShadowFactor(shadowPos, offsetBias, sssBias));
                #endif
            #endif

            shadowFinal *= mix(shadowSample, vec3(1.0), shadowFade);

            #if defined WORLD_SKY_ENABLED && defined RENDER_CLOUD_SHADOWS_ENABLED
                #if SKY_CLOUD_TYPE > CLOUDS_VANILLA
                    vec3 worldPos = cameraPosition + localPos;
                    float cloudShadow = TraceCloudShadow(worldPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
                    shadowFinal *= cloudShadow;
                #else
                    vec2 cloudOffset = GetCloudOffset();
                    vec3 camOffset = GetCloudCameraOffset();
                    //vec3 worldPos = cameraPosition + localPos;
                    //float cloudShadow = TraceCloudShadow(worldPos, localSkyLightDirection, CLOUD_SHADOW_STEPS);
                    float cloudShadow = SampleCloudShadow(localPos, localSkyLightDirection, cloudOffset, camOffset, 0.5);
                    shadowFinal *= cloudShadow;
                #endif
            #endif

            #ifdef SHADOW_SCREEN
                if (geoNoL > 0.0) {
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

                    float traceDist = 0.0;
                    float shadowTrace = 1.0;
                    for (uint i = 0; i < SHADOW_SCREEN_STEPS; i++) {
                        if (shadowTrace < EPSILON) break;
                        // if (all(lessThan(shadowTrace * shadowFinal, EPSILON3))) break;

                        traceScreenPos += traceScreenStep;

                        if (saturate(traceScreenPos) != traceScreenPos) break;

                        ivec2 sampleUV = ivec2(traceScreenPos.xy * viewSize);
                        float sampleDepth = texelFetch(depthtex1, sampleUV, 0).r;
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
                        float sss_offset = 0.5 * dither * sss * saturate(1.0 - traceDist / MATERIAL_SSS_MAXDIST);
                        shadowFinal *= shadowTrace * (1.0 - sss_offset) + sss_offset;
                    }
                }
            #endif
        }

        outShadow = vec4(shadowFinal, 1.0);
    #else
        outShadow = vec4(1.0);
    #endif
}
