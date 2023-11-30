#define RENDER_DEFERRED_HI_Z_RAD_1
#define RENDER_DEFERRED
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8) in;

const vec2 workGroupsRender = vec2(0.5, 0.5);

shared float sharedBuffer[324];

layout(r32f) uniform image2D imgDepthNear;

uniform sampler2D depthtex1;

uniform vec2 viewSize;
uniform vec2 pixelSize;

#include "/lib/utility/depth_tiles.glsl"
#include "/lib/utility/near_z_radial.glsl"


void main() {
	ivec2 localPos = ivec2(gl_LocalInvocationID.xy);
	ivec2 globalPos = ivec2(gl_GlobalInvocationID.xy);

    ivec2 kernelPos = localPos * 2 + 1;
    ivec2 kernelEdgeDir = getKernelDir(localPos);

	ivec2 sampleUV = globalPos * 2;
	writeShared(kernelPos              , texelFetch      (depthtex1, sampleUV, 0).r);
	writeShared(kernelPos + ivec2(1, 0), texelFetchOffset(depthtex1, sampleUV, 0, ivec2(1, 0)).r);
	writeShared(kernelPos + ivec2(0, 1), texelFetchOffset(depthtex1, sampleUV, 0, ivec2(0, 1)).r);
	writeShared(kernelPos + ivec2(1, 1), texelFetchOffset(depthtex1, sampleUV, 0, ivec2(1, 1)).r);

    if (localPos.x == 0 || localPos.x == 7) {
        writeShared(kernelPos + ivec2(kernelEdgeDir.x, 0), texelFetch(depthtex1, sampleUV + ivec2(kernelEdgeDir.x, 0), 0).r);
        writeShared(kernelPos + ivec2(kernelEdgeDir.x, 1), texelFetch(depthtex1, sampleUV + ivec2(kernelEdgeDir.x, 1), 0).r);
    }

    if (localPos.y == 0 || localPos.y == 7) {
        writeShared(kernelPos + ivec2(0, kernelEdgeDir.y), texelFetch(depthtex1, sampleUV + ivec2(0, kernelEdgeDir.y), 0).r);
        writeShared(kernelPos + ivec2(1, kernelEdgeDir.y), texelFetch(depthtex1, sampleUV + ivec2(1, kernelEdgeDir.y), 0).r);
    }

    barrier();

	if (any(greaterThanEqual(globalPos, ivec2(ceil(viewSize * 0.5))))) return;

	float minZ = getSharedBufferMinZ(kernelPos);
	writeNearTileMinZ(kernelPos, globalPos, minZ, 0);
}
