#define RENDER_BEGIN_CSM
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(4, 1, 1);

#ifdef IRIS_FEATURE_SSBO
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferPreviousProjection;

    uniform int heldItemId;
    uniform int heldItemId2;

    #ifdef WORLD_SKY_ENABLED
        uniform vec3 shadowLightPosition;
        uniform float rainStrength;
        uniform vec3 sunPosition;

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
            uniform mat4 shadowModelView;
            uniform vec3 cameraPosition;
            uniform float far;
        #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
            uniform mat4 shadowProjection;
        #endif

        #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
            uniform mat4 gbufferModelView;
            uniform mat4 gbufferProjection;
            uniform float near;
            //uniform float far;
        #endif
    #endif

    #include "/lib/lights.glsl"
    #include "/lib/blocks.glsl"
    #include "/lib/items.glsl"

    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/voxel/block_light_map.glsl"
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/items.glsl"

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/utility/matrix.glsl"
        #include "/lib/shadows/common.glsl"
        #include "/lib/buffers/shadow.glsl"

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #include "/lib/shadows/cascaded/common.glsl"
        #endif
    #endif
#endif


void main() {
    int i = int(gl_GlobalInvocationID.x);

    #ifdef IRIS_FEATURE_SSBO
        if (i == 0) {
            HandLightTypePrevious1 = HandLightType1;
            HandLightType1 = GetSceneItemLightType(heldItemId);
        }
        else if (i == 1) {
            HandLightTypePrevious2 = HandLightType2;
            HandLightType2 = GetSceneItemLightType(heldItemId2);
        }

        if (i == 0) {
            #ifdef WORLD_SKY_ENABLED
                localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);
                localSkyLightDirection = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

                WorldSunLightColor = GetSkySunColor(localSunDirection.y);
                WorldMoonLightColor = GetSkyMoonColor(-localSunDirection.y);
                WorldSkyLightColor = CalculateSkyLightColor(localSunDirection);
                //WeatherSkyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);
            #else
                WorldSunLightColor = vec3(0.0);
                WorldMoonLightColor = vec3(0.0);
                WorldSkyLightColor = vec3(0.0);
            #endif

            gbufferModelViewProjectionInverse = gbufferModelViewInverse * gbufferProjectionInverse;
            gbufferPreviousModelViewProjection = gbufferPreviousProjection * gbufferPreviousModelView;

            #if (defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE) //|| defined LIGHT_COLOR_ENABLED
                shadowModelViewEx = shadowModelView;//BuildShadowViewMatrix(localSkyLightDirection);

                //mat4 matTranslate = mat4(1.0);
                //matTranslate[2][3] = -1.0;

                //shadowModelViewEx = matTranslate * shadowModelViewEx;

                #if SHADOW_TYPE != SHADOW_TYPE_CASCADED
                    shadowProjectionEx = shadowProjection;//BuildShadowProjectionMatrix();
                    //shadowProjectionEx[0][0] = 2.0 / min(shadowDistance, far);
                    //shadowProjectionEx[1][1] = 2.0 / min(shadowDistance, far);
                    shadowProjectionEx[2][2] = -2.0 / (3.0 * far);
                    shadowProjectionEx[3][2] = 0.0;

                    shadowModelViewProjection = shadowProjectionEx * shadowModelViewEx;
                #endif
            #endif

            #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
                SceneLightCount = 0u;
                SceneLightMaxCount = 0u;

                HandLightPos1 = vec3(0.0);
                HandLightPos2 = vec3(0.0);

                #ifdef DYN_LIGHT_FRUSTUM_TEST
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
            #endif
        }

        #ifdef WORLD_SHADOW_ENABLED
            memoryBarrierBuffer();

            #if SHADOW_TYPE == SHADOW_TYPE_DISTORTED && DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined DYN_LIGHT_FRUSTUM_TEST
                if (i == 0) {
                    vec3 clipMin, clipMax;
                    mat4 matSceneToShadow = shadowModelViewEx * gbufferModelViewProjectionInverse;
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
