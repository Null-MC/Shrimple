#define RENDER_SHADOW
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 mc_Entity;
in vec3 vaPosition;
in vec3 at_midBlock;

out vec4 vColor;
out vec2 vTexcoord;
flat out int vBlockId;
flat out vec3 vOriginPos;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform int renderStage;
uniform float far;

uniform int blockEntityId;
uniform vec4 entityColor;
uniform int entityId;

#if DYN_LIGHT_MODE == DYN_LIGHT_PIXEL && LPV_SIZE > 0
    uniform int frameCounter;
#endif

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferProjection;
    uniform float near;
#endif

#include "/lib/blocks.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/shadow.glsl"
#endif

#ifdef WORLD_WAVING_ENABLED
    #include "/lib/sampling/noise.glsl"
    #include "/lib/world/waving.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/lights.glsl"
    #include "/lib/entities.glsl"
    #include "/lib/items.glsl"

    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"

    // #if DYN_LIGHT_MODE != DYN_LIGHT_TRACED && LPV_SIZE > 0
    //     #include "/lib/buffers/volume.glsl"
    //     #include "/lib/lighting/voxel/lpv.glsl"
    // #endif
#endif


// #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_PIXEL && LPV_SIZE > 0
//     void AddLpvLight(const in vec3 lpvPos, const in vec3 lightColor, const in float lightRange) {
//         ivec3 lpvCoord = GetLPVImgCoord(lpvPos);
//         vec3 lightFinal = LpvRangeF * lightColor * lightRange;// * VolumetricBlockRangeF;
//         imageStore((frameCounter % 2) == 0 ? imgSceneLPV_2 : imgSceneLPV_1, lpvCoord, vec4(lightFinal, 1.0));
//     }
// #endif

void main() {
    vTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;

    bool isRenderTerrain = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
                        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
                        || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
                        || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;

    int blockId = int(mc_Entity.x + 0.5);
    if (blockId <= 0) blockId = BLOCK_SOLID;

    if (renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES) {
        blockId = blockEntityId;

        if (blockId == 0xFFFF)
            blockId = BLOCK_EMPTY;
    }

    vOriginPos = gl_Vertex.xyz;
    if ((blockId < BLOCK_LIGHT_1 || blockId > BLOCK_LIGHT_15) && isRenderTerrain) {
        vOriginPos += at_midBlock / 64.0;
    }

    vOriginPos = (gl_ModelViewMatrix * vec4(vOriginPos, 1.0)).xyz;

    if (!isRenderTerrain) {
        vec3 geoNormal = normalize(gl_NormalMatrix * gl_Normal);
        vOriginPos -= 0.05 * geoNormal;
    }

    #ifdef SHADOW_FRUSTUM_CULL
        if (isRenderTerrain && vBlockId > 0) {
            if (clamp(vOriginPos.xy, shadowViewBoundsMin, shadowViewBoundsMax) != vOriginPos.xy) {
                gl_Position = vec4(-1.0);
                return;
            }
        }
    #endif

    vOriginPos = (shadowModelViewInverse * vec4(vOriginPos, 1.0)).xyz;

    int vertexId = gl_VertexID;
    if (renderStage == MC_RENDER_STAGE_ENTITIES)
        blockId = BLOCK_EMPTY;

    vBlockId = blockId;

    vec4 pos = gl_Vertex;

    #ifdef WORLD_WAVING_ENABLED
        ApplyWavingOffset(pos.xyz, blockId);
    #endif

    gl_Position = gl_ModelViewMatrix * pos;

    gl_Position = shadowModelViewInverse * gl_Position;
    gl_Position = shadowModelViewEx * gl_Position;

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        bool intersects = true;

        if (blockId > 0 && isRenderTerrain) {
            vec3 cf = fract(cameraPosition);
            vec3 lightGridOrigin = floor(vOriginPos + cf) - cf + 0.5;

            ivec3 gridCell, blockCell;
            vec3 gridPos = GetLightGridPosition(lightGridOrigin);
            if (GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
                uint gridIndex = GetSceneLightGridIndex(gridCell);
                uint lightType = GetSceneLightType(blockId);

                #ifdef DYN_LIGHT_FRUSTUM_TEST
                    vec3 lightViewPos = (gbufferModelView * vec4(vOriginPos, 1.0)).xyz;

                    const float maxLightRange = 16.0 * DynamicLightRangeF + 1.0;
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

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                    if (lightType > 0) {
                        if (!intersects) lightType = LIGHT_IGNORED;

                        if (SetSceneLightMask(blockCell, gridIndex, lightType)) {
                            #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
                                if (intersects) atomicAdd(SceneLightMaps[gridIndex].LightCount, 1u);
                                #ifdef DYN_LIGHT_DEBUG_COUNTS
                                    else atomicAdd(SceneLightMaxCount, 1u);
                                #endif
                            #endif
                        }
                    }
                #endif

                #if LPV_SIZE > 0 && LPV_SUN_SAMPLES > 0
                    if (!IsTraceEmptyBlock(blockId))
                        SetSceneBlockMask(blockCell, gridIndex, blockId);
                #else
                    if (intersects && !IsTraceEmptyBlock(blockId))
                        SetSceneBlockMask(blockCell, gridIndex, blockId);
                #endif
            }
        }
        //else if (renderStage == MC_RENDER_STAGE_ENTITIES) {
            //if (entityId == ENTITY_LIGHTNING_BOLT) return;

            // #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
            //     if (entityId == ENTITY_PLAYER) {
            //         if (vertexId % 600 == 300) {
            //             HandLightPos1 = (shadowModelViewInverse * gl_Position).xyz;
            //         }

            //         if (vertexId == 5) {
            //             HandLightPos2 = (shadowModelViewInverse * gl_Position).xyz;
            //         }
            //     }
            // #endif
        //}

        // if (!intersects) {
        //     gl_Position = vec4(-1.0);
        //     return;
        // }
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        if (isRenderTerrain) {
            if (blockId == BLOCK_FIRE || blockId == BLOCK_SOUL_FIRE) gl_Position = vec4(-1.0);
        }
    #else
        gl_Position = vec4(-1.0);
    #endif
}
