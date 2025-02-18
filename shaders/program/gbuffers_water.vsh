#define RENDER_WATER
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec3 at_midBlock;
in vec4 at_tangent;
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

    #if defined WORLD_WATER_ENABLED && (defined WATER_TESSELLATION_ENABLED || WATER_WAVE_SIZE > 0)
        vec3 surfacePos;
    #endif

    #if defined WORLD_WATER_ENABLED && defined WATER_TESSELLATION_ENABLED
        float vertexY;
    #endif

    #if defined PARALLAX_ENABLED || defined WORLD_WATER_ENABLED
        vec3 viewPos_T;

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
            vec3 lightPos_T;
        #endif
    #endif

    #if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vOut;

uniform sampler2D lightmap;

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE //&& !defined RENDER_SHADOWS_ENABLED
    uniform sampler2D noisetex;
#endif

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform ivec2 atlasSize;
uniform float far;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;

    #ifdef WORLD_SKY_ENABLED
        uniform float rainStrength;
    #endif
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform vec3 shadowLightPosition;
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    // uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferProjection;
        uniform float near;
    #endif

    #ifdef IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE //&& !defined RENDER_SHADOWS_ENABLED
    // uniform vec3 previousCameraPosition;
    uniform mat4 gbufferPreviousModelView;
#endif

#ifdef IS_IRIS
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#ifdef EFFECT_TAA_ENABLED
    // uniform int frameCounter;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/block_static.glsl"

    #if LIGHTING_MODE != LIGHTING_MODE_NONE
        #include "/lib/buffers/light_static.glsl"
        #include "/lib/buffers/block_voxel.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/buffers/light_voxel.glsl"
    #endif
#endif

#include "/lib/blocks.glsl"

#include "/lib/sampling/atlas.glsl"
#include "/lib/sampling/noise.glsl"

#include "/lib/utility/anim.glsl"
#include "/lib/utility/lightmap.glsl"
#include "/lib/utility/tbn.glsl"

#if WORLD_WIND_STRENGTH > 0 //&& defined WORLD_SKY_ENABLED
    //#include "/lib/buffers/block_static.glsl"
    #include "/lib/world/waving.glsl"
#endif

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined DEFERRED_BUFFER_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/apply.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/apply.glsl"
    #endif
#endif

#include "/lib/lights.glsl"

#include "/lib/material/normalmap.glsl"

#ifdef WORLD_WATER_ENABLED
    #if WATER_WAVE_SIZE > 0
        #include "/lib/water/water_waves.glsl"
    #endif
#endif

#include "/lib/vertex_common.glsl"

#if (LIGHTING_MODE != LIGHTING_MODE_NONE && !defined DEFERRED_BUFFER_ENABLED) || (defined IS_LPV_ENABLED && !defined RENDER_SHADOWS_ENABLED)
    #include "/lib/voxel/voxel_common.glsl"
    #include "/lib/voxel/lights/mask.glsl"
    #include "/lib/voxel/blocks.glsl"

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/voxel/lights/light_mask.glsl"
    #endif
#endif

#if !defined DEFERRED_BUFFER_ENABLED && LIGHTING_MODE != LIGHTING_MODE_NONE //&& !defined RENDER_SHADOWS_ENABLED
    #ifdef LIGHTING_FLICKER
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    // #include "/lib/voxel/lights/mask.glsl"
    // #include "/lib/voxel/blocks.glsl"

    #ifdef IS_LPV_ENABLED
        #include "/lib/buffers/volume.glsl"
        #include "/lib/utility/hsv.glsl"
    #endif

    #if defined IS_LPV_ENABLED && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED)
        #include "/lib/voxel/lpv/lpv.glsl"
        #include "/lib/voxel/lpv/lpv_write.glsl"
        // #include "/lib/lighting/voxel/entities.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/lighting/voxel/lights.glsl"
    #endif

    #include "/lib/lighting/voxel/lights_render.glsl"
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    #if defined WORLD_WATER_ENABLED && (defined WATER_TESSELLATION_ENABLED || WATER_WAVE_SIZE > 0)
        vOut.surfacePos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
        vOut.surfacePos = mul3(gbufferModelViewInverse, vOut.surfacePos);
    #endif

    #if defined WORLD_WATER_ENABLED && defined WATER_TESSELLATION_ENABLED
        vOut.vertexY = saturate(-at_midBlock.y/64.0 + 0.5);
    #endif

    vec4 viewPos = BasicVertex();

    #if (defined WORLD_WATER_ENABLED && WATER_TESSELLATION_ENABLED) || DISPLACE_MODE == DISPLACE_TESSELATION
        gl_Position = viewPos;
        
        #if DISPLACE_MODE != DISPLACE_TESSELATION
            if (vOut.blockId != BLOCK_WATER) {
                gl_Position = gl_ProjectionMatrix * gl_Position;
        
                #ifdef EFFECT_TAA_ENABLED
                    jitter(gl_Position);
                #endif
            }
        #endif
    #else
        gl_Position = gl_ProjectionMatrix * viewPos;

        #ifdef EFFECT_TAA_ENABLED
            jitter(gl_Position);
        #endif
    #endif

    PrepareNormalMap();

    GetAtlasBounds(vOut.texcoord, vOut.atlasBounds, vOut.localCoord);

    #if defined PARALLAX_ENABLED || defined WORLD_WATER_ENABLED
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent, at_tangent.w);

        vOut.viewPos_T = viewPos.xyz * matViewTBN;

        #ifdef WORLD_SHADOW_ENABLED
            vOut.lightPos_T = shadowLightPosition * matViewTBN;
        #endif
    #endif


    #if (defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED) && !defined RENDER_SHADOWS_ENABLED
        uint blockId = vOut.blockId;
        if (blockId <= 0) blockId = BLOCK_SOLID;

        vec3 originPos = at_midBlock/64.0 + vOut.localPos;
        ivec3 voxelPos = ivec3(GetVoxelPosition(originPos));
        bool intersects = IsInVoxelBounds(voxelPos);

        if (intersects && !IsTraceEmptyBlock(blockId)) {
            imageStore(imgVoxels, voxelPos, uvec4(blockId));
        }

        #if LIGHTING_MODE == LIGHTING_MODE_TRACED
            ivec3 gridCell, blockCell;
            vec3 gridPos = GetVoxelLightPosition(originPos);
            if (GetVoxelGridCell(gridPos, gridCell, blockCell)) {
                uint lightType = StaticBlockMap[blockId].lightType;

                if (lightType > 0) {
                    if (!intersects) lightType = LIGHT_IGNORED;

                    uint gridIndex = GetVoxelGridCellIndex(gridCell);

                    if (SetVoxelLightMask(blockCell, gridIndex, lightType)) {
                        if (intersects) atomicAdd(SceneLightMaps[gridIndex].LightCount, 1u);
                        #ifdef DYN_LIGHT_DEBUG_COUNTS
                            else atomicAdd(SceneLightMaxCount, 1u);
                        #endif
                    }
                }
            }
        #endif
    #endif
}
