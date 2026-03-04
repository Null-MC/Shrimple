#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0
#define SSAO_RADIUS 4.0

const float SSAO_StrengthF = 0.1;
const float SSAO_Bias = 0.08;
const float SSAO_MinLight = 0.3;

in vec2 texcoord;


//uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_DEPTH;
//uniform sampler2D TEX_GI_COLOR;
uniform usampler2D TEX_TEX_NORMAL;
//uniform usampler2D TEX_REFLECT_SPECULAR;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
#endif

uniform float far;
//uniform vec2 viewSize;
uniform int frameCounter;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec2 taa_offset = vec2(0.0);

uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;
uniform float dhNearPlane;

#include "/lib/octohedral.glsl"
#include "/lib/ign.glsl"


#ifdef DISTANT_HORIZONS
    #define SSAO_PROJ projection
    #define SSAO_PROJ_INV projectionInv
#else
    #define SSAO_PROJ gbufferProjection
    #define SSAO_PROJ_INV gbufferProjectionInverse
#endif


float GetSpiralOcclusion(const in vec2 texcoord, const in vec3 viewPos, const in vec3 viewNormal) {
    float dither = InterleavedGradientNoise(gl_FragCoord.xy);

    float rotatePhase = dither * (PI * 2.0);
    const float rStep = SSAO_RADIUS / float(SSAO_SAMPLES);

//    #ifdef DISTANT_HORIZONS
//        #define SSAO_PROJ_INV sharedProjectionInv
//
//        mat4 sharedProjectionInv = gbufferProjectionInverse;
//        gbufferProjectionInverse.
//    #else
//        #define SSAO_PROJ_INV gbufferProjectionInverse
//    #endif

    float ao = 0.0;
    int sampleCount = 0;
    float radius = rStep;
    for (int i = 0; i < SSAO_SAMPLES; i++) {
        vec2 offset = vec2(
            sin(rotatePhase),
            cos(rotatePhase)
        ) * radius;

        radius += rStep;
        rotatePhase += GOLDEN_ANGLE;

        vec3 sampleViewPos = viewPos + vec3(offset, -0.1);

        #ifdef DISTANT_HORIZONS
            mat4 projection = gbufferProjection;
//            float traceNear = nearPlane;
//            float traceFar = farPlane;

            if (abs(sampleViewPos.z) > dhNearPlane) {
                projection = dhProjection;
//                traceNear = dhNearPlane;
//                traceFar = dhFarPlane;
            }
        #endif

        vec3 sampleClipPos = project(SSAO_PROJ, sampleViewPos);
        sampleClipPos = saturate(sampleClipPos * 0.5 + 0.5);

        float sampleClipDepth = texture(TEX_DEPTH, sampleClipPos.xy).r;

        #ifdef DISTANT_HORIZONS
            mat4 projectionInv = gbufferProjectionInverse;

            if (sampleClipDepth >= 1.0) {
                sampleClipDepth = texture(dhDepthTex0, sampleClipPos.xy).r;
                projectionInv = dhProjectionInverse;
            }
        #endif

        if (sampleClipDepth >= 1.0) {
//            maxWeight += 1.0;
            continue;
        }

        sampleClipPos.z = sampleClipDepth;
        sampleClipPos = sampleClipPos * 2.0 - 1.0;
        sampleViewPos = project(SSAO_PROJ_INV, sampleClipPos);

        vec3 diff = sampleViewPos - viewPos;
        float sampleDist = length(diff);
        vec3 sampleNormal = diff / sampleDist;

        float sampleNoLm = max(dot(viewNormal, sampleNormal) - SSAO_Bias, 0.0);
//        float aoF = saturate(sampleDist / SSAO_RADIUS);
//        ao += sampleNoLm * (1.0 - _pow2(aoF));
        ao += sampleNoLm / (1.0 + sampleDist);
        sampleCount++;
    }

    ao /= max(sampleCount, 1);
    ao = smoothstep(0.0, SSAO_StrengthF, ao);

    return ao * (1.0 - SSAO_MinLight);
}



/* RENDERTARGETS: 1 */
layout(location = 0) out float outOcclusion;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float occlusion = 1.0;

    float depth = texelFetch(TEX_DEPTH, uv, 0).r;

    #ifdef DISTANT_HORIZONS
        #define SSAO_PROJ_INV projectionInv
        mat4 projectionInv = gbufferProjectionInverse;

        if (depth >= 1.0) {
            projectionInv = dhProjectionInverse;
            depth = texelFetch(dhDepthTex0, uv, 0).r;
        }
    #else
        #define SSAO_PROJ_INV gbufferProjectionInverse
    #endif

    if (depth < 1.0) {
        uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
//        uint geoNormalData = texelFetch(TEX_GEO_NORMAL, uv, 0).r;

        vec3 screenPos = vec3(texcoord, depth);

        #ifdef TAA_ENABLED
            // screenPos.xy -= taa_offset;
        #endif

        vec3 ndcPos = screenPos * 2.0 - 1.0;

        // TODO: fix hand depth

        vec3 viewPos = project(SSAO_PROJ_INV, ndcPos);
        float viewDist = length(viewPos);

        if (viewDist >= 0.9 * far) {
//            vec3 localGeoNormal = OctDecode(unpackUnorm2x16(geoNormalData));
            vec3 viewTexNormal = OctDecode(unpackUnorm2x16(reflectNormalData));

            occlusion = GetSpiralOcclusion(texcoord, viewPos, viewTexNormal);
            occlusion = saturate(1.0 - occlusion);
        }
    }

    outOcclusion = occlusion;
}
