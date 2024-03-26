#define RENDER_TERRAIN_DH
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

    // #ifdef RENDER_CLOUD_SHADOWS_ENABLED
    //     vec3 cloudPos;
    // #endif

    // #ifdef RENDER_SHADOWS_ENABLED
    //     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    //         vec3 shadowPos[4];
    //         flat int shadowTile;
    //     #else
    //         vec3 shadowPos;
    //     #endif
    // #endif
} vOut;

uniform sampler2D lightmap;

// #if defined IS_TRACING_ENABLED || defined IS_LPV_ENABLED
//     uniform sampler2D noisetex;
// #endif

uniform int frameCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

#ifdef IS_IRIS
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

    #if defined SHADOW_ENABLED && defined IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform float frameTime;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/utility/lightmap.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

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
        #include "/lib/shadows/distorted/apply.glsl"
    #endif
#endif

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.materialId = uint(dhMaterialId);
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec3 vPos = gl_Vertex.xyz;

    vec3 cameraOffset = fract(cameraPosition);
    vPos = floor(vPos + cameraOffset + 0.5) - cameraOffset;
    
    vec3 viewPos = mul3(gl_ModelViewMatrix, vPos);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    #if WORLD_CURVE_RADIUS > 0
        #ifdef WORLD_CURVE_SHADOWS
            vOut.localPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = mul3(gbufferModelView, vOut.localPos);
        #else
            vec3 worldPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = mul3(gbufferModelView, worldPos);
        #endif
    #endif

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif

    vOut.localNormal = normalize(gl_Normal);

    #ifdef RENDER_SHADOWS_ENABLED
        // #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        //     vOut.shadowTile = -1;
        // #endif

        // #if defined WORLD_SKY_ENABLED && defined RENDER_SHADOWS_ENABLED && !defined RENDER_BILLBOARD
        //     float geoNoL = dot(localSkyLightDirection, vOut.localNormal);
        // #else
        //     const float geoNoL = 1.0;
        // #endif

        // #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        //     ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL, vOut.shadowPos, vOut.shadowTile);
        // #else
        //     vOut.shadowPos = ApplyShadows(vOut.localPos, vOut.localNormal, geoNoL);
        // #endif

        // #if defined RENDER_CLOUD_SHADOWS_ENABLED && SKY_CLOUD_TYPE == CLOUD_TYPE_VANILLA
        //     vOut.cloudPos = ApplyCloudShadows(vOut.localPos);
        // #endif
    #endif
}
