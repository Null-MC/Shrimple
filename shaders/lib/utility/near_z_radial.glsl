int getSharedCoord(ivec2 pos) {
    const ivec2 flatten = ivec2(1, 18);
    return sumOf(pos * flatten);
}

ivec2 getKernelDir(const in uvec2 localPos) {
    ivec2 kernelEdgeDir = ivec2(step(ivec2(1), localPos)) * 2 - 1;
    return kernelEdgeDir + ivec2(step(0, kernelEdgeDir));
}

void writeShared(const in ivec2 coord, const in float value) {
	sharedBuffer[getSharedCoord(coord)] = value;
}

float getSharedBufferMinZ(const in ivec2 kernelPos) {
	float minZ = 1.0;

	// center
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 0,  0))]);
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 1,  0))]);
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 0,  1))]);
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 1,  1))]);

	// top
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 0, -1))]);
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 1, -1))]);

	// bottom
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 0,  2))]);
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 1,  2))]);

	// left
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2(-1,  0))]);
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2(-1,  1))]);

	// right
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 2,  0))]);
	minZ = min(minZ, sharedBuffer[getSharedCoord(kernelPos + ivec2( 2,  1))]);

	return minZ;
}

void populateSharedBuffer(const in ivec2 kernelPos, const in ivec2 localPos, const in ivec2 globalPos, const in int tile) {
    ivec2 kernelEdgeDir = getKernelDir(localPos);

    ivec2 readTileOffset, _size;
	GetDepthTileBounds(viewSize, tile, readTileOffset, _size);

	ivec2 sampleUV = globalPos * 2 + readTileOffset;
	writeShared(kernelPos              , imageLoad(imgDepthNear, sampleUV              ).r);
	writeShared(kernelPos + ivec2(1, 0), imageLoad(imgDepthNear, sampleUV + ivec2(1, 0)).r);
	writeShared(kernelPos + ivec2(0, 1), imageLoad(imgDepthNear, sampleUV + ivec2(0, 1)).r);
	writeShared(kernelPos + ivec2(1, 1), imageLoad(imgDepthNear, sampleUV + ivec2(1, 1)).r);

    if (localPos.x == 0 || localPos.x == 7) {
        writeShared(kernelPos + ivec2(kernelEdgeDir.x, 0), imageLoad(imgDepthNear, sampleUV + ivec2(kernelEdgeDir.x, 0)).r);
        writeShared(kernelPos + ivec2(kernelEdgeDir.x, 1), imageLoad(imgDepthNear, sampleUV + ivec2(kernelEdgeDir.x, 1)).r);
    }

    if (localPos.y == 0 || localPos.y == 7) {
        writeShared(kernelPos + ivec2(0, kernelEdgeDir.y), imageLoad(imgDepthNear, sampleUV + ivec2(0, kernelEdgeDir.y)).r);
        writeShared(kernelPos + ivec2(1, kernelEdgeDir.y), imageLoad(imgDepthNear, sampleUV + ivec2(1, kernelEdgeDir.y)).r);
    }
}

void writeNearTileMinZ(const in ivec2 kernelPos, const in ivec2 globalPos, const in float minZ, const in int tile) {
    ivec2 writeTileOffset, _size;
	GetDepthTileBounds(viewSize, tile, writeTileOffset, _size);
	imageStore(imgDepthNear, globalPos + writeTileOffset, vec4(minZ));
}
