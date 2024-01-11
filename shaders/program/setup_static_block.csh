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

    #include "/lib/buffers/block_static.glsl"

    #include "/lib/material/specular_blocks.glsl"
    #include "/lib/material/subsurface_blocks.glsl"

    #include "/lib/lighting/voxel/block_light_map.glsl"

    #ifdef WORLD_WAVING_ENABLED
        #include "/lib/world/waving_blocks.glsl"
    #endif

    #if LIGHTING_MODE == DYN_LIGHT_TRACED || LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
        #include "/lib/lighting/voxel/collisions.glsl"
    #endif
#endif


void main() {
    #ifdef IRIS_FEATURE_SSBO
        uint blockId = uint(gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 32);
        //if (blockId >= 1280) return;

        StaticBlockData block;

        block.lightType = GetSceneLightType(blockId);

        block.materialRough = GetBlockRoughness(blockId);
        block.materialMetalF0 = GetBlockMetalF0(blockId);
        block.materialSSS = GetBlockSSS(blockId);

        #ifdef WORLD_WAVING_ENABLED
            GetBlockWavingRangeAttachment(blockId, block.wavingRange, block.wavingAttachment);
        #endif

        #if LIGHTING_MODE == DYN_LIGHT_TRACED || LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
            block.Collisions.Count = 0u;

            vec3 boundsMin[BLOCK_MASK_PARTS];
            vec3 boundsMax[BLOCK_MASK_PARTS];

            GetVoxelBlockParts(blockId, block.Collisions.Count, boundsMin, boundsMax);

            for (uint i = 0u; i < min(block.Collisions.Count, BLOCK_MASK_PARTS); i++) {
                block.Collisions.Bounds[i] = uvec2(
                    packUnorm4x8(vec4(boundsMin[i], 0.0)),
                    packUnorm4x8(vec4(boundsMax[i], 0.0)));
            }
        #endif

        StaticBlockMap[blockId] = block;
    #endif
}
