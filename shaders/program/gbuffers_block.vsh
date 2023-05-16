#define RENDER_BLOCK
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec3 at_midBlock;
in vec4 at_tangent;
in vec4 mc_Entity;
in vec4 mc_midTexCoord;
in vec3 vaPosition;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 vPos;
out vec3 vNormal;
out float geoNoL;
out vec3 vBlockLight;
out vec3 vLocalPos;
out vec2 vLocalCoord;
out vec3 vLocalNormal;
out vec3 vLocalTangent;
out float vTangentW;
flat out int vBlockId;
flat out mat2 atlasBounds;

#if MATERIAL_PARALLAX != PARALLAX_NONE
    out vec3 tanViewPos;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
        out vec3 tanLightPos;
    #endif
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
//uniform sampler2D noisetex;

//uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
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

// uniform int heldItemId;
// uniform int heldItemId2;
// uniform int heldBlockLightValue;
// uniform int heldBlockLightValue2;

#ifdef IS_IRIS
    uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
#endif

#include "/lib/blocks.glsl"
#include "/lib/items.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

//#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/atlas.glsl"

#if MATERIAL_NORMALS != NORMALMAP_NONE || MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/utility/tbn.glsl"
#endif

// #ifdef DYN_LIGHT_FLICKER
//     #include "/lib/lighting/blackbody.glsl"
//     #include "/lib/lighting/flicker.glsl"
// #endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded.glsl"
    #else
        #include "/lib/shadows/basic.glsl"
    #endif
#endif

#include "/lib/material/normalmap.glsl"
// #include "/lib/lighting/voxel/lights.glsl"
// #include "/lib/lighting/voxel/items.glsl"
// #include "/lib/lighting/fresnel.glsl"
// #include "/lib/lighting/sampling.glsl"

// #include "/lib/lighting/basic_hand.glsl"
#include "/lib/lighting/basic.glsl"


void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    BasicVertex();

    PrepareNormalMap();

    GetAtlasBounds(atlasBounds, vLocalCoord);

    #if MATERIAL_PARALLAX != PARALLAX_NONE
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent);

        tanViewPos = vPos * matViewTBN;

        #ifdef WORLD_SHADOW_ENABLED
            tanLightPos = shadowLightPosition * matViewTBN;
        #endif
    #endif
}
