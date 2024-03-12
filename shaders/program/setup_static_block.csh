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

    #if WORLD_WIND_STRENGTH > 0
        #include "/lib/world/waving_blocks.glsl"
    #endif

    #ifdef IS_LPV_ENABLED
        #include "/lib/lighting/voxel/blocks.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED || LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
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

        #if WORLD_WIND_STRENGTH > 0
            GetBlockWavingRangeAttachment(blockId, block.wavingRange, block.wavingAttachment);
        #endif

        #ifdef IS_LPV_ENABLED
            float mixWeight = 0.0;
            uint mixMask = 0xFFFF;

            if (blockId == BLOCK_SLAB_TOP || blockId == BLOCK_SLAB_BOTTOM) {
                mixMask = mixMask & ~(1 << 2) & ~(1 << 3);
                mixWeight = 0.5;
                // allowLight = true;
            }
            else if (blockId == BLOCK_DOOR_N || blockId == BLOCK_DOOR_S) {
                // allowLight = true;
                mixMask = mixMask & ~(1 << 4) & ~(1 << 5);
                mixWeight = 1.0;
            }
            else if (blockId == BLOCK_DOOR_W || blockId == BLOCK_DOOR_E) {
                // allowLight = true;
                mixMask = mixMask & ~(1 << 0) & ~(1 << 1);
                mixWeight = 1.0;
            }
            else {
                if (IsTraceOpenBlock(blockId)) mixWeight = 1.0;
            }

            block.lpv_data = BuildBlockLpvData(mixMask, mixWeight);
        #endif

        #if LIGHTING_MODE == LIGHTING_MODE_TRACED || LIGHTING_MODE_HAND == HAND_LIGHT_TRACED
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
