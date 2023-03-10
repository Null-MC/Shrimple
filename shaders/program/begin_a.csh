#define RENDER_BEGIN_CSM
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(4, 1, 1);

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    uniform mat4 gbufferProjectionInverse;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform float near;
    uniform float far;
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/buffers/lighting.glsl"
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    #include "/lib/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"
    #include "/lib/shadows/cascaded.glsl"
#endif


void main() {
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        SceneLightCount = 0u;

        vec3 farClipPos[4];
        farClipPos[0] = unproject(gbufferProjectionInverse * vec4(-1.0, -1.0, 1.0, 1.0));
        farClipPos[1] = unproject(gbufferProjectionInverse * vec4( 1.0, -1.0, 1.0, 1.0));
        farClipPos[2] = unproject(gbufferProjectionInverse * vec4(-1.0,  1.0, 1.0, 1.0));
        farClipPos[3] = unproject(gbufferProjectionInverse * vec4( 1.0,  1.0, 1.0, 1.0));

        sceneViewUp    = normalize(cross(farClipPos[0] - farClipPos[1], farClipPos[0]));
        sceneViewRight = normalize(cross(farClipPos[1] - farClipPos[3], farClipPos[1]));
        sceneViewDown  = normalize(cross(farClipPos[3] - farClipPos[2], farClipPos[3]));
        sceneViewLeft  = normalize(cross(farClipPos[2] - farClipPos[0], farClipPos[2]));
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        float cascadeSizes[4];
        cascadeSizes[0] = GetCascadeDistance(0);
        cascadeSizes[1] = GetCascadeDistance(1);
        cascadeSizes[2] = GetCascadeDistance(2);
        cascadeSizes[3] = GetCascadeDistance(3);

        int i = int(gl_GlobalInvocationID.x);

        cascadeSize[i] = cascadeSizes[i];
        shadowProjectionPos[i] = GetShadowTilePos(i);
        cascadeProjection[i] = GetShadowTileProjectionMatrix(cascadeSizes, i, cascadeViewMin[i], cascadeViewMax[i]);

        shadowProjectionSize[i] = 2.0 / vec2(
            cascadeProjection[i][0].x,
            cascadeProjection[i][1].y);
    #endif
}
