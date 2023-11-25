#define RENDER_SETUP_COLLISIONS
#define RENDER_SETUP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(5, 5, 1);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    #include "/lib/blocks.glsl"
    #include "/lib/buffers/collisions.glsl"
    #include "/lib/lighting/voxel/collisions.glsl"
#endif


void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        uint blockId = uint(gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 40);
        if (blockId >= 1200) return;

        CollissionMaps[blockId].LightId = GetSceneLightType(blockId);

        uint shapeCount = 0u;
        vec3 boundsMin[BLOCK_MASK_PARTS];
        vec3 boundsMax[BLOCK_MASK_PARTS];

        GetVoxelBlockParts(blockId, shapeCount, boundsMin, boundsMax);

        CollissionMaps[blockId].Count = shapeCount;

        for (uint i = 0u; i < min(shapeCount, BLOCK_MASK_PARTS); i++) {
            CollissionMaps[blockId].Bounds[i] = uvec2(
                packUnorm4x8(vec4(boundsMin[i], 0.0)),
                packUnorm4x8(vec4(boundsMax[i], 0.0)));
        }
    #endif
}
