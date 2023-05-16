#define RENDER_SETUP_STATIC_LIGHT
#define RENDER_SETUP
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const ivec3 workGroups = ivec3(2, 2, 1);

#ifdef IRIS_FEATURE_SSBO //&& DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/blocks.glsl"

    #include "/lib/lights.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
#endif


void main() {
    #ifdef IRIS_FEATURE_SSBO //&& DYN_LIGHT_MODE != DYN_LIGHT_NONE
        uint lightType = uint(gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 16);
        if (lightType >= 256) return;

        vec3 lightOffset = GetSceneLightOffset(lightType);
        vec3 lightColor = GetSceneLightColor(lightType);
        float lightRange = GetSceneLightRange(lightType);
        float lightSize = GetSceneLightSize(lightType);

        StaticLightData light;
        light.Offset = packSnorm4x8(vec4(lightOffset, 0.0));
        light.Color = packUnorm4x8(vec4(lightColor, 0.0));
        light.RangeSize = packUnorm4x8(vec4(lightRange/255.0, lightSize, 0.0, 0.0));

        StaticLightMap[lightType] = light;
    #endif
}
