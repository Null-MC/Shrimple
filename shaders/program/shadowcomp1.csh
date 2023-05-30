#define RENDER_SHADOWCOMP_LPV
#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#define LPV_CHUNK_SIZE 4

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && LPV_SIZE > 0
    #ifdef DYN_LIGHT_FLICKER
        uniform sampler2D noisetex;
    #endif

    uniform int frameCounter;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;

    #ifdef DYN_LIGHT_FLICKER
        uniform float frameTimeCounter;
    #endif

    #include "/lib/blocks.glsl"
    #include "/lib/lights.glsl"

    #include "/lib/buffers/lighting.glsl"
    #include "/lib/buffers/volume.glsl"

    #ifdef DYN_LIGHT_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #include "/lib/lighting/voxel/lpv.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
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
    return (frameCounter % 2) == 0
        ? imageLoad(imgSceneLPV_2, texCoord).rgb
        : imageLoad(imgSceneLPV_1, texCoord).rgb;
}

vec3 mixNeighbours(const in ivec3 fragCoord) {
    const float FALLOFF = 0.9;

    vec3 nX1 = GetLpvValue(fragCoord + ivec3(-1,  0,  0));
    vec3 nX2 = GetLpvValue(fragCoord + ivec3( 1,  0,  0));
    vec3 nY1 = GetLpvValue(fragCoord + ivec3( 0, -1,  0));
    vec3 nY2 = GetLpvValue(fragCoord + ivec3( 0,  1,  0));
    vec3 nZ1 = GetLpvValue(fragCoord + ivec3( 0,  0, -1));
    vec3 nZ2 = GetLpvValue(fragCoord + ivec3( 0,  0,  1));

    vec3 avgColor = (nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2) * (1.0/6.0);
    return FALLOFF * avgColor;
}

void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && LPV_SIZE > 0
        ivec3 chunkPos = ivec3(gl_GlobalInvocationID);

        ivec3 imgChunkPos = chunkPos * LPV_CHUNK_SIZE;
        if (any(greaterThanEqual(imgChunkPos, SceneLPVSize))) return;

        int frameIndex = frameCounter % 2;
        ivec3 imgCoordOffset = GetLPVFrameOffset();
        ivec3 voxelOffset = GetLPVVoxelOffset();

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;

        for (int z = 0; z < LPV_CHUNK_SIZE; z++) {
            for (int y = 0; y < LPV_CHUNK_SIZE; y++) {
                for (int x = 0; x < LPV_CHUNK_SIZE; x++) {
                    ivec3 iPos = ivec3(x, y, z);

                    ivec3 imgCoord = imgChunkPos + iPos;
                    if (any(greaterThanEqual(imgCoord, SceneLPVSize))) continue;

                    ivec3 voxelPos = voxelOffset + imgCoord;

                    ivec3 gridCell = ivec3(floor(voxelPos / LIGHT_BIN_SIZE));
                    uint gridIndex = GetSceneLightGridIndex(gridCell);
                    ivec3 blockCell = voxelPos - gridCell * LIGHT_BIN_SIZE;
                    uint blockId = GetSceneBlockMask(blockCell, gridIndex);

                    vec3 lightValue = vec3(0.0);

                    #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
                        uint lightType = GetSceneLightType(int(blockId));
                        if (lightType != LIGHT_NONE && lightType != LIGHT_IGNORED) {
                            StaticLightData lightInfo = StaticLightMap[lightType];
                            vec3 lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
                            vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
                            float lightRange = lightRangeSize.x * 255.0;

                            vec3 blockLocalPos = gridCell * LIGHT_BIN_SIZE + blockCell + 0.5 - LightGridCenter - cameraOffset;

                            lightColor = RGBToLinear(lightColor);

                            vec2 lightNoise = vec2(0.0);
                            #ifdef DYN_LIGHT_FLICKER
                                lightNoise = GetDynLightNoise(cameraPosition + blockLocalPos);
                                ApplyLightFlicker(lightColor, lightType, lightNoise);
                            #endif

                            lightValue = LpvRangeF * lightColor * exp2(lightRange);
                        }
                        else {
                    #endif
                        bool allowLight = false;
                        vec3 tint = vec3(1.0);

                        #ifdef LPV_GLASS_TINT
                            if (blockId >= BLOCK_HONEY && blockId <= BLOCK_STAINED_GLASS_YELLOW) {
                                tint = GetLightGlassTint(blockId);
                                allowLight = true;
                            }
                            else {
                        #endif
                            allowLight = IsTraceOpenBlock(blockId);
                        #ifdef LPV_GLASS_TINT
                            }
                        #endif

                        if (allowLight) {
                            ivec3 imgCoordPrev = imgCoord + imgCoordOffset;
                            lightValue = mixNeighbours(imgCoordPrev) * tint;
                        }
                    #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED
                        }
                    #endif

                    if (frameIndex == 0)
                        imageStore(imgSceneLPV_1, imgCoord, vec4(lightValue, 1.0));
                    else
                        imageStore(imgSceneLPV_2, imgCoord, vec4(lightValue, 1.0));
                }
            }
        }
    #endif
}
