#define RENDER_SETUP_STATIC_BLOCK
#define RENDER_SETUP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(4, 5, 1);

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/blocks.glsl"
    #include "/lib/lights.glsl"

    #include "/lib/buffers/static_block.glsl"

    #include "/lib/world/waving_blocks.glsl"
    #include "/lib/material/specular_blocks.glsl"
    #include "/lib/material/subsurface_blocks.glsl"
    #include "/lib/lighting/voxel/block_light_map.glsl"
#endif


void main() {
    #ifdef IRIS_FEATURE_SSBO
        uint blockId = uint(gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 32);
        //if (blockId >= 1280) return;

        StaticBlockData block;

        GetBlockWavingRangeAttachment(blockId, block.wavingRange, block.wavingAttachment);

        block.materialRough = GetBlockRoughness(blockId);
        block.materialMetalF0 = GetBlockMetalF0(blockId);
        block.materialSSS = GetBlockSSS(blockId);

        block.lightType = GetSceneLightType(blockId);

        StaticBlockMap[blockId] = block;
    #endif
}
