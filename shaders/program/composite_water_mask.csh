#define RENDER_COMPOSITE_WATER_MASK
#define RENDER_COMPOSITE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8) in;

const vec2 workGroupsRender = vec2(1.0, 1.0);

shared uint sharedMask[2];


uniform usampler2D BUFFER_DEFERRED_DATA;

uniform vec2 viewSize;

#include "/lib/buffers/water_mask.glsl"


void main() {
    if (gl_LocalInvocationIndex < 2) {
        sharedMask[gl_LocalInvocationIndex] = 0u;
    }

    memoryBarrierShared();

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (all(lessThan(uv, viewSize))) {
        uint deferredDataB = texelFetch(BUFFER_DEFERRED_DATA, uv, 0).b;
        float deferredWater = unpackUnorm4x8(deferredDataB).r;

        if (deferredWater > 0.5) {
            ivec2 localPos = ivec2(gl_LocalInvocationID.xy);
            int localIndex = localPos.y*8 + localPos.x;

            uint mask = 1u << (localIndex % 32);
            int shift = localIndex >= 32 ? 1 : 0;
            atomicOr(sharedMask[shift], mask);
        }
    }

    memoryBarrier();
    // memoryBarrierShared();

    if (gl_LocalInvocationIndex < 2) {
        int i = int(gl_WorkGroupID.y*gl_NumWorkGroups.x + gl_WorkGroupID.x);
        WaterMask[i*2 + gl_LocalInvocationIndex] = sharedMask[gl_LocalInvocationIndex];
    }
}
