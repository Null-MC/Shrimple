#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_LPV
    //uniform mat4 gbufferModelView;
    uniform vec3 cameraPosition;
    //uniform float far;

    //#include "/lib/blocks.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/buffers/volume.glsl"
    
    #include "/lib/lighting/sampling.glsl"
    #include "/lib/lighting/dynamic.glsl"
    #include "/lib/lighting/collisions.glsl"
    #include "/lib/lighting/tracing.glsl"
    //#include "/lib/lighting/dynamic_blocks.glsl"
    //#include "/lib/lighting/dynamic_lights.glsl"
#endif


void main() {
    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_LPV
        ivec3 gridCell = ivec3(gl_GlobalInvocationID);
        ivec3 gridBlockOffset = gridCell * LIGHT_BIN_SIZE;

        if (any(greaterThanEqual(gridBlockOffset, ivec3(256, 64, 256)))) return;

        vec3 cameraOffset = fract(cameraPosition / LIGHT_BIN_SIZE) * LIGHT_BIN_SIZE;
        
        uint gridIndex = GetSceneLightGridIndex(gridCell);
        uint binLightCountMin = min(SceneLightMaps[gridIndex].LightCount + SceneLightMaps[gridIndex].LightNeighborCount, LIGHT_BIN_MAX_COUNT);
        if (binLightCountMin == 0u) return;

        for (int z = 0; z < LIGHT_BIN_SIZE; z++) {
            for (int y = 0; y < LIGHT_BIN_SIZE; y++) {
                for (int x = 0; x < LIGHT_BIN_SIZE; x++) {
                    ivec3 blockCell = ivec3(x, y, z);
                    vec3 blockLocalPos = gridBlockOffset + blockCell + 0.5 - LightGridCenter - cameraOffset;

                    vec3 accumLight = vec3(0.0);
                    for (int i = 0; i < binLightCountMin; i++) {
                        uint lightGlobalIndex = SceneLightMaps[gridIndex].GlobalLights[i];
                        SceneLightData light = SceneLights[lightGlobalIndex];

                        vec3 lightColor = light.color;
                        vec3 lightVec = blockLocalPos - light.position;
                        if (dot(lightVec, lightVec) >= _pow2(light.range)) continue;

                        //lightColor *= TraceDDA_fast(light.position, blockLocalPos, light.range);

                        float lightAtt = GetLightAttenuation(lightVec, light.range);
                        accumLight += lightColor * lightAtt;
                    }

                    ivec3 tex = gridBlockOffset + blockCell;
                    imageStore(imgSceneLPV, tex, vec4(accumLight, 1.0));
                }
            }
        }

        //memoryBarrierImage();
        //memoryBarrier();
    #endif
}
