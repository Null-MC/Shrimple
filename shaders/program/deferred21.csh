#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

#ifdef DISTANT_HORIZONS
    #define TEX_LOD_DEPTH dhDepthTex0
    #define SSAO_PROJ dhProjection
    #define SSAO_PROJ_INV dhProjectionInverse
#elif defined(VOXY)
    #define TEX_LOD_DEPTH vxDepthTexOpaque
    #define SSAO_PROJ vxProj
    #define SSAO_PROJ_INV vxProjInv
#endif


layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);


layout(rgba16f) uniform writeonly image2D IMG_FINAL;

shared float sharedOcclusion[20*20];
shared float sharedDepthL[20*20];

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_LOD_DEPTH;
uniform sampler2D TEX_SSAO;

uniform float far;
uniform vec2 viewSize;
uniform float farPlane;
uniform float nearPlane;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform float skyDayF;
uniform vec3 skyColor;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform int isEyeInWater;
//uniform vec3 sunPosition;
uniform vec3 sunLocalDir;
uniform int hasSkylight;
uniform ivec2 eyeBrightnessSmooth;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec2 taa_offset = vec2(0.0);

uniform float dhNearPlane;
uniform float dhFarPlane;
uniform mat4 dhProjectionInverse;
uniform mat4 vxProjInv;
uniform int vxRenderDistance;

#include "/lib/sampling/depth.glsl"
#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"
#include "/lib/ssao.glsl"


int getSharedIndex(const in ivec2 uv) {
    return uv.y * 20 + uv.x;
}

void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
    if (i_shared >= (20*20)) return;

    ivec2 uv = uv_base + ivec2(i_shared % 20, i_shared / 20);
    sharedOcclusion[i_shared] = texelFetch(TEX_SSAO, uv, 0).r;

//    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
//    float _near = nearPlane;
//    float _far = farPlane;

    float depth = texelFetch(TEX_LOD_DEPTH, uv, 0).r;
    #ifdef DISTANT_HORIZONS
//        if (depth >= 1.0) {
            float _near = dhNearPlane;
            float _far = dhFarPlane;
//        }
    #elif defined(VOXY)
        float _near = vxNearPlane;
        float _far = vxFarPlane;
    #endif

    sharedDepthL[i_shared] = linearizeDepth(depth * 2.0 - 1.0, _near, _far);
}

float Gaussian(const in float sigma, const in float x) {
    return exp(_pow2(x) / (-2.0 * _pow2(sigma)));
}

float BilateralGaussianBlur() {
    const float g_sigmaXY = 1.6;
    const float g_sigmaV = 0.2;

    ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 2;
    float depthL = sharedDepthL[getSharedIndex(luv)];

    float accum = 0.0;
    float total = 0.0;
    for (int iy = -2; iy <= 2; iy++) {
        float fy = Gaussian(g_sigmaXY, iy);

        for (int ix = -2; ix <= 2; ix++) {
            float fx = Gaussian(g_sigmaXY, ix);

            int shared_i = getSharedIndex(luv + ivec2(ix, iy));
            float sampleOcclusion = sharedOcclusion[shared_i];
            float sampleDepthL = sharedDepthL[shared_i];

            float depthDiff = abs(sampleDepthL - depthL);
            float fv = Gaussian(g_sigmaV, depthDiff);

            float weight = fx*fy*fv;
            accum += weight * sampleOcclusion;
            total += weight;
        }
    }

    if (total <= EPSILON) return 1.0;
    return accum / total;
}


void main() {
    // preload shared memory
    int i_base = int(gl_LocalInvocationIndex) * 2;
    ivec2 uv_base = ivec2(gl_WorkGroupID.xy) * 16 - 2;

    copyToShared(uv_base, i_base + 0);
    copyToShared(uv_base, i_base + 1);

    memoryBarrierShared();
    barrier();

    // exit early if OOB
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSize))) return;

    vec3 color = texelFetch(TEX_FINAL, uv, 0).rgb;
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    float lodDepth = 1.0;

    if (depth >= 1.0) {
        lodDepth = texelFetch(TEX_LOD_DEPTH, uv, 0).r;
    }

    if (lodDepth < 1.0) {
        float occlusion = BilateralGaussianBlur();

        //        occlusion = mix(1.0, occlusion, SSAO_GetFade(viewDist));
        color *= occlusion;
    }

    if (depth < 1.0 || lodDepth < 1.0) {
        vec2 texcoord = (gl_GlobalInvocationID.xy + 0.5) / viewSize;
        vec3 screenPos = vec3(texcoord, depth);

        #ifdef TAA_ENABLED
            // screenPos.xy -= taa_offset;
        #endif

        vec3 ndcPos = screenPos * 2.0 - 1.0;

        // TODO: fix hand depth

        vec3 viewPos = project(lodDepth < 1.0 ? SSAO_PROJ_INV : gbufferProjectionInverse, ndcPos);
        vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

        float viewDist = length(localPos);

        float borderFogF = GetBorderFogStrength(viewDist);
        float envFogF = GetEnvFogStrength(viewDist);
        float fogF = max(borderFogF, envFogF);

        vec3 fogColorL = RGBToLinear(fogColor);
        vec3 skyColorL = RGBToLinear(skyColor);
        vec3 localViewDir = normalize(localPos);
        vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

        color.rgb = mix(color.rgb, fogColorFinal, fogF);
    }

    imageStore(IMG_FINAL, uv, vec4(color, 1.0));
}
