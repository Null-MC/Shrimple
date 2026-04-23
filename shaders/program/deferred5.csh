#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex1
#define TEX_LOD_DEPTH texDepthLod_opaque


layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

#if RENDER_SCALE == 3
    const vec2 workGroupsRender = vec2(0.25, 0.25);
#elif RENDER_SCALE == 2
    const vec2 workGroupsRender = vec2(0.50, 0.50);
#elif RENDER_SCALE == 1
    const vec2 workGroupsRender = vec2(0.75, 0.75);
#else
    const vec2 workGroupsRender = vec2(1.00, 1.00);
#endif

layout(r16f) uniform writeonly image2D IMG_SSAO;

shared float sharedOcclusion[20*20];
shared float sharedDepthL[20*20];
shared float sharedGaussian[3];
//shared float sharedGaussianY[3];

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_LOD_DEPTH;
uniform sampler2D TEX_SSAO;

uniform float near;
uniform float far;
uniform float nearPlane;
uniform float farPlane;
uniform vec2 viewSizeScaled;
uniform vec2 taa_offset = vec2(0.0);

#include "/lib/sampling/depth.glsl"
#include "/lib/ssao.glsl"


int getSharedIndex(const in ivec2 uv) {
    return uv.y * 20 + uv.x;
}

void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
    if (i_shared >= (20*20)) return;

    ivec2 uv = uv_base + ivec2(i_shared % 20, i_shared / 20);
    float occlusion = texelFetch(TEX_SSAO, uv, 0).r;
    sharedOcclusion[i_shared] = RGBToLinear(occlusion);

    #ifdef LOD_ENABLED
        float depth = texelFetch(TEX_LOD_DEPTH, uv, 0).r;
        float depthL = near / depth;
    #else
        float depth = texelFetch(TEX_DEPTH, uv, 0).r;
        float depthL = linearizeDepth(depth, nearPlane, farPlane);
    #endif
    sharedDepthL[i_shared] = depthL;
}

float Gaussian(const in float sigma, const in float x) {
    return exp(_pow2(x) / (-2.0 * _pow2(sigma)));
}

const float g_sigmaXY = 1.6;
const float g_sigmaV = 0.2;

float BilateralGaussianBlur() {
    ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 2;
    float depthL = sharedDepthL[getSharedIndex(luv)];

    float accum = 0.0;
    float total = 0.0;
    for (int iy = -2; iy <= 2; iy++) {
        float fy = sharedGaussian[abs(iy)];

        for (int ix = -2; ix <= 2; ix++) {
            float fx = sharedGaussian[abs(ix)];

            int shared_i = getSharedIndex(luv + ivec2(ix, iy));
            float sampleOcclusion = sharedOcclusion[shared_i];
            float sampleDepthL = sharedDepthL[shared_i];

            float depthDiff = abs(sampleDepthL - depthL);
            float fv = Gaussian(g_sigmaV, depthDiff);

            float weight = fx * fy * fv;
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

    int i = int(gl_LocalInvocationIndex);
    if (i < 3) sharedGaussian[i] = Gaussian(g_sigmaXY, i);

    memoryBarrierShared();
    barrier();

    // exit early if OOB
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSizeScaled))) return;

    #ifdef LOD_ENABLED
        float depth = texelFetch(TEX_LOD_DEPTH, uv, 0).r;
        bool isSky = depth <= 0.0;
    #else
        float depth = texelFetch(TEX_DEPTH, uv, 0).r;
        bool isSky = depth >= 1.0;
    #endif

    float occlusion = 1.0;
    if (!isSky) {
        occlusion = BilateralGaussianBlur();
    }

    occlusion = LinearToRGB(occlusion);
    imageStore(IMG_SSAO, uv, vec4(occlusion));
}
