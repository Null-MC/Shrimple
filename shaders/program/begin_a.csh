#define RENDER_BEGIN_CSM
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(4, 1, 1);

#ifdef IRIS_FEATURE_SSBO
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferProjectionInverse;

    #ifdef WORLD_SKY_ENABLED
        uniform vec3 sunPosition;
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        uniform mat4 shadowModelView;
        //uniform mat4 gbufferModelViewInverse;
    #endif

    //#if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    //    uniform mat4 gbufferProjectionInverse;
    //#endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferProjection;
        uniform float near;
        uniform float far;
    #endif

    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"

    // #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
    //     #include "/lib/buffers/lighting.glsl"
    // #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/common.glsl"
        #include "/lib/buffers/shadow.glsl"

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #include "/lib/utility/matrix.glsl"
            #include "/lib/shadows/cascaded.glsl"
        #endif
    #endif
#endif


void main() {
    int i = int(gl_GlobalInvocationID.x);

    #ifdef IRIS_FEATURE_SSBO
        if (i == 0) {
            localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);

            gbufferModelViewProjectionInverse = gbufferModelViewInverse * gbufferProjectionInverse;

            #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
                SceneLightCount = 0u;
                SceneLightMaxCount = 0u;

                HandLightPos1 = vec3(0.0);
                HandLightPos2 = vec3(0.0);

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
        }

        #ifdef WORLD_SHADOW_ENABLED
            #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED && DYN_LIGHT_MODE != DYN_LIGHT_NONE
                if (i == 0) {
                    vec3 clipMin, clipMax;
                    mat4 matSceneToShadow = shadowModelView * (gbufferModelViewInverse * gbufferProjectionInverse);
                    GetFrustumMinMax(matSceneToShadow, clipMin, clipMax);

                    shadowViewBoundsMin = max(clipMin.xy - 3.0, vec2(-shadowDistance));
                    shadowViewBoundsMax = min(clipMax.xy + 3.0, vec2( shadowDistance));
                }
            #endif

            #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
                float cascadeSizes[4];
                cascadeSizes[0] = GetCascadeDistance(0);
                cascadeSizes[1] = GetCascadeDistance(1);
                cascadeSizes[2] = GetCascadeDistance(2);
                cascadeSizes[3] = GetCascadeDistance(3);

                cascadeSize[i] = cascadeSizes[i];
                shadowProjectionPos[i] = GetShadowTilePos(i);
                cascadeProjection[i] = GetShadowTileProjectionMatrix(cascadeSizes, i, cascadeViewMin[i], cascadeViewMax[i]);

                shadowProjectionSize[i] = 2.0 / vec2(
                    cascadeProjection[i][0].x,
                    cascadeProjection[i][1].y);
            #endif
        #endif
    #endif
}
