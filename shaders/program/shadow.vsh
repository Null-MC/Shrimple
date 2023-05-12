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

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferProjection;
    uniform float near;
#endif

#include "/lib/blocks.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#ifdef WORLD_WAVING_ENABLED
    #include "/lib/sampling/noise.glsl"
    #include "/lib/world/waving.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/entities.glsl"
    #include "/lib/items.glsl"

    #include "/lib/buffers/lighting.glsl"
    #include "/lib/lighting/voxel/mask.glsl"
    #include "/lib/lighting/voxel/lights.glsl"
    #include "/lib/lighting/voxel/blocks.glsl"
#endif


void main() {
    vTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;

    int blockId = int(mc_Entity.x + 0.5);
    if (blockId <= 0) blockId = BLOCK_SOLID;

    if (renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES) {
        blockId = blockEntityId;

        if (blockId == 0xFFFF)
            blockId = BLOCK_EMPTY;
    }

    vOriginPos = gl_Vertex.xyz;
    if ((blockId < BLOCK_LIGHT_1 || blockId > BLOCK_LIGHT_15) && renderStage != MC_RENDER_STAGE_BLOCK_ENTITIES) {
        vOriginPos += at_midBlock / 64.0;
    }

    vOriginPos = (gl_ModelViewMatrix * vec4(vOriginPos, 1.0)).xyz;

    if (renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES) {
        vec3 geoNormal = normalize(gl_NormalMatrix * gl_Normal);
        vOriginPos -= 0.05 * geoNormal;
    }

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
        if (blockId > 0 && (
            renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
         || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
         || renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
         || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT)) {
            vec3 cf = fract(cameraPosition);
            vec3 lightGridOrigin = floor(vOriginPos + cf) - cf + 0.5;

            ivec3 gridCell, blockCell;
            vec3 gridPos = GetLightGridPosition(lightGridOrigin);
            if (GetSceneLightGridCell(gridPos, gridCell, blockCell)) {
                uint gridIndex = GetSceneLightGridIndex(gridCell);
                uint lightType = GetSceneLightType(blockId);

                bool intersects = true;
                #ifdef DYN_LIGHT_FRUSTUM_TEST
                    vec3 lightViewPos = (gbufferModelView * vec4(vOriginPos, 1.0)).xyz;

                    const float lightRange = 16.0 * DynamicLightRangeF + 1.0;//lightRange + 1.0;
                    //float maxRange = lightRange > EPSILON ? lightRange : 16.0;
                    if (lightViewPos.z > lightRange) intersects = false;
                    else if (lightViewPos.z < -(far + lightRange)) intersects = false;
                    else {
                        if (dot(sceneViewUp,   lightViewPos) > lightRange) intersects = false;
                        if (dot(sceneViewDown, lightViewPos) > lightRange) intersects = false;
                        if (dot(sceneViewLeft,  lightViewPos) > lightRange) intersects = false;
                        if (dot(sceneViewRight, lightViewPos) > lightRange) intersects = false;
                    }
                #endif

                if (lightType > 0) {
                    if (!intersects) lightType = LIGHT_IGNORED;

                    if (SetSceneLightMask(blockCell, gridIndex, lightType)) {
                        if (intersects) atomicAdd(SceneLightMaps[gridIndex].LightCount, 1u);
                        #ifdef DYN_LIGHT_DEBUG_COUNTS
                            else atomicAdd(SceneLightMaxCount, 1u);
                        #endif
                    }
                }

                #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
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
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        if (
            renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
            renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT ||
            renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED ||
            renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
        ) {
            if (blockId == BLOCK_FIRE || blockId == BLOCK_SOUL_FIRE) gl_Position = vec4(-1.0);
        }
    #else
        gl_Position = vec4(-1.0);
    #endif
}
