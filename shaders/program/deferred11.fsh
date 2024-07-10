#define RENDER_OPAQUE_SSAO
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D BUFFER_DEFERRED_NORMAL_TEX;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform int frameCounter;

#ifdef DISTANT_HORIZONS
    uniform mat4 dhProjectionInverse;
    uniform float dhFarPlane;
#endif

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/effects/ssao.glsl"

// #ifdef EFFECT_TAA_ENABLED
//     #include "/lib/effects/taa_jitter.glsl"
// #endif


/* RENDERTARGETS: 6 */
layout(location = 0) out float outAO;

void main() {
    // vec2 coord = texcoord;

    // #ifdef EFFECT_TAA_ENABLED
    //     coord -= getJitterOffset(frameCounter);
    // #endif

    float depth = textureLod(depthtex0, texcoord, 0).r;

    #ifdef DISTANT_HORIZONS
        mat4 projectionInv = gbufferProjectionInverse;

        if (depth >= 1.0) {
            depth = textureLod(dhDepthTex0, texcoord, 0).r;
            projectionInv = dhProjectionInverse;
        }
    #endif

    vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;

    #ifdef DISTANT_HORIZONS
        vec3 viewPos = unproject(projectionInv, clipPos);
    #else
        vec3 viewPos = unproject(gbufferProjectionInverse, clipPos);
    #endif

    float occlusion = 0.0;

    if (depth < 1.0) {
        vec3 texViewNormal = texelFetch(BUFFER_DEFERRED_NORMAL_TEX, ivec2(gl_FragCoord.xy), 0).rgb;

        if (any(greaterThan(texViewNormal, EPSILON3))) {
            texViewNormal = normalize(texViewNormal * 2.0 - 1.0);
            texViewNormal = mat3(gbufferModelView) * texViewNormal;
        }

        occlusion = GetSpiralOcclusion(viewPos, texViewNormal);

        // fade away from nearby surfaces
        float viewDist = length(viewPos);
        occlusion *= smoothstep(0.0, 3.0, viewDist);
    }

    outAO = 1.0 - occlusion;
}
