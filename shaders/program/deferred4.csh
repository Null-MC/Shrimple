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


void BuildTile(const in ivec2 sourcePos, const in ivec2 sourceSize, const in ivec2 destPos) {
	float minZ = 1.0;

	for (int y = 0; y < 2; y++) {
		for (int x = 0; x < 2; x++) {
			ivec2 sampleUV = sourcePos + ivec2(x, y);
			if (any(greaterThanEqual(sampleUV, sourceSize))) continue;

			float sampleZ = imageLoad(imgDepthNear, sampleUV).r;
			minZ = min(minZ, sampleZ);
		}
	}

	imageStore(imgDepthNear, destPos, vec4(minZ));
}

void main() {
	ivec2 viewSize = ivec2(viewWidth, viewHeight);
	ivec2 fragWritePos = ivec2(gl_GlobalInvocationID.xy);

	ivec2 tileSize = viewSize / 2;
	if (any(greaterThanEqual(fragWritePos, tileSize))) return;

	ivec2 fragReadPos = fragWritePos * 2;

	float minZ = 1.0;
	for (int y = 0; y < 2; y++) {
		for (int x = 0; x < 2; x++) {
			ivec2 sampleUV = fragReadPos + ivec2(x, y);
			float sampleZ = texelFetch(depthtex0, sampleUV, 0).r;
			minZ = min(minZ, sampleZ);
		}
	}

	imageStore(imgDepthNear, fragWritePos, vec4(minZ));

	ivec2 tilePos, readPos, writePos;
	for (int i = 1; i < 4; i++) {
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

		readPos = fragWritePos * 2 + tilePos;

		BuildTile(readPos, tilePos + tileSize, writePos);

		tileSize /= 2;
	}
}
