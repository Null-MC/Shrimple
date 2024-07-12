#define RENDER_TERRAIN
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 at_tangent;
in vec3 at_midBlock;
in vec4 mc_Entity;
in vec4 mc_midTexCoord;
in vec3 vaPosition;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat int blockId;
    flat mat2 atlasBounds;
    
    #ifdef EFFECT_TAA_ENABLED
        vec3 velocity;
    #endif

    #if DISPLACE_MODE == DISPLACE_TESSELATION
        vec3 surfacePos;
    #endif

    #ifdef PARALLAX_ENABLED
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

    // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
    //     vec3 cloudPos;
    // #endif

    // #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    //     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    //         vec3 shadowPos[4];
    //         flat int shadowTile;
    //     #else
    //         vec3 shadowPos;
    //     #endif
    // #endif
} vOut;

// uniform sampler2D lightmap;

#if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
    uniform sampler2D noisetex;
#endif

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform ivec2 atlasSize;
uniform float far;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#ifdef IS_IRIS
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform vec3 shadowLightPosition;
#endif

// #ifdef WORLD_SHADOW_ENABLED
//     uniform mat4 shadowModelView;
//     uniform mat4 shadowProjection;
//     uniform vec3 shadowLightPosition;
//     // uniform float far;

//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         uniform mat4 gbufferProjection;
//         uniform float near;
//     #endif

//     #if SHADOW_TYPE != SHADOW_TYPE_NONE && defined IS_IRIS
//         uniform float cloudTime;
//         uniform float cloudHeight;
//     #endif

//     #ifdef DISTANT_HORIZONS
//         uniform float dhFarPlane;
//     #endif
// #endif

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE //&& !defined RENDER_SHADOWS_ENABLED
    // uniform vec3 previousCameraPosition;
    // uniform mat4 gbufferPreviousModelView;
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform float frameTime;
    // uniform int frameCounter;
    // uniform vec3 previousCameraPosition;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"

    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/buffers/light_static.glsl"
    #endif

    #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
        #include "/lib/buffers/block_voxel.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/buffers/light_voxel.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"
#include "/lib/lights.glsl"

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/atlas.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"
#include "/lib/utility/tbn.glsl"

#if WORLD_WIND_STRENGTH > 0 //&& defined WORLD_SKY_ENABLED
    #include "/lib/world/waving.glsl"
#endif

// #ifdef RENDER_SHADOWS_ENABLED
//     #include "/lib/utility/matrix.glsl"
//     #include "/lib/buffers/shadow.glsl"

//     #ifdef SHADOW_CLOUD_ENABLED
//         #include "/lib/clouds/cloud_vanilla.glsl"
//     #endif
    
//     #include "/lib/shadows/common.glsl"

//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         #include "/lib/shadows/cascaded/common.glsl"
//     #else
//         #include "/lib/shadows/distorted/common.glsl"
//         #include "/lib/shadows/distorted/apply.glsl"
//     #endif
// #endif

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/block_mask.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"

    #ifdef IS_LPV_ENABLED //&& (LIGHTING_MODE == LIGHTING_MODE_FLOODFILL || LPV_SHADOW_SAMPLES > 0)
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"
    #endif

    #if defined IS_LPV_ENABLED && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED)
        #include "/lib/lpv/lpv.glsl"
        #include "/lib/lpv/lpv_write.glsl"
        // #include "/lib/lighting/voxel/entities.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/voxel/lights.glsl"
        #include "/lib/lighting/voxel/light_mask.glsl"
    #endif

    #include "/lib/lighting/voxel/lights_render.glsl"
#endif

#ifdef WORLD_WATER_ENABLED
    #ifdef PHYSICS_OCEAN
        #include "/lib/physics_mod/ocean.glsl"
    #elif WATER_WAVE_SIZE > 0
        #include "/lib/world/water_waves.glsl"
    #endif
#endif

