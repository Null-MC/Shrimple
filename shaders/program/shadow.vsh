#define RENDER_SHADOW
#define RENDER_VERTEX

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec4 mc_Entity;
in vec3 vaPosition;
in vec3 at_midBlock;

out vec2 vTexcoord;
out vec4 vColor;

flat out vec3 vOriginPos;
flat out int vBlockId;
flat out int vEntityId;
flat out int vVertexId;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform int renderStage;
uniform int entityId;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferProjection;
    uniform float near;
    uniform float far;
#endif

#ifdef ENABLE_WAVING
    #include "/lib/world/waving.glsl"
#endif

#if DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined IRIS_FEATURE_SSBO
    #include "/lib/entities.glsl"
    #include "/lib/lighting/dynamic_entities.glsl"
#endif


void main() {
    vTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;

    int blockId = int(mc_Entity.x + 0.5);

    vOriginPos = gl_Vertex.xyz + at_midBlock / 64.0;
    vOriginPos = (gl_ModelViewMatrix * vec4(vOriginPos, 1.0)).xyz;
    vOriginPos = (shadowModelViewInverse * vec4(vOriginPos, 1.0)).xyz;

    vVertexId = -1;
    if (renderStage == MC_RENDER_STAGE_ENTITIES) {
        vEntityId = entityId;

        #if DYN_LIGHT_MODE != DYN_LIGHT_NONE && defined IRIS_FEATURE_SSBO
            vVertexId = GetWrappedVertexID();
        #endif
    }
    else {
        vBlockId = blockId;
    }

    vec4 pos = gl_Vertex;

    #ifdef ENABLE_WAVING
        if (blockId >= 10001 && blockId <= 10004)
            pos.xyz += GetWavingOffset();
    #endif

    gl_Position = gl_ModelViewMatrix * pos;
}
