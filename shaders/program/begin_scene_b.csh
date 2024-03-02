#define RENDER_BEGIN_SCENE_B
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    layout (local_size_x = 4, local_size_y = 1, local_size_z = 1) in;
#else
    layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
#endif

const ivec3 workGroups = ivec3(1, 1, 1);

#if defined IRIS_FEATURE_SSBO && defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferProjectionInverse;
    // uniform mat4 gbufferPreviousProjection;
    uniform vec3 cameraPosition;
    uniform float near;

    #ifdef WORLD_SKY_ENABLED
        uniform mat4 shadowModelView;
        //uniform vec3 cameraPosition;
        uniform float far;

        // #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
        //     uniform mat4 shadowProjection;
        // #endif
    #endif

    #ifdef DISTANT_HORIZONS
        uniform mat4 dhProjection;
        uniform float dhFarPlane;
    #endif

    #include "/lib/buffers/scene.glsl"

    #include "/lib/utility/matrix.glsl"
    #include "/lib/shadows/common.glsl"
    #include "/lib/buffers/shadow.glsl"

    #include "/lib/shadows/cascaded/common.glsl"
    #include "/lib/shadows/cascaded/prepare.glsl"
#endif


void main() {
    #if defined IRIS_FEATURE_SSBO && defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        int i = int(gl_GlobalInvocationID.x);

        cascadeSize[i] = GetCascadeDistance(i);

        groupMemoryBarrier();

        shadowProjectionPos[i] = GetShadowTilePos(i);
        cascadeProjection[i] = GetShadowTileProjectionMatrix(cascadeSize, i, cascadeViewMin[i], cascadeViewMax[i]);

        shadowProjectionSize[i] = 2.0 / vec2(
            cascadeProjection[i][0].x,
            cascadeProjection[i][1].y);
    #endif
}
