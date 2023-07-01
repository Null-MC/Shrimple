#define RENDER_DEFERRED_HI_Z
#define RENDER_DEFERRED
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(16, 16, 1);


void main() {
	uvec2 viewSize = uvec2(viewWidth, viewHeight);

	uvec2 fragReadPos = uvec2(gl_GlobalInvocationID.xy) * 4u;
	if (any(greaterThanEqual(fragReadPos, viewSize))) return;

	float minZ = 1.0;
	for (uint y = 0; y < 4; y++) {
		for (uint x = 0; x < 4; x++) {
			uvec2 sampleUV = fragReadPos + uvec2(x, y);
			if (any(greaterThanEqual(sampleUV, viewSize))) continue;

			float sampleZ = texelFetch(depthtex0, sampleUV, 0).r;
			minZ = min(minZ, sampleZ);
		}
	}

	uvec2 fragWritePos = uvec2(gl_GlobalInvocationID.xy);
	// TODO: apply tile shifting

	imageStore(imgDepthNear, fragWritePos, vec4(minZ));
}
