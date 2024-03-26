#define RENDER_ENTITIES
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 at_tangent;
in vec4 mc_midTexCoord;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat mat2 atlasBounds;

    #if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

    // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
    //     vec3 cloudPos;
    // #endif

    #if defined RENDER_SHADOWS_ENABLED && defined RENDER_TRANSLUCENT
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vOut;

uniform sampler2D lightmap;

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE && !defined RENDER_SHADOWS_ENABLED
    uniform sampler2D noisetex;
#endif

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform ivec2 atlasSize;

uniform int entityId;
uniform vec4 entityColor;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 shadowLightPosition;
    uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        attribute vec3 at_midBlock;

        uniform mat4 gbufferProjection;
        uniform float near;
    #endif

    #if defined SHADOW_ENABLED && defined IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE && !defined RENDER_SHADOWS_ENABLED
    uniform vec3 previousCameraPosition;
    uniform int currentRenderedItemId;
    uniform mat4 gbufferPreviousModelView;
#endif

#ifdef IS_IRIS
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform vec2 pixelSize;
    // uniform int frameCounter;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"

    #if defined IS_LPV_ENABLED || defined IS_TRACING_ENABLED
        #include "/lib/buffers/light_static.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/entities.glsl"
#include "/lib/items.glsl"

#include "/lib/sampling/atlas.glsl"

#include "/lib/utility/lightmap.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE || defined PARALLAX_ENABLED
    #include "/lib/utility/tbn.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef RENDER_SHADOWS_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/apply.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/apply.glsl"
    #endif
//#elif LIGHTING_MODE != LIGHTING_MODE_NONE && LPV_SIZE > 0
#elif defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
    #include "/lib/buffers/block_static.glsl"

    #if LPV_SIZE > 0
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"
    #endif

    #ifdef LIGHTING_FLICKER
        #include "/lib/utility/anim.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #include "/lib/lights.glsl"
    #include "/lib/lighting/voxel/lights_render.glsl"

    //#include "/lib/lighting/voxel/mask.glsl"
    //#include "/lib/lighting/voxel/block_mask.glsl"
    //#include "/lib/lighting/voxel/blocks.glsl"

    #if defined IS_LPV_ENABLED && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED)
        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_write.glsl"
    #endif

    #include "/lib/lighting/voxel/entities.glsl"
    #include "/lib/lighting/voxel/item_light_map.glsl"
    #include "/lib/lighting/voxel/items.glsl"

    // #if LIGHTING_MODE == LIGHTING_MODE_TRACED
    //     #include "/lib/lighting/voxel/lights.glsl"
    //     #include "/lib/lighting/voxel/light_mask.glsl"
    // #endif
#endif

// #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE
//     #include "/lib/entities.glsl"

//     #include "/lib/lighting/voxel/entities.glsl"
// #endif

#include "/lib/material/normalmap.glsl"
#include "/lib/lighting/common.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    #ifdef DEFERRED_BUFFER_ENABLED
        if (entityId == ENTITY_SHADOW) {
            gl_Position = vec4(-1.0);
            return;
        }
    #endif

    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);
    
    vec4 viewPos = BasicVertex();
    gl_Position = gl_ProjectionMatrix * viewPos;

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif

    PrepareNormalMap();

    GetAtlasBounds(vOut.texcoord, vOut.atlasBounds, vOut.localCoord);

    #if defined PARALLAX_ENABLED && defined MATERIAL_DISPLACE_ENTITIES
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent, at_tangent.w);

        //viewPos = (gbufferModelView * vec4(vOut.localPos, 1.0)).xyz;
        vOut.viewPos_T = viewPos.xyz * matViewTBN;

        #ifdef WORLD_SHADOW_ENABLED
            vOut.lightPos_T = shadowLightPosition * matViewTBN;
        #endif
    #endif


    // #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE && LPV_SIZE > 0 && !defined RENDER_SHADOWS_ENABLED
    #if (defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED) && !defined RENDER_SHADOWS_ENABLED
        if (entityId > 0 || currentRenderedItemId > 0) {
            vec3 originPos = vOut.localPos; // TODO: offset by normal?
            bool intersects = true;

            // #ifdef DYN_LIGHT_FRUSTUM_TEST //&& LIGHTING_MODE != LIGHTING_MODE_NONE
            //     vec3 lightViewPos = (gbufferModelView * vec4(originPos, 1.0)).xyz;

            //     const float maxLightRange = 16.0 * DynamicLightRangeF + 1.0;
            //     //float maxRange = maxLightRange > EPSILON ? maxLightRange : 16.0;
            //     if (lightViewPos.z > maxLightRange) intersects = false;
            //     else if (lightViewPos.z < -(far + maxLightRange)) intersects = false;
            //     else {
            //         if (dot(sceneViewUp,   lightViewPos) > maxLightRange) intersects = false;
            //         if (dot(sceneViewDown, lightViewPos) > maxLightRange) intersects = false;
            //         if (dot(sceneViewLeft,  lightViewPos) > maxLightRange) intersects = false;
            //         if (dot(sceneViewRight, lightViewPos) > maxLightRange) intersects = false;
            //     }
            // #endif

            uint lightType = LIGHT_NONE;
            vec3 lightColor = vec3(0.0);
            float lightRange = 0.0;

            vec3 playerOffset = originPos - (eyePosition - cameraPosition);
            playerOffset.y += 1.0;

            if (entityId != ENTITY_ITEM_FRAME && entityId != ENTITY_PLAYER) {
                uint itemLightType = GetSceneItemLightType(currentRenderedItemId);
                if (itemLightType > 0) lightType = itemLightType;

                if (entityId == ENTITY_SPECTRAL_ARROW)
                    lightType = LIGHT_TORCH_FLOOR;
                else if (entityId == ENTITY_TORCH_ARROW)
                    lightType = LIGHT_TORCH_FLOOR;
            }

            vec4 entityLightColorRange = GetSceneEntityLightColor(entityId);

            if (entityLightColorRange.a > EPSILON) {
                lightColor = entityLightColorRange.rgb;
                lightRange = entityLightColorRange.a;
            }

            if (lightType != LIGHT_NONE && lightType != LIGHT_IGNORED) {
                StaticLightData lightInfo = StaticLightMap[lightType];
                lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
                lightColor = RGBToLinear(lightColor);

                vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
                lightRange = lightRangeSize.x * 255.0;

                #ifdef LIGHTING_FLICKER
                   vec2 lightNoise = GetDynLightNoise(cameraPosition + originPos);
                   ApplyLightFlicker(lightColor, lightType, lightNoise);
                #endif
            }

            if (lightRange > EPSILON) {
                vec3 viewDir = getCameraViewDir(gbufferModelView);
                vec3 lpvPos = GetLpvCenter(cameraPosition, viewDir) + originPos;
                ivec3 imgCoordPrev = GetLPVImgCoord(lpvPos) + GetLPVFrameOffset();

                AddLpvLight(imgCoordPrev, lightColor, lightRange);
            }
        }
    #endif
}
