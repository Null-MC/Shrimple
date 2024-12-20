#define RENDER_BEGIN_WATER_DEPTHS
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8) in;

const vec2 workGroupsRender = vec2(1.0, 1.0);

uniform vec2 viewSize;

#include "/lib/buffers/water_depths.glsl"


void main() {
    ivec2 iViewSize = ivec2(viewSize);
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(pos, iViewSize))) return;

    uint waterUV = uint(gl_GlobalInvocationID.y * iViewSize.x + gl_GlobalInvocationID.x);

    // WaterDepths[waterUV].IsWater = false;
    for (int i = 0; i < WATER_DEPTH_LAYERS; i++)
        WaterDepths[waterUV].Depth[i] = UINT32_MAX;
}
