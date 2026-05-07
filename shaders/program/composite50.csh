#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_SOURCE TEX_FINAL


layout (local_size_x = 128, local_size_y = 1) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

const int sharedSize = 128+32;
shared vec3 sharedColor[sharedSize];

layout(rgba16f) uniform writeonly image2D imgBlurred;

uniform sampler2D TEX_SOURCE;

uniform vec2 viewSize;

#include "/lib/sampling/gaussian.glsl"
#include "/lib/blur_shared.glsl"


void main() {
    int i = int(gl_LocalInvocationIndex) * 2;
    ivec2 shared_uv = ivec2(gl_WorkGroupID.xy * gl_WorkGroupSize.xy);
    shared_uv.x -= 16;

    copyToShared(shared_uv + ivec2(i+0, 0), i+0);
    copyToShared(shared_uv + ivec2(i+1, 0), i+1);

    memoryBarrierShared();
    barrier();

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSize))) return;

    int base_i = int(gl_LocalInvocationID.x) + 16;
    vec3 color = SampleBlur(base_i);

    imageStore(imgBlurred, uv, vec4(color, 1.0));
}
