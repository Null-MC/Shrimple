#define RENDER_SHADOWCOMP_LPV
#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_LPV
    #ifdef DYN_LIGHT_FLICKER
        uniform sampler2D noisetex;
    #endif

    uniform int frameCounter;
    uniform float frameTimeCounter;
    //uniform mat4 gbufferModelView;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;
    //uniform float far;

    #include "/lib/blocks.glsl"
    #include "/lib/lights.glsl"

    #include "/lib/sampling/ign.glsl"
    #include "/lib/sampling/noise.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/buffers/volume.glsl"

    #ifdef DYN_LIGHT_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif
    
    //#include "/lib/lighting/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
#endif


vec3 mixNeighbours(const in ivec3 fragCoord) {
    const float FALLOFF = 0.002;

    int frameIndex = frameCounter % 2;

    vec3 nX1 = imageLoad(frameIndex == 0 ? imgSceneLPV_2 : imgSceneLPV_1, fragCoord + ivec3(-1,  0,  0)).rgb;
    vec3 nX2 = imageLoad(frameIndex == 0 ? imgSceneLPV_2 : imgSceneLPV_1, fragCoord + ivec3( 1,  0,  0)).rgb;
    vec3 nY1 = imageLoad(frameIndex == 0 ? imgSceneLPV_2 : imgSceneLPV_1, fragCoord + ivec3( 0, -1,  0)).rgb;
    vec3 nY2 = imageLoad(frameIndex == 0 ? imgSceneLPV_2 : imgSceneLPV_1, fragCoord + ivec3( 0,  1,  0)).rgb;
    vec3 nZ1 = imageLoad(frameIndex == 0 ? imgSceneLPV_2 : imgSceneLPV_1, fragCoord + ivec3( 0,  0, -1)).rgb;
    vec3 nZ2 = imageLoad(frameIndex == 0 ? imgSceneLPV_2 : imgSceneLPV_1, fragCoord + ivec3( 0,  0,  1)).rgb;

    vec3 n = (nX1 + nX2 + nY1 + nY2 + nZ1 + nZ2) / 6.0;
    //float falloff = rcp(max(luminance(n), 1.0)) * FALLOFF;
    return n;// * (1.0 - falloff);
}

void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_LPV
        ivec3 gridCell = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(gridCell, SceneLightGridSize))) return;

        ivec3 gridBlockOffset = gridCell * LIGHT_BIN_SIZE;
        if (any(greaterThanEqual(gridBlockOffset, ivec3(256, 128, 256)))) return;

        vec3 p1 = GetLightGridPosition(vec3(0.0));
        vec3 p2 = GetLightGridPosition(previousCameraPosition - cameraPosition);

        ivec3 gridCellOffset = GetSceneLightGridCell(p1) - GetSceneLightGridCell(p2);
        ivec3 gridCellLast = gridCell + gridCellOffset;
        ivec3 gridBlockOffsetLast = gridCellLast * LIGHT_BIN_SIZE;

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
        
        uint gridIndex = GetSceneLightGridIndex(gridCell);
        uint binLightCountMin = min(SceneLightMaps[gridIndex].LightCount + SceneLightMaps[gridIndex].LightNeighborCount, LIGHT_BIN_MAX_COUNT);
        //if (binLightCountMin == 0u) return;

        vec3 lightPos, lightColor, lightVec, accumLight;
        float lightSize, lightRange, traceDist2;
        uint lightGlobalIndex, blockId;
        ivec3 blockCell, fragPos;
        uvec4 lightData;

        int frameIndex = frameCounter % 2;

        for (int z = 0; z < LIGHT_BIN_SIZE; z++) {
            for (int y = 0; y < LIGHT_BIN_SIZE; y++) {
                for (int x = 0; x < LIGHT_BIN_SIZE; x++) {
                    blockCell = ivec3(x, y, z);

                    blockId = GetSceneBlockMask(blockCell, gridIndex);

                    accumLight = vec3(0.0);
                    if (blockId == BLOCK_EMPTY && frameCounter > 1) {
                        fragPos = gridBlockOffsetLast + blockCell;
                        accumLight = mixNeighbours(fragPos);
                    }

                    fragPos = gridBlockOffset + blockCell;
                    imageStore(frameIndex == 0 ? imgSceneLPV_1 : imgSceneLPV_2, fragPos, vec4(accumLight, 1.0));
                }
            }
        }

        for (int i = 0; i < binLightCountMin; i++) {
            lightGlobalIndex = SceneLightMaps[gridIndex].GlobalLights[i];
            lightData = SceneLights[lightGlobalIndex];

            ParseLightPosition(lightData, lightPos);
            ParseLightColor(lightData, lightColor);
            ParseLightRange(lightData, lightRange);

            ivec3 _gridCell;
            vec3 gridPos = GetLightGridPosition(lightPos);
            GetSceneLightGridCell(gridPos, _gridCell, blockCell);
            fragPos = _gridCell * LIGHT_BIN_SIZE + blockCell;

            vec3 lightFinal = RGBToLinear(lightColor) * lightRange * 8.0;// * VolumetricBlockRangeF;
            imageStore(frameIndex == 0 ? imgSceneLPV_1 : imgSceneLPV_2, fragPos, vec4(lightFinal, 1.0));
        }

        //memoryBarrierImage();
        //memoryBarrier();
    #endif
}
