#define RENDER_BEGIN_LIGHTING
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

    const ivec3 workGroups = ivec3(16, 8, 16);
#else
#endif

#if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;

    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
#endif


void main() {
    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        ivec3 pos = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(pos, VoxelGridSize))) return;
        uint gridIndex = GetVoxelGridCellIndex(pos);

        //LightCellData cellData = SceneLightMaps[gridIndex];

        SceneLightMaps[gridIndex].LightPreviousCount = cellData.LightCount + cellData.LightNeighborCount;
        SceneLightMaps[gridIndex].LightNeighborCount = 0u;
        SceneLightMaps[gridIndex].LightCount = 0u;

        //SceneLightMaps[gridIndex] = cellData;
    #endif
}
