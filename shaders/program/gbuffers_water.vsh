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

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 vPos;
out vec3 vNormal;
out float geoNoL;
out vec3 vLocalPos;
out vec2 vLocalCoord;
out vec3 vLocalNormal;
out vec3 vLocalTangent;
out vec3 vBlockLight;
out float vTangentW;
flat out int vBlockId;
flat out mat2 atlasBounds;

#if MATERIAL_PARALLAX != PARALLAX_NONE || defined WORLD_WATER_ENABLED
    out vec3 tanViewPos;

    #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
        out vec3 tanLightPos;
    #endif
#endif

#if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
    out vec3 physics_localPosition;
    out float physics_localWaviness;
#endif

#ifdef RENDER_CLOUD_SHADOWS_ENABLED
    out vec3 cloudPos;
#endif

#if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        out vec3 shadowPos[4];
        flat out int shadowTile;
    #else
        out vec3 shadowPos;
    #endif
#endif

uniform sampler2D lightmap;
//uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

#ifdef ANIM_WORLD_TIME
    uniform int worldTime;
#else
    uniform float frameTimeCounter;
#endif

#if defined WORLD_WATER_ENABLED && defined WORLD_SKY_ENABLED
    uniform float rainStrength;
#endif

#ifdef WORLD_SHADOW_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 shadowLightPosition;
    uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        uniform mat4 gbufferProjection;
        uniform float near;
    #endif

    #if SHADOW_TYPE != SHADOW_TYPE_NONE && defined IS_IRIS
        uniform float cloudTime;
        //uniform vec3 eyePosition;
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

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
    #include "/lib/buffers/lighting.glsl"
#endif

#include "/lib/blocks.glsl"
//#include "/lib/items.glsl"
#include "/lib/anim.glsl"

//#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/atlas.glsl"
#include "/lib/utility/tbn.glsl"

#if defined WORLD_SKY_ENABLED && defined WORLD_WAVING_ENABLED
    #include "/lib/world/waving.glsl"
#endif

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/shadows/clouds.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/distorted/common.glsl"
    #endif
#endif

// #ifdef DYN_LIGHT_FLICKER
//     #include "/lib/lighting/blackbody.glsl"
//     #include "/lib/lighting/flicker.glsl"
// #endif

// #ifdef IRIS_FEATURE_SSBO
//     #if DYN_LIGHT_MODE != DYN_LIGHT_NONE
//         #include "/lib/lighting/voxel/blocks.glsl"
//     #endif
// #endif

#include "/lib/lights.glsl"

// #include "/lib/lighting/voxel/lights.glsl"
// #include "/lib/lighting/voxel/items.glsl"
// #include "/lib/lighting/fresnel.glsl"
// #include "/lib/lighting/sampling.glsl"

#include "/lib/material/emission.glsl"
#include "/lib/material/normalmap.glsl"
//#include "/lib/material/subsurface.glsl"

//#include "/lib/lighting/basic_hand.glsl"
#include "/lib/lighting/basic.glsl"

#ifdef WORLD_WATER_ENABLED
    //#include "/lib/world/water.glsl"

    #ifdef PHYSICS_OCEAN
        #include "/lib/physics_mod/ocean.glsl"
    #elif WORLD_WATER_WAVES != WATER_WAVES_NONE
        #include "/lib/world/water_waves.glsl"
    #endif
#endif


void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    BasicVertex();

    PrepareNormalMap();

    GetAtlasBounds(atlasBounds, vLocalCoord);

    #if MATERIAL_PARALLAX != PARALLAX_NONE || defined WORLD_WATER_ENABLED
        vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
        vec3 viewTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        mat3 matViewTBN = GetViewTBN(viewNormal, viewTangent);

        tanViewPos = vPos * matViewTBN;

        #ifdef WORLD_SHADOW_ENABLED
            tanLightPos = shadowLightPosition * matViewTBN;
        #endif
    #endif

    #if defined WORLD_WATER_ENABLED
        if (vBlockId == BLOCK_WATER) {
            vec4 finalPosition = gl_Vertex;

            float distF = saturate((length(vPos) - 1.0) * 0.5);
            distF = smoothstep(0.0, 1.0, distF);

            #ifdef PHYSICS_OCEAN
                physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

                #ifdef WATER_DISPLACEMENT
                    finalPosition.y += distF * physics_waveHeight(gl_Vertex.xz, PHYSICS_ITERATIONS_OFFSET, physics_localWaviness, physics_gameTime);
                #endif

                physics_localPosition = finalPosition.xyz;
            #elif WORLD_WATER_WAVES != WATER_WAVES_NONE && defined WATER_DISPLACEMENT
                float skyLight = saturate((lmcoord.y - (0.5/16.0)) / (15.0/16.0));
                finalPosition.y += distF * water_waveHeight(vLocalPos.xz + cameraPosition.xz, skyLight);
            #endif

            gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * finalPosition);
        }
    #endif
}
