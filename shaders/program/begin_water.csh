#define RENDER_BEGIN_WATER_DEPTHS
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

const vec2 workGroupsRender = vec2(1.0, 1.0);

uniform float viewWidth;
uniform vec2 viewSize;

#include "/lib/buffers/water_depths.glsl"


void main() {
    if (any(greaterThanEqual(gl_GlobalInvocationID.xy, uvec2(viewSize)))) return;

    uint waterUV = GetWaterDepthIndex(gl_GlobalInvocationID.xy);
    for (int i = 0; i < WATER_DEPTH_LAYERS; i++)
        WaterDepths[waterUV].Depth[i] = UINT32_MAX;
}
