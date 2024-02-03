#define RENDER_WATER_DH
#define RENDER_GBUFFER
#define RENDER_VERTEX

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 localNormal;

    flat uint materialId;

    #if defined WORLD_WATER_ENABLED && defined PHYSICS_OCEAN
        vec3 physics_localPosition;
        float physics_localWaviness;
    #endif

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

#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE != DYN_LIGHT_NONE //&& !defined RENDER_SHADOWS_ENABLED
    uniform sampler2D noisetex;
#endif

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

#ifdef WORLD_WATER_ENABLED
    uniform int isEyeInWater;

    #ifdef WORLD_SKY_ENABLED
        uniform float rainStrength;
    #endif
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

    #ifdef IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
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
#endif

#include "/lib/utility/lightmap.glsl"

#if WORLD_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#ifdef WORLD_SHADOW_ENABLED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
    #elif SHADOW_TYPE != SHADOW_TYPE_NONE
        #include "/lib/shadows/distorted/common.glsl"
    #endif
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa.glsl"
#endif


void main() {
    bool isWater = (dhMaterialId == DH_BLOCK_WATER);

    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.materialId = uint(dhMaterialId);
    vOut.localNormal = gl_Normal;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec4 vPos = gl_Vertex;
    
    vec3 cameraOffset = fract(cameraPosition);
    vPos.xyz = floor(vPos.xyz + cameraOffset + 0.5) - cameraOffset;

    if (isWater) vPos.y -= (2.0/16.0);

    vec4 viewPos = gl_ModelViewMatrix * vPos;

    vOut.localPos = (gbufferModelViewInverse * viewPos).xyz;

    #if WORLD_RADIUS > 0
        #ifdef WORLD_CURVE_SHADOWS
            vOut.localPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = gbufferModelView * vec4(vOut.localPos, 1.0);
        #else
            vec3 worldPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = gbufferModelView * vec4(worldPos, 1.0);
        #endif
    #endif

    gl_Position = gl_ProjectionMatrix * viewPos;

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif

    #if defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vOut.shadowTile = -1;
        #endif

        #if defined WORLD_SKY_ENABLED && defined WORLD_SHADOW_ENABLED && SHADOW_TYPE != SHADOW_TYPE_NONE && !defined RENDER_BILLBOARD
            float geoNoL = dot(localSkyLightDirection, vOut.localNormal);
        #else
            float geoNoL = 1.0;
        #endif

        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
        #else
            vOut.shadowPos = ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL);
        #endif

        #if defined RENDER_CLOUD_SHADOWS_ENABLED
            vOut.cloudPos = ApplyCloudShadows(vOut.localPos);
        #endif
    #endif
}
