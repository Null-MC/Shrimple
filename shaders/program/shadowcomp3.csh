#define RENDER_SHADOWCOMP_LPV
#define RENDER_SHADOWCOMP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

const ivec3 workGroups = ivec3(16, 8, 16);

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_LPV
    #ifdef DYN_LIGHT_FLICKER
        uniform sampler2D noisetex;
    #endif

    uniform int frameCounter;
    uniform float frameTimeCounter;
    //uniform mat4 gbufferModelView;
    uniform vec3 cameraPosition;
    //uniform float far;

    #include "/lib/blocks.glsl"

    #include "/lib/sampling/ign.glsl"
    #include "/lib/sampling/noise.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/buffers/volume.glsl"

    #ifdef DYN_LIGHT_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif
    
    //#include "/lib/lighting/voxel/blocks.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/collisions.glsl"
    #include "/lib/lighting/voxel/tracing.glsl"
    #include "/lib/lighting/sampling.glsl"
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

        vec3 lightPos, lightColor, lightVec;
        float lightSize, lightRange, traceDist2;
        uvec4 lightData;

        for (int z = 0; z < LIGHT_BIN_SIZE; z++) {
            for (int y = 0; y < LIGHT_BIN_SIZE; y++) {
                for (int x = 0; x < LIGHT_BIN_SIZE; x++) {
                    ivec3 blockCell = ivec3(x, y, z);
                    vec3 blockLocalPos = gridBlockOffset + blockCell + 0.5 - LightGridCenter - cameraOffset;

                    vec3 accumLight = vec3(0.0);
                    for (int i = 0; i < binLightCountMin; i++) {
                        lightData = GetSceneLight(gridIndex, i);
                        ParseLightData(lightData, lightPos, lightSize, lightRange, lightColor);

                        //vec3 lightColor = light.color;
                        vec3 lightVec = blockLocalPos - lightPos;
                        if (dot(lightVec, lightVec) >= _pow2(lightRange)) continue;

                        //lightColor *= TraceDDA_fast(light.position, blockLocalPos, light.range);

                        float lightAtt = GetLightAttenuation(lightVec, lightRange);
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
