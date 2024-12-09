#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_VERTEX

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
    vec3 localNormal;

    #ifdef DISTANT_HORIZONS
        float viewPosZ;
    #endif

    // #ifdef RENDER_SHADOWS_ENABLED
    //     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    //         vec3 shadowPos[4];
    //         flat int shadowTile;
    //     #else
    //         vec3 shadowPos;
    //     #endif
    // #endif
} vOut;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

// #ifdef WORLD_SHADOW_ENABLED
//     uniform mat4 shadowModelView;
//     uniform mat4 shadowProjection;
//     uniform vec3 shadowLightPosition;
//     uniform float far;

//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         uniform mat4 gbufferProjection;
//         uniform float near;
//     #endif

//     #ifdef RENDER_CLOUD_SHADOWS_ENABLED
//         uniform float cloudTime;
//         uniform vec3 eyePosition;
//     #endif

//     #ifdef DISTANT_HORIZONS
//         uniform float dhFarPlane;
//     #endif
// #endif

#ifdef EFFECT_TAA_ENABLED
    uniform int frameCounter;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/blocks.glsl"
#include "/lib/sampling/noise.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

// #ifdef WORLD_SHADOW_ENABLED
//     #include "/lib/utility/matrix.glsl"
//     #include "/lib/buffers/shadow.glsl"
//     #include "/lib/shadows/common.glsl"

//     #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
//         #include "/lib/shadows/cascaded/common.glsl"
//         #include "/lib/shadows/cascaded/apply.glsl"
//     #elif SHADOW_TYPE != SHADOW_TYPE_NONE
//         #include "/lib/shadows/distorted/common.glsl"
//         #include "/lib/shadows/distorted/apply.glsl"
//     #endif
// #endif

// #include "/lib/vertex_common.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.color = gl_Color;

    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    // TODO: scale?
    // vOut.localPos;

    #if WORLD_CURVE_RADIUS > 0
        #ifdef WORLD_CURVE_SHADOWS
            vOut.localPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = mul3(gbufferModelView, vOut.localPos);
        #else
            vec3 localPos = GetWorldCurvedPosition(vOut.localPos);
            viewPos = mul3(gbufferModelView, localPos);
        #endif
    #endif

    #ifdef DISTANT_HORIZONS
        vOut.viewPosZ = -viewPos.z;
    #endif

    vec3 viewNormal = gl_NormalMatrix * gl_Normal;
    vOut.localNormal = mat3(gbufferModelViewInverse) * viewNormal;

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);

    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
