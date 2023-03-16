#define RENDER_PREPARE_LPV
#define RENDER_PREPARE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(64, 16, 64);

#include "/lib/buffers/lighting.glsl"
#include "/lib/lighting/dynamic.glsl"


void main() {
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_LPV
        //ivec3 pos = ivec3(gl_GlobalInvocationID);
        //if (any(greaterThanEqual(pos, SceneLightGridSize))) return;

        for (int z = 0; z < 4; z++) {
            for (int y = 0; y < 4; y++) {
                for (int x = 0; x < 4; x++) {
                    // TODO: darken pixel
                    ivec3 tex = gl_GlobalInvocationID + ivec3(x, z, y);
                    vec3 value = imageLoad(imgLPV, tex).rgb;

                    value = max(value - 0.1);
                    imageStore(imgLPV, tex, value);
                }
            }
        }

        MemoryBarrier();

        uint gridIndex = GetSceneLightGridIndex(pos);
        uint lightCount = SceneLightMaps[gridIndex].LightCount;
        lightCount = min(lightCount, LIGHT_BIN_MAX_COUNT);

        for (int i = 0; i < lightCount; i++) {
            // TODO: add lights to pixels
            ivec3 tex = ?;
            imageStore(imgLPV, tex, value);
        }

        MemoryBarrier();

        for (int z = 0; z < 4; z++) {
            for (int y = 0; y < 4; y++) {
                for (int x = 0; x < 4; x++) {
                    uint blockType = GetSceneBlockMask(?, gridIndex);
                    if (blockType == BLOCKTYPE_SOLID) continue;

                    // TODO: brighten by neighbor pixel
                    ivec3 tex = gl_GlobalInvocationID + ivec3(x, z, y);
                    vec3 value = imageLoad(imgLPV, tex).rgb;

                    vec3 valueN = imageLoad(imgLPV, tex + ivec2( 0, -1)).rgb;
                    vec3 valueE = imageLoad(imgLPV, tex + ivec2( 1,  0)).rgb;
                    vec3 valueS = imageLoad(imgLPV, tex + ivec2( 0,  1)).rgb;
                    vec3 valueW = imageLoad(imgLPV, tex + ivec2(-1,  0)).rgb;
                    vec3 valueMax = max(value, max(max(valueN, valueS), max(valueW, valueE)) - 0.1);
                    
                    imageStore(imgLPV, tex, value);
                }
            }
        }
    #endif
}
