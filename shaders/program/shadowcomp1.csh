#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #ifdef DYN_LIGHT_FLICKER
        uniform sampler2D noisetex;

        uniform float frameTimeCounter;
    #endif

    uniform mat4 gbufferModelView;
    uniform vec3 cameraPosition;
    uniform float far;

    #include "/lib/blocks.glsl"
    #include "/lib/buffers/lighting.glsl"

    #ifdef DYN_LIGHT_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif
    
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
#endif


void main() {
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        ivec3 gridCell = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(gridCell, SceneLightGridSize))) return;

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
        
        uint gridIndex = GetSceneLightGridIndex(gridCell);
        //LightCellData sceneLightMap = SceneLightMaps[gridIndex];
        
        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined DYN_LIGHT_OCTREE
            BlockCellData sceneBlockMap = SceneBlockMaps[gridIndex];
            for (int i = 0; i < DYN_LIGHT_OCTREE_SIZE; i++)
                sceneBlockMap.OctreeMask[i] = 0u;
        #endif

        uint lightCount = SceneLightMaps[gridIndex].LightCount;
        if (lightCount != 0u) atomicAdd(SceneLightMaxCount, lightCount);

        uint binLightCountMin = min(lightCount, LIGHT_BIN_MAX_COUNT);
        uint lightGlobalOffset = atomicAdd(SceneLightCount, binLightCountMin);

        uint lightLocalIndex = 0u;
        for (int z = 0; z < LIGHT_BIN_SIZE && lightLocalIndex < LIGHT_BIN_MAX_COUNT; z++) {
            for (int y = 0; y < LIGHT_BIN_SIZE && lightLocalIndex < LIGHT_BIN_MAX_COUNT; y++) {
                for (int x = 0; x < LIGHT_BIN_SIZE && lightLocalIndex < LIGHT_BIN_MAX_COUNT; x++) {
                    ivec3 blockCell = ivec3(x, y, z);

                    #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined DYN_LIGHT_OCTREE
                        uint blockType = GetSceneBlockMask(blockCell, gridIndex);
                        if (blockType != BLOCKTYPE_EMPTY) {
                            uvec3 nodeMin = uvec3(0);
                            uvec3 nodeMax = uvec3(LIGHT_BIN_SIZE);
                            uvec3 nodePos = uvec3(0);

                            uint nodeBitOffset = 1u;

                            sceneBlockMap.OctreeMask[0] |= 1u;

                            for (uint treeDepth = 0u; treeDepth < DYN_LIGHT_OCTREE_LEVELS; treeDepth++) {
                                uvec3 nodeCenter = (nodeMin + nodeMax) / 2u;
                                uvec3 nodeChild = uvec3(step(nodeCenter, blockCell));

                                uint nodeSize = uint(exp2(treeDepth));
                                uint nodeMaskOffset = (nodePos.z * _pow2(nodeSize)) + (nodePos.y * nodeSize) + nodePos.x;
                                uint childMask = (nodeChild.z << 2u) & (nodeChild.y << 1u) & nodeChild.x;

                                uint nodeBitIndex = nodeBitOffset + 8u * nodeMaskOffset + childMask;
                                uint nodeArrayIndex = nodeBitIndex / 32u;

                                uint nodeMask = 1u << (nodeBitIndex - nodeArrayIndex);
                                sceneBlockMap.OctreeMask[nodeArrayIndex] |= nodeMask;

                                nodeBitOffset += uint(pow(8u, treeDepth + 1u));

                                uvec3 nodeHalfSize = (nodeMax - nodeMin) / 2u;
                                nodeMin += nodeHalfSize * nodeChild;
                                nodeMax -= nodeHalfSize * (1u - nodeChild);
                                nodePos = (nodePos + nodeChild) * 2u;
                            }
                        }
                    #endif

                    uint lightType = GetSceneLightMask(blockCell, gridIndex);
                    if (lightType == LIGHT_NONE || lightType == LIGHT_IGNORED) continue;

                    float lightRange = GetSceneLightRange(lightType);
                    vec3 blockLocalPos = gridCell * LIGHT_BIN_SIZE + blockCell + 0.5 - LightGridCenter - cameraOffset;

                    vec2 lightNoise = vec2(0.0);
                    #ifdef DYN_LIGHT_FLICKER
                        lightNoise = GetDynLightNoise(cameraPosition + blockLocalPos);
                    #endif

                    vec3 lightOffset = GetSceneLightOffset(lightType);
                    float lightSize = GetSceneLightSize(lightType);
                    vec3 lightColor = GetSceneLightColor(lightType, lightNoise);
                    bool lightTraced = GetLightTraced(lightType);
                    uint lightMask = BuildLightMask(lightType);
                    
                    vec3 lightPos = blockLocalPos + lightOffset;

                    uint lightGlobalIndex = lightGlobalOffset + lightLocalIndex;
                    SceneLights[lightGlobalIndex] = BuildLightData(lightPos, lightTraced, lightMask, lightSize, lightRange, lightColor);
                    SceneLightMaps[gridIndex].GlobalLights[lightLocalIndex] = lightGlobalIndex;

                    //if (++lightLocalIndex >= LIGHT_BIN_MAX_COUNT) return;
                    lightLocalIndex++;
                }
            }
        }

        #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED && defined DYN_LIGHT_OCTREE
            SceneBlockMaps[gridIndex] = sceneBlockMap;
        #endif
    #endif
}
