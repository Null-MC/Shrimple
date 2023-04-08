#define RENDER_WATER
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 mc_Entity;
in vec3 vaPosition;
in vec3 at_midBlock;

#if MATERIAL_PARALLAX != PARALLAX_NONE || (defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN)
    in vec4 mc_midTexCoord;
#endif

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 vPos;
out vec3 vNormal;
out float geoNoL;
out float vLit;
out vec3 vLocalPos;
out vec3 vLocalNormal;
out vec3 vBlockLight;
flat out int vBlockId;

#if MATERIAL_NORMALS != NORMALMAP_NONE
    in vec4 at_tangent;

    out vec3 vLocalTangent;
    out float vTangentW;
#endif

#if MATERIAL_PARALLAX != PARALLAX_NONE || (defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN)
    out vec2 vLocalCoord;
    //out vec3 tanViewPos;
    flat out mat2 atlasBounds;
#endif

#if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
    out vec3 physics_localPosition;
    out float physics_localWaviness;
#endif

#ifdef WORLD_SHADOW_ENABLED
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        out vec3 shadowPos[4];
        flat out int shadowTile;
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        out vec3 shadowPos;
    #endif
#endif

uniform sampler2D lightmap;
uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

#ifdef WORLD_SHADOW_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 shadowLightPosition;
    uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferProjection;
        uniform float near;
    #endif
#endif

#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
    uniform int heldItemId;
    uniform int heldItemId2;
    uniform int heldBlockLightValue;
    uniform int heldBlockLightValue2;
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#include "/lib/blocks.glsl"
#include "/lib/sampling/atlas.glsl"
#include "/lib/sampling/noise.glsl"
#include "/lib/world/waving.glsl"

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/basic.glsl"
    #endif
#endif

#ifdef IRIS_FEATURE_SSBO
    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        #include "/lib/items.glsl"
        #include "/lib/lighting/blackbody.glsl"
        #include "/lib/lighting/flicker.glsl"
    #endif

    #if DYN_LIGHT_MODE == DYN_LIGHT_VERTEX
        #include "/lib/buffers/lighting.glsl"
        #include "/lib/lighting/dynamic.glsl"
    #endif

    #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
        #include "/lib/lighting/dynamic_lights.glsl"
        #include "/lib/lighting/dynamic_blocks.glsl"
        #include "/lib/lighting/dynamic_items.glsl"
    #endif
#endif

#include "/lib/material/emission.glsl"
#include "/lib/material/subsurface.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE
    #include "/lib/material/normalmap.glsl"
#endif

#if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
    #include "/lib/physics_mod/ocean.glsl"
#endif

#include "/lib/lighting/sampling.glsl"
#include "/lib/lighting/basic.glsl"


void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    BasicVertex();

    #if MATERIAL_NORMALS != NORMALMAP_NONE
        PrepareNormalMap();
    #endif

    #if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
        vTangentW = at_tangent.w;
    #endif

    #if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
        if (vBlockId == BLOCK_WATER) {
            physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;
            vec4 finalPosition = vec4(gl_Vertex.x, gl_Vertex.y + physics_waveHeight(gl_Vertex.xz, PHYSICS_ITERATIONS_OFFSET, physics_localWaviness, physics_gameTime), gl_Vertex.z, gl_Vertex.w);
            physics_localPosition = finalPosition.xyz;

            gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * finalPosition);
        }
    #endif

    #if MATERIAL_PARALLAX != PARALLAX_NONE || (defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN)
        GetAtlasBounds(atlasBounds, vLocalCoord);
    #endif
}
