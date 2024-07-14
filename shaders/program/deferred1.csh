#define RENDER_DEFERRED_HI_Z_DDA
#define RENDER_DEFERRED
#define RENDER_COMPUTE

<DO NOT RUN>

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8) in;

const vec2 workGroupsRender = vec2(1.0, 1.0);

layout(r32f) uniform image2D imgDepthNear;

uniform sampler2D depthtex0;

uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform vec2 pixelSize;

#include "/lib/utility/depth_tiles.glsl"


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
	//ivec2 viewSize = ivec2(viewWidth, viewHeight);
	ivec2 fragWritePos = ivec2(gl_GlobalInvocationID.xy);

	ivec2 tileSize = ivec2(viewSize) / 2;
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
		tileSize /= 2;

		if (any(greaterThanEqual(fragWritePos, tileSize))) break;
		
		memoryBarrierImage();

	    ivec2 _tileSize;
	    GetDepthTileBounds(viewSize, i - 1, tilePos, _tileSize);

	    GetDepthTileBounds(viewSize, i, writePos, _tileSize);
		writePos += fragWritePos;

		readPos = fragWritePos * 2 + tilePos;
		ivec2 sourceSize = tilePos + 2*tileSize;

		minZ = 1.0;
		SampleTileMin(minZ, sourceSize, readPos + ivec2(0, 0));
		SampleTileMin(minZ, sourceSize, readPos + ivec2(1, 0));
		SampleTileMin(minZ, sourceSize, readPos + ivec2(0, 1));
		SampleTileMin(minZ, sourceSize, readPos + ivec2(1, 1));

		imageStore(imgDepthNear, writePos, vec4(minZ));
	}
}
