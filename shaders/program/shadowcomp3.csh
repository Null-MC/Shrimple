#define RENDER_SHADOWCOMP_LIGHT_NEIGHBORS
#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    uniform mat4 gbufferModelView;
    uniform vec3 cameraPosition;
    uniform float far;

    #include "/lib/blocks.glsl"
    #include "/lib/lights.glsl"

    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/light_mask.glsl"
    #include "/lib/lighting/voxel/lights.glsl"


    uint PopulateNeighborLists(const in ivec3 gridCell, const in uint gridIndex, const in vec3 cameraOffset) {
        uint lightLocalIndex = SceneLightMaps[gridIndex].LightCount;
        if (lightLocalIndex >= LIGHT_BIN_MAX_COUNT) return 0u;

        const int gridSize = int(16.0 * DynamicLightRangeF) / LIGHT_BIN_SIZE + 1;
        vec3 binPos = gridCell * LIGHT_BIN_SIZE - VoxelBlockCenter - cameraOffset;

        uint neighborCount = 0u;
        ivec3 neighborOffset;
        for (neighborOffset.z = -gridSize; neighborOffset.z <= gridSize; neighborOffset.z++) {
            for (neighborOffset.y = -gridSize; neighborOffset.y <= gridSize; neighborOffset.y++) {
                for (neighborOffset.x = -gridSize; neighborOffset.x <= gridSize; neighborOffset.x++) {
                    if (lightLocalIndex >= LIGHT_BIN_MAX_COUNT) break;
                    if (neighborOffset == ivec3(0)) continue;

                    ivec3 neighborGridCell = gridCell + neighborOffset;
                    if (any(lessThan(neighborGridCell, ivec3(0))) || any(greaterThanEqual(neighborGridCell, VoxelGridSize))) continue;

                    uint neighborGridIndex = GetVoxelGridCellIndex(neighborGridCell);
                    uint neighborLightCount = SceneLightMaps[neighborGridIndex].LightCount;
                    
                    for (uint i = 0u; i < min(neighborLightCount, LIGHT_BIN_MAX_COUNT); i++) {
                        if (lightLocalIndex >= LIGHT_BIN_MAX_COUNT) break;

                        uint lightGlobalIndex = SceneLightMaps[neighborGridIndex].GlobalLights[i];
                        uvec4 lightData = SceneLights[lightGlobalIndex];

                        vec3 lightPos;
                        float lightRange;
                        ParseLightPosition(lightData, lightPos);
                        ParseLightRange(lightData, lightRange);
                        
                        if (LightIntersectsBin(binPos, LIGHT_BIN_SIZE, lightPos, lightRange + 0.5)) {
                            SceneLightMaps[gridIndex].GlobalLights[lightLocalIndex] = lightGlobalIndex;
                            lightLocalIndex++;
                            neighborCount++;
                        }

                        //if (++lightLocalIndex >= LIGHT_BIN_MAX_COUNT)
                        //    return neighborCount;
                    }
                }
            }
        }

        return neighborCount;
    }
#endif

void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        ivec3 gridCell = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(gridCell, VoxelGridSize))) return;

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
        
        uint gridIndex = GetVoxelGridCellIndex(gridCell);
        
        uint neighborCount = PopulateNeighborLists(gridCell, gridIndex, cameraOffset);

        SceneLightMaps[gridIndex].LightNeighborCount = neighborCount;

        //memoryBarrierBuffer();
    #endif
}
