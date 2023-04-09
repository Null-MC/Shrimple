#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform mat4 gbufferModelView;
    uniform vec3 cameraPosition;
    uniform float far;

    #include "/lib/blocks.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
    #include "/lib/lighting/dynamic_lights.glsl"


    uint PopulateNeighborLists(const in ivec3 gridCell, const in uint gridIndex, const in vec3 cameraOffset) {
        uint lightLocalIndex = SceneLightMaps[gridIndex].LightCount;
        if (lightLocalIndex >= LIGHT_BIN_MAX_COUNT) return 0u;

        const int gridSize = 16 / LIGHT_BIN_SIZE;
        vec3 binPos = (gridCell + 0.5) * LIGHT_BIN_SIZE - LightGridCenter - cameraOffset;

        uint neighborCount = 0u;
        ivec3 neighborOffset;
        for (neighborOffset.z = -gridSize; neighborOffset.z <= gridSize; neighborOffset.z++) {
            for (neighborOffset.y = -gridSize; neighborOffset.y <= gridSize; neighborOffset.y++) {
                for (neighborOffset.x = -gridSize; neighborOffset.x <= gridSize; neighborOffset.x++) {
                    if (neighborOffset == ivec3(0)) continue;

                    ivec3 neighborGridCell = gridCell + neighborOffset;
                    if (any(lessThan(neighborGridCell, ivec3(0))) || any(greaterThanEqual(neighborGridCell, SceneLightGridSize))) continue;

                    uint neighborGridIndex = GetSceneLightGridIndex(neighborGridCell);
                    uint neighborLightCount = min(SceneLightMaps[neighborGridIndex].LightCount, LIGHT_BIN_MAX_COUNT);
                    
                    for (uint i = 0u; i < neighborLightCount; i++) {
                        uint lightGlobalIndex = SceneLightMaps[neighborGridIndex].GlobalLights[i];
                        SceneLightData light = SceneLights[lightGlobalIndex];

                        if (!LightIntersectsBin(binPos, LIGHT_BIN_SIZE, light.position, light.range)) continue;

                        SceneLightMaps[gridIndex].GlobalLights[lightLocalIndex] = lightGlobalIndex;
                        neighborCount++;

                        if (++lightLocalIndex >= LIGHT_BIN_MAX_COUNT)
                            return neighborCount;
                    }
                }
            }
        }

        return neighborCount;
    }
#endif

void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        ivec3 gridCell = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(gridCell, SceneLightGridSize))) return;

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
        
        uint gridIndex = GetSceneLightGridIndex(gridCell);
        
        uint neighborCount = PopulateNeighborLists(gridCell, gridIndex, cameraOffset);

        SceneLightMaps[gridIndex].LightNeighborCount = neighborCount;
    #endif
}
