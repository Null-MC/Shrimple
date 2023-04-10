#define RENDER_SHADOW
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 mc_Entity;
in vec3 vaPosition;
in vec3 at_midBlock;

out vec2 vTexcoord;
out vec4 vColor;

flat out vec3 vOriginPos;
flat out int vBlockId;
flat out int vVertexId;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform int renderStage;
uniform vec4 entityColor;
uniform int entityId;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform float near;
    uniform float far;
#endif

#ifdef WORLD_WAVING_ENABLED
    #include "/lib/blocks.glsl"
    #include "/lib/sampling/noise.glsl"
    #include "/lib/world/waving.glsl"
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
    #include "/lib/items.glsl"
    #include "/lib/entities.glsl"
    #include "/lib/lighting/dynamic_entities.glsl"
#endif


void main() {
    vTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;

    int blockId = int(mc_Entity.x + 0.5);

    vOriginPos = gl_Vertex.xyz;
    if (blockId < BLOCK_LIGHT_1 || blockId > BLOCK_LIGHT_15) {
        vOriginPos += at_midBlock / 64.0;
    }

    vOriginPos = (gl_ModelViewMatrix * vec4(vOriginPos, 1.0)).xyz;
    vOriginPos = (shadowModelViewInverse * vec4(vOriginPos, 1.0)).xyz;

    vVertexId = gl_VertexID;
    if (renderStage == MC_RENDER_STAGE_ENTITIES) {
        // #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE != DYN_LIGHT_NONE
        //     vVertexId = GetWrappedVertexID(entityId);
        // #endif
        vBlockId = -1;
    }
    else {
        vBlockId = blockId;
    }

    vec4 pos = gl_Vertex;

    #ifdef WORLD_WAVING_ENABLED
        ApplyWavingOffset(pos.xyz, blockId);
    #endif

    gl_Position = gl_ModelViewMatrix * pos;
}