#include "/lib/material/normalmap.glsl"
#include "/lib/vertex_common.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    #ifdef EFFECT_TAA_ENABLED
        vOut.velocity = vec3(0.0);
    #endif

    vec4 viewPos = BasicVertex();

    PrepareNormalMap();

    GetAtlasBounds(vOut.texcoord, vOut.atlasBounds, vOut.localCoord);

    #ifdef PARALLAX_ENABLED
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent, at_tangent.w);

        vOut.viewPos_T = viewPos.xyz * matViewTBN;

        #ifdef WORLD_SHADOW_ENABLED
            vOut.lightPos_T = shadowLightPosition * matViewTBN;
        #endif
    #endif

    #if DISPLACE_MODE == DISPLACE_TESSELATION
        vOut.surfacePos = viewPos.xyz;
        gl_Position = viewPos;
    #else
        gl_Position = gl_ProjectionMatrix * viewPos;

        #ifdef EFFECT_TAA_ENABLED
            jitter(gl_Position);
        #endif
    #endif

    #if (defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED) && !defined RENDER_SHADOWS_ENABLED
        uint blockId = vOut.blockId;
        if (blockId <= 0) blockId = BLOCK_SOLID;

        vec3 originPos = at_midBlock/64.0 + vOut.localPos;
        bool intersects = true;

        // #ifdef DYN_LIGHT_FRUSTUM_TEST //&& LIGHTING_MODE != LIGHTING_MODE_NONE
        //     vec3 lightViewPos = (gbufferModelView * vec4(originPos, 1.0)).xyz;

        //     const float maxLightRange = 16.0 * Lighting_RangeF + 1.0;
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

        // uint lightType = StaticBlockMap[blockId].lightType;

        ivec3 gridCell, blockCell;
        vec3 gridPos = GetVoxelBlockPosition(originPos);
        if (GetVoxelGridCell(gridPos, gridCell, blockCell)) {
            uint gridIndex = GetVoxelGridCellIndex(gridCell);

            if (intersects && !IsTraceEmptyBlock(blockId))
                SetVoxelBlockMask(blockCell, gridIndex, blockId);

            #if LIGHTING_MODE == LIGHTING_MODE_TRACED
                uint lightType = StaticBlockMap[blockId].lightType;

                if (lightType > 0) {
                    if (!intersects) lightType = LIGHT_IGNORED;

                    if (SetVoxelLightMask(blockCell, gridIndex, lightType)) {
                        if (intersects) atomicAdd(SceneLightMaps[gridIndex].LightCount, 1u);
                        #ifdef DYN_LIGHT_DEBUG_COUNTS
                            else atomicAdd(SceneLightMaxCount, 1u);
                        #endif
                    }
                }
            #endif
        }

        // #ifdef IS_LPV_ENABLED
        //     vec3 playerOffset = originPos - (eyePosition - cameraPosition);
        //     playerOffset.y += 1.0;

        //     vec3 lightColor = vec3(0.0);
        //     float lightRange = 0.0;

        //     if (lightType != LIGHT_NONE && lightType != LIGHT_IGNORED) {
        //         StaticLightData lightInfo = StaticLightMap[lightType];
        //         lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
        //         vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
        //         lightRange = lightRangeSize.x * 255.0;

        //         lightColor = RGBToLinear(lightColor);

        //         #ifdef LIGHTING_FLICKER
        //            vec2 lightNoise = GetDynLightNoise(cameraPosition + originPos);
        //            ApplyLightFlicker(lightColor, lightType, lightNoise);
        //         #endif
        //     }

        //     if (lightRange > EPSILON) {
        //         vec3 viewDir = getCameraViewDir(gbufferModelView);
        //         vec3 lpvPos = GetLpvCenter(cameraPosition, viewDir) + originPos;
        //         ivec3 imgCoordPrev = GetLPVImgCoord(lpvPos) + GetLPVFrameOffset();

        //         // if (clamp(imgCoordPrev, ivec3(0), ivec3(SceneLPVSize-1)) == imgCoordPrev) {
        //             AddLpvLight(imgCoordPrev, lightColor, lightRange);
        //         // }
        //     }
        // #endif
    #endif
}
