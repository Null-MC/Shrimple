#define RENDER_SHADOW
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(64, 16, 64);

#include "/lib/buffers/lighting.glsl"
#include "/lib/lighting/dynamic.glsl"
#include "/lib/lighting/dynamic_lights.glsl"


void main() {
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_LPV
        ivec3 pos = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(pos, SceneLightGridSize))) return;

        uint gridIndex = GetSceneLightGridIndex(gridCell);

        // TODO: populate local lists
        for (int z = 0; z < LIGHT_BIN_SIZE; z++) {
            for (int y = 0; y < LIGHT_BIN_SIZE; y++) {
                for (int x = 0; x < LIGHT_BIN_SIZE; x++) {
                    ivec3 blockCell = ivec3(x, y, z);
                    uint lightType = GetSceneLightMask(blockCell, gridIndex);
                    if (lightType == LIGHT_NONE) continue;

                    // TODO: Add to local light list
                }
            }
        }

        MemoryBarrier();

        // TODO: populate neighbor lists

        //MemoryBarrier();
    #endif
}
