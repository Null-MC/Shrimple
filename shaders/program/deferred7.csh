#define RENDER_DEFERRED_HI_Z_RAD_4
#define RENDER_DEFERRED
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8) in;

const vec2 workGroupsRender = vec2(0.0625, 0.0625);

shared float sharedBuffer[324];

layout(r32f) uniform image2D imgDepthNear;

uniform vec2 viewSize;
uniform vec2 pixelSize;

#include "/lib/utility/depth_tiles.glsl"
#include "/lib/utility/near_z_radial.glsl"


void main() {
	ivec2 localPos = ivec2(gl_LocalInvocationID.xy);
	ivec2 globalPos = ivec2(gl_GlobalInvocationID.xy);

    ivec2 kernelPos = localPos * 2 + 1;
    populateSharedBuffer(kernelPos, localPos, globalPos, 2);
    barrier();

	if (any(greaterThanEqual(globalPos * 2 + 1, ivec2(viewSize) / 2))) return;

	float minZ = getSharedBufferMinZ(kernelPos);
	writeNearTileMinZ(kernelPos, globalPos, minZ, 3);
}
