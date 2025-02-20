#define RENDER_BEGIN_SCENE_A
#define RENDER_BEGIN
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(1, 1, 1);

#ifdef IRIS_FEATURE_SSBO
    #ifdef WORLD_SKY_ENABLED
        uniform sampler2D texSkyIrradiance;
    #endif

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferPreviousProjection;
    uniform vec3 cameraPosition;
    uniform float near;

    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int worldTime;

    #ifdef WORLD_SKY_ENABLED
        uniform vec4 lightningBoltPosition = vec4(0.0);
        uniform vec3 shadowLightPosition;
        uniform float rainStrength;
        uniform float weatherStrength;
        uniform vec3 sunPosition;
        uniform int moonPhase;

        uniform float thunderStrength;
        uniform float frameTime;
        uniform float cloudTime;
        uniform vec3 eyePosition;

        #ifdef SKY_MORE_LIGHTNING
            uniform float cloudHeight;
            uniform int frameCounter;
        #endif

        #ifdef RENDER_SHADOWS_ENABLED
            uniform mat4 shadowModelView;
            uniform mat4 shadowProjection;
            uniform float far;
        #endif
    #endif

    #ifdef DISTANT_HORIZONS
        uniform mat4 dhProjection;
        uniform float dhFarPlane;
    #endif

    #if MC_VERSION >= 11900
        uniform float darknessFactor;
        uniform float darknessLightFactor;
    #endif

    #include "/lib/lights.glsl"
    #include "/lib/blocks.glsl"
    #include "/lib/items.glsl"

    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/light_static.glsl"

    #include "/lib/sampling/erp.glsl"

    #ifdef SKY_MORE_LIGHTNING
        #include "/lib/sampling/noise.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/buffers/light_voxel.glsl"
    #endif

    #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
        #include "/lib/buffers/block_static.glsl"

        #include "/lib/lighting/voxel/item_light_map.glsl"
        #include "/lib/lighting/voxel/items.glsl"
    #endif

    #ifdef WORLD_SKY_ENABLED
        #include "/lib/world/sky.glsl"
        #include "/lib/sky/irradiance.glsl"

        #include "/lib/clouds/cloud_common.glsl"
    #endif

    #ifdef RENDER_SHADOWS_ENABLED
        #include "/lib/utility/matrix.glsl"
        #include "/lib/shadows/common.glsl"
        #include "/lib/buffers/shadow.glsl"

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            #include "/lib/shadows/cascaded/common.glsl"
            #include "/lib/shadows/cascaded/prepare.glsl"
        #endif
    #endif
#endif


void main() {
    #ifdef IRIS_FEATURE_SSBO
        #if LIGHTING_MODE_HAND != HAND_LIGHT_NONE
            HandLightTypePrevious1 = HandLightType1;
            HandLightType1 = GetSceneItemLightType(heldItemId);

            HandLightTypePrevious2 = HandLightType2;
            HandLightType2 = GetSceneItemLightType(heldItemId2);
        #endif

        worldTimePrevious = worldTimeCurrent;
        worldTimeCurrent = worldTime;

        #ifdef WORLD_SKY_ENABLED
            localSunDirection = mat3(gbufferModelViewInverse) * normalize(sunPosition);

            // localSkyLightDirection = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
            localSkyLightDirection = GetSkyLightDirection(localSunDirection);

            WorldSunLightColor = GetSkySunColor(localSunDirection.y);
            WorldMoonLightColor = GetSkyMoonColor(-localSunDirection.y);
            WorldSkyLightColor = CalculateSkyLightColor(localSunDirection.y);
            //WeatherSkyLightColor = CalculateSkyLightWeatherColor(WorldSkyLightColor);

            // TODO: currently using previous-frame data, needs to be moved
            WorldSkyAmbientColor = SampleSkyIrradiance(vec3(0.0, 1.0, 0.0));

            if (lightningBoltPosition.w > 0.5) {
                lightningPosition.xyz = lightningBoltPosition.xyz + cameraPosition;
                lightningPosition.w = 1.0;
            }

            #ifdef SKY_MORE_LIGHTNING
                if (thunderStrength > 0.5 && lightningPosition.w < EPSILON) {
                    vec3 random = hash31(frameCounter);

                    if (random.z < 0.02) {
                        float angle = random.x * TAU;
                        float dist = random.y * 2000.0 + 200.0;

                        float cloudAlt = GetCloudAltitude();

                        lightningPosition.y = cloudAlt - 80.0;
                        lightningPosition.xz = vec2(cos(angle), sin(angle)) * dist;
                        lightningPosition.xz += cameraPosition.xz;
                        lightningPosition.w = 1.0;
                    }
                }
            #endif

            lightningPosition.w = max(lightningPosition.w - lightningSpeed*frameTime, 0.0);
        #else
            WorldSunLightColor = vec3(0.0);
            WorldMoonLightColor = vec3(0.0);
            WorldSkyLightColor = vec3(0.0);
        #endif

        //gbufferModelViewProjection = gbufferModelView * gbufferProjection;
        gbufferModelViewProjectionInverse = gbufferModelViewInverse * gbufferProjectionInverse;
        gbufferPreviousModelViewProjection = gbufferPreviousProjection * gbufferPreviousModelView;
        //gbufferPreviousModelViewProjectionInverse = inverse(gbufferPreviousModelViewProjection);

        #if (defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED) //|| defined LIGHT_COLOR_ENABLED
            shadowModelViewEx = BuildShadowViewMatrix(localSkyLightDirection);

            #if SHADOW_TYPE != SHADOW_TYPE_CASCADED
                float _far = (3.0 * far);
                #ifdef DISTANT_HORIZONS
                    _far = 2.0 * dhFarPlane;
                #endif

                shadowProjectionEx = shadowProjection;
                shadowProjectionEx[2][2] = -2.0 / _far;
                shadowProjectionEx[3][2] = 0.0;

                shadowModelViewProjection = shadowProjectionEx * shadowModelViewEx;
            #endif
        #endif

        #if LIGHTING_MODE != LIGHTING_MODE_NONE
            #if LIGHTING_MODE == LIGHTING_MODE_TRACED
                SceneLightCount = 0u;
                SceneLightMaxCount = 0u;
            #endif

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

        #ifdef DISTANT_HORIZONS
            dhProjectionFullPrev = dhProjectionFull;
            dhProjectionFull = dhProjection;

            dhProjectionFull[2][2] = -((near + dhFarPlane) / (dhFarPlane - near));
            dhProjectionFull[3][2] = -((2.0 * dhFarPlane * near) / (dhFarPlane - near));

            dhProjectionFullInv = inverse(dhProjectionFull);
        #endif
    #endif
}
