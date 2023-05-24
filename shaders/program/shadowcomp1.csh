#define RENDER_SHADOWCOMP_LPV
#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#define LPV_CHUNK_SIZE 4

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && LPV_SIZE > 0
    uniform int frameCounter;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;

    #include "/lib/blocks.glsl"

    #include "/lib/buffers/lighting.glsl"
    #include "/lib/buffers/volume.glsl"

    #include "/lib/lighting/voxel/lpv.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/tinting.glsl"
#endif


ivec3 GetLPVFrameOffset() {
    vec3 posNow = GetLPVPosition(vec3(0.0));
    vec3 posLast = GetLPVPosition(previousCameraPosition - cameraPosition);
    return GetLPVImgCoord(posNow) - GetLPVImgCoord(posLast);
}

ivec3 GetLPVVoxelOffset() {
    vec3 voxelCameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
    ivec3 voxelOrigin = ivec3(voxelCameraOffset + LightGridCenter + 0.5);

    vec3 lpvCameraOffset = fract(cameraPosition);
    ivec3 lpvOrigin = ivec3(lpvCameraOffset + SceneLPVCenter + 0.5);

    return voxelOrigin - lpvOrigin;
}

vec3 GetLpvValue(const in ivec3 texCoord) {
    return imageLoad((frameCounter % 2) == 0 ? imgSceneLPV_2 : imgSceneLPV_1, texCoord).rgb;
}

vec3 mixNeighbours(const in ivec3 fragCoord) {
    //const float FALLOFF = 0.002;

    vec3 nX1 = GetLpvValue(fragCoord + ivec3(-1,  0,  0));
    vec3 nX2 = GetLpvValue(fragCoord + ivec3( 1,  0,  0));
    vec3 nY1 = GetLpvValue(fragCoord + ivec3( 0, -1,  0));
    vec3 nY2 = GetLpvValue(fragCoord + ivec3( 0,  1,  0));
    vec3 nZ1 = GetLpvValue(fragCoord + ivec3( 0,  0, -1));
    vec3 nZ2 = GetLpvValue(fragCoord + ivec3( 0,  0,  1));

    vec3 avgColor = (nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2) / 6.0;
    //float falloff = rcp(max(luminance(n), 1.0)) * FALLOFF;
    return avgColor;// * (1.0 - falloff);
}

void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && LPV_SIZE > 0
        ivec3 chunkPos = ivec3(gl_GlobalInvocationID);

        ivec3 imgChunkPos = chunkPos * LPV_CHUNK_SIZE;
        if (any(greaterThanEqual(imgChunkPos, SceneLPVSize))) return;

        int frameIndex = frameCounter % 2;
        ivec3 imgCoordOffset = GetLPVFrameOffset();
        ivec3 voxelOffset = GetLPVVoxelOffset();

        vec3 lightValue, tint;
        uint blockId, gridIndex;
        ivec3 iPos, gridCell, imgCoord, imgCoordPrev, voxelPos, blockCell;

        for (int z = 0; z < LPV_CHUNK_SIZE; z++) {
            for (int y = 0; y < LPV_CHUNK_SIZE; y++) {
                for (int x = 0; x < LPV_CHUNK_SIZE; x++) {
                    iPos = ivec3(x, y, z);

                    imgCoord = imgChunkPos + iPos;
                    if (any(greaterThanEqual(imgCoord, SceneLPVSize))) continue;

                    voxelPos = voxelOffset + imgCoord;

                    gridCell = ivec3(floor(voxelPos / LIGHT_BIN_SIZE));
                    gridIndex = GetSceneLightGridIndex(gridCell);
                    blockCell = voxelPos - gridCell * LIGHT_BIN_SIZE;
                    blockId = GetSceneBlockMask(blockCell, gridIndex);

                    lightValue = vec3(0.0);

                    // TODO: clear in setup
                    if (frameCounter > 1) {
                        bool hasLight = false;
                        tint = vec3(1.0);

                        #ifdef LPV_GLASS_TINT
                            if (blockId >= BLOCK_HONEY && blockId <= BLOCK_STAINED_GLASS_YELLOW) {
                                tint = GetLightGlassTint(blockId);
                                hasLight = true;
                            }
                            else {
                        #endif
                            if (IsTraceOpenBlock(blockId)) {
                                hasLight = true;
                            }
                        #ifdef LPV_GLASS_TINT
                            }
                        #endif

                        if (hasLight) {
                            imgCoordPrev = imgCoord + imgCoordOffset;
                            lightValue = mixNeighbours(imgCoordPrev) * tint;
                        }
                    }

                    imageStore(frameIndex == 0 ? imgSceneLPV_1 : imgSceneLPV_2, imgCoord, vec4(lightValue, 1.0));
                }
            }
        }
    #endif
}
