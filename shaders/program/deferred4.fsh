#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef LOD_ENABLED
    #define TEX_LOD_DEPTH texDepthLod_opaque
    #define MAT_PROJ_INV matProjInv
#else
    #define MAT_PROJ_INV gbufferProjectionInverse
#endif

//#ifdef DISTANT_HORIZONS
////    #define TEX_LOD_DEPTH dhDepthTex0
//    #define SSAO_PROJ dhProjection
//    #define SSAO_PROJ_INV dhProjectionInverse
//#elif defined(VOXY)
////    #define TEX_LOD_DEPTH vxDepthTexOpaque
//    #define SSAO_PROJ vxProj
//    #define SSAO_PROJ_INV vxProjInv
//#endif

#define TEX_DEPTH depthtex1
#define SSAO_RADIUS 4.0

const float SSAO_StrengthF = 0.2;
const float SSAO_Bias = 0.08;
const float SSAO_MinLight = 0.0;

in vec2 texcoord;


uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_LOD_DEPTH;
uniform sampler2D TEX_GB_NORMALS;

uniform float far;
uniform float near;
uniform int frameCounter;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec2 taa_offset = vec2(0.0);

//uniform mat4 dhProjection;
//uniform mat4 dhProjectionInverse;
//uniform float dhNearPlane;
//uniform mat4 vxProj;
//uniform mat4 vxProjInv;

#include "/lib/octohedral.glsl"
#include "/lib/ign.glsl"


float GetSpiralOcclusion(const in vec2 texcoord, const in vec3 viewPos, const in vec3 viewNormal) {
    vec2 seed = gl_FragCoord.xy;

    #ifdef TAA_ENABLED
        seed += vec2(71.83, 83.71) * (frameCounter % 16);
    #endif

    float dither = InterleavedGradientNoise(seed);

    float max_radius = length(viewPos) / 25.0; //SSAO_RADIUS;

    float rotatePhase = dither * (PI * 2.0);
    const float rStep = max_radius / float(SSAO_SAMPLES);

    mat4 matProj = mat4(
        gbufferProjection[0][0], 0.0, 0.0, 0.0,
        0.0, gbufferProjection[1][1], 0.0, 0.0,
        0.0, 0.0, 0.0, -1.0,
        0.0, 0.0, near, 0.0);

    mat4 matProjInv = mat4(
        gbufferProjectionInverse[0][0], 0.0, 0.0, 0.0,
        0.0, gbufferProjectionInverse[1][1], 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0/near,
        0.0, 0.0, -1.0, 0.0);

    float ao = 0.0;
    int sampleCount = 0;
    float radius = rStep;
    for (int i = 0; i < SSAO_SAMPLES; i++) {
        vec2 offset = vec2(
            sin(rotatePhase),
            cos(rotatePhase)
        ) * radius;

        radius += rStep;
        rotatePhase += GoldenAngle;

        vec3 sampleViewPos = viewPos + vec3(offset, -0.1);

//        #ifdef DISTANT_HORIZONS
//            mat4 projection = gbufferProjection;
//
//            if (abs(sampleViewPos.z) > dhNearPlane) {
//                projection = dhProjection;
//            }
//        #endif

        vec3 sampleClipPos = project(matProj, sampleViewPos);
        sampleClipPos.xy = sampleClipPos.xy * 0.5 + 0.5;
        sampleClipPos = saturate(sampleClipPos);

        float sampleClipDepth = texture(TEX_LOD_DEPTH, sampleClipPos.xy).r;

//        #ifdef DISTANT_HORIZONS
//            mat4 projectionInv = gbufferProjectionInverse;

//            if (sampleClipDepth >= 1.0) {
//                sampleClipDepth = texture(dhDepthTex0, sampleClipPos.xy).r;
//                projectionInv = dhProjectionInverse;
//            }
//        #endif

        // TODO: invert if LOD?
        if (sampleClipDepth <= 0.0) {
//            maxWeight += 1.0;
            continue;
        }

        sampleClipPos.z = sampleClipDepth;
        sampleClipPos.xy = sampleClipPos.xy * 2.0 - 1.0;
        sampleViewPos = project(matProjInv, sampleClipPos);

        vec3 diff = sampleViewPos - viewPos;
        float sampleDist = length(diff);
        vec3 sampleNormal = diff / sampleDist;

        float sampleNoLm = max(dot(viewNormal, sampleNormal) - SSAO_Bias, 0.0);
        sampleNoLm /= (1.0 + sampleDist);
        ao += sampleNoLm;
        sampleCount++;
    }

    ao /= max(sampleCount, 1);
//    ao = smoothstep(0.0, SSAO_StrengthF, ao);
    ao = pow(ao, 0.4);

    return ao * (1.0 - SSAO_MinLight);
}


/* RENDERTARGETS: 7 */
layout(location = 0) out float outOcclusion;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float occlusion = 1.0;
    bool hasAO = false;

    #ifdef LOD_ENABLED
        float depth = texelFetch(TEX_LOD_DEPTH, uv, 0).r;
        hasAO = depth > 0.0;
    #else
        float depth = texelFetch(TEX_DEPTH, uv, 0).r;
        hasAO = depth < 1.0;
    #endif


//    if (depth < 1.0) depth = 1.0;
//    else {
//        depth = texelFetch(TEX_LOD_DEPTH, uv, 0).r;
//    }

//    #ifdef DISTANT_HORIZONS
//        #define SSAO_PROJ_INV projectionInv
//        mat4 projectionInv = gbufferProjectionInverse;
//
//        if (depth >= 1.0) {
//            projectionInv = dhProjectionInverse;
//            depth = texelFetch(dhDepthTex0, uv, 0).r;
//        }
//    #else
//        #define SSAO_PROJ_INV gbufferProjectionInverse
//    #endif

    if (hasAO) {
        vec2 texNormalData = texelFetch(TEX_GB_NORMALS, uv, 0).zw;

        vec3 screenPos = vec3(texcoord, depth);

        #ifdef TAA_ENABLED
            // screenPos.xy -= taa_offset;
        #endif

        vec3 ndcPos = screenPos;
        ndcPos.xy = ndcPos.xy * 2.0 - 1.0;

        // don't fix hand depth, not needed

        #ifdef LOD_ENABLED
            mat4 matProjInv = mat4(
                gbufferProjectionInverse[0][0], 0.0, 0.0, 0.0,
                0.0, gbufferProjectionInverse[1][1], 0.0, 0.0,
                0.0, 0.0, 0.0, 1.0/near,
                0.0, 0.0, -1.0, 0.0);
        #endif

        vec3 viewPos = project(MAT_PROJ_INV, ndcPos);

        #if SSAO_MODE == SSAO_LOD
            float viewDist = length(viewPos);
            if (viewDist < dh_clipDistF * far) hasAO = false;
        #endif

        if (hasAO) {
//            vec3 localGeoNormal = OctDecode(unpackUnorm2x16(geoNormalData));
            vec3 viewTexNormal = OctDecode(texNormalData);

            occlusion = GetSpiralOcclusion(texcoord, viewPos, viewTexNormal);
            occlusion = saturate(1.0 - occlusion);
        }
    }

    outOcclusion = occlusion;
}
