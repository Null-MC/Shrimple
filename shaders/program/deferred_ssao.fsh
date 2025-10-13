#define RENDER_OPAQUE_SSAO
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform usampler2D BUFFER_DEFERRED_DATA;
uniform sampler2D BUFFER_DEFERRED_NORMAL_TEX;
uniform sampler2D texBlueNoise;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform int frameCounter;
uniform float near;
uniform float farPlane;

#ifdef DISTANT_HORIZONS
    uniform mat4 dhProjection;
    uniform mat4 dhProjectionInverse;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#ifdef EFFECT_SSAO_RT
    #include "/lib/effects/ssao_rt.glsl"
#else
    #include "/lib/effects/ssao.glsl"
#endif

#include "/lib/material/mat_deferred.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


/* RENDERTARGETS: 6 */
layout(location = 0) out float outAO;

void main() {
    vec2 coord = texcoord;

    // #ifdef EFFECT_TAA_ENABLED
    //     vec2 jitterOffset = getJitterOffset(frameCounter);
    //     coord -= jitterOffset;
    // #endif

    float depth = textureLod(depthtex0, texcoord, 0).r;

    #ifdef DISTANT_HORIZONS
        mat4 projectionInv = gbufferProjectionInverse;

        if (depth >= 1.0) {
            depth = textureLod(dhDepthTex, texcoord, 0).r;
            projectionInv = dhProjectionInverse;
        }
    #endif

    float occlusion = 0.0;

    if (depth < 1.0) {
        vec3 clipPos = vec3(coord, depth) * 2.0 - 1.0;

        #ifdef DISTANT_HORIZONS
            vec3 viewPos = unproject(projectionInv, clipPos);
        #else
            vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
        #endif

        ivec2 iuv = ivec2(texcoord * viewSize);

        uint deferredDataB = texelFetch(BUFFER_DEFERRED_DATA, iuv, 0).b;
        float deferredMaterial = unpackUnorm4x8(deferredDataB).r;
        uint matId = uint(deferredMaterial*255.0+0.5);

        if (matId != deferredMat_hand) {
            vec3 texViewNormal = texelFetch(BUFFER_DEFERRED_NORMAL_TEX, iuv, 0).rgb;

            if (any(greaterThan(texViewNormal, EPSILON3))) {
                texViewNormal = normalize(texViewNormal * 2.0 - 1.0);
                texViewNormal = mat3(gbufferModelView) * texViewNormal;
            }

            viewPos.z += EFFECT_SSAO_BIAS * 0.1;

            occlusion = GetSpiralOcclusion(viewPos, texViewNormal);

            // fade away from nearby surfaces
            // float viewDist = length(viewPos);
            // occlusion *= smoothstep(0.0, 3.0, viewDist);
        }
    }

    outAO = 1.0 - occlusion;
}
