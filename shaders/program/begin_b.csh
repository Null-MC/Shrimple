#define RENDER_BEGIN_LIGHTING
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

uniform vec3 cameraPosition;

#include "/lib/buffers/lighting.glsl"
#include "/lib/lighting/dynamic.glsl"


void main() {
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        ivec3 pos = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(pos, SceneLightGridSize))) return;
        uint gridIndex = GetSceneLightGridIndex(pos);

        SceneLightMaps[gridIndex].LightCount = 0u;

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
            for (int i = 0; i < (LIGHT_BIN_SIZE3*DYN_LIGHT_MASK_STRIDE/32); i++) {
                SceneLightMaps[gridIndex].BlockMask[i] = 0u;
                SceneLightMaps[gridIndex].LightMask[i] = 0u;
            }
        #else
            for (int i = 0; i < (LIGHT_BIN_SIZE3/32); i++)
                SceneLightMaps[gridIndex].LightMask[i] = 0u;
        #endif
    #endif
}
