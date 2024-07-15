#define RENDER_PARTICLES
#define RENDER_GBUFFER
#define RENDER_VERTEX

#define RENDER_BILLBOARD

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if defined DEFERRED_BUFFER_ENABLED && (!defined RENDER_TRANSLUCENT || (defined RENDER_TRANSLUCENT && defined DEFER_TRANSLUCENT))
    #define IS_RENDER_DEFERRED
#endif

#ifdef MATERIAL_PARTICLES
    in vec4 at_tangent;
    in vec4 mc_midTexCoord;
#endif

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec3 localNormal;

    #ifdef MATERIAL_PARTICLES
        vec2 localCoord;
        vec4 localTangent;

        flat mat2 atlasBounds;
    #endif

    #if defined RENDER_SHADOWS_ENABLED && !defined IS_RENDER_DEFERRED
        #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
            vec3 shadowPos[4];
            flat int shadowTile;
        #else
            vec3 shadowPos;
        #endif
    #endif
} vOut;

uniform sampler2D lightmap;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

#if defined RENDER_SHADOWS_ENABLED && !defined IS_RENDER_DEFERRED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform vec3 shadowLightPosition;
    uniform float far;

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        attribute vec3 at_midBlock;

        uniform mat4 gbufferProjection;
        uniform float near;
    #endif

    #if SHADOW_TYPE != SHADOW_TYPE_NONE && defined IS_IRIS
        uniform float cloudTime;
        uniform float cloudHeight;
        uniform vec3 eyePosition;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float dhFarPlane;
    #endif
#endif

#ifdef EFFECT_TAA_ENABLED
    uniform float frameTime;
    uniform int frameCounter;
    uniform vec2 pixelSize;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/utility/lightmap.glsl"

#if WORLD_CURVE_RADIUS > 0
    #include "/lib/world/curvature.glsl"
#endif

#if defined RENDER_SHADOWS_ENABLED && !defined IS_RENDER_DEFERRED
    #include "/lib/utility/matrix.glsl"
    #include "/lib/buffers/shadow.glsl"

    #ifdef SHADOW_CLOUD_ENABLED
        #include "/lib/clouds/cloud_vanilla.glsl"
    #endif
    
    #include "/lib/shadows/common.glsl"

    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        #include "/lib/shadows/cascaded/common.glsl"
        #include "/lib/shadows/cascaded/apply.glsl"
    #else
        #include "/lib/shadows/distorted/common.glsl"
        #include "/lib/shadows/distorted/apply.glsl"
    #endif
#endif

#ifdef MATERIAL_PARTICLES
    #include "/lib/sampling/atlas.glsl"
    #include "/lib/utility/tbn.glsl"

    #include "/lib/material/normalmap.glsl"
#endif

#include "/lib/vertex_common.glsl"

#ifdef EFFECT_TAA_ENABLED
    #include "/lib/effects/taa_jitter.glsl"
#endif


void main() {
    vOut.texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.color = gl_Color;

    vOut.lmcoord = LightMapNorm(vOut.lmcoord);

    vec4 viewPos = BasicVertex();
    gl_Position = gl_ProjectionMatrix * viewPos;

    #ifdef MATERIAL_PARTICLES
        PrepareNormalMap();

        GetAtlasBounds(vOut.texcoord, vOut.atlasBounds, vOut.localCoord);
    #endif
    
    #ifdef EFFECT_TAA_ENABLED
        jitter(gl_Position);
    #endif
}
