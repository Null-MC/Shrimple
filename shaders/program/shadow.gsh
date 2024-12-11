#define RENDER_SHADOW
#define RENDER_GEOMETRY

layout(triangles) in;
layout(triangle_strip, max_vertices=12) out;

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    float viewDist;

    flat int blockId;
    flat vec3 originPos;
} vIn[];

out VertexData {
    vec4 color;
    vec2 texcoord;
    float viewDist;

    flat uint blockId;

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        flat vec2 shadowTilePos;
    #endif
} vOut;

#if defined LIGHTING_FLICKER && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED)
    uniform sampler2D noisetex;
#endif

uniform int renderStage;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
//uniform vec3 previousCameraPosition;
uniform float far;

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform float near;

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

#if LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED
    uniform int entityId;
    uniform int frameCounter;
    uniform vec3 eyePosition;
    uniform vec3 relativeEyePosition;
    uniform mat4 gbufferModelViewInverse;
    uniform vec3 previousCameraPosition;
    uniform mat4 gbufferPreviousModelView;
    uniform int currentRenderedItemId;
    uniform vec4 entityColor;

    #ifdef ANIM_WORLD_TIME
        uniform int worldTime;
    #else
        uniform float frameTimeCounter;
    #endif
#endif

#include "/lib/blocks.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    
    #if defined IS_LPV_ENABLED || defined IS_TRACING_ENABLED
        #include "/lib/buffers/block_static.glsl"
        #include "/lib/buffers/block_voxel.glsl"
        #include "/lib/buffers/light_static.glsl"
    #endif
    
    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/buffers/light_voxel.glsl"
    #endif

    #ifdef IS_LPV_ENABLED
        #include "/lib/buffers/volume.glsl"
    #endif

    #if defined IS_LPV_ENABLED || defined IS_TRACING_ENABLED
        #include "/lib/entities.glsl"
        #include "/lib/items.glsl"
        #include "/lib/lights.glsl"

        #include "/lib/sampling/noise.glsl"

        #ifdef LIGHTING_FLICKER
            #include "/lib/utility/anim.glsl"
            #include "/lib/lighting/blackbody.glsl"
            #include "/lib/lighting/flicker.glsl"
        #endif
        
        #include "/lib/voxel/lights/mask.glsl"
        #include "/lib/lighting/voxel/lights.glsl"
        #include "/lib/lighting/voxel/lights_render.glsl"
        #include "/lib/voxel/blocks.glsl"

        #include "/lib/voxel/voxel_common.glsl"

        #include "/lib/lighting/voxel/item_light_map.glsl"
        #include "/lib/lighting/voxel/items.glsl"
    #endif

    #if defined IS_LPV_ENABLED && (LIGHTING_MODE != LIGHTING_MODE_NONE || defined IS_LPV_SKYLIGHT_ENABLED)
        #include "/lib/utility/hsv.glsl"
        #include "/lib/voxel/lpv/lpv.glsl"
        #include "/lib/voxel/lpv/lpv_write.glsl"
        #include "/lib/lighting/voxel/entities.glsl"
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_TRACED
        #include "/lib/voxel/lights/light_mask.glsl"
    #endif
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/buffers/shadow.glsl"
    #endif

    #include "/lib/utility/matrix.glsl"
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
    #endif
#endif


#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
    // returns: tile [0-3] or -1 if excluded
    int GetShadowRenderTile(const in vec3 blockPos) {
        const int max = 4;

        for (int i = 0; i < max; i++) {
            if (CascadeContainsPosition(blockPos, i, 3.0)) return i;
        }

        return -1;
    }
#endif

