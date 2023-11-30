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

void writeNearTileMinZ(const in ivec2 kernelPos, const in ivec2 globalPos, const in float minZ, const in int tile) {
    ivec2 writeTileOffset, _size;
    GetDepthTileBounds(viewSize, tile, writeTileOffset, _size);
    imageStore(imgDepthNear, globalPos + writeTileOffset, vec4(minZ));
}

#ifndef RENDER_DEFERRED_HI_Z_RAD_1
    void copyToShared(const in ivec2 kernelPos, const in ivec2 samplePos, const in ivec2 sampleOffset, const in ivec2 tileMin, const in ivec2 tileMax) {
        ivec2 samplePosFinal = clamp(samplePos + sampleOffset, tileMin, tileMax - 1);
        float depth = imageLoad(imgDepthNear, samplePosFinal).r;
        writeShared(kernelPos + sampleOffset, depth);
    }

    void populateSharedBuffer(const in ivec2 kernelPos, const in ivec2 localPos, const in ivec2 globalPos, const in int tile) {
        ivec2 kernelEdgeDir = getKernelDir(localPos);

        ivec2 readTileOffset, _size;
        GetDepthTileBounds(viewSize, tile, readTileOffset, _size);

        ivec2 tileMin = readTileOffset;
        ivec2 tileMax = readTileOffset + _size;

        ivec2 samplePos = globalPos * 2 + readTileOffset;
        copyToShared(kernelPos, samplePos, ivec2(0, 0), tileMin, tileMax);
        copyToShared(kernelPos, samplePos, ivec2(1, 0), tileMin, tileMax);
        copyToShared(kernelPos, samplePos, ivec2(0, 1), tileMin, tileMax);
        copyToShared(kernelPos, samplePos, ivec2(1, 1), tileMin, tileMax);

        if (localPos.x == 0 || localPos.x == 7) {
            copyToShared(kernelPos, samplePos, ivec2(kernelEdgeDir.x, 0), tileMin, tileMax);
            copyToShared(kernelPos, samplePos, ivec2(kernelEdgeDir.x, 1), tileMin, tileMax);
        }

        if (localPos.y == 0 || localPos.y == 7) {
            copyToShared(kernelPos, samplePos, ivec2(0, kernelEdgeDir.y), tileMin, tileMax);
            copyToShared(kernelPos, samplePos, ivec2(1, kernelEdgeDir.y), tileMin, tileMax);
        }
    }
#endif
