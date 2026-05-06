#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_SOURCE colortex9

#ifdef LOD_ENABLED
    #define TEX_DEPTH texDepthLod_trans
    #define MAT_PROJ_INV matProjInv
#else
    #define TEX_DEPTH depthtex0
    #define MAT_PROJ_INV gbufferProjectionInverse
#endif


layout (local_size_x = 1, local_size_y = 128) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

const int sharedSize = 128+33;
shared vec3 sharedColor[sharedSize];
shared float sharedDepth[sharedSize];

layout(rgba16f) uniform writeonly image2D IMG_FINAL;

uniform sampler2D TEX_SOURCE;
uniform sampler2D TEX_DEPTH;

uniform float near;
uniform float farPlane;
uniform float nearPlane;
uniform int isEyeInWater;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec2 viewSize;

#include "/lib/sampling/gaussian.glsl"

#ifndef LOD_ENABLED
    #include "/lib/sampling/depth.glsl"
#endif

#include "/lib/blur_shared.glsl"


void main() {
    int i = int(gl_LocalInvocationIndex) * 2;
    ivec2 shared_uv = ivec2(gl_WorkGroupID.xy * gl_WorkGroupSize.xy);
    shared_uv.y -= 16;

    copyToShared(shared_uv + ivec2(0, i+0), i+0);
    copyToShared(shared_uv + ivec2(0, i+1), i+1);

    memoryBarrierShared();
    barrier();

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSize))) return;

    int base_i = int(gl_LocalInvocationID.y) + 16;
    float center_depth = sharedDepth[base_i];
    vec3 color = SampleBlur(center_depth, base_i);

    imageStore(IMG_FINAL, uv, vec4(color, 1.0));
}
