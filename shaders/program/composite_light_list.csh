#define RENDER_SHADOWCOMP_LIGHT_POPULATE
#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if LIGHTING_MODE != LIGHTING_MODE_NONE
    #ifdef LIGHTING_FLICKER
        uniform sampler2D noisetex;
    #endif

    uniform mat4 gbufferModelView;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;
    uniform float far;

    #ifdef ANIM_WORLD_TIME
        uniform int worldTime;
    #else
        uniform float frameTimeCounter;
    #endif
    
    #ifdef IS_LPV_ENABLED
        uniform int frameCounter;
    #endif

    #include "/lib/blocks.glsl"
    #include "/lib/lights.glsl"
    
    #include "/lib/buffers/light_static.glsl"
    #include "/lib/buffers/light_voxel.glsl"

    #include "/lib/sampling/noise.glsl"

    #ifdef LIGHTING_FLICKER
        #include "/lib/utility/anim.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif
    
    #include "/lib/voxel/lights/mask.glsl"
    #include "/lib/voxel/lights/light_mask.glsl"
    #include "/lib/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/lights_render.glsl"
#endif


void main() {
    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        ivec3 gridCell = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(gridCell, VoxelLightBufferSize))) return;
        
        uint gridIndex = GetVoxelGridCellIndex(gridCell);
        
        // #ifdef DYN_LIGHT_OCTREE
        //     BlockCellData sceneBlockMap = SceneBlockMaps[gridIndex];
        //     for (int i = 0; i < DYN_LIGHT_OCTREE_SIZE; i++)
        //         sceneBlockMap.OctreeMask[i] = 0u;
        // #endif

        #if LIGHTING_MODE == LIGHTING_MODE_TRACED
            uint lightCount = SceneLightMaps[gridIndex].LightCount;
            if (lightCount != 0u) atomicAdd(SceneLightMaxCount, lightCount);

            uint binLightCountMin = min(lightCount, LIGHT_BIN_MAX_COUNT);
            uint lightGlobalOffset = atomicAdd(SceneLightCount, binLightCountMin);
        #endif

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;

        #ifdef IS_LPV_ENABLED
            int frameIndex = frameCounter % 2;
        #endif

        uint lightLocalIndex = 0u;
        for (int z = 0; z < LIGHT_BIN_SIZE; z++) {
            for (int y = 0; y < LIGHT_BIN_SIZE; y++) {
                for (int x = 0; x < LIGHT_BIN_SIZE; x++) {
                    ivec3 blockCell = ivec3(x, y, z);

                    if (lightLocalIndex >= LIGHT_BIN_MAX_COUNT) break;

                    // #ifdef DYN_LIGHT_OCTREE
                    //     uint blockType = GetSceneBlockMask(blockCell, gridIndex);
                    //     if (blockType != BLOCKTYPE_EMPTY) {
                    //         uvec3 nodeMin = uvec3(0);
                    //         uvec3 nodeMax = uvec3(LIGHT_BIN_SIZE);
                    //         uvec3 nodePos = uvec3(0);

                    //         uint nodeBitOffset = 1u;

                    //         sceneBlockMap.OctreeMask[0] |= 1u;

                    //         for (uint treeDepth = 0u; treeDepth < DYN_LIGHT_OCTREE_LEVELS; treeDepth++) {
                    //             uvec3 nodeCenter = (nodeMin + nodeMax) / 2u;
                    //             uvec3 nodeChild = uvec3(step(nodeCenter, blockCell));

                    //             uint nodeSize = uint(exp2(treeDepth));
                    //             uint nodeMaskOffset = (nodePos.z * _pow2(nodeSize)) + (nodePos.y * nodeSize) + nodePos.x;
                    //             uint childMask = (nodeChild.z << 2u) & (nodeChild.y << 1u) & nodeChild.x;

                    //             uint nodeBitIndex = nodeBitOffset + 8u * nodeMaskOffset + childMask;
                    //             uint nodeArrayIndex = nodeBitIndex / 32u;

                    //             uint nodeMask = 1u << (nodeBitIndex - nodeArrayIndex);
                    //             sceneBlockMap.OctreeMask[nodeArrayIndex] |= nodeMask;

                    //             nodeBitOffset += uint(pow(8u, treeDepth + 1u));

                    //             uvec3 nodeHalfSize = (nodeMax - nodeMin) / 2u;
                    //             nodeMin += nodeHalfSize * nodeChild;
                    //             nodeMax -= nodeHalfSize * (1u - nodeChild);
                    //             nodePos = (nodePos + nodeChild) * 2u;
                    //         }
                    //     }
                    // #endif

                    uint lightType = GetVoxelLightMask(blockCell, gridIndex);
                    if (lightType == LIGHT_NONE || lightType == LIGHT_IGNORED) continue;

                    StaticLightData lightInfo = StaticLightMap[lightType];
                    vec3 lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
                    vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
                    float lightRange = lightRangeSize.x * 255.0;

                    vec3 blockLocalPos = gridCell * LIGHT_BIN_SIZE + blockCell + 0.5 - VoxelLightBlockCenter - cameraOffset;

                    lightColor = RGBToLinear(lightColor);

                    vec3 worldPos = cameraPosition + blockLocalPos;
                    ApplyLightAnimation(lightColor, lightRange, lightType, worldPos);

                    vec2 lightNoise = vec2(0.0);
                    #ifdef LIGHTING_FLICKER
                        lightNoise = GetDynLightNoise(worldPos);
                        ApplyLightFlicker(lightColor, lightType, lightNoise);
                    #endif

                    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
                        if (lightLocalIndex < LIGHT_BIN_MAX_COUNT) {
                            lightColor = LinearToRGB(lightColor);
                            vec3 lightOffset = unpackSnorm4x8(lightInfo.Offset).xyz;
                            uint lightMask = BuildLightMask(lightType);
                            float lightSize = lightRangeSize.y;

                            // bool lightTraced = GetLightTraced(lightType);
//                            bool lightTraced = (lightInfo.Metadata & 1u) == 1u;
//                            bool selfTraced = ((lightInfo.Metadata >> 1u) & 1u) == 1u;
                            bool lightTraced = bitfieldExtract(lightInfo.Metadata, 0, 1) == 1u;
                            bool selfTraced = bitfieldExtract(lightInfo.Metadata, 1, 1) == 1u;

                            uint lightGlobalIndex = lightGlobalOffset + lightLocalIndex;
                            SceneLights[lightGlobalIndex] = BuildLightData(blockLocalPos + lightOffset, lightTraced, selfTraced, lightMask, lightSize, lightRange, lightColor);
                            SceneLightMaps[gridIndex].GlobalLights[lightLocalIndex] = lightGlobalIndex;

                            lightLocalIndex++;
                        }
                    #endif
                }
            }
        }

        // #ifdef DYN_LIGHT_OCTREE
        //     SceneBlockMaps[gridIndex] = sceneBlockMap;
        // #endif
    #endif
}
