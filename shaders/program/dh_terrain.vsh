#define RENDER_TERRAIN_DH
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

// in vec4 mc_Entity;
//in vec3 vaPosition;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    // vec2 texcoord;
    vec3 localPos;
    // vec2 localCoord;
    vec3 localNormal;
    // vec4 localTangent;
    flat uint materialId;

    // flat int blockId;
    // flat mat2 atlasBounds;
    
    // #ifdef EFFECT_TAA_ENABLED
    //     vec3 velocity;
    // #endif

    // #if DISPLACE_MODE == DISPLACE_TESSELATION
    //     vec3 surfacePos;
    // #endif

    // #ifdef PARALLAX_ENABLED
    //     vec3 viewPos_T;

    //     #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED
    //         vec3 lightPos_T;
    //     #endif
    // #endif

    #ifdef RENDER_CLOUD_SHADOWS_ENABLED
        vec3 cloudPos;
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vOut;

uniform sampler2D lightmap;

// #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
//     uniform sampler2D noisetex;
// #endif

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
// uniform vec3 previousCameraPosition;
// uniform ivec2 atlasSize;

// #ifdef ANIM_WORLD_TIME
//     uniform int worldTime;
// #else
//     uniform float frameTimeCounter;
// #endif

#ifdef IS_IRIS
    // uniform bool firstPersonCamera;
    uniform vec3 eyePosition;
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
        uniform float cloudHeight = WORLD_CLOUD_HEIGHT;
    #endif
#endif

// #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != DYN_LIGHT_NONE //&& !defined RENDER_SHADOWS_ENABLED
//     // uniform vec3 previousCameraPosition;
//     uniform mat4 gbufferPreviousModelView;
// #endif

#ifdef EFFECT_TAA_ENABLED
    uniform float frameTime;
    // uniform int frameCounter;
    // uniform vec3 previousCameraPosition;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/utility/lightmap.glsl"

#ifdef RENDER_SHADOWS_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
    #endif
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa.glsl"
#endif


void main() {
    //vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;
    vOut.materialId = uint(dhMaterialId);

    vOut.lmcoord  = gl_MultiTexCoord1.xy;
    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec4 pos = gl_Vertex;
    vec4 viewPos = gl_ModelViewMatrix * pos;
    vOut.localPos = (gbufferModelViewInverse * viewPos).xyz;

    gl_Position = gl_ProjectionMatrix * viewPos;

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif


    //vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vOut.localNormal = gl_Normal;//mat3(gbufferModelViewInverse) * viewNormal;

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vOut.shadowTile = -1;
        #endif

        // #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && !defined RENDER_BILLBOARD
        //     vec3 skyLightDir = normalize(shadowLightPosition);
        //     float geoNoL = dot(skyLightDir, viewNormal);
        // #else
            const float geoNoL = 1.0;
        // #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
        #else
            vOut.shadowPos = ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL);
        #endif

        #if defined RENDER_CLOUD_SHADOWS_ENABLED && !defined RENDER_CLOUDS
            vOut.cloudPos = ApplyCloudShadows(vOut.localPos);
        #endif
    #endif
}
