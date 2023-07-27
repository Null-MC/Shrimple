#define RENDER_DEFERRED_HI_Z
#define RENDER_DEFERRED
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(256, 256, 1);

layout(r32f) uniform image2D imgDepthNear;

uniform sampler2D depthtex0;

uniform float viewWidth;
uniform float viewHeight;


void SampleDepthMin(inout float minZ, const in ivec2 sampleUV) {
	float sampleZ = texelFetch(depthtex0, sampleUV, 0).r;
	minZ = min(minZ, sampleZ);
}

void SampleTileMin(inout float minZ, const in ivec2 sourceSize, const in ivec2 sampleUV) {
	float sampleZ = imageLoad(imgDepthNear, sampleUV).r;
	float sampleWeight = float(any(greaterThanEqual(sampleUV, sourceSize)));
	minZ = min(minZ, max(sampleZ, sampleWeight));
}

void main() {
	ivec2 viewSize = ivec2(viewWidth, viewHeight);
	ivec2 fragWritePos = ivec2(gl_GlobalInvocationID.xy);

	ivec2 tileSize = viewSize / 2;
	if (any(greaterThanEqual(fragWritePos, tileSize))) return;

	float minZ = 1.0;
	ivec2 fragReadPos = fragWritePos * 2;
	SampleDepthMin(minZ, fragReadPos + ivec2(0, 0));
	SampleDepthMin(minZ, fragReadPos + ivec2(1, 0));
	SampleDepthMin(minZ, fragReadPos + ivec2(0, 1));
	SampleDepthMin(minZ, fragReadPos + ivec2(1, 1));

	imageStore(imgDepthNear, fragWritePos, vec4(minZ));

	ivec2 tilePos, readPos, writePos;
	for (int i = 1; i < SSR_LOD_MAX; i++) {
		if (any(greaterThanEqual(fragWritePos, tileSize/2))) break;
		
		memoryBarrierImage();

		writePos = fragWritePos;

		if (i == 1) {
			tilePos = ivec2(0);
			writePos += tileSize * ivec2(0, 1);
		}
		else if (i == 2) {
			tilePos = viewSize/2 * ivec2(0, 1);
			writePos += tileSize * ivec2(1, 2);
		}
		else if (i == 3) {
			tilePos = viewSize/4 * ivec2(1, 2);
			writePos += tileSize * ivec2(3, 4);
		}

		minZ = 1.0;
		readPos = fragWritePos * 2 + tilePos;
		ivec2 sourceSize = tilePos + tileSize;
		SampleTileMin(minZ, sourceSize, readPos + ivec2(0, 0));
		SampleTileMin(minZ, sourceSize, readPos + ivec2(1, 0));
		SampleTileMin(minZ, sourceSize, readPos + ivec2(0, 1));
		SampleTileMin(minZ, sourceSize, readPos + ivec2(1, 1));

		imageStore(imgDepthNear, writePos, vec4(minZ));

		tileSize /= 2;
	}
}