void main() {
    vec3 originPos = (vIn[0].originPos + vIn[1].originPos + vIn[2].originPos) * rcp(3.0);

    bool isRenderTerrain = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
                        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
                        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
                        || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;

    #if defined IS_LPV_ENABLED || defined IS_TRACING_ENABLED

        bool isRenderEntity = renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES
                           || renderStage == MC_RENDER_STAGE_ENTITIES;

        if ((vIn[0].blockId > 0 || currentRenderedItemId > 0 || entityId > 0) && (isRenderTerrain || isRenderEntity)) {
            // #ifdef SHADOW_FRUSTUM_CULL
            //     if (vBlockId[0] > 0) {
            //         vec2 lightViewPos = (shadowModelViewEx * vec4(originPos, 1.0)).xy;

            //         if (clamp(lightViewPos, shadowViewBoundsMin, shadowViewBoundsMax) != lightViewPos) return;
            //     }
            // #endif

            ivec3 voxelPos = ivec3(GetVoxelPosition(originPos));
            bool intersects = IsInVoxelBounds(voxelPos);

            #ifdef DYN_LIGHT_FRUSTUM_TEST //&& LIGHTING_MODE != LIGHTING_MODE_NONE
                vec3 lightViewPos = mul3(gbufferModelView, originPos);

                const float maxLightRange = 16.0 * Lighting_RangeF + 1.0;
                //float maxRange = maxLightRange > EPSILON ? maxLightRange : 16.0;
                if (lightViewPos.z > maxLightRange) intersects = false;
                else if (lightViewPos.z < -(far + maxLightRange)) intersects = false;
                else {
                    if (dot(sceneViewUp,   lightViewPos) > maxLightRange) intersects = false;
                    if (dot(sceneViewDown, lightViewPos) > maxLightRange) intersects = false;
                    if (dot(sceneViewLeft,  lightViewPos) > maxLightRange) intersects = false;
                    if (dot(sceneViewRight, lightViewPos) > maxLightRange) intersects = false;
                }
            #endif

            if (intersects && !IsTraceEmptyBlock(vIn[0].blockId)) {
                imageStore(imgVoxels, voxelPos, uvec4(vIn[0].blockId));
            }

            #if LIGHTING_MODE == LIGHTING_MODE_TRACED
                vec3 cameraOffset = fract(cameraPosition);
                vec3 lightGridOrigin = floor(originPos + cameraOffset) - cameraOffset + 0.5;

                ivec3 gridCell, blockCell;
                vec3 gridPos = GetVoxelLightPosition(lightGridOrigin);
                if (GetVoxelGridCell(gridPos, gridCell, blockCell)) {
                    uint lightType = StaticBlockMap[vIn[0].blockId].lightType;

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

            #ifdef IS_LPV_ENABLED //&& (LIGHTING_MODE == LIGHTING_MODE_FLOODFILL || LPV_SHADOW_SAMPLES > 0)
                #if defined IRIS_VERSION && IRIS_VERSION >= 10800
                    bool isThisPlayer = entityId == ENTITY_PLAYER_CURRENT;
                #else
                    float dist = length(originPos + relativeEyePosition);
                    bool isThisPlayer = entityId == ENTITY_PLAYER && dist < 3.0;
                #endif

                if (renderStage == MC_RENDER_STAGE_ENTITIES && entityId != ENTITY_ITEM_FRAME) {
                    uint lightType = GetSceneItemLightType(currentRenderedItemId);

                    vec3 lightColor = vec3(0.0);
                    float lightRange = 0.0;

                    // WARN: MAKE THESE WORK AGAIN!!!!
                    if (entityId == ENTITY_SPECTRAL_ARROW)
                        lightType = LIGHT_TORCH_FLOOR;
                    else if (entityId == ENTITY_TORCH_ARROW)
                        lightType = LIGHT_TORCH_FLOOR;

                    //if (itemLightType > 0) lightType = itemLightType;

                    if (lightType != LIGHT_NONE && lightType != LIGHT_IGNORED) {
                        StaticLightData lightInfo = StaticLightMap[lightType];
                        lightColor = unpackUnorm4x8(lightInfo.Color).rgb;
                        vec2 lightRangeSize = unpackUnorm4x8(lightInfo.RangeSize).xy;
                        lightRange = lightRangeSize.x * 255.0;

                        lightColor = RGBToLinear(lightColor);

                        vec3 worldPos = cameraPosition + originPos;
                        ApplyLightAnimation(lightColor, lightRange, lightType, worldPos);

                        #ifdef LIGHTING_FLICKER
                           vec2 lightNoise = GetDynLightNoise(worldPos);
                           ApplyLightFlicker(lightColor, lightType, lightNoise);
                        #endif
                    }

                    vec4 entityLightColorRange = GetSceneEntityLightColor(entityId);

                    if (entityLightColorRange.a > EPSILON) {
                        lightColor = entityLightColorRange.rgb;
                        lightRange = entityLightColorRange.a;
                    }

                    if (isThisPlayer) {
                        lightRange *= 0.4;
                    }

                    if (lightRange > EPSILON) {
                        vec3 lpvPos = GetVoxelPosition(originPos);
                        ivec3 imgCoordPrev = ivec3(lpvPos) + GetVoxelFrameOffset();

                        AddLpvLight(imgCoordPrev, lightColor, lightRange);
                    }
                }
            #endif
        }
    #endif

    #ifdef RENDER_SHADOWS_ENABLED
        if (isRenderTerrain) {
            // TODO: use emission as inv of alpha instead?
            if (vIn[0].blockId == BLOCK_FIRE || vIn[0].blockId == BLOCK_SOUL_FIRE) return;
        }

        //vec3 originShadowViewPos = (shadowModelViewEx * vec4(vOriginPos[0], 1.0)).xyz;

        // #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != LIGHTING_MODE_NONE && SHADOW_TYPE == SHADOW_TYPE_DISTORTED
        //     if (!all(greaterThan(originShadowViewPos.xy, shadowViewBoundsMin))
        //      || !all(lessThan(originShadowViewPos.xy, shadowViewBoundsMax))) return;
        // #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 originShadowViewPos = mul3(shadowModelViewEx, originPos);

            int shadowTile = GetShadowRenderTile(originShadowViewPos);
            if (shadowTile < 0) return;

            #ifdef SHADOW_CSM_OVERLAP
                int cascadeMin = max(shadowTile - 1, 0);
                int cascadeMax = min(shadowTile + 1, 3);
            #else
                int cascadeMin = shadowTile;
                int cascadeMax = shadowTile;
            #endif

            for (int c = cascadeMin; c <= cascadeMax; c++) {
                if (c != shadowTile) {
                    #ifdef SHADOW_CSM_OVERLAP
                        // duplicate geometry if intersecting overlapping cascades
                        if (!CascadeContainsPosition(originShadowViewPos, c, 9.0)) continue;
                    #else
                        continue;
                    #endif
                }

                vec2 shadowTilePos = shadowProjectionPos[c];

                for (int v = 0; v < 3; v++) {
                    vOut.shadowTilePos = shadowTilePos;

                    vOut.color = vIn[v].color;
                    vOut.texcoord = vIn[v].texcoord;
                    vOut.viewDist = vIn[v].viewDist;
                    vOut.blockId = vIn[v].blockId;

                    gl_Position.xyz = mul3(cascadeProjection[c], gl_in[v].gl_Position.xyz);
                    gl_Position.w = 1.0;

                    gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
                    gl_Position.xy = gl_Position.xy * 0.5 + shadowTilePos;
                    gl_Position.xy = gl_Position.xy * 2.0 - 1.0;

                    EmitVertex();
                }

                EndPrimitive();
            }
        #else
            for (int v = 0; v < 3; v++) {
                vOut.color = vIn[v].color;
                vOut.texcoord = vIn[v].texcoord;
                vOut.viewDist = vIn[v].viewDist;
                vOut.blockId = vIn[v].blockId;

                #ifdef IRIS_FEATURE_SSBO
                    gl_Position.xyz = mul3(shadowProjectionEx, gl_in[v].gl_Position.xyz);
                #else
                    gl_Position.xyz = mul3(gl_ProjectionMatrix, gl_in[v].gl_Position.xyz);
                #endif

                gl_Position.xyz = distort(gl_Position.xyz);
                gl_Position.w = 1.0;

                EmitVertex();
            }

            EndPrimitive();
        #endif
    #endif
}
