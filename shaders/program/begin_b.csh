#define RENDER_BEGIN_LIGHTING
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;

    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
#endif


void main() {
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        ivec3 pos = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(pos, SceneLightGridSize))) return;
        uint gridIndex = GetSceneLightGridIndex(pos);

        LightCellData cellData = SceneLightMaps[gridIndex];

        cellData.LightPreviousCount = cellData.LightCount + cellData.LightNeighborCount;
        cellData.LightNeighborCount = 0u;
        cellData.LightCount = 0u;

        SceneLightMaps[gridIndex] = cellData;
    #endif
}
