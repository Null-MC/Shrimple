#define RENDER_SHADOW
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(64, 16, 64);

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform mat4 gbufferModelView;
    uniform vec3 cameraPosition;
    uniform float far;

    #include "/lib/blocks.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/blackbody.glsl"
    #include "/lib/lighting/flicker.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/dynamic_blocks.glsl"
    #include "/lib/lighting/dynamic_lights.glsl"
#endif


void PopulateLocalLists(const in ivec3 gridCell, const in uint gridIndex, const in vec3 cameraOffset) {
    //vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
    uint lightLocalIndex = 0u;

    uint binLightCountMin = min(SceneLightMaps[gridIndex].LightCount, LIGHT_BIN_MAX_COUNT);
    uint lightGlobalIndex = atomicAdd(SceneLightCount, binLightCountMin);

    for (int z = 0; z < LIGHT_BIN_SIZE; z++) {
        for (int y = 0; y < LIGHT_BIN_SIZE; y++) {
            for (int x = 0; x < LIGHT_BIN_SIZE; x++) {
                ivec3 blockCell = ivec3(x, y, z);
                uint lightType = GetSceneLightMask(blockCell, gridIndex);
                if (lightType == LIGHT_NONE) continue;

                float lightRange = GetSceneLightRange(lightType);
                vec3 blockLocalPos = gridCell * LIGHT_BIN_SIZE + blockCell + 0.5 - LightGridCenter - cameraOffset;

                // TODO: This is probably faster in compute than shadow
                #ifdef DYN_LIGHT_FRUSTUM_TEST
                    vec3 lightViewPos = (gbufferModelView * vec4(blockLocalPos, 1.0)).xyz;
                    bool intersects = true;

                    float maxRange = lightRange > EPSILON ? lightRange : 16.0;
                    if (lightViewPos.z > maxRange) intersects = false;
                    else if (lightViewPos.z < -far - maxRange) intersects = false;
                    else {
                        if (dot(sceneViewUp,   lightViewPos) > maxRange) intersects = false;
                        if (dot(sceneViewDown, lightViewPos) > maxRange) intersects = false;
                        if (dot(sceneViewLeft,  lightViewPos) > maxRange) intersects = false;
                        if (dot(sceneViewRight, lightViewPos) > maxRange) intersects = false;
                    }

                    if (!intersects) continue;
                #endif

                vec3 lightOffset = vec3(0.0); // TODO
                vec2 lightNoise = vec2(0.0); // TODO

                float lightSize = GetSceneLightSize(lightType);
                vec3 lightColor = GetSceneLightColor(lightType, lightNoise);
                uint lightData = BuildLightMask(lightType, lightSize);
                SceneLightData light = SceneLightData(blockLocalPos + lightOffset, lightRange, lightColor, lightData);

                uint lightIndex = lightGlobalIndex + lightLocalIndex;
                //localLightMap[lightLocalIndex] = lightGlobalIndex;
                SceneLights[lightIndex] = light;

                ivec2 uv = GetSceneLightUV(gridIndex, lightLocalIndex);
                imageStore(imgSceneLights, uv, uvec4(lightIndex));

                if (lightLocalIndex++ >= LIGHT_BIN_MAX_COUNT) return;
            }
        }
    }
}

uint PopulateNeighborLists(const in ivec3 gridCell, const in uint gridIndex, const in vec3 cameraOffset) {
    // populate neighbor lists
    const float neighborRange = 0.0;

    uint lightLocalIndex = SceneLightMaps[gridIndex].LightCount;
    if (lightLocalIndex >= LIGHT_BIN_MAX_COUNT) return 0u;

    const int gridSize = int(ceil(neighborRange / LIGHT_BIN_SIZE));
    ivec3 neighborGridCellMin = max(gridCell - gridSize, ivec3(0.0));
    ivec3 neighborGridCellMax = min(gridCell + gridSize, SceneLightGridSize);

    vec3 binPos = (gridCell + 0.5) * LIGHT_BIN_SIZE - LightGridCenter - cameraOffset;

    uint neighborCount = 0u;
    ivec3 neighborGridCell;
    for (neighborGridCell.z = neighborGridCellMin.z; neighborGridCell.z <= neighborGridCellMax.z; neighborGridCell.z++) {
        for (neighborGridCell.y = neighborGridCellMin.y; neighborGridCell.y <= neighborGridCellMax.y; neighborGridCell.y++) {
            for (neighborGridCell.x = neighborGridCellMin.x; neighborGridCell.x <= neighborGridCellMax.x; neighborGridCell.x++) {
                if (neighborGridCell == gridCell) continue;

                uint neighborGridIndex = GetSceneLightGridIndex(neighborGridCell);
                uint neighborLightCount = min(SceneLightMaps[neighborGridIndex].LightCount, LIGHT_BIN_MAX_COUNT);
                
                for (uint i = 0u; i < neighborLightCount; i++) {
                    ivec2 uv = GetSceneLightUV(neighborGridIndex, i);
                    uint lightGlobalIndex = imageLoad(imgSceneLights, uv).r;
                    SceneLightData light = SceneLights[lightGlobalIndex];

                    if (!LightIntersectsBin(binPos, LIGHT_BIN_SIZE, light.position, light.range)) continue;

                    uv = GetSceneLightUV(gridIndex, lightLocalIndex);
                    imageStore(imgSceneLights, uv, uvec4(lightGlobalIndex));
                    lightLocalIndex++;
                    neighborCount++;

                    if (lightLocalIndex >= LIGHT_BIN_MAX_COUNT)
                        return neighborCount;
                }
            }
        }
    }

    return neighborCount;
}

void main() {
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        ivec3 gridCell = ivec3(gl_GlobalInvocationID);
        if (any(greaterThanEqual(gridCell, SceneLightGridSize))) return;

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
        
        uint gridIndex = GetSceneLightGridIndex(gridCell);
        
        if (SceneLightMaps[gridIndex].LightCount > 0u) {
            atomicAdd(SceneLightMaxCount, SceneLightMaps[gridIndex].LightCount);

            PopulateLocalLists(gridCell, gridIndex, cameraOffset);
        }

        memoryBarrier();

        uint neighborCount = PopulateNeighborLists(gridCell, gridIndex, cameraOffset);

        memoryBarrier();

        SceneLightMaps[gridIndex].LightCount += neighborCount;
    #endif
}
