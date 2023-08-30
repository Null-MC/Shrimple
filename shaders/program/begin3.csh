#define RENDER_BEGIN_WATER_DEPTHS
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(400, 400, 1);

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/buffers/water_depths.glsl"


void main() {
    ivec2 viewSize = ivec2(viewWidth, viewHeight);
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(pos, viewSize))) return;

    uint waterUV = uint(gl_GlobalInvocationID.y * viewWidth + gl_GlobalInvocationID.x);

    WaterDepths[waterUV].IsWater = false;
    for (int i = 0; i < WATER_DEPTH_LAYERS; i++)
        WaterDepths[waterUV].Depth[i] = UINT32_MAX;
}
