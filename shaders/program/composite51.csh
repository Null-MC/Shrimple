#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_SOURCE texBlurred

#ifdef LOD_ENABLED
    #define TEX_DEPTH texDepthLod_trans
    #define MAT_PROJ_INV matProjInv
#else
    #define TEX_DEPTH depthtex0
    #define MAT_PROJ_INV gbufferProjectionInverse
#endif


layout (local_size_x = 1, local_size_y = 128) in;

#if RENDER_SCALE == 3
    const vec2 workGroupsRender = vec2(0.125, 0.125);
#elif RENDER_SCALE == 2
    const vec2 workGroupsRender = vec2(0.250, 0.250);
#elif RENDER_SCALE == 1
    const vec2 workGroupsRender = vec2(0.375, 0.375);
#else
    const vec2 workGroupsRender = vec2(0.500, 0.500);
#endif

const int sharedSize = 128+32;
shared vec3 sharedColor[sharedSize];

layout(rgba16f) uniform writeonly image2D imgBlurred;

uniform sampler2D TEX_SOURCE;

uniform vec2 viewSizeScaled;

#include "/lib/sampling/gaussian.glsl"
#include "/lib/blur_shared.glsl"

void copyToShared(in ivec2 uv, const in int i_shared) {
    if (i_shared >= sharedSize) return;

    uv = clamp(uv, ivec2(0), ivec2(viewSizeScaled)/2-1);

    sharedColor[i_shared] = texelFetch(TEX_SOURCE, uv, 0).rgb;
}


void main() {
    int i = int(gl_LocalInvocationIndex) * 2;
    ivec2 shared_uv = ivec2(gl_WorkGroupID.xy * gl_WorkGroupSize.xy);
    shared_uv.y -= 16;

    copyToShared(shared_uv + ivec2(0, i+0), i+0);
    copyToShared(shared_uv + ivec2(0, i+1), i+1);

    memoryBarrierShared();
    barrier();

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSizeScaled))) return;

    int base_i = int(gl_LocalInvocationID.y) + 16;
    vec3 color = SampleBlur(base_i);

    uv.y += int(viewSizeScaled.y)/2;
    imageStore(imgBlurred, uv, vec4(color, 1.0));
}
